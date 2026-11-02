using Microsoft.EntityFrameworkCore;
using PdksApp.Data;
using PdksApp.Models;
using PdksApp.Services;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddSingleton<CentralStore>();
builder.Services.Configure<Microsoft.AspNetCore.Http.Features.FormOptions>(o => o.MultipartBodyLengthLimit = 11 * 1024 * 1024);
builder.Services.AddCors(options => options.AddPolicy("CentralClient", policy => policy
    .SetIsOriginAllowed(origin => Uri.TryCreate(origin, UriKind.Absolute, out var uri) &&
        (uri.IsLoopback || (builder.Configuration["Central:AllowedOrigins"] ?? "").Split(';').Contains(origin)))
    .AllowAnyHeader().AllowAnyMethod()));

// Add services to the container.
builder.Services.AddRazorPages();

// SQLite Veritabanı Bağlantısı
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite("Data Source=pdks.db"));

var app = builder.Build();

// Otomatik DB oluştur ve Seed datayı yükle
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.EnsureCreated();
}

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseRouting();
app.UseCors();
app.UseAuthorization();

app.MapStaticAssets();
app.MapRazorPages().WithStaticAssets();

// ==========================================
// Mobil GPS Check-in / Check-out API Uçları
// ==========================================

app.MapPost("/api/attendance/check", async (AttendanceRequest req, AppDbContext db) =>
{
    var employee = await db.Employees
        .Include(e => e.Company)
        .FirstOrDefaultAsync(e => e.Id == req.EmployeeId && e.IsActive);

    if (employee == null)
    {
        return Results.NotFound(new { success = false, message = "Personel bulunamadı veya pasif durumda." });
    }

    if (employee.PinCode != req.PinCode)
    {
        return Results.BadRequest(new { success = false, message = "Hatalı PIN kodu girdiniz." });
    }

    var company = employee.Company;
    if (company == null || !company.IsActive)
    {
        return Results.BadRequest(new { success = false, message = "Şirket hesabı veya aboneliği aktif değil." });
    }

    // GPS Mesafe Doğrulaması (Haversine)
    double distance = GeoLocationService.CalculateDistanceInMeters(
        req.Latitude, req.Longitude,
        company.OfficeLatitude, company.OfficeLongitude
    );

    bool isLocationVerified = distance <= company.AllowedRadiusMeters;

    var record = new AttendanceRecord
    {
        EmployeeId = employee.Id,
        CompanyId = company.Id,
        Type = (AttendanceType)req.AttendanceType,
        Timestamp = DateTime.UtcNow,
        UserLatitude = req.Latitude,
        UserLongitude = req.Longitude,
        CalculatedDistanceMeters = Math.Round(distance, 1),
        IsLocationVerified = isLocationVerified,
        DeviceInfo = req.DeviceInfo ?? "Mobil Cihaz",
        Note = isLocationVerified
            ? $"Ofis sınırları içinde ({Math.Round(distance, 0)} m)."
            : $"Konum doğrulanamadı! Ofise uzaklık: {Math.Round(distance, 0)} m (İzin: {company.AllowedRadiusMeters} m)"
    };

    db.AttendanceRecords.Add(record);
    await db.SaveChangesAsync();

    if (!isLocationVerified)
    {
        return Results.BadRequest(new
        {
            success = false,
            distance = Math.Round(distance, 0),
            allowedRadius = company.AllowedRadiusMeters,
            message = $"Giriş/Çıkış yapılamadı: Ofis lokasyonunun dışındasınız ({Math.Round(distance, 0)} metre uzaktasınız, izin: {company.AllowedRadiusMeters} m)."
        });
    }

    return Results.Ok(new
    {
        success = true,
        type = record.Type == AttendanceType.CheckIn ? "Giriş" : "Çıkış",
        employee = employee.FullName,
        time = record.Timestamp.AddHours(3).ToString("dd.MM.yyyy HH:mm:ss"), // TR Saati
        distance = Math.Round(distance, 0),
        message = $"İşlem başarılı! {employee.FullName} {(record.Type == AttendanceType.CheckIn ? "Giriş" : "Çıkış")} yapıldı."
    });
});

app.MapGet("/api/company/info", async (AppDbContext db) =>
{
    var company = await db.Companies.FirstOrDefaultAsync(c => c.Id == 1);
    if (company == null) return Results.NotFound();
    return Results.Ok(new
    {
        company.Id,
        company.Name,
        company.Plan,
        company.OfficeLatitude,
        company.OfficeLongitude,
        company.AllowedRadiusMeters
    });
});

