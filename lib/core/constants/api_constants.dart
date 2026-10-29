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
  
  // Geofence Varsayılan Ayarları (Ofis Koordinatları)
  static const double defaultOfficeLat = 41.0082; // İstanbul Örnek Lokasyon
  static const double defaultOfficeLng = 28.9784;
  static const double defaultAllowedRadiusMeters = 150.0; // 150 metre geofence sınırı

  // QR Kod Yenilenme Süresi (Saniye)
  static const int qrRefreshIntervalSeconds = 10;
}
