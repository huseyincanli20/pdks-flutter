# PDKS merkezi sunucu

Bu klasör .NET 10 sunucusunun kaynak kodunu içerir. Flutter uygulamasının merkezi depolama bağlantısı ve özel dosya deposu bu sunucuyu kullanır.

## Yerel çalıştırma

.NET 10 SDK kurulu bilgisayarda, depo kökünden:

```powershell
dotnet run --project server/PdksApp.csproj --no-launch-profile --urls http://127.0.0.1:5000
```

Ayrı bir terminalde Flutter uygulamasını çalıştırın:

```powershell
flutter pub get
flutter run -d chrome --web-port 8080
```

Yönetici veya patron hesabında **Ayarlar → Merkezi Veritabanı ve Dosyalar** ekranını açın.

- Sunucu adresi: `http://127.0.0.1:5000/api/central`
- Anahtar dosyası: ilk sunucu açılışında oluşan `server/App_Data/central/connection.key`
- İlk kurulumda **Bu cihazdaki kayıtları boş sunucuya aktar** açık olsun. Dolu bir sunucuyu bu seçenekle ezmek engellenir.
- Mevcut sunucuya bağlanan başka bir yönetici cihazında bu seçeneği kapatın. Sunucu değerleri yüklenmeden önce yerel yedek alınır.

Anahtar, tüm kurulum verilerine erişim veren bir yönetici anahtarıdır. Çalışanlara dağıtılmamalıdır. Tarayıcıda saklanır; kaynak koda, derleme parametrelerine veya GitHub'a eklenmemelidir.

## Verilerin yeri ve kapsam

- `App_Data/central/central.db`: Flutter modüllerinin iş kayıtları; sürümlü JSON koleksiyonları olarak SQLite içinde saklanır.
- `App_Data/central/files/`: yüklenen dosyaların gerçek içeriği; özgün dosya adı yerine sunucunun ürettiği kimlik kullanılır.
- Dosya adı, türü, boyutu, şirket/personel ilişkisi ve SHA-256 özeti merkezi veritabanında tutulur.
- `connection.key`: sunucunun oluşturduğu özel erişim anahtarı.
- Eski `pdks.db`, önceki .NET ekranları/API'leri için ayrı kalır. Merkezi JSON koleksiyonları bu eski ilişkisel tablolarla otomatik olarak birleştirilmez.

`App_Data`, tüm veritabanları, bağlantı anahtarları ve derleme çıktıları Git kapsamı dışındadır. Yeni bir klon mevcut üretim verilerini içermez. Verileri taşırken veritabanı, dosya klasörü ve anahtar birlikte güvenli şekilde yedeklenmelidir; çalışan sunucunun SQLite dosyasını tek başına kopyalamayın.

Oturum, PIN deneme/kilitleme durumu, aktif şirket seçimi, görünüm tercihi ve cihazın gönderim kuyruğu cihazda kalır. Diğer `pdks_db_` iş koleksiyonlarının yazmaları merkezi eşitleme katmanından geçer. Değişiklikler 5 saniyede bir gönderilir. Diğer cihazlardaki değişiklikler açılışta veya **Sunucudan yenile** ile alınır. Yerel verilerin ilk aktarımı bağlantı ekranından ayrıca başlatılmalıdır.

Çevrimdışı değişiklikler kalıcı gönderim listesinde bekler. Aynı koleksiyon başka cihazda değişirse HTTP 409 ile işlem durur; yerel kayıtlar korunur. Otomatik birleştirme yapılmaz. Sunucu değerlerini kullanmadan önce yerel JSON yedeği alınabilir.

## Fotoğraf ve belgeler

PDF, JPG ve PNG desteklenir; dosya başına üst sınır 10 MB'dir. Uzantı ve dosya başlangıç imzası kontrol edilir. Dosyalar `wwwroot` dışında tutulur. Listeleme, yükleme, indirme ve silme için bağlantı anahtarı gerekir. Görseller önizlenebilir; PDF indirilebilir. Bağlantı kurulduktan sonra yeni profil fotoğrafları da dosya deposuna yüklenir.

Önceden yalnızca dosya adı kaydedilmiş belgelerin gerçek içeriği geri getirilemez; dosya yeniden yüklenmelidir. Önceden satır içinde saklanan fotoğraflar ilk veri aktarımında kendi mevcut biçiminde taşınır; bu işlem onları otomatik olarak ayrı dosyaya dönüştürmez.

## Ağ ve güvenlik sınırı

Varsayılan kullanım aynı bilgisayardadır. Bu bağlantı, kurulum sahibine ait güvenilir yönetici cihazları içindir; sunucu tarafında çalışan bazlı yetkilendirme veya bağımsız kiracı izolasyonu sağlamaz. Uygulamanın mevcut çalışan rolleri bu anahtarı alan bir cihazı sunucu düzeyinde sınırlamaz.

İnternete açmadan önce HTTPS, kullanıcı bazlı kimlik doğrulama, sunucuda rol/şirket yetkileri, anahtar yönetimi ve düzenli yedekleme kurulmalıdır. Eski API uçları merkezi uçların anahtar filtresine dahil değildir. Sunucu varsayılan olarak yalnızca loopback adresinde başlatılmalıdır.

Merkezi uçlar varsayılan olarak localhost tarayıcı kaynaklarına CORS izni verir. Uzak HTTPS dağıtımında izinli kaynaklar `Central__AllowedOrigins` ortam değişkeninde noktalı virgülle ayrılır. Depolama konumu `Central__StoragePath` ile değiştirilebilir. Flutter bağlantı ekranı uzak adresler için HTTPS ister. iOS/Android cihazında `localhost`, cihazın kendisidir; bu yerel adres telefonun bilgisayardaki sunucuya bağlanmasını sağlamaz.

## Kontroller

```powershell
flutter analyze --no-pub
flutter test --no-pub
flutter build web --no-pub --no-tree-shake-icons
dotnet build server/PdksApp.csproj
```

Simge kodları dinamik yüklendiğinden mevcut projede web yayın derlemesinin `--no-tree-shake-icons` seçeneğine ihtiyacı vardır.