app.MapGet("/api/employees", async (AppDbContext db) =>
{
    var employees = await db.Employees
        .Where(e => e.IsActive)
        .Select(e => new { e.Id, e.FullName, e.Department, e.Title, e.AnnualLeaveAllowance, e.UsedLeaveDays })
        .ToListAsync();
    return Results.Ok(employees);
});

// ==========================================
// İzin Yönetim API Uçları (Leave Management)
// ==========================================

// Personel İzin Talebi Oluşturma (Mobil / Web)
app.MapPost("/api/leave/create", async (CreateLeaveRequestDto dto, AppDbContext db) =>
{
    var employee = await db.Employees.FirstOrDefaultAsync(e => e.Id == dto.EmployeeId && e.IsActive);
    if (employee == null)
    {
        return Results.NotFound(new { success = false, message = "Personel bulunamadı." });
    }

    if (employee.PinCode != dto.PinCode)
    {
        return Results.BadRequest(new { success = false, message = "Geçersiz PIN kodu." });
    }

    if (!DateTime.TryParse(dto.StartDate, out var startDate) || !DateTime.TryParse(dto.EndDate, out var endDate))
    {
        return Results.BadRequest(new { success = false, message = "Geçersiz tarih formatı." });
    }

    if (endDate < startDate)
    {
        return Results.BadRequest(new { success = false, message = "Bitiş tarihi başlangıç tarihinden önce olamaz." });
    }

    int totalDays = Math.Max(1, (int)(endDate.Date - startDate.Date).TotalDays + 1);

    var leave = new LeaveRequest
    {
        CompanyId = employee.CompanyId,
        EmployeeId = employee.Id,
        Type = (LeaveType)dto.LeaveType,
        StartDate = startDate,
        EndDate = endDate,
        TotalDays = totalDays,
        Reason = dto.Reason,
        Status = LeaveStatus.Pending,
        CreatedAt = DateTime.UtcNow
    };

    db.LeaveRequests.Add(leave);
    await db.SaveChangesAsync();

    return Results.Ok(new
    {
        success = true,
        message = $"{totalDays} günlük izin talebiniz başarıyla yönetici onayına iletildi.",
        leaveId = leave.Id
    });
});

// Yönetici İzin Onay / Ret İşlemi
app.MapPost("/api/leave/process", async (ProcessLeaveRequestDto dto, AppDbContext db) =>
{
    var leave = await db.LeaveRequests
        .Include(l => l.Employee)
        .FirstOrDefaultAsync(l => l.Id == dto.RequestId);

    if (leave == null)
    {
        return Results.NotFound(new { success = false, message = "İzin talebi bulunamadı." });
    }

    leave.Status = (LeaveStatus)dto.NewStatus;
    leave.ManagerComment = dto.ManagerComment;
    leave.ProcessedAt = DateTime.UtcNow;

    // Eğer yıllık izin onaylandıysa personelin kullanılan izin gününü artır
    if (leave.Status == LeaveStatus.Approved && leave.Type == LeaveType.Annual && leave.Employee != null)
    {
        leave.Employee.UsedLeaveDays += leave.TotalDays;
    }

    await db.SaveChangesAsync();

    return Results.Ok(new
    {
        success = true,
        status = leave.Status.ToString(),
        message = leave.Status == LeaveStatus.Approved ? "İzin talebi onaylandı." : "İzin talebi reddedildi."
    });
});

// ==========================================
// Excel Puantaj Dışa Aktarma API Ucu
// ==========================================
app.MapGet("/api/reports/puantaj/excel", async (AppDbContext db, int? year, int? month) =>
{
    int targetYear = year ?? DateTime.UtcNow.Year;
    int targetMonth = month ?? DateTime.UtcNow.Month;

    var fileBytes = await PuantajExportService.GenerateExcelPuantajAsync(db, targetYear, targetMonth);
    string fileName = $"Puantaj_Raporu_{targetYear}_{targetMonth:00}.xlsx";

    return Results.File(
        fileBytes,
        contentType: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        fileDownloadName: fileName
    );
});

