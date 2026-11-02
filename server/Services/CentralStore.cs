using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.Data.Sqlite;

namespace PdksApp.Services;

// Separate database keeps the existing application database untouched.
public sealed class CentralStore
{
    private readonly string connectionString;
    public string Root { get; }
    private readonly byte[] keyHash;
    public CentralStore(IWebHostEnvironment env, IConfiguration configuration)
    {
        Root = configuration["Central:StoragePath"] ?? Path.Combine(env.ContentRootPath, "App_Data", "central");
        Directory.CreateDirectory(Path.Combine(Root, "files"));
        var keyPath = Path.Combine(Root, "connection.key");
        if (!File.Exists(keyPath)) File.WriteAllText(keyPath, Convert.ToHexString(RandomNumberGenerator.GetBytes(32)));
        keyHash = SHA256.HashData(Encoding.UTF8.GetBytes(File.ReadAllText(keyPath).Trim()));
        connectionString = new SqliteConnectionStringBuilder { DataSource = Path.Combine(Root, "central.db") }.ToString();
        using var db = Open();
        using var cmd = db.CreateCommand();
        cmd.CommandText = """
            PRAGMA journal_mode=WAL;
            CREATE TABLE IF NOT EXISTS Collections (Key TEXT PRIMARY KEY, Value TEXT NOT NULL, Version INTEGER NOT NULL);
            CREATE TABLE IF NOT EXISTS Files (Id TEXT PRIMARY KEY, Name TEXT NOT NULL, ContentType TEXT NOT NULL,
              Size INTEGER NOT NULL, CompanyId TEXT NOT NULL, EmployeeId TEXT NOT NULL, Category TEXT NOT NULL,
              UploadedAt TEXT NOT NULL, Sha256 TEXT NOT NULL);
            CREATE TABLE IF NOT EXISTS Changes (Id INTEGER PRIMARY KEY, ChangedAt TEXT NOT NULL, Keys TEXT NOT NULL);
            """;
        cmd.ExecuteNonQuery();
    }
    public SqliteConnection Open() { var db = new SqliteConnection(connectionString); db.Open(); return db; }
    public bool Authorized(HttpRequest request)
    {
        var header = request.Headers.Authorization.ToString();
        return header.StartsWith("Bearer ", StringComparison.Ordinal) &&
            CryptographicOperations.FixedTimeEquals(keyHash, SHA256.HashData(Encoding.UTF8.GetBytes(header[7..])));
    }
    public static bool ValidKey(string key) => key.StartsWith("pdks_db_", StringComparison.Ordinal) &&
        key.Length < 100 && key.All(c => char.IsAsciiLetterOrDigit(c) || c == '_') &&
        !new[] { "session", "logged_in", "last_user", "saved_company_code", "failed_pin", "pin_lockout", "theme_mode", "active_company_id", "offline_queue" }.Any(key.Contains);

    public Dictionary<string, CentralValue> Snapshot()
    {
        using var db = Open(); using var cmd = db.CreateCommand();
        cmd.CommandText = "SELECT Key, Value, Version FROM Collections";
        using var rows = cmd.ExecuteReader(); var result = new Dictionary<string, CentralValue>();
        while (rows.Read()) result[rows.GetString(0)] = new(JsonSerializer.Deserialize<JsonElement>(rows.GetString(1)), rows.GetInt64(2));
        return result;
    }
}

public record CentralValue(JsonElement Value, long Version);
public record CentralChange(string Key, JsonElement Value, long ExpectedVersion);
public record CentralBatch(List<CentralChange> Changes);

