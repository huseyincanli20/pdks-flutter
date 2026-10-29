import 'dart:async';
import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../models/attendance_record.dart';
import '../models/leave_request.dart';
import '../models/shift_schedule.dart';
import '../core/services/api_service.dart';
import '../core/services/location_service.dart';
import '../core/theme/app_theme_type.dart';
import '../core/theme/app_theme.dart';

class PdksState extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Aktif Giriş Yapan Kullanıcı
  late Employee _currentUser;
  bool _isLoggedIn = true;

  // Personelin anlık durumu: true = İçeride (Checked in), false = Dışarıda
  bool _isCheckedIn = false;
  DateTime? _lastCheckInTime;
  Duration _workedToday = const Duration(hours: 4, minutes: 25);
  Timer? _workTimer;

  // Veri Listeleri
  List<Employee> _employees = [];
  List<AttendanceRecord> _records = [];
  List<LeaveRequest> _leaves = [];
  List<ShiftSchedule> _shifts = [];

  // Sistem & Geofence Ayarları (Admin tarafından değiştirilebilir - Sincan / Ankara)
  double _officeLat = 40.01461;
  double _officeLng = 32.51520;
  double _allowedRadiusMeters = 150.0;
  String _allowedWifiSsid = 'Sirket_Personel';
  String _officeAddress = 'Fırat Cd. 14, 06946 Sincan Ankara, Türkiye';

  // Görünüm Teması: Sistem, Aydınlık, Koyu, Lacivert, Zümrüt, Mor, Kehribar
  ThemeMode _themeMode = ThemeMode.system;
  AppThemeType _currentTheme = AppThemeType.system;

  // Getters
  Employee get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isCheckedIn => _isCheckedIn;
  DateTime? get lastCheckInTime => _lastCheckInTime;
  Duration get workedToday => _workedToday;

  AppThemeType get currentTheme => _currentTheme;
  ThemeData get activeThemeData => AppTheme.getThemeData(_currentTheme);
  ThemeMode get themeMode => _themeMode;

  String get themeModeName => _currentTheme.title;

  void setTheme(AppThemeType theme) {
    _currentTheme = theme;
    if (theme == AppThemeType.system) {
      _themeMode = ThemeMode.system;
    } else if (theme == AppThemeType.light) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    if (mode == ThemeMode.system) {
      _currentTheme = AppThemeType.system;
    } else if (mode == ThemeMode.light) {
      _currentTheme = AppThemeType.light;
    } else {
      _currentTheme = AppThemeType.dark;
    }
    notifyListeners();
  }

  void toggleTheme() {
    if (_currentTheme.isDarkTheme) {
      setTheme(AppThemeType.light);
    } else {
      setTheme(AppThemeType.dark);
    }
  }

  List<Employee> get employees => _employees;
  List<AttendanceRecord> get records => _records;
  List<LeaveRequest> get leaves => _leaves;
  List<ShiftSchedule> get shifts => _shifts;

  double get officeLat => _officeLat;
  double get officeLng => _officeLng;
  double get allowedRadiusMeters => _allowedRadiusMeters;
  String get allowedWifiSsid => _allowedWifiSsid;
  String get officeAddress => _officeAddress;

  // İK & Patron Dashboard Sayaçları
  int get totalEmployeesCount => _employees.length;
  int get presentEmployeesCount => _employees.where((e) => e.isActive).length - 2;
  int get onLeaveEmployeesCount => _leaves.where((l) => l.status == LeaveStatus.approved).length;
  int get lateEmployeesCount => 2;

  PdksState() {
    _initializeSeedData();
    _startTimer();
  }

  void _startTimer() {
    _workTimer?.cancel();
    _workTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isCheckedIn && _isLoggedIn) {
        _workedToday += const Duration(seconds: 1);
        notifyListeners();
      }
    });
  }

  void _initializeSeedData() {
    // 4 Farklı Rol İçin Tanımlı Kullanıcılar
    final personel = Employee(
      id: 1,
      fullName: 'Ahmet Yılmaz',
      email: 'personel@sirket.com',
      phone: '+90 532 111 22 33',
      department: 'Yazılım & Ar-Ge',
      title: 'Kıdemli Mobil Geliştirici',
      pinCode: '1234',
      role: UserRole.employee, // PERSONEL
      annualLeaveAllowance: 14,
      usedLeaveDays: 3,
    );

    final ik = Employee(
      id: 2,
      fullName: 'Zeynep Kaya',
      email: 'ik@sirket.com',
      phone: '+90 533 222 33 44',
      department: 'İnsan Kaynakları',
      title: 'İK Direktörü',
      pinCode: '2345',
      role: UserRole.hr, // İK
      annualLeaveAllowance: 20,
      usedLeaveDays: 5,
    );

    final patron = Employee(
      id: 3,
      fullName: 'Kemal Özdemir',
      email: 'patron@sirket.com',
      phone: '+90 530 999 88 77',
      department: 'Yönetim Kurulu',
      title: 'Genel Müdür / CEO',
      pinCode: '3456',
      role: UserRole.boss, // PATRON
      annualLeaveAllowance: 30,
      usedLeaveDays: 2,
    );

    final admin = Employee(
      id: 4,
      fullName: 'Serkan Arslan',
      email: 'admin@sirket.com',
      phone: '+90 540 888 77 66',
      department: 'Bilgi İşlem & IT',
      title: 'Sistem Yöneticisi',
      pinCode: '4567',
      role: UserRole.admin, // ADMIN
      annualLeaveAllowance: 20,
      usedLeaveDays: 1,
    );

    final diger1 = Employee(
      id: 5,
      fullName: 'Mehmet Demir',
      email: 'mehmet.demir@sirket.com',
      phone: '+90 535 333 44 55',
      department: 'Satış & Pazarlama',
      title: 'Bölge Satış Müdürü',
      pinCode: '9988',
      role: UserRole.employee,
      annualLeaveAllowance: 14,
      usedLeaveDays: 7,
    );

    final diger2 = Employee(
      id: 6,
      fullName: 'Elif Şahin',
      email: 'elif.sahin@sirket.com',
      phone: '+90 542 444 55 66',
      department: 'Mali İşler',
      title: 'Muhasebe Uzmanı',
      pinCode: '1122',
      role: UserRole.employee,
      annualLeaveAllowance: 14,
      usedLeaveDays: 2,
    );

    _currentUser = personel; // Varsayılan personel
    _employees = [personel, ik, patron, admin, diger1, diger2];

    final now = DateTime.now();
    _records = [
      AttendanceRecord(
        id: 101,
        employeeId: 1,
        employeeName: 'Ahmet Yılmaz',
        type: AttendanceType.checkIn,
        timestamp: now.subtract(const Duration(hours: 4, minutes: 25)),
        calculatedDistanceMeters: 42.0,
        isLocationVerified: true,
        verificationMethod: VerificationMethod.qrCode,
        note: 'Dinamik QR Kod Turnikeden okutuldu.',
      ),
      AttendanceRecord(
        id: 102,
        employeeId: 2,
        employeeName: 'Zeynep Kaya',
        type: AttendanceType.checkIn,
        timestamp: now.subtract(const Duration(hours: 4, minutes: 40)),
        calculatedDistanceMeters: 18.0,
        isLocationVerified: true,
        verificationMethod: VerificationMethod.geofenceGps,
        note: 'Ofis Geofence (18m mesafe).',
      ),
      AttendanceRecord(
        id: 103,
        employeeId: 5,
        employeeName: 'Mehmet Demir',
        type: AttendanceType.checkIn,
        timestamp: now.subtract(const Duration(hours: 3, minutes: 50)),
        calculatedDistanceMeters: 35.0,
        isLocationVerified: true,
        verificationMethod: VerificationMethod.wifiIp,
        note: 'Sirket_Personel Wi-Fi ağı doğrulandı.',
      ),
    ];

    _leaves = [
      LeaveRequest(
        id: 201,
        employeeId: 1,
        employeeName: 'Ahmet Yılmaz',
        type: LeaveType.annual,
        startDate: now.add(const Duration(days: 10)),
        endDate: now.add(const Duration(days: 14)),
        totalDays: 5,
        reason: 'Yıllık yaz tatili planı',
        status: LeaveStatus.pending,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      LeaveRequest(
        id: 202,
        employeeId: 6,
        employeeName: 'Elif Şahin',
        type: LeaveType.medical,
        startDate: now.subtract(const Duration(days: 2)),
        endDate: now.subtract(const Duration(days: 1)),
        totalDays: 2,
        reason: 'Grip ve doktor istirahat raporu',
        status: LeaveStatus.approved,
        managerComment: 'Rapor incelendi, onaylandı.',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];

    _shifts = [
      ShiftSchedule(
        id: 1,
        title: 'Standart Ofis Vardiyası',
        startTime: '08:30',
        endTime: '17:30',
        breakMinutes: 60,
        activeDays: ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma'],
        assignedEmployeeCount: 5,
      ),
      ShiftSchedule(
        id: 2,
        title: 'Geç / Esnek Vardiya',
        startTime: '10:00',
        endTime: '19:00',
        breakMinutes: 60,
        activeDays: ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma'],
        assignedEmployeeCount: 1,
      ),
      ShiftSchedule(
        id: 3,
        title: 'Hafta Sonu Nöbetçi Ekip',
        startTime: '09:00',
        endTime: '15:00',
        breakMinutes: 45,
        activeDays: ['Cumartesi'],
        assignedEmployeeCount: 1,
      ),
    ];

    _isCheckedIn = true;
    _lastCheckInTime = now.subtract(const Duration(hours: 4, minutes: 25));
  }

  // Giriş Yapma: YALNIZCA GİRİŞ BİLGİLERİNE GÖRE ROL BELİRLENİR
  bool login(String email, String pin) {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPin = pin.trim();

    // 1. Önce tam e-posta ve PIN eşleşmesine bak
    final found = _employees.where(
      (e) => e.email.toLowerCase() == cleanEmail && e.pinCode == cleanPin,
    );

    if (found.isNotEmpty) {
      _currentUser = found.first;
      _isLoggedIn = true;
      _startTimer();
      notifyListeners();
      return true;
    }

    // 2. Demo kısayolları için kullanıcı adı bazlı kontrol
    Employee? matched;
    if (cleanEmail == 'personel@sirket.com' || cleanEmail == 'personel') {
      matched = _employees.firstWhere((e) => e.role == UserRole.employee);
    } else if (cleanEmail == 'ik@sirket.com' || cleanEmail == 'ik') {
      matched = _employees.firstWhere((e) => e.role == UserRole.hr);
    } else if (cleanEmail == 'patron@sirket.com' || cleanEmail == 'patron') {
      matched = _employees.firstWhere((e) => e.role == UserRole.boss);
    } else if (cleanEmail == 'admin@sirket.com' || cleanEmail == 'admin') {
      matched = _employees.firstWhere((e) => e.role == UserRole.admin);
    }

    if (matched != null) {
      _currentUser = matched;
      _isLoggedIn = true;
      _startTimer();
      notifyListeners();
      return true;
    }

    return false;
  }

  // Yeni Personel Kaydı
  bool register({
    required String fullName,
    required String email,
    required String phone,
    required String department,
    required String title,
    required String pin,
  }) {
    final newId = _employees.length + 1;
    final newEmployee = Employee(
      id: newId,
      fullName: fullName,
      email: email,
      phone: phone,
      department: department.isEmpty ? 'Genel' : department,
      title: title.isEmpty ? 'Personel' : title,
      pinCode: pin,
      role: UserRole.employee, // Yeni kaydolanlar daima personel olarak başlar
      annualLeaveAllowance: 14,
      usedLeaveDays: 0,
      isActive: true,
    );

    _employees.add(newEmployee);
    _currentUser = newEmployee;
    _isLoggedIn = true;
    _isCheckedIn = false;
    _workedToday = Duration.zero;
    _startTimer();
    notifyListeners();
    return true;
  }

  // Oturumu Kapat
  void logout() {
    _isLoggedIn = false;
    _isCheckedIn = false;
    _workTimer?.cancel();
    notifyListeners();
  }

  // Admin: Personel Rolünü Değiştir
  void changeEmployeeRole(int employeeId, UserRole newRole) {
    final index = _employees.indexWhere((e) => e.id == employeeId);
    if (index != -1) {
      final old = _employees[index];
      final updated = Employee(
        id: old.id,
        fullName: old.fullName,
        email: old.email,
        phone: old.phone,
        department: old.department,
        title: old.title,
        pinCode: old.pinCode,
        role: newRole,
        annualLeaveAllowance: old.annualLeaveAllowance,
        usedLeaveDays: old.usedLeaveDays,
        isActive: old.isActive,
      );
      _employees[index] = updated;
      if (_currentUser.id == employeeId) {
        _currentUser = updated;
      }
      notifyListeners();
    }
  }

  // Admin: Geofence Ayarlarını Güncelle
  void updateSystemSettings({
    required double lat,
    required double lng,
    required double radius,
    required String wifiSsid,
    String? address,
  }) {
    _officeLat = lat;
    _officeLng = lng;
    _allowedRadiusMeters = radius;
    _allowedWifiSsid = wifiSsid;
    if (address != null && address.isNotEmpty) {
      _officeAddress = address;
    }
    notifyListeners();
  }

  // Profil Güncelle
  void updateProfile({required String fullName, required String phone, required String department, required String title}) {
    final index = _employees.indexWhere((e) => e.id == _currentUser.id);
    final updated = Employee(
      id: _currentUser.id,
      fullName: fullName,
      email: _currentUser.email,
      phone: phone,
      department: department,
      title: title,
      pinCode: _currentUser.pinCode,
      role: _currentUser.role,
      annualLeaveAllowance: _currentUser.annualLeaveAllowance,
      usedLeaveDays: _currentUser.usedLeaveDays,
      isActive: _currentUser.isActive,
    );

    _currentUser = updated;
    if (index != -1) {
      _employees[index] = updated;
    }
    notifyListeners();
  }

  // Giriş / Çıkış Tetikleme
  Future<Map<String, dynamic>> performCheckInOut({
    required AttendanceType type,
    required VerificationMethod method,
    required GeofenceResult geofence,
    String? note,
  }) async {
    final response = await _apiService.sendAttendance(
      employeeId: _currentUser.id,
      pinCode: _currentUser.pinCode,
      type: type,
      latitude: geofence.latitude,
      longitude: geofence.longitude,
      method: method,
    );

    final now = DateTime.now();
    final newRecord = AttendanceRecord(
      id: DateTime.now().millisecondsSinceEpoch % 10000,
      employeeId: _currentUser.id,
      employeeName: _currentUser.fullName,
      type: type,
      timestamp: now,
      userLatitude: geofence.latitude,
      userLongitude: geofence.longitude,
      calculatedDistanceMeters: geofence.distanceMeters,
      isLocationVerified: geofence.isInside,
      verificationMethod: method,
      note: note ?? (geofence.isInside ? 'Konum ve kural doğrulandı.' : geofence.errorMessage),
    );

    _records.insert(0, newRecord);

    if (type == AttendanceType.checkIn) {
      _isCheckedIn = true;
      _lastCheckInTime = now;
    } else {
      _isCheckedIn = false;
    }

    notifyListeners();
    return response;
  }

  // Yeni İzin Talebi Gönder
  Future<bool> submitLeaveRequest({
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    final days = endDate.difference(startDate).inDays + 1;
    final newLeave = LeaveRequest(
      id: DateTime.now().millisecondsSinceEpoch % 10000,
      employeeId: _currentUser.id,
      employeeName: _currentUser.fullName,
      type: type,
      startDate: startDate,
      endDate: endDate,
      totalDays: days > 0 ? days : 1,
      reason: reason,
      status: LeaveStatus.pending,
      createdAt: DateTime.now(),
    );

    _leaves.insert(0, newLeave);
    notifyListeners();
    return true;
  }

  // İK: İzin Onayla / Reddet
  void updateLeaveStatus(int leaveId, LeaveStatus newStatus, {String? comment}) {
    final index = _leaves.indexWhere((l) => l.id == leaveId);
    if (index != -1) {
      final old = _leaves[index];
      _leaves[index] = LeaveRequest(
        id: old.id,
        employeeId: old.employeeId,
        employeeName: old.employeeName,
        type: old.type,
        startDate: old.startDate,
        endDate: old.endDate,
        totalDays: old.totalDays,
        reason: old.reason,
        status: newStatus,
        managerComment: comment ?? (newStatus == LeaveStatus.approved ? 'Yönetici onayladı.' : 'Talebiniz reddedildi.'),
        createdAt: old.createdAt,
      );

      if (newStatus == LeaveStatus.approved && old.type == LeaveType.annual) {
        final empIndex = _employees.indexWhere((e) => e.id == old.employeeId);
        if (empIndex != -1) {
          final emp = _employees[empIndex];
          _employees[empIndex] = Employee(
            id: emp.id,
            fullName: emp.fullName,
            email: emp.email,
            phone: emp.phone,
            department: emp.department,
            title: emp.title,
            pinCode: emp.pinCode,
            role: emp.role,
            annualLeaveAllowance: emp.annualLeaveAllowance,
            usedLeaveDays: emp.usedLeaveDays + old.totalDays,
          );
        }
      }

      notifyListeners();
    }
  }

  @override
  void dispose() {
    _workTimer?.cancel();
    super.dispose();
  }
}