// ==========================================
// SaaS Abonelik & Ödeme API Ucu (200 TL / 2000 TL)
// ==========================================
app.MapPost("/api/subscription/upgrade", async (SubscribePlanDto dto, AppDbContext db) =>
{
    var company = await db.Companies.FirstOrDefaultAsync(c => c.Id == dto.CompanyId);
    if (company == null)
    {
        return Results.NotFound(new { success = false, message = "Şirket bulunamadı." });
    }

    if (string.IsNullOrWhiteSpace(dto.CardNumber) || dto.CardNumber.Replace(" ", "").Length < 16)
    {
        return Results.BadRequest(new { success = false, message = "Geçersiz kredi kartı numarası." });
    }

    // Abonelik güncelleme
    company.Plan = (SubscriptionPlan)dto.PlanType;
    if (company.Plan == SubscriptionPlan.Yearly)
    {
        company.SubscriptionStartDate = DateTime.UtcNow;
        company.SubscriptionEndDate = DateTime.UtcNow.AddYears(1);
    }
    else
    {
        company.SubscriptionStartDate = DateTime.UtcNow;
        company.SubscriptionEndDate = DateTime.UtcNow.AddMonths(1);
    }
    company.IsActive = true;

    await db.SaveChangesAsync();

    decimal amount = company.Plan == SubscriptionPlan.Yearly ? company.YearlyPrice : company.MonthlyPrice;
    string periodText = company.Plan == SubscriptionPlan.Yearly ? "Yıllık (2.000 TL)" : "Aylık (200 TL)";

    return Results.Ok(new
    {
        success = true,
        plan = periodText,
        amount = $"{amount:N2} TL",
        endDate = company.SubscriptionEndDate.ToString("dd.MM.yyyy"),
        message = $"Tebrikler! {periodText} PDKS aboneliğiniz başarıyla aktif edildi. Son geçerlilik: {company.SubscriptionEndDate:dd.MM.yyyy}"
    });
});

// ==========================================
// FAZLA MESAİ API UÇLARI
// ==========================================
app.MapPost("/api/overtime/create", async (CreateOvertimeDto dto, AppDbContext db) =>
{
    var employee = await db.Employees.FirstOrDefaultAsync(e => e.Id == dto.EmployeeId && e.IsActive);
    if (employee == null || employee.PinCode != dto.PinCode)
    {
        return Results.BadRequest(new { success = false, message = "Geçersiz personel veya PIN kodu." });
    }

    if (!DateTime.TryParse(dto.Date, out var date))
    {
        return Results.BadRequest(new { success = false, message = "Geçersiz tarih formatı." });
    }

    decimal estimatedPay = (decimal)dto.Hours * employee.HourlyRate;

    var record = new OvertimeRecord
    {
        CompanyId = employee.CompanyId,
        EmployeeId = employee.Id,
        OvertimeDate = date,
        Hours = dto.Hours,
        Reason = dto.Reason,
        EstimatedPay = estimatedPay,
        Status = ApprovalStatus.Pending,
        CreatedAt = DateTime.UtcNow
    };

    db.OvertimeRecords.Add(record);
    await db.SaveChangesAsync();

    return Results.Ok(new { success = true, message = $"{dto.Hours} saatlik fazla mesai talebiniz onaya gönderildi." });
});

// ==========================================
// İŞÇİLİK TALEBİ API UÇLARI
// ==========================================
app.MapPost("/api/labor/create", async (CreateLaborRequestDto dto, AppDbContext db) =>
{
    if (!DateTime.TryParse(dto.NeededDate, out var neededDate))
    {
        return Results.BadRequest(new { success = false, message = "Geçersiz ihtiyaç tarihi." });
    }

    var labor = new LaborRequest
    {
        CompanyId = 1,
        Department = dto.Department,
        PositionTitle = dto.PositionTitle,
        HeadCount = dto.HeadCount,
        NeededDate = neededDate,
        Justification = dto.Justification,
        Urgency = dto.Urgency,
        Status = ApprovalStatus.Pending,
        CreatedAt = DateTime.UtcNow
    };

    db.LaborRequests.Add(labor);
    await db.SaveChangesAsync();

    return Results.Ok(new { success = true, message = $"{dto.HeadCount} kişilik personel/işçilik talebi oluşturuldu." });
});

