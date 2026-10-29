import 'dart:async';
import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../models/attendance_record.dart';
import '../models/leave_request.dart';
import '../models/shift_schedule.dart';
import '../core/services/api_service.dart';
import '../core/services/location_service.dart';

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

  // Getters
  Employee get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isCheckedIn => _isCheckedIn;
  DateTime? get lastCheckInTime => _lastCheckInTime;
  Duration get workedToday => _workedToday;

  List<Employee> get employees => _employees;
  List<AttendanceRecord> get records => _records;
  List<LeaveRequest> get leaves => _leaves;
  List<ShiftSchedule> get shifts => _shifts;

  // İK Dashboard Sayaçları
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
    _currentUser = Employee(
      id: 1,
      fullName: 'Ahmet Yılmaz',
      email: 'ahmet.yilmaz@sirket.com',
      phone: '+90 532 111 22 33',
      department: 'Yazılım & Ar-Ge',
      title: 'Kıdemli Mobil Geliştirici',
      pinCode: '1234',
      role: UserRole.employee,
      annualLeaveAllowance: 14,
      usedLeaveDays: 3,
    );

    _employees = [
      _currentUser,
      Employee(
        id: 2,
        fullName: 'Zeynep Kaya',
        email: 'zeynep.kaya@sirket.com',
        phone: '+90 533 222 33 44',
        department: 'İnsan Kaynakları',
        title: 'İK Direktörü',
        pinCode: '5678',
        role: UserRole.hrAdmin,
        annualLeaveAllowance: 20,
        usedLeaveDays: 5,
      ),
      Employee(
        id: 3,
        fullName: 'Mehmet Demir',
        email: 'mehmet.demir@sirket.com',
        phone: '+90 535 333 44 55',
        department: 'Satış & Pazarlama',
        title: 'Bölge Satış Müdürü',
        pinCode: '9988',
        role: UserRole.employee,
        annualLeaveAllowance: 14,
        usedLeaveDays: 7,
      ),
      Employee(
        id: 4,
        fullName: 'Elif Şahin',
        email: 'elif.sahin@sirket.com',
        phone: '+90 542 444 55 66',
        department: 'Mali İşler',
        title: 'Muhasebe Uzmanı',
        pinCode: '1122',
        role: UserRole.employee,
        annualLeaveAllowance: 14,
        usedLeaveDays: 2,
      ),
      Employee(
        id: 5,
        fullName: 'Caner Özkan',
        email: 'caner.ozkan@sirket.com',
        phone: '+90 555 555 66 77',
        department: 'Operasyon',
        title: 'Saha Süpervizörü',
        pinCode: '3344',
        role: UserRole.supervisor,
        annualLeaveAllowance: 14,
        usedLeaveDays: 4,
      ),
    ];

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
        employeeId: 3,
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
        employeeId: 4,
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
        assignedEmployeeCount: 4,
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

  // Kullanıcı Girişi
  bool login(String email, String pin) {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPin = pin.trim();

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

    // Demo kolaylığı: Eğer eşleşmezse ve pin 1234 ise ilk kullanıcı ile aç
    if (cleanPin == '1234' || cleanEmail.contains('admin')) {
      _currentUser = cleanEmail.contains('admin')
          ? _employees.firstWhere((e) => e.role == UserRole.hrAdmin)
          : _employees.first;
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
      title: title.isEmpty ? 'Uzman' : title,
      pinCode: pin,
      role: UserRole.employee,
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

  // Kullanıcı Rolünü Değiştir (Demo)
  void switchUserRole(UserRole role) {
    if (role == UserRole.hrAdmin) {
      _currentUser = _employees.firstWhere((e) => e.role == UserRole.hrAdmin);
    } else {
      _currentUser = _employees.firstWhere((e) => e.role == UserRole.employee);
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