public static class CentralEndpoints
{
    public static void MapCentralStore(this WebApplication app)
    {
        var api = app.MapGroup("/api/central").RequireCors("CentralClient");
        api.AddEndpointFilter(async (ctx, next) =>
        {
            var store = ctx.HttpContext.RequestServices.GetRequiredService<CentralStore>();
            ctx.HttpContext.Response.Headers.CacheControl = "no-store";
            return store.Authorized(ctx.HttpContext.Request) ? await next(ctx) : Results.Unauthorized();
        });
        api.MapGet("/snapshot", (CentralStore store) => Results.Ok(new { collections = store.Snapshot() }));
        api.MapPost("/sync", (CentralBatch batch, CentralStore store) =>
        {
            if (batch.Changes is null || batch.Changes.Count > 100 || batch.Changes.Select(x => x.Key).Distinct().Count() != batch.Changes.Count ||
                batch.Changes.Any(c => !CentralStore.ValidKey(c.Key) || c.Value.ValueKind == JsonValueKind.Undefined || c.Value.GetRawText().Length > 12_000_000))
                return Results.BadRequest(new { message = "Geçersiz koleksiyon veya veri boyutu." });
            using var db = store.Open(); using var tx = db.BeginTransaction();
            var versions = new Dictionary<string, long>();
            foreach (var change in batch.Changes)
            {
                using var check = db.CreateCommand(); check.Transaction = tx;
                check.CommandText = "SELECT Version FROM Collections WHERE Key=$key"; check.Parameters.AddWithValue("$key", change.Key);
                var current = Convert.ToInt64(check.ExecuteScalar() ?? 0L);
                if (current != change.ExpectedVersion) return Results.Conflict(new { message = "Veri başka bir cihazda değişti. Yerel kayıtlarınız korundu.", key = change.Key });
                versions[change.Key] = current + 1;
            }
            foreach (var change in batch.Changes)
            {
                using var put = db.CreateCommand(); put.Transaction = tx;
                put.CommandText = "INSERT INTO Collections(Key,Value,Version) VALUES($k,$v,$r) ON CONFLICT(Key) DO UPDATE SET Value=$v,Version=$r";
                put.Parameters.AddWithValue("$k", change.Key); put.Parameters.AddWithValue("$v", change.Value.GetRawText()); put.Parameters.AddWithValue("$r", versions[change.Key]); put.ExecuteNonQuery();
            }
            using var audit = db.CreateCommand(); audit.Transaction = tx;
            audit.CommandText = "INSERT INTO Changes(ChangedAt,Keys) VALUES($t,$k)";
            audit.Parameters.AddWithValue("$t", DateTimeOffset.UtcNow.ToString("O")); audit.Parameters.AddWithValue("$k", JsonSerializer.Serialize(versions.Keys)); audit.ExecuteNonQuery();
            tx.Commit(); return Results.Ok(new { versions });
        });

        api.MapGet("/files", (CentralStore store, string? companyId) =>
        {
            using var db = store.Open(); using var cmd = db.CreateCommand();
            cmd.CommandText = "SELECT Id,Name,ContentType,Size,CompanyId,EmployeeId,Category,UploadedAt,Sha256 FROM Files WHERE $c='' OR CompanyId=$c ORDER BY UploadedAt DESC";
            cmd.Parameters.AddWithValue("$c", companyId ?? ""); using var rows = cmd.ExecuteReader();
            var files = new List<object>(); while (rows.Read()) files.Add(new { id = rows.GetString(0), name = rows.GetString(1), contentType = rows.GetString(2), size = rows.GetInt64(3), companyId = rows.GetString(4), employeeId = rows.GetString(5), category = rows.GetString(6), uploadedAt = rows.GetString(7), sha256 = rows.GetString(8) });
            return Results.Ok(files);
        });
        api.MapPost("/files", async (HttpRequest request, CentralStore store) =>
        {
            if (!request.HasFormContentType) return Results.BadRequest(new { message = "Dosya seçiniz." });
            var form = await request.ReadFormAsync(); var file = form.Files.GetFile("file");
            if (file is null || file.Length == 0 || file.Length > 10 * 1024 * 1024) return Results.BadRequest(new { message = "Dosya 1 bayt–10 MB arasında olmalı." });
            var types = new Dictionary<string, string> { [".jpg"] = "image/jpeg", [".jpeg"] = "image/jpeg", [".png"] = "image/png", [".pdf"] = "application/pdf" };
            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (!types.TryGetValue(extension, out var mime)) return Results.BadRequest(new { message = "Yalnızca JPG, PNG ve PDF yükleyebilirsiniz." });
            using var buffer = new MemoryStream(); await file.CopyToAsync(buffer); var bytes = buffer.ToArray();
            var valid = extension == ".pdf" ? bytes.AsSpan().StartsWith("%PDF-"u8) : extension == ".png" ? bytes.AsSpan().StartsWith(new byte[] {137,80,78,71,13,10,26,10}) : bytes.AsSpan().StartsWith(new byte[] {255,216,255});
            if (!valid) return Results.BadRequest(new { message = "Dosya içeriği uzantısıyla eşleşmiyor." });
            var companyId = form["companyId"].ToString(); var employeeId = form["employeeId"].ToString(); var category = form["category"].ToString();
            if (string.IsNullOrWhiteSpace(companyId) || companyId.Length > 100 || employeeId.Length > 100 || category.Length > 100) return Results.BadRequest(new { message = "Şirket bilgisi gerekli." });
            var name = Path.GetFileName(file.FileName.Replace('\\', '/'));
            if (name.Length > 200) return Results.BadRequest(new { message = "Dosya adı çok uzun." });
            var id = Guid.NewGuid().ToString("N"); var path = Path.Combine(store.Root, "files", id);
            await File.WriteAllBytesAsync(path, bytes);
            try {
                using var db = store.Open(); using var cmd = db.CreateCommand();
                cmd.CommandText = "INSERT INTO Files VALUES($i,$n,$t,$s,$c,$e,$g,$d,$h)";
                cmd.Parameters.AddWithValue("$i", id); cmd.Parameters.AddWithValue("$n", name); cmd.Parameters.AddWithValue("$t", mime); cmd.Parameters.AddWithValue("$s", bytes.Length);
                cmd.Parameters.AddWithValue("$c", companyId); cmd.Parameters.AddWithValue("$e", employeeId); cmd.Parameters.AddWithValue("$g", category);
                cmd.Parameters.AddWithValue("$d", DateTimeOffset.UtcNow.ToString("O")); cmd.Parameters.AddWithValue("$h", Convert.ToHexString(SHA256.HashData(bytes))); cmd.ExecuteNonQuery();
            } catch { File.Delete(path); throw; }
            return Results.Ok(new { id, name, contentType = mime, size = bytes.Length });
        }).DisableAntiforgery();
        api.MapGet("/files/{id}", (string id, CentralStore store, HttpResponse response) =>
        {
            if (!Guid.TryParseExact(id, "N", out _)) return Results.NotFound();
            using var db = store.Open(); using var cmd = db.CreateCommand();
            cmd.CommandText = "SELECT Name,ContentType FROM Files WHERE Id=$i"; cmd.Parameters.AddWithValue("$i", id); using var row = cmd.ExecuteReader();
            var path = Path.Combine(store.Root, "files", id);
            if (!row.Read() || !File.Exists(path)) return Results.NotFound();
            response.Headers["X-Content-Type-Options"] = "nosniff";
            return Results.File(path, row.GetString(1), row.GetString(0));
        });
        api.MapDelete("/files/{id}", (string id, CentralStore store) =>
        {
            if (!Guid.TryParseExact(id, "N", out _)) return Results.NotFound();
            using var db = store.Open(); using var cmd = db.CreateCommand();
            cmd.CommandText = "DELETE FROM Files WHERE Id=$i"; cmd.Parameters.AddWithValue("$i", id);
            if (cmd.ExecuteNonQuery() == 0) return Results.NotFound();
            File.Delete(Path.Combine(store.Root, "files", id)); return Results.NoContent();
        });
    }
}