// ==========================================
// ZİYARETÇİ TAKİP API UÇLARI
// ==========================================
app.MapPost("/api/visitors/checkin", async (CreateVisitorDto dto, AppDbContext db) =>
{
    var visitor = new VisitorEntry
    {
        CompanyId = 1,
        VisitorFullName = dto.VisitorFullName,
        CompanyOrOrganization = dto.CompanyOrOrganization,
        Phone = dto.Phone,
        HostEmployeeName = dto.HostEmployeeName,
        Purpose = dto.Purpose,
        BadgeNumber = dto.BadgeNumber,
        CheckInTime = DateTime.UtcNow
    };

    db.VisitorEntries.Add(visitor);
    await db.SaveChangesAsync();

    return Results.Ok(new { success = true, message = $"{visitor.VisitorFullName} ziyaretçi girişi yapıldı." });
});

app.MapPost("/api/visitors/checkout/{id:int}", async (int id, AppDbContext db) =>
{
    var visitor = await db.VisitorEntries.FirstOrDefaultAsync(v => v.Id == id);
    if (visitor == null) return Results.NotFound(new { success = false, message = "Ziyaretçi bulunamadı." });

    visitor.CheckOutTime = DateTime.UtcNow;
    await db.SaveChangesAsync();

    return Results.Ok(new { success = true, message = $"{visitor.VisitorFullName} çıkış yaptı." });
});

// ==========================================
// MERKEZİ ONAYLARIM SİSTEMİ API UÇLARI
// ==========================================
app.MapPost("/api/approvals/process", async (ProcessApprovalDto dto, AppDbContext db) =>
{
    var status = (ApprovalStatus)dto.NewStatus;

    if (dto.ItemType == (int)ApprovalItemType.Leave)
    {
        var item = await db.LeaveRequests.Include(l => l.Employee).FirstOrDefaultAsync(l => l.Id == dto.ItemId);
        if (item == null) return Results.NotFound();
        item.Status = (LeaveStatus)dto.NewStatus;
        item.ManagerComment = dto.Comment;
        item.ProcessedAt = DateTime.UtcNow;
        if (dto.NewStatus == (int)LeaveStatus.Approved && item.Type == LeaveType.Annual && item.Employee != null)
        {
            item.Employee.UsedLeaveDays += item.TotalDays;
        }
    }
    else if (dto.ItemType == (int)ApprovalItemType.Overtime)
    {
        var item = await db.OvertimeRecords.FirstOrDefaultAsync(o => o.Id == dto.ItemId);
        if (item == null) return Results.NotFound();
        item.Status = status;
        item.ManagerComment = dto.Comment;
        item.ProcessedAt = DateTime.UtcNow;
    }
    else if (dto.ItemType == (int)ApprovalItemType.LaborRequest)
    {
        var item = await db.LaborRequests.FirstOrDefaultAsync(l => l.Id == dto.ItemId);
        if (item == null) return Results.NotFound();
        item.Status = status;
        item.ManagerComment = dto.Comment;
        item.ProcessedAt = DateTime.UtcNow;
    }

    await db.SaveChangesAsync();
    return Results.Ok(new { success = true, message = "Talep başarıyla işlendi." });
});

// ==========================================
// ANKET SİSTEMİ API UÇLARI
// ==========================================
app.MapPost("/api/surveys/submit", async (SubmitSurveyDto dto, AppDbContext db) =>
{
    var response = new SurveyResponse
    {
        SurveyId = dto.SurveyId,
        EmployeeId = dto.EmployeeId,
        Rating = dto.Rating,
        Feedback = dto.Feedback,
        SubmittedAt = DateTime.UtcNow
    };

    db.SurveyResponses.Add(response);
    await db.SaveChangesAsync();

    return Results.Ok(new { success = true, message = "Geri bildiriminiz için teşekkürler! Değerlendirmeniz kaydedildi." });
});

// ==========================================
// BORDRO ÖDEME API UÇLARI
// ==========================================
app.MapPost("/api/payroll/pay/{id:int}", async (int id, AppDbContext db) =>
{
    var payroll = await db.PayrollRecords.FirstOrDefaultAsync(p => p.Id == id);
    if (payroll == null) return Results.NotFound();

    payroll.IsPaid = true;
    payroll.PaidDate = DateTime.UtcNow;
    await db.SaveChangesAsync();

    return Results.Ok(new { success = true, message = "Maaş ödeme durumu 'Ödendi' olarak güncellendi." });
});

app.MapCentralStore();
app.Services.GetRequiredService<CentralStore>();
app.Run();
