class ApiConstants {
  // Backend URL (Yerel geliştirme veya Canlı API)
  static const String baseUrl = 'http://localhost:5000/api';

  // Endpoint'ler
  static const String checkAttendance = '/attendance/check';
  static const String companyInfo = '/company/info';
  static const String employees = '/employees';
  static const String createLeave = '/leave/create';
  static const String processLeave = '/leave/process';
  static const String puantajExcel = '/reports/puantaj/excel';
  static const String overtimeCreate = '/overtime/create';
  
  // Geofence Varsayılan Ayarları (Ofis Koordinatları - Sincan / Ankara)
  static const double defaultOfficeLat = 40.01461; // Fırat Cd. 14, Sincan Ankara
  static const double defaultOfficeLng = 32.51520;
  static const double defaultAllowedRadiusMeters = 150.0; // 150 metre geofence sınırı
  static const String defaultOfficeAddress = 'Fırat Cd. 14, 06946 Sincan Ankara, Türkiye';

  // QR Kod Yenilenme Süresi (Saniye)
  static const int qrRefreshIntervalSeconds = 10;
}
