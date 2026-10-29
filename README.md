# Kurumsal PDKS (Personel Devam Kontrol Sistemi) - Flutter Cross-Platform

Bu proje; **iOS**, **Android**, **Web** ve **Tablet Kiosk** cihazlarında tek bir kod tabanı (Flutter) üzerinden çalışan kapsamlı bir Personel Devam Kontrol Sistemidir.

---

## 🚀 Öne Çıkan Özellikler ve Modüller

### 1. Giriş - Çıkış (Check-in / Check-out) Mekanizmaları
* **Dinamik QR Kod (Turnike Kiosk):** Her 10 saniyede bir HMAC-SHA256 ile şifrelenmiş tek kullanımlık token üretir. Ekran görüntüsü alıp başkasının yerine okutmayı tamamen engeller.
* **Geofencing (GPS Konum Sınırı):** Haversine formülü ile ofis merkezine metre cinsinden mesafe hesabı yapar. İzin verilen yarıçap (örn. 150m) dışındayken giriş-çıkışa izin vermez.
* **Anti-Cheat (Sahte GPS Koruması):** `position.isMocked` kontrolü ile Fake GPS uygulamalarını tespit eder ve engeller.
* **Ofis Wi-Fi / IP Kontrolü:** Kurumsal Wi-Fi (SSID/BSSID) veya sabit ofis IP'si doğrulaması.
* **Biyometrik Doğrulama (Opsiyonel):** iOS FaceID / Android Parmak İzi veya PIN ile işlem onayı.

### 2. Personel Mobil Uygulaması (iOS & Android)
* Anlık durum kartı (İş yerindesiniz / Mesai başlamadı) ve canlı mesai çalışma sayacı.
* Tek tıkla GPS / Turnike QR / Wi-Fi ile Giriş ve Çıkış.
* Kalan yıllık izin bakiyesi takibi (örn. 11 Gün).
* İzin talep formu (Yıllık, Hastalık/Rapor, Mazeret, Ücretsiz İzin) ve yöneticiye iletimi.
* Turnike ve konum hareket log geçmişi.

### 3. Yönetici & İK Web Paneli (Responsive Web & Desktop)
* **Dashboard:** Anlık şirket mevcudu (Toplam personel, içeride olanlar, izinliler, geç kalanlar).
* **Canlı Turnike Akışı:** Turnikeden veya mobilden geçenlerin saniyelik log akışı.
* **Personel Yönetimi:** Departman, unvan, kalan izin günleri ve PIN kodları.
* **Vardiya ve Çalışma Takvimi:** Haftalık vardiyalar ve mola saatleri.
* **İzin Yönetimi:** Gelen talepleri tek tıkla Onaylama / Reddetme ve personelin bakiyesinden otomatik düşme.
* **Puantaj & Bordro Raporları:** Normal mesai, fazla mesai, izin ve gecikmelerin hesaplandığı tablo ve **Excel (.xlsx)** dışa aktarma.

---

## 📁 Proje Dosya Yapısı

```
pdks-flutter/
├── pubspec.yaml                       # Bağımlılıklar (geolocator, mobile_scanner, qr_flutter, local_auth)
├── web/index.html                     # Web çıktısı için HTML kabuğu
└── lib/
    ├── main.dart                      # Uygulama başlangıcı, tema, yerelleştirme & platform değiştirici
    ├── core/
    │   ├── constants/
    │   │   ├── app_colors.dart        # Renk paleti & gradyanlar
    │   │   └── api_constants.dart     # Endpoint'ler ve Geofence ofis koordinatları
    │   ├── theme/
    │   │   └── app_theme.dart         # Material 3 kurumsal tema
    │   ├── services/
    │   │   ├── location_service.dart  # GPS, Haversine, Anti-Mock GPS & Geofence
    │   │   ├── qr_service.dart / qr_token.dart # Dinamik QR token üretim & doğrulama
    │   │   ├── biometric_service.dart # FaceID / Parmak İzi
    │   │   ├── wifi_network_service.dart # Wi-Fi ağ doğrulaması
    │   │   └── api_service.dart       # REST API iletişimi & offline fallback
    │   └── utils/
    │       └── responsive_layout.dart # Mobil (<768px), Tablet, Desktop (>1100px)
    ├── models/
    │   ├── employee.dart              # Personel modeli & roller
    │   ├── attendance_record.dart     # Giriş/Çıkış log modeli
    │   ├── leave_request.dart         # İzin talepleri
    │   ├── shift_schedule.dart        # Vardiya modeli
    │   └── qr_token.dart              # Güvenli dinamik QR kod yapısı
    ├── state/
    │   └── pdks_state.dart            # ChangeNotifier State Management
    └── views/
        ├── mobile/                    # Personel Mobil Ekranları (iOS & Android)
        │   ├── mobile_home_screen.dart
        │   ├── qr_scanner_screen.dart
        │   └── leave_request_screen.dart
        ├── kiosk/                     # Turnike Tablet Ekranı
        │   └── kiosk_screen.dart      # 10 saniyede bir dönen QR kod ve geri sayım
        └── web_admin/                 # İK & Yönetici Web Paneli
            ├── admin_shell.dart
            ├── dashboard_tab.dart
            ├── employees_tab.dart
            ├── shifts_tab.dart
            ├── leaves_management_tab.dart
            └── reports_puantaj_tab.dart
```

---

## 🛠️ Nasıl Çalıştırılır?

Proje dizinine gidin:
```bash
cd "C:\Users\husey\.gemini\antigravity\scratch\pdks-flutter"
```

Paketleri yükleyin:
```bash
flutter pub get
```

### 1. Web'de Çalıştırma (Tarayıcı)
```bash
flutter run -d chrome
```

### 2. Android'de Çalıştırma
```bash
flutter run -d android
```

### 3. iOS'ta Çalıştırma (macOS / Xcode üzerinde)
```bash
flutter run -d ios
```

---

## 🔗 Mevcut .NET Backend Entegrasyonu
Proje, `C:\Users\husey\.gemini\antigravity\scratch\pdks-saas` dizinindeki mevcut .NET 10 REST API ile doğrudan haberleşecek şekilde tasarlanmıştır. Backend kapalı olduğunda dahi uygulama içi mock mekanizması sayesinde arayüz ve özellikler kesintisiz test edilebilir.
