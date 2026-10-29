import 'dart:async';
import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../models/attendance_record.dart';
import '../models/leave_request.dart';
import '../models/shift_schedule.dart';
import '../models/app_notification.dart';
import '../models/cafeteria_menu.dart';
import '../models/company.dart';
import '../models/payroll_slip.dart';
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
  List<PayrollSlip> _payrolls = [];

  // Bildirimler
  List<AppNotification> _notifications = [
    AppNotification(
      id: 'notif_1',
      title: 'Günün Yemekhane Menüsü Hazır 🍽️',
      message: 'Öğle Menüsü: Süzme Mercimek Çorbası, Hasanpaşa Köfte, Tereyağlı Pirinç Pilavı, Mevsim Salata & Kazandibi (~820 kcal).',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      isRead: false,
      type: NotificationType.cafeteria,
      icon: Icons.restaurant_rounded,
      color: const Color(0xFFEA580C),
    ),
    AppNotification(
      id: 'notif_2',
      title: 'Mesai Girişi Başarılı ⏰',
      message: 'Ofis Wi-Fi (Sirket_Personel) üzerinden saat 08:26\'da mesai başlangıcınız kaydedildi.',
      timestamp: DateTime.now().subtract(const Duration(hours: 4, minutes: 20)),
      isRead: false,
      type: NotificationType.attendance,
      icon: Icons.login_rounded,
      color: const Color(0xFF10B981),
    ),
    AppNotification(
      id: 'notif_3',
      title: 'İzin Talebi Onaylandı 🌴',
      message: 'İnsan Kaynakları Direktörlüğü 3 günlük mazeret izni talebinizi onayladı.',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      isRead: true,
      type: NotificationType.leave,
      icon: Icons.beach_access_rounded,
      color: const Color(0xFF0284C7),
    ),
    AppNotification(
      id: 'notif_4',
      title: '29 Ekim Cumhuriyet Bayramı Duyurusu 🇹🇷',
      message: 'Değerli çalışma arkadaşlarımız, 29 Ekim Cumhuriyet Bayramı sebebiyle yarın şirketimiz tam gün resmi tatildir.',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
      type: NotificationType.announcement,
      icon: Icons.campaign_rounded,
      color: const Color(0xFFEF4444),
    ),
    AppNotification(
      id: 'notif_5',
      title: 'Ekim 2026 Puantaj Raporu Hazır 📊',
      message: 'Bu aya ait 176 saatlik normal çalışma ve onaylanan fazla mesai kayıtlarınız puantaj çizelgesine işlendi.',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
      type: NotificationType.system,
      icon: Icons.assessment_outlined,
      color: const Color(0xFF8B5CF6),
    ),
  ];

  // Günün Yemekhane Menüsü
  CafeteriaMenu _todayMenu = CafeteriaMenu(
    date: DateTime.now(),
    soup: 'Süzme Mercimek Çorbası',
    mainDish: 'Hasanpaşa Köfte',
    sideDish: 'Tereyağlı Pirinç Pilavı',
    dessertOrSalad: 'Mevsim Salata & Kazandibi',
    drink: 'Ayran / Su',
    totalCalories: 820,
    vegetarianAlternative: 'Zeytinyağlı Enginar & Fırın Sebze',
    chefNote: 'Glüten ve laktoz içerir. Menümüz taze ve organik malzemelerle hazırlanmıştır.',
    updatedBy: 'Hasan Usta (Mutfak Şefi)',
  );

  // Sistem Rolleri ve Patron/Admin tarafından eklenen roller
  final List<AppRoleItem> _roles = [
    const AppRoleItem(
      id: 'role_employee',
      name: 'Personel',
      description: 'Standart mobil devam takip ve QR okuma yetkisi',
      baseRole: UserRole.employee,
      color: Color(0xFF2563EB),
      icon: Icons.badge_outlined,
      isSystemRole: true,
      createdBy: 'Sistem',
    ),
    const AppRoleItem(
      id: 'role_hr',
      name: 'İnsan Kaynakları (İK)',
      description: 'Personel, puantaj, vardiya ve izin yönetimi yetkileri',
      baseRole: UserRole.hr,
      color: Color(0xFF0284C7),
      icon: Icons.people_alt_outlined,
      isSystemRole: true,
      createdBy: 'Sistem',
    ),
    const AppRoleItem(
      id: 'role_boss',
      name: 'Patron (Yönetim)',
      description: 'Şirket maliyetleri, devam istatistikleri ve rol ekleme yetkisi',
      baseRole: UserRole.boss,
      color: Color(0xFFD97706),
      icon: Icons.workspace_premium_outlined,
      isSystemRole: true,
      createdBy: 'Sistem',
    ),
    const AppRoleItem(
      id: 'role_admin',
      name: 'Sistem Yöneticisi (Admin)',
      description: 'En yüksek güvenlikli teknik sistem yapılandırma yetkisi',
      baseRole: UserRole.admin,
      color: Color(0xFF9333EA),
      icon: Icons.admin_panel_settings_outlined,
      isSystemRole: true,
      createdBy: 'Sistem',
    ),
    const AppRoleItem(
      id: 'role_cafeteria',
      name: 'Yemekhane Personeli',
      description: 'Yemekhane menüsü düzenleme, yayınlama ve porsiyon takibi yetkileri',
      baseRole: UserRole.cafeteria,
      color: Color(0xFFEA580C),
      icon: Icons.restaurant_menu_rounded,
      isSystemRole: true,
      createdBy: 'Sistem',
    ),
  ];

  // Multi-Company (Çoklu Şirket / SaaS Desteği)
  final List<Company> _companies = [
    Company(
      id: 'cmp_acme',
      code: 'ACME',
      name: 'ACME Teknoloji ve Bilişim A.Ş.',
      sector: 'Yazılım & Bilişim Ar-Ge',
      address: 'Fırat Cd. 14, 06946 Sincan Ankara, Türkiye',
      officeLat: 40.01461,
      officeLng: 32.51520,
      allowedRadiusMeters: 150.0,
      allowedWifiSsid: 'Sirket_Personel',
      taxNumber: '0123456789',
      phone: '+90 312 444 01 02',
      email: 'iletisim@acmeteknoloji.com',
      primaryColor: const Color(0xFF2563EB),
    ),
    Company(
      id: 'cmp_nova',
      code: 'NOVA',
      name: 'Nova Savunma ve Havacılık A.Ş.',
      sector: 'Savunma Sanayii & Aviyonik',
      address: 'ODTÜ Teknokent Silikon Blok No: 4, Çankaya Ankara',
      officeLat: 39.89160,
      officeLng: 32.78250,
      allowedRadiusMeters: 200.0,
      allowedWifiSsid: 'Nova_Secure_Wifi',
      taxNumber: '9876543210',
      phone: '+90 312 210 99 88',
      email: 'info@novasavunma.com.tr',
      primaryColor: const Color(0xFF0D9488),
    ),
    Company(
      id: 'cmp_ozdemir',
      code: 'OZDEMIR',
      name: 'Özdemir Holding & Lojistik A.Ş.',
      sector: 'Uluslararası Taşımacılık & Depolama',
      address: 'Büyükdere Cd. Maslak No: 122, Sarıyer İstanbul',
      officeLat: 41.11050,
      officeLng: 29.02030,
      allowedRadiusMeters: 250.0,
      allowedWifiSsid: 'Holding_Corporate_Net',
      taxNumber: '5544332211',
      phone: '+90 212 333 44 55',
      email: 'merkez@ozdemirholding.com.tr',
      primaryColor: const Color(0xFFD97706),
    ),
  ];

  String _activeCompanyId = 'cmp_acme';

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

  // Multi-Company Getters & Methods
  List<Company> get companies => List.unmodifiable(_companies);
  Company get activeCompany =>
      _companies.firstWhere((c) => c.id == _activeCompanyId, orElse: () => _companies.first);
  String get activeCompanyId => _activeCompanyId;

  double get officeLat => activeCompany.officeLat;
  double get officeLng => activeCompany.officeLng;
  double get allowedRadiusMeters => activeCompany.allowedRadiusMeters;
  String get allowedWifiSsid => activeCompany.allowedWifiSsid;
  String get officeAddress => activeCompany.address;

  // Tenant filtrelenmiş veriler (Aktif şirkete ait kayıtlar)
  List<Employee> get employees =>
      _employees.where((e) => e.companyId == _activeCompanyId).toList();
  List<Employee> get allEmployees => List.unmodifiable(_employees);
  List<AttendanceRecord> get records =>
      _records.where((r) => r.companyId == _activeCompanyId).toList();
  List<LeaveRequest> get leaves =>
      _leaves.where((l) => l.companyId == _activeCompanyId).toList();
  List<ShiftSchedule> get shifts =>
      _shifts.where((s) => s.companyId == _activeCompanyId).toList();
  List<PayrollSlip> get payrolls =>
      _payrolls.where((p) => p.companyId == _activeCompanyId).toList();
  List<PayrollSlip> get allPayrolls => List.unmodifiable(_payrolls);
  List<PayrollSlip> get currentUserPayrolls =>
      _payrolls.where((p) => p.employeeId == _currentUser.id).toList();
  PayrollSlip? get latestUserPayroll =>
      currentUserPayrolls.isNotEmpty ? currentUserPayrolls.first : null;

  void switchCompany(String companyId) {
    if (_companies.any((c) => c.id == companyId)) {
      _activeCompanyId = companyId;
      // Aktif şirkete ait bir kullanıcıya otomatik geçiş yap
      final compEmps = _employees.where((e) => e.companyId == companyId).toList();
      if (compEmps.isNotEmpty) {
        final sameRole = compEmps.where((e) => e.role == _currentUser.role);
        _currentUser = sameRole.isNotEmpty ? sameRole.first : compEmps.first;
      }
      notifyListeners();
    }
  }

  void switchCompanyByCode(String code) {
    final clean = code.trim().toUpperCase();
    final idx = _companies.indexWhere((c) => c.code.toUpperCase() == clean);
    if (idx != -1) {
      switchCompany(_companies[idx].id);
    }
  }

  ({bool success, String message, Company? company}) registerNewCompany({
    required String name,
    required String code,
    required String sector,
    required String address,
    required double lat,
    required double lng,
    required String wifiSsid,
    required String adminFullName,
    required String adminEmail,
    required String adminPin,
  }) {
    final cleanCode = code.trim().toUpperCase();
    final cleanName = name.trim();

    if (cleanName.isEmpty || cleanCode.isEmpty) {
      return (success: false, message: 'Şirket adı ve şirket kodu zorunludur.', company: null);
    }

    if (_companies.any((c) => c.code.toUpperCase() == cleanCode)) {
      return (success: false, message: '"$cleanCode" şirket kodu zaten kayıtlı.', company: null);
    }

    final newCompanyId = 'cmp_${DateTime.now().millisecondsSinceEpoch}';
    final newCompany = Company(
      id: newCompanyId,
      code: cleanCode,
      name: cleanName,
      sector: sector.trim().isEmpty ? 'Genel' : sector.trim(),
      address: address.trim().isEmpty ? 'Merkez Ofis' : address.trim(),
      officeLat: lat,
      officeLng: lng,
      allowedWifiSsid: wifiSsid.trim().isEmpty ? '${cleanCode}_Office_Wifi' : wifiSsid.trim(),
    );

    _companies.add(newCompany);

    // Yeni şirket için varsayılan Admin ve Patron hesabı oluştur
    final newAdmin = Employee(
      id: _employees.length + 1,
      companyId: newCompanyId,
      fullName: adminFullName.trim().isEmpty ? 'Sistem Yöneticisi' : adminFullName.trim(),
      email: adminEmail.trim().isEmpty ? 'admin@${cleanCode.toLowerCase()}.com' : adminEmail.trim(),
      department: 'Bilgi İşlem & IT',
      title: 'Sistem Yöneticisi',
      pinCode: adminPin.trim().isEmpty ? '1234' : adminPin.trim(),
      role: UserRole.admin,
    );

    final newBoss = Employee(
      id: _employees.length + 2,
      companyId: newCompanyId,
      fullName: 'Yönetim Kurulu Başkanı',
      email: 'patron@${cleanCode.toLowerCase()}.com',
      department: 'Yönetim Kurulu',
      title: 'Genel Müdür / CEO',
      pinCode: '3456',
      role: UserRole.boss,
    );

    _employees.addAll([newAdmin, newBoss]);
    _activeCompanyId = newCompanyId;
    _currentUser = newAdmin;
    notifyListeners();

    return (
      success: true,
      message: '"$cleanName" ($cleanCode) şirketi başarıyla oluşturuldu.',
      company: newCompany,
    );
  }

  void updateCompanySettings({
    required double lat,
    required double lng,
    required double radius,
    required String wifiSsid,
    String? address,
    String? name,
  }) {
    final idx = _companies.indexWhere((c) => c.id == _activeCompanyId);
    if (idx != -1) {
      _companies[idx] = _companies[idx].copyWith(
        officeLat: lat,
        officeLng: lng,
        allowedRadiusMeters: radius,
        allowedWifiSsid: wifiSsid,
        address: address ?? _companies[idx].address,
        name: name ?? _companies[idx].name,
      );
      notifyListeners();
    }
  }

  // Bildirim Getters ve Metotları
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadNotificationsCount => _notifications.where((n) => !n.isRead).length;

  void markNotificationAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_notifications[idx].isRead) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAllNotificationsAsRead() {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  void clearAllNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  void addNotification(AppNotification notif) {
    _notifications.insert(0, notif);
    notifyListeners();
  }

  // Yemekhane Menüsü Getters ve Metotları
  CafeteriaMenu get todayMenu => _todayMenu;

  void updateTodayMenu(CafeteriaMenu menu) {
    _todayMenu = menu;
    // Otomatik olarak tüm personele bildirim gönder
    addNotification(AppNotification(
      id: 'menu_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Günün Yemekhane Menüsü Güncellendi 🍽️',
      message: '${menu.soup}, ${menu.mainDish}, ${menu.sideDish}, ${menu.dessertOrSalad} (~${menu.totalCalories} kcal)',
      timestamp: DateTime.now(),
      isRead: false,
      type: NotificationType.cafeteria,
      icon: Icons.restaurant_rounded,
      color: const Color(0xFFEA580C),
    ));
    notifyListeners();
  }

  // Bordro ve Maaş Yönetimi Metotları
  void updatePayrollStatus(String id, PayrollStatus newStatus) {
    final idx = _payrolls.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _payrolls[idx].status = newStatus;
      notifyListeners();
    }
  }

  void bulkApprovePayrolls(int month, int year) {
    for (final p in _payrolls) {
      if (p.companyId == _activeCompanyId && p.periodMonth == month && p.periodYear == year) {
        p.status = PayrollStatus.approved;
      }
    }
    notifyListeners();
  }

  void bulkPayPayrolls(int month, int year) {
    for (final p in _payrolls) {
      if (p.companyId == _activeCompanyId && p.periodMonth == month && p.periodYear == year) {
        p.status = PayrollStatus.paid;
      }
    }
    notifyListeners();
  }

  PayrollSlip generatePayrollForEmployee({
    required Employee employee,
    required int month,
    required int year,
    double overtimeHours = 0.0,
    double bonus = 0.0,
  }) {
    final company = _companies.firstWhere((c) => c.id == employee.companyId, orElse: () => activeCompany);
    final hourlyRate = employee.baseGrossSalary / 225.0; // Standart aylık 225 saat (İş Kanunu)
    final overtimePay = overtimeHours * hourlyRate * 1.5;
    const meal = 4500.0;
    const travel = 1800.0;
    final sgkBase = employee.baseGrossSalary + overtimePay + bonus;
    final sgkWorker = sgkBase * 0.14;
    final unempWorker = sgkBase * 0.01;
    final taxBase = sgkBase - (sgkWorker + unempWorker);
    final incomeTax = taxBase * 0.15;
    final stampTax = sgkBase * 0.00759;
    const exemption = 3200.0;

    return PayrollSlip(
      id: 'brd_${year}_${month}_${employee.id}',
      companyId: employee.companyId,
      companyName: company.name,
      employeeId: employee.id,
      employeeName: employee.fullName,
      employeeTitle: employee.title,
      department: employee.department,
      tcKimlikNo: employee.tcKimlikNo,
      sicilNo: '10${employee.id.toString().padLeft(2, '0')}',
      iban: employee.iban,
      bankName: employee.bankName,
      periodMonth: month,
      periodYear: year,
      issueDate: DateTime(year, month, 28),
      paymentDate: DateTime(year, month == 12 ? 1 : month + 1, 5),
      workedDays: 22,
      workedHours: 176.0,
      overtimeHours: overtimeHours,
      baseGrossSalary: employee.baseGrossSalary,
      overtimePay: overtimePay,
      mealAllowance: meal,
      travelAllowance: travel,
      bonus: bonus,
      incomeTax: incomeTax,
      stampTax: stampTax,
      taxExemption: exemption,
      status: PayrollStatus.approved,
      isSigned: true,
      signatureTimestamp: DateTime(year, month, 28, 17, 30),
    );
  }

  void recalculateCompanyPayroll(int month, int year) {
    final compEmployees = _employees.where((e) => e.companyId == _activeCompanyId).toList();
    for (final emp in compEmployees) {
      final otHours = (emp.id % 2 == 0) ? (emp.id * 3.5) : 0.0;
      final bonus = (emp.role == UserRole.boss || emp.role == UserRole.hr) ? 5000.0 : 0.0;
      final newSlip = generatePayrollForEmployee(
        employee: emp,
        month: month,
        year: year,
        overtimeHours: otHours,
        bonus: bonus,
      );
      final existingIdx = _payrolls.indexWhere(
        (p) => p.companyId == _activeCompanyId && p.employeeId == emp.id && p.periodMonth == month && p.periodYear == year,
      );
      if (existingIdx != -1) {
        _payrolls[existingIdx] = newSlip;
      } else {
        _payrolls.insert(0, newSlip);
      }
    }

    addNotification(AppNotification(
      id: 'payroll_${DateTime.now().millisecondsSinceEpoch}',
      title: '$month/$year Bordroları Hesaplandı 📑',
      message: '${activeCompany.name} için $month/$year dönemi bordroları PDKS verileriyle güncellendi.',
      timestamp: DateTime.now(),
      isRead: false,
      type: NotificationType.system,
      icon: Icons.receipt_long_rounded,
      color: const Color(0xFF0D9488),
    ));
    notifyListeners();
  }

  // Resim / Avatar Güncelleme Metotları
  void updateEmployeeAvatar(int employeeId, String avatarUrl) {
    final idx = _employees.indexWhere((e) => e.id == employeeId);
    if (idx != -1) {
      _employees[idx] = _employees[idx].copyWith(avatarUrl: avatarUrl);
      if (_currentUser.id == employeeId) {
        _currentUser = _employees[idx];
      }
      notifyListeners();
    }
  }

  void updateCurrentUserAvatar(String avatarUrl) {
    updateEmployeeAvatar(_currentUser.id, avatarUrl);
  }

  List<AppRoleItem> get roles => List.unmodifiable(_roles);
  List<AppRoleItem> get customRoles => _roles.where((r) => !r.isSystemRole).toList();
  List<AppRoleItem> get rolesSelectableByBoss =>
      _roles.where((r) => r.baseRole != UserRole.admin && r.id != 'role_admin').toList();

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

    final yemekhane = Employee(
      id: 7,
      companyId: 'cmp_acme',
      fullName: 'Hasan Usta',
      email: 'yemekhane@sirket.com',
      phone: '+90 533 777 88 99',
      department: 'Yemekhane & Sosyal Tesisler',
      title: 'Mutfak Şefi',
      pinCode: '5678',
      role: UserRole.cafeteria,
      annualLeaveAllowance: 14,
      usedLeaveDays: 1,
      avatarUrl: 'https://images.unsplash.com/photo-1577219491135-ce391730fb2c?w=150',
    );

    // NOVA Savunma Personelleri
    final novaPersonel = Employee(
      id: 11,
      companyId: 'cmp_nova',
      fullName: 'Can Demir',
      email: 'personel@novasavunma.com.tr',
      phone: '+90 532 999 11 22',
      department: 'Aviyonik & Radar',
      title: 'Kıdemli Sistem Mühendisi',
      pinCode: '1234',
      role: UserRole.employee,
      annualLeaveAllowance: 18,
      usedLeaveDays: 4,
    );

    final novaIk = Employee(
      id: 12,
      companyId: 'cmp_nova',
      fullName: 'Ayşe Çelik',
      email: 'ik@novasavunma.com.tr',
      phone: '+90 533 888 22 33',
      department: 'İnsan Kaynakları',
      title: 'İK & Yetenek Direktörü',
      pinCode: '2345',
      role: UserRole.hr,
      annualLeaveAllowance: 22,
      usedLeaveDays: 3,
    );

    final novaPatron = Employee(
      id: 13,
      companyId: 'cmp_nova',
      fullName: 'Dr. Burak Kaya',
      email: 'patron@novasavunma.com.tr',
      phone: '+90 530 777 33 44',
      department: 'Yönetim Kurulu',
      title: 'Genel Müdür / CEO',
      pinCode: '3456',
      role: UserRole.boss,
      annualLeaveAllowance: 30,
      usedLeaveDays: 1,
    );

    final novaAdmin = Employee(
      id: 14,
      companyId: 'cmp_nova',
      fullName: 'Selim Vural',
      email: 'admin@novasavunma.com.tr',
      phone: '+90 540 666 44 55',
      department: 'Bilgi Güvenliği & Siber',
      title: 'Ağ & Altyapı Mimarı',
      pinCode: '4567',
      role: UserRole.admin,
      annualLeaveAllowance: 20,
      usedLeaveDays: 0,
    );

    // ÖZDEMİR Holding Personelleri
    final ozdemirPersonel = Employee(
      id: 21,
      companyId: 'cmp_ozdemir',
      fullName: 'Murat Yıldız',
      email: 'personel@ozdemirholding.com.tr',
      phone: '+90 532 111 55 66',
      department: 'Depolama & Sevkiyat',
      title: 'Lojistik Operasyon Uzmanı',
      pinCode: '1234',
      role: UserRole.employee,
      annualLeaveAllowance: 15,
      usedLeaveDays: 2,
    );

    final ozdemirIk = Employee(
      id: 22,
      companyId: 'cmp_ozdemir',
      fullName: 'Sevgi Öztürk',
      email: 'ik@ozdemirholding.com.tr',
      phone: '+90 533 222 66 77',
      department: 'İnsan Kaynakları & Bordro',
      title: 'İK Direktörü',
      pinCode: '2345',
      role: UserRole.hr,
      annualLeaveAllowance: 20,
      usedLeaveDays: 6,
    );

    final ozdemirPatron = Employee(
      id: 23,
      companyId: 'cmp_ozdemir',
      fullName: 'Tarık Özdemir',
      email: 'patron@ozdemirholding.com.tr',
      phone: '+90 530 333 77 88',
      department: 'Yönetim Kurulu',
      title: 'Yönetim Kurulu Başkanı',
      pinCode: '3456',
      role: UserRole.boss,
      annualLeaveAllowance: 30,
      usedLeaveDays: 0,
    );

    final ozdemirAdmin = Employee(
      id: 24,
      companyId: 'cmp_ozdemir',
      fullName: 'Cenk Akın',
      email: 'admin@ozdemirholding.com.tr',
      phone: '+90 540 444 88 99',
      department: 'ERP & Sistem Yönetimi',
      title: 'Sistem Yöneticisi',
      pinCode: '4567',
      role: UserRole.admin,
      annualLeaveAllowance: 20,
      usedLeaveDays: 2,
    );

    _currentUser = personel; // Varsayılan personel
    _employees = [
      personel, ik, patron, admin, diger1, diger2, yemekhane,
      novaPersonel, novaIk, novaPatron, novaAdmin,
      ozdemirPersonel, ozdemirIk, ozdemirPatron, ozdemirAdmin,
    ];

    final now = DateTime.now();
    _records = [
      // ACME Kayıtları
      AttendanceRecord(
        id: 101,
        companyId: 'cmp_acme',
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
        companyId: 'cmp_acme',
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
        companyId: 'cmp_acme',
        employeeId: 5,
        employeeName: 'Mehmet Demir',
        type: AttendanceType.checkIn,
        timestamp: now.subtract(const Duration(hours: 3, minutes: 50)),
        calculatedDistanceMeters: 35.0,
        isLocationVerified: true,
        verificationMethod: VerificationMethod.wifiIp,
        note: 'Sirket_Personel Wi-Fi ağı doğrulandı.',
      ),
      // NOVA Savunma Kayıtları
      AttendanceRecord(
        id: 104,
        companyId: 'cmp_nova',
        employeeId: 11,
        employeeName: 'Can Demir',
        type: AttendanceType.checkIn,
        timestamp: now.subtract(const Duration(hours: 3, minutes: 10)),
        calculatedDistanceMeters: 25.0,
        isLocationVerified: true,
        verificationMethod: VerificationMethod.geofenceGps,
        note: 'Nova Savunma Geofence (ODTÜ Teknokent)',
      ),
      AttendanceRecord(
        id: 105,
        companyId: 'cmp_nova',
        employeeId: 12,
        employeeName: 'Ayşe Çelik',
        type: AttendanceType.checkIn,
        timestamp: now.subtract(const Duration(hours: 4, minutes: 5)),
        calculatedDistanceMeters: 12.0,
        isLocationVerified: true,
        verificationMethod: VerificationMethod.wifiIp,
        note: 'Nova_Secure_Wifi güvenli ağ doğrulaması.',
      ),
      // ÖZDEMİR Holding Kayıtları
      AttendanceRecord(
        id: 106,
        companyId: 'cmp_ozdemir',
        employeeId: 21,
        employeeName: 'Murat Yıldız',
        type: AttendanceType.checkIn,
        timestamp: now.subtract(const Duration(hours: 5, minutes: 0)),
        calculatedDistanceMeters: 55.0,
        isLocationVerified: true,
        verificationMethod: VerificationMethod.qrCode,
        note: 'Maslak Plaza Turnike QR Giriş',
      ),
    ];

    _leaves = [
      LeaveRequest(
        id: 201,
        companyId: 'cmp_acme',
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
        companyId: 'cmp_acme',
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
      LeaveRequest(
        id: 203,
        companyId: 'cmp_nova',
        employeeId: 11,
        employeeName: 'Can Demir',
        type: LeaveType.annual,
        startDate: now.add(const Duration(days: 20)),
        endDate: now.add(const Duration(days: 25)),
        totalDays: 5,
        reason: 'Yıllık izin talebi',
        status: LeaveStatus.pending,
        createdAt: now.subtract(const Duration(hours: 12)),
      ),
    ];

    _shifts = [
      ShiftSchedule(
        id: 1,
        companyId: 'cmp_acme',
        title: 'Standart Ofis Vardiyası',
        startTime: '08:30',
        endTime: '17:30',
        breakMinutes: 60,
        activeDays: ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma'],
        assignedEmployeeCount: 5,
      ),
      ShiftSchedule(
        id: 2,
        companyId: 'cmp_acme',
        title: 'Geç / Esnek Vardiya',
        startTime: '10:00',
        endTime: '19:00',
        breakMinutes: 60,
        activeDays: ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma'],
        assignedEmployeeCount: 1,
      ),
      ShiftSchedule(
        id: 3,
        companyId: 'cmp_acme',
        title: 'Hafta Sonu Nöbetçi Ekip',
        startTime: '09:00',
        endTime: '15:00',
        breakMinutes: 45,
        activeDays: ['Cumartesi'],
        assignedEmployeeCount: 1,
      ),
      ShiftSchedule(
        id: 4,
        companyId: 'cmp_nova',
        title: 'Savunma Ar-Ge Mühendislik Vardiyası',
        startTime: '08:00',
        endTime: '17:00',
        breakMinutes: 60,
        activeDays: ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma'],
        assignedEmployeeCount: 4,
      ),
      ShiftSchedule(
        id: 5,
        companyId: 'cmp_ozdemir',
        title: 'Lojistik & Operasyon Vardiyası',
        startTime: '07:30',
        endTime: '16:30',
        breakMinutes: 60,
        activeDays: ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi'],
        assignedEmployeeCount: 4,
      ),
    ];

    _payrolls = [
      // Ahmet Yılmaz (Ekim 2026 - Son Dönem)
      PayrollSlip(
        id: 'brd_2026_10_01',
        companyId: 'cmp_acme',
        companyName: 'ACME Teknoloji ve Bilişim A.Ş.',
        employeeId: 1,
        employeeName: 'Ahmet Yılmaz',
        employeeTitle: 'Kıdemli Mobil Geliştirici',
        department: 'Yazılım & Ar-Ge',
        tcKimlikNo: '28491028472',
        sicilNo: '1001',
        iban: 'TR42 0006 2000 0001 2345 6789 01',
        bankName: 'Garanti BBVA',
        periodMonth: 10,
        periodYear: 2026,
        issueDate: DateTime(2026, 10, 28),
        paymentDate: DateTime(2026, 11, 5),
        workedDays: 22,
        workedHours: 176.0,
        overtimeHours: 8.5,
        baseGrossSalary: 56000.0,
        overtimePay: 3173.33,
        mealAllowance: 4500.0,
        travelAllowance: 1800.0,
        bonus: 2500.0,
        incomeTax: 7600.0,
        stampTax: 468.0,
        taxExemption: 3200.0,
        status: PayrollStatus.paid,
        isSigned: true,
        signatureTimestamp: DateTime(2026, 10, 28, 17, 30),
      ),
      // Ahmet Yılmaz (Eylül 2026)
      PayrollSlip(
        id: 'brd_2026_09_01',
        companyId: 'cmp_acme',
        companyName: 'ACME Teknoloji ve Bilişim A.Ş.',
        employeeId: 1,
        employeeName: 'Ahmet Yılmaz',
        employeeTitle: 'Kıdemli Mobil Geliştirici',
        department: 'Yazılım & Ar-Ge',
        tcKimlikNo: '28491028472',
        sicilNo: '1001',
        iban: 'TR42 0006 2000 0001 2345 6789 01',
        bankName: 'Garanti BBVA',
        periodMonth: 9,
        periodYear: 2026,
        issueDate: DateTime(2026, 9, 28),
        paymentDate: DateTime(2026, 10, 5),
        workedDays: 22,
        workedHours: 176.0,
        overtimeHours: 12.0,
        baseGrossSalary: 56000.0,
        overtimePay: 4480.0,
        mealAllowance: 4500.0,
        travelAllowance: 1800.0,
        bonus: 0.0,
        incomeTax: 7400.0,
        stampTax: 459.0,
        taxExemption: 3200.0,
        status: PayrollStatus.paid,
        isSigned: true,
        signatureTimestamp: DateTime(2026, 9, 28, 17, 30),
      ),
      // Ahmet Yılmaz (Ağustos 2026)
      PayrollSlip(
        id: 'brd_2026_08_01',
        companyId: 'cmp_acme',
        companyName: 'ACME Teknoloji ve Bilişim A.Ş.',
        employeeId: 1,
        employeeName: 'Ahmet Yılmaz',
        employeeTitle: 'Kıdemli Mobil Geliştirici',
        department: 'Yazılım & Ar-Ge',
        tcKimlikNo: '28491028472',
        sicilNo: '1001',
        iban: 'TR42 0006 2000 0001 2345 6789 01',
        bankName: 'Garanti BBVA',
        periodMonth: 8,
        periodYear: 2026,
        issueDate: DateTime(2026, 8, 28),
        paymentDate: DateTime(2026, 9, 5),
        workedDays: 22,
        workedHours: 176.0,
        overtimeHours: 5.0,
        baseGrossSalary: 56000.0,
        overtimePay: 1866.67,
        mealAllowance: 4500.0,
        travelAllowance: 1800.0,
        bonus: 5000.0,
        incomeTax: 8100.0,
        stampTax: 477.0,
        taxExemption: 3200.0,
        status: PayrollStatus.paid,
        isSigned: true,
        signatureTimestamp: DateTime(2026, 8, 28, 17, 30),
      ),
      // Zeynep Kaya (İK - Ekim 2026)
      PayrollSlip(
        id: 'brd_2026_10_02',
        companyId: 'cmp_acme',
        companyName: 'ACME Teknoloji ve Bilişim A.Ş.',
        employeeId: 2,
        employeeName: 'Zeynep Kaya',
        employeeTitle: 'İK Direktörü',
        department: 'İnsan Kaynakları',
        tcKimlikNo: '31592039481',
        sicilNo: '1002',
        iban: 'TR55 0006 4000 0002 3456 7890 12',
        bankName: 'İş Bankası',
        periodMonth: 10,
        periodYear: 2026,
        issueDate: DateTime(2026, 10, 28),
        paymentDate: DateTime(2026, 11, 5),
        workedDays: 22,
        workedHours: 176.0,
        overtimeHours: 4.0,
        baseGrossSalary: 68000.0,
        overtimePay: 1813.33,
        mealAllowance: 4500.0,
        travelAllowance: 1800.0,
        bonus: 5000.0,
        incomeTax: 9800.0,
        stampTax: 568.0,
        taxExemption: 3200.0,
        status: PayrollStatus.paid,
        isSigned: true,
        signatureTimestamp: DateTime(2026, 10, 28, 17, 30),
      ),
      // Kemal Özdemir (Patron - Ekim 2026)
      PayrollSlip(
        id: 'brd_2026_10_03',
        companyId: 'cmp_acme',
        companyName: 'ACME Teknoloji ve Bilişim A.Ş.',
        employeeId: 3,
        employeeName: 'Kemal Özdemir',
        employeeTitle: 'Genel Müdür / CEO',
        department: 'Yönetim Kurulu',
        tcKimlikNo: '19482019485',
        sicilNo: '1003',
        iban: 'TR12 0006 2000 0003 4567 8901 23',
        bankName: 'Garanti BBVA',
        periodMonth: 10,
        periodYear: 2026,
        issueDate: DateTime(2026, 10, 28),
        paymentDate: DateTime(2026, 11, 5),
        workedDays: 22,
        workedHours: 176.0,
        overtimeHours: 0.0,
        baseGrossSalary: 120000.0,
        overtimePay: 0.0,
        mealAllowance: 4500.0,
        travelAllowance: 1800.0,
        bonus: 0.0,
        incomeTax: 16500.0,
        stampTax: 910.0,
        taxExemption: 3200.0,
        status: PayrollStatus.paid,
        isSigned: true,
        signatureTimestamp: DateTime(2026, 10, 28, 17, 30),
      ),
      // Serkan Arslan (Admin - Ekim 2026)
      PayrollSlip(
        id: 'brd_2026_10_04',
        companyId: 'cmp_acme',
        companyName: 'ACME Teknoloji ve Bilişim A.Ş.',
        employeeId: 4,
        employeeName: 'Serkan Arslan',
        employeeTitle: 'Sistem Yöneticisi',
        department: 'Bilgi İşlem & IT',
        tcKimlikNo: '47281039482',
        sicilNo: '1004',
        iban: 'TR77 0001 5000 0004 5678 9012 34',
        bankName: 'Vakıfbank',
        periodMonth: 10,
        periodYear: 2026,
        issueDate: DateTime(2026, 10, 28),
        paymentDate: DateTime(2026, 11, 5),
        workedDays: 22,
        workedHours: 176.0,
        overtimeHours: 6.0,
        baseGrossSalary: 62000.0,
        overtimePay: 2480.0,
        mealAllowance: 4500.0,
        travelAllowance: 1800.0,
        bonus: 0.0,
        incomeTax: 8100.0,
        stampTax: 489.0,
        taxExemption: 3200.0,
        status: PayrollStatus.paid,
        isSigned: true,
        signatureTimestamp: DateTime(2026, 10, 28, 17, 30),
      ),
      // Mehmet Demir (Ekim 2026)
      PayrollSlip(
        id: 'brd_2026_10_05',
        companyId: 'cmp_acme',
        companyName: 'ACME Teknoloji ve Bilişim A.Ş.',
        employeeId: 5,
        employeeName: 'Mehmet Demir',
        employeeTitle: 'Bölge Satış Müdürü',
        department: 'Satış & Pazarlama',
        tcKimlikNo: '58291039471',
        sicilNo: '1005',
        iban: 'TR88 0006 2000 0005 6789 0123 45',
        bankName: 'Yapı Kredi',
        periodMonth: 10,
        periodYear: 2026,
        issueDate: DateTime(2026, 10, 28),
        paymentDate: DateTime(2026, 11, 5),
        workedDays: 22,
        workedHours: 176.0,
        overtimeHours: 14.0,
        baseGrossSalary: 48000.0,
        overtimePay: 4480.0,
        mealAllowance: 4500.0,
        travelAllowance: 1800.0,
        bonus: 3000.0,
        incomeTax: 6900.0,
        stampTax: 421.0,
        taxExemption: 3200.0,
        status: PayrollStatus.paid,
        isSigned: true,
        signatureTimestamp: DateTime(2026, 10, 28, 17, 30),
      ),
      // Elif Şahin (Ekim 2026)
      PayrollSlip(
        id: 'brd_2026_10_06',
        companyId: 'cmp_acme',
        companyName: 'ACME Teknoloji ve Bilişim A.Ş.',
        employeeId: 6,
        employeeName: 'Elif Şahin',
        employeeTitle: 'Muhasebe Uzmanı',
        department: 'Mali İşler',
        tcKimlikNo: '69382049182',
        sicilNo: '1006',
        iban: 'TR99 0006 4000 0006 7890 1234 56',
        bankName: 'İş Bankası',
        periodMonth: 10,
        periodYear: 2026,
        issueDate: DateTime(2026, 10, 28),
        paymentDate: DateTime(2026, 11, 5),
        workedDays: 22,
        workedHours: 176.0,
        overtimeHours: 2.0,
        baseGrossSalary: 45000.0,
        overtimePay: 600.0,
        mealAllowance: 4500.0,
        travelAllowance: 1800.0,
        bonus: 0.0,
        incomeTax: 5900.0,
        stampTax: 346.0,
        taxExemption: 3200.0,
        status: PayrollStatus.paid,
        isSigned: true,
        signatureTimestamp: DateTime(2026, 10, 28, 17, 30),
      ),
      // Hasan Usta (Yemekhane - Ekim 2026)
      PayrollSlip(
        id: 'brd_2026_10_07',
        companyId: 'cmp_acme',
        companyName: 'ACME Teknoloji ve Bilişim A.Ş.',
        employeeId: 7,
        employeeName: 'Hasan Usta',
        employeeTitle: 'Mutfak Şefi',
        department: 'Yemekhane & Sosyal Tesisler',
        tcKimlikNo: '71829304918',
        sicilNo: '1007',
        iban: 'TR23 0001 0000 0007 8901 2345 67',
        bankName: 'Ziraat Bankası',
        periodMonth: 10,
        periodYear: 2026,
        issueDate: DateTime(2026, 10, 28),
        paymentDate: DateTime(2026, 11, 5),
        workedDays: 22,
        workedHours: 176.0,
        overtimeHours: 10.0,
        baseGrossSalary: 38000.0,
        overtimePay: 2533.33,
        mealAllowance: 4500.0,
        travelAllowance: 1800.0,
        bonus: 0.0,
        incomeTax: 4900.0,
        stampTax: 307.0,
        taxExemption: 3200.0,
        status: PayrollStatus.paid,
        isSigned: true,
        signatureTimestamp: DateTime(2026, 10, 28, 17, 30),
      ),
      // Can Demir (NOVA - Ekim 2026)
      PayrollSlip(
        id: 'brd_2026_10_11',
        companyId: 'cmp_nova',
        companyName: 'NOVA Savunma Teknolojileri A.Ş.',
        employeeId: 11,
        employeeName: 'Can Demir',
        employeeTitle: 'Kıdemli Sistem Mühendisi',
        department: 'Aviyonik & Radar',
        tcKimlikNo: '12384920192',
        sicilNo: '2001',
        iban: 'TR34 0006 2000 0008 9012 3456 78',
        bankName: 'Garanti BBVA',
        periodMonth: 10,
        periodYear: 2026,
        issueDate: DateTime(2026, 10, 28),
        paymentDate: DateTime(2026, 11, 5),
        workedDays: 22,
        workedHours: 176.0,
        overtimeHours: 6.0,
        baseGrossSalary: 65000.0,
        overtimePay: 2600.0,
        mealAllowance: 4500.0,
        travelAllowance: 1800.0,
        bonus: 4000.0,
        incomeTax: 8900.0,
        stampTax: 543.0,
        taxExemption: 3200.0,
        status: PayrollStatus.paid,
        isSigned: true,
        signatureTimestamp: DateTime(2026, 10, 28, 17, 30),
      ),
      // Murat Yıldız (ÖZDEMİR - Ekim 2026)
      PayrollSlip(
        id: 'brd_2026_10_21',
        companyId: 'cmp_ozdemir',
        companyName: 'ÖZDEMİR Sanayi ve Yatırım Holding',
        employeeId: 21,
        employeeName: 'Murat Yıldız',
        employeeTitle: 'Lojistik Operasyon Uzmanı',
        department: 'Depolama & Sevkiyat',
        tcKimlikNo: '98472910283',
        sicilNo: '3001',
        iban: 'TR91 0006 2000 0012 3456 7890 12',
        bankName: 'Yapı Kredi',
        periodMonth: 10,
        periodYear: 2026,
        issueDate: DateTime(2026, 10, 28),
        paymentDate: DateTime(2026, 11, 5),
        workedDays: 22,
        workedHours: 176.0,
        overtimeHours: 16.0,
        baseGrossSalary: 42000.0,
        overtimePay: 4480.0,
        mealAllowance: 4500.0,
        travelAllowance: 1800.0,
        bonus: 0.0,
        incomeTax: 5600.0,
        stampTax: 352.0,
        taxExemption: 3200.0,
        status: PayrollStatus.paid,
        isSigned: true,
        signatureTimestamp: DateTime(2026, 10, 28, 17, 30),
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
      _activeCompanyId = _currentUser.companyId;
      _isLoggedIn = true;
      _startTimer();
      notifyListeners();
      return true;
    }

    // 2. Demo kısayolları için kullanıcı adı bazlı kontrol
    Employee? matched;
    // Aktif şirketin personelleri içinden eşleştir
    final companyPool = _employees.where((e) => e.companyId == _activeCompanyId).toList();
    final fallbackPool = companyPool.isNotEmpty ? companyPool : _employees;

    if (cleanEmail == 'personel@sirket.com' || cleanEmail == 'personel') {
      matched = fallbackPool.firstWhere((e) => e.role == UserRole.employee, orElse: () => _employees.firstWhere((e) => e.role == UserRole.employee));
    } else if (cleanEmail == 'ik@sirket.com' || cleanEmail == 'ik') {
      matched = fallbackPool.firstWhere((e) => e.role == UserRole.hr, orElse: () => _employees.firstWhere((e) => e.role == UserRole.hr));
    } else if (cleanEmail == 'patron@sirket.com' || cleanEmail == 'patron') {
      matched = fallbackPool.firstWhere((e) => e.role == UserRole.boss, orElse: () => _employees.firstWhere((e) => e.role == UserRole.boss));
    } else if (cleanEmail == 'admin@sirket.com' || cleanEmail == 'admin') {
      matched = fallbackPool.firstWhere((e) => e.role == UserRole.admin, orElse: () => _employees.firstWhere((e) => e.role == UserRole.admin));
    } else if (cleanEmail == 'yemekhane@sirket.com' || cleanEmail == 'yemekhane') {
      matched = fallbackPool.firstWhere((e) => e.role == UserRole.cafeteria, orElse: () => _employees.firstWhere((e) => e.role == UserRole.cafeteria));
    }

    if (matched != null) {
      _currentUser = matched;
      _activeCompanyId = _currentUser.companyId;
      _isLoggedIn = true;
      _startTimer();
      notifyListeners();
      return true;
    }

    return false;
  }

  // Yeni Personel Kaydı - Şirket Kodu ile Şirket Belirleme
  ({bool success, String message}) register({
    required String companyCode,
    required String fullName,
    required String email,
    required String phone,
    required String department,
    required String title,
    required String pin,
  }) {
    final cleanCode = companyCode.trim().toUpperCase();
    final idx = _companies.indexWhere((c) => c.code.toUpperCase() == cleanCode);
    if (idx == -1) {
      final availableCodes = _companies.map((c) => c.code).join(', ');
      return (
        success: false,
        message: 'Belirtilen "$cleanCode" koduna ait şirket bulunamadı. Mevcut şirket kodları: $availableCodes',
      );
    }

    final targetCompany = _companies[idx];
    final newId = _employees.length + 1;
    final newEmployee = Employee(
      id: newId,
      companyId: targetCompany.id,
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
    _activeCompanyId = targetCompany.id;
    _isLoggedIn = true;
    _isCheckedIn = false;
    _workedToday = Duration.zero;
    _startTimer();
    notifyListeners();
    return (
      success: true,
      message: '"${targetCompany.name}" şirketine kaydınız başarıyla yapıldı.',
    );
  }

  // Oturumu Kapat
  void logout() {
    _isLoggedIn = false;
    _isCheckedIn = false;
    _workTimer?.cancel();
    notifyListeners();
  }

  // ==========================================
  // ROL YÖNETİMİ & GÜVENLİK PROTOKOLLERİ
  // Kural: Patron yeni roller ekleyebilir AMA admin rolü ekleyemez ve admin atayamaz.
  // ==========================================

  /// Yeni Rol Ekleme Metodu
  /// Güvenlik kuralı: Patron yeni roller ekleyebilir AMA admin rolünü ekleyemez!
  ({bool success, String message}) addNewRole({
    required String name,
    required String description,
    required UserRole baseRole,
    required Color color,
    required IconData icon,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return (success: false, message: 'Lütfen bir rol adı giriniz.');
    }

    // GÜVENLİK PROTOKOLÜ 1: Patron seviyesinde Admin yetkili rol EKLEYEMEZ
    if (_currentUser.role == UserRole.boss) {
      if (baseRole == UserRole.admin) {
        return (
          success: false,
          message: 'Yetki Sınırı: Patron seviyesinde Sistem Yöneticisi (Admin) tabanlı rol eklenemez.',
        );
      }
      final lower = trimmedName.toLowerCase();
      if (lower == 'admin' || lower.contains('admin') || lower.contains('sistem yöneticisi')) {
        return (
          success: false,
          message: 'Güvenlik Sınırı: "Admin" veya "Sistem Yöneticisi" ismiyle yeni rol tanımlanamaz.',
        );
      }
    }

    // İsim benzersizlik kontrolü
    if (_roles.any((r) => r.name.toLowerCase() == trimmedName.toLowerCase())) {
      return (success: false, message: '"$trimmedName" isimli bir rol sistemde zaten mevcut.');
    }

    final newRole = AppRoleItem(
      id: 'role_${DateTime.now().millisecondsSinceEpoch}',
      name: trimmedName,
      description: description.trim().isEmpty ? '$trimmedName Yetkisi' : description.trim(),
      baseRole: baseRole,
      color: color,
      icon: icon,
      isSystemRole: false,
      createdBy: _currentUser.role == UserRole.boss ? 'Patron (${_currentUser.fullName})' : 'Admin (${_currentUser.fullName})',
    );

    _roles.add(newRole);
    notifyListeners();
    return (success: true, message: '"$trimmedName" rolü başarıyla oluşturuldu.');
  }

  /// Özel Rolü Sil
  ({bool success, String message}) deleteRole(String roleId) {
    final index = _roles.indexWhere((r) => r.id == roleId);
    if (index == -1) return (success: false, message: 'Rol bulunamadı.');

    final role = _roles[index];
    if (role.isSystemRole) {
      return (success: false, message: 'Varsayılan sistem rolleri silinemez.');
    }

    // Bu role sahip personellerin özel rol kaydını temizle
    for (int i = 0; i < _employees.length; i++) {
      if (_employees[i].customRoleId == roleId) {
        _employees[i] = _employees[i].copyWith(clearCustomRole: true);
      }
    }

    _roles.removeAt(index);
    notifyListeners();
    return (success: true, message: '"${role.name}" rolü başarıyla silindi.');
  }

  /// Personel Rolünü Değiştir (Rol Atama)
  /// Güvenlik kuralı: Patron kimseye Admin rolü ATAYAMAZ ve Admin personeli DEĞİŞTİREMEZ.
  ({bool success, String message}) changeEmployeeRoleByActor({
    required int employeeId,
    required UserRole newBaseRole,
    String? customRoleId,
    String? customRoleName,
  }) {
    final index = _employees.indexWhere((e) => e.id == employeeId);
    if (index == -1) {
      return (success: false, message: 'Personel kaydı bulunamadı.');
    }

    final target = _employees[index];

    // GÜVENLİK KONTROLLERİ (Patron İçin):
    if (_currentUser.role == UserRole.boss) {
      // 1. Patron kimseye Admin rolü ATAYAMAZ
      if (newBaseRole == UserRole.admin) {
        return (
          success: false,
          message: 'Yetki Sınırı: Patron seviyesinde kullanıcılara Admin rolü atanamaz!',
        );
      }
      // 2. Patron mevcut Admin kullanıcısının yetkisini DEĞİŞTİREMEZ
      if (target.role == UserRole.admin) {
        return (
          success: false,
          message: 'Güvenlik Sınırı: Sistem Yöneticisi (Admin) kullanıcısının yetkisi Patron tarafından değiştirilemez.',
        );
      }
    }

    final updated = target.copyWith(
      role: newBaseRole,
      customRoleId: customRoleId,
      customRoleName: customRoleName,
      clearCustomRole: customRoleId == null,
    );

    _employees[index] = updated;
    if (_currentUser.id == employeeId) {
      _currentUser = updated;
    }
    notifyListeners();

    final roleName = customRoleName ?? newBaseRole.label;
    return (
      success: true,
      message: '${target.fullName} kullanıcısına "$roleName" rolü atandı.',
    );
  }

  // Admin / Geriye Uyumluluk İçin Rol Değiştirme
  void changeEmployeeRole(int employeeId, UserRole newRole) {
    changeEmployeeRoleByActor(
      employeeId: employeeId,
      newBaseRole: newRole,
    );
  }

  // Admin: Geofence Ayarlarını Güncelle
  void updateSystemSettings({
    required double lat,
    required double lng,
    required double radius,
    required String wifiSsid,
    String? address,
  }) {
    updateCompanySettings(
      lat: lat,
      lng: lng,
      radius: radius,
      wifiSsid: wifiSsid,
      address: address,
    );
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
      companyId: _currentUser.companyId,
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
      companyId: _currentUser.companyId,
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
        companyId: old.companyId,
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
