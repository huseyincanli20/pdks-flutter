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
import '../models/page_customization.dart';
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
  Duration _workedToday = Duration.zero;
  Timer? _workTimer;

  // Veri Listeleri
  List<Employee> _employees = [];
  List<AttendanceRecord> _records = [];
  List<LeaveRequest> _leaves = [];
  List<ShiftSchedule> _shifts = [];
  List<PayrollSlip> _payrolls = [];

  // Bildirimler
  List<AppNotification> _notifications = [];

  // Günün Yemekhane Menüsü
  CafeteriaMenu _todayMenu = CafeteriaMenu(
    date: DateTime.now(),
    soup: 'Süzme Mercimek Çorbası',
    soupCalories: 160,
    mainDish: 'Hasanpaşa Köfte',
    mainDishCalories: 380,
    sideDish: 'Tereyağlı Pirinç Pilavı',
    sideDishCalories: 210,
    dessertOrSalad: 'Mevsim Salata & Kazandibi',
    dessertCalories: 190,
    drink: 'Ayran / Su',
    drinkCalories: 80,
    totalCalories: 820,
    vegetarianAlternative: 'Zeytinyağlı Enginar & Fırın Sebze',
    vegetarianCalories: 260,
    chefNote: 'Glüten ve laktoz içerir. Menümüz taze ve organik malzemelerle hazırlanmıştır.',
    updatedBy: 'Hasan Usta (Mutfak Şefi)',
  );

  // 2 Haftalık Yemekhane Menüsü (14 Günlük Çizelge)
  late List<CafeteriaMenu> _twoWeekMenus = buildDefaultTwoWeekMenu();

  // Admin Sayfa Düzenleme Modu (Yalnızca Admin rolünde aktiftir)
  bool _isAdminEditMode = false;
  final Map<String, PageCustomization> _pageCustomizations = {};

  bool get isAdminEditMode => _isAdminEditMode && _isLoggedIn && _currentUser.role == UserRole.admin;

  void setAdminEditMode(bool active) {
    if (_currentUser.role != UserRole.admin) return;
    _isAdminEditMode = active;
    notifyListeners();
  }

  void toggleAdminEditMode() {
    if (_currentUser.role != UserRole.admin) return;
    _isAdminEditMode = !_isAdminEditMode;
    notifyListeners();
  }

  PageCustomization getPageCustomization(String pageId) {
    return _pageCustomizations[pageId] ?? PageCustomization(pageId: pageId);
  }

  void updatePageCustomization(PageCustomization customization) {
    if (_currentUser.role != UserRole.admin) return;
    _pageCustomizations[customization.pageId] = customization;
    notifyListeners();
  }

  void togglePageSection(String pageId, String sectionId) {
    if (_currentUser.role != UserRole.admin) return;
    final current = getPageCustomization(pageId);
    final hidden = Set<String>.from(current.hiddenSectionIds);
    if (hidden.contains(sectionId)) {
      hidden.remove(sectionId);
    } else {
      hidden.add(sectionId);
    }
    _pageCustomizations[pageId] = current.copyWith(hiddenSectionIds: hidden);
    notifyListeners();
  }

  void resetPageCustomization(String pageId) {
    if (_currentUser.role != UserRole.admin) return;
    _pageCustomizations.remove(pageId);
    notifyListeners();
  }

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
  List<CafeteriaMenu> get twoWeekMenus => _twoWeekMenus;

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

  void setTwoWeekMenus(List<CafeteriaMenu> menus, {bool publishNotification = true}) {
    _twoWeekMenus = List.from(menus);

    // Eğer bugünün tarihine denk gelen gün varsa günün menüsünü de senkronize et
    final now = DateTime.now();
    for (final m in _twoWeekMenus) {
      if (m.isSameDay(now) && m.isCompleted) {
        _todayMenu = m;
        break;
      }
    }

    if (publishNotification) {
      addNotification(AppNotification(
        id: 'twoweek_menu_${DateTime.now().millisecondsSinceEpoch}',
        title: '📢 2 Haftalık Yemek Menüsü Yayınlandı! 🍽️',
        message: 'Önümüzdeki 14 günlük kurumsal yemekhane menüsü yayında! Kalori ve vejetaryen seçeneklerini hemen inceleyebilirsiniz.',
        timestamp: DateTime.now(),
        isRead: false,
        type: NotificationType.cafeteria,
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFFEA580C),
      ));
    }
    notifyListeners();
  }

  void updateTwoWeekDay(int index, CafeteriaMenu menu) {
    if (index >= 0 && index < _twoWeekMenus.length) {
      _twoWeekMenus[index] = menu;
      if (menu.isSameDay(DateTime.now())) {
        _todayMenu = menu;
      }
      notifyListeners();
    }
  }

  void resetTwoWeekMenuToTemplate() {
    _twoWeekMenus = buildDefaultTwoWeekMenu();
    notifyListeners();
  }

  void clearTwoWeekMenu() {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    _twoWeekMenus = List.generate(14, (i) {
      return CafeteriaMenu(
        date: monday.add(Duration(days: i)),
        soup: '',
        mainDish: '',
        sideDish: '',
        dessertOrSalad: '',
        drink: 'Ayran / Su',
        totalCalories: 0,
        updatedBy: currentUser.fullName,
      );
    });
    notifyListeners();
  }

  static List<CafeteriaMenu> buildDefaultTwoWeekMenu({DateTime? startMonday}) {
    final now = DateTime.now();
    final monday = startMonday ?? DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

    final items = [
      // 1. Hafta (Gün 1 - Gün 7)
      {
        'soup': 'Süzme Mercimek Çorbası',
        'soupCal': 160,
        'main': 'Hasanpaşa Köfte',
        'mainCal': 380,
        'side': 'Tereyağlı Pirinç Pilavı',
        'sideCal': 210,
        'dessert': 'Mevsim Salata & Kazandibi',
        'dessertCal': 190,
        'drink': 'Ayran / Su',
        'drinkCal': 80,
        'cal': 820,
        'veg': 'Zeytinyağlı Enginar & Fırın Sebze',
        'vegCal': 260,
        'note': 'Haftanın ilk günü enerjik başlangıç! Glüten ve süt içerir.',
      },
      {
        'soup': 'Yayla Çorbası',
        'soupCal': 140,
        'main': 'Orman Kebabı',
        'mainCal': 390,
        'side': 'Şehriyeli Bulgur Pilavı',
        'sideCal': 190,
        'dessert': 'Kemalpaşa Tatlısı',
        'dessertCal': 210,
        'drink': 'Şalgam Suyu / Su',
        'drinkCal': 35,
        'cal': 780,
        'veg': 'Mantar Sote & Yoğurtlu Kabak',
        'vegCal': 230,
        'note': 'Kebabımız taze kuzu eti ve dağ kekiğiyle hazırlanmıştır.',
      },
      {
        'soup': 'Ezogelin Çorbası',
        'soupCal': 150,
        'main': 'Geleneksel Kuru Fasulye',
        'mainCal': 410,
        'side': 'Tereyağlı Pirinç Pilavı',
        'sideCal': 210,
        'dessert': 'Karışık Turşu & Cacık',
        'dessertCal': 120,
        'drink': 'Ayran / Su',
        'drinkCal': 80,
        'cal': 850,
        'veg': 'Zeytinyağlı Barbunya Pilaki',
        'vegCal': 280,
        'note': 'İspir kuru fasulyesi tereyağlı güveçte pişirilmiştir.',
      },
      {
        'soup': 'Tarhana Çorbası',
        'soupCal': 150,
        'main': 'Fırında Soslu Tavuk Baget',
        'mainCal': 360,
        'side': 'Elma Dilim Baharatlı Patates',
        'sideCal': 200,
        'dessert': 'Mozaik Pasta',
        'dessertCal': 210,
        'drink': 'Ev Yapımı Limonata',
        'drinkCal': 90,
        'cal': 790,
        'veg': 'Fırın Sebze Dizmesi & Humus',
        'vegCal': 240,
        'note': 'Tavuklarımız yerli üretimdir. Afiyet olsun.',
      },
      {
        'soup': 'Domates Çorbası (Kaşarlı)',
        'soupCal': 150,
        'main': 'İzmir Köfte',
        'mainCal': 380,
        'side': 'Fesleğenli Burgu Makarna',
        'sideCal': 220,
        'dessert': 'Fırın Sütlaç',
        'dessertCal': 210,
        'drink': 'Ayran / Su',
        'drinkCal': 80,
        'cal': 830,
        'veg': 'Ispanak Graten & Fırın Mantar',
        'vegCal': 250,
        'note': 'Cuma gününe özel fırın sütlaç ikramımızdır.',
      },
      {
        'soup': 'Kremalı Mantar Çorbası',
        'soupCal': 160,
        'main': 'Çıtır Piliç Şinitzel',
        'mainCal': 380,
        'side': 'Kremalı Patates Püresi',
        'sideCal': 190,
        'dessert': 'Supangle & Muz',
        'dessertCal': 220,
        'drink': 'Meyve Suyu / Su',
        'drinkCal': 90,
        'cal': 750,
        'veg': 'Falafel Dürüm & Tahin Sos',
        'vegCal': 310,
        'note': 'Hafta sonu mesai personeli için hafif ve lezzetli menü.',
      },
      {
        'soup': 'Tavuk Suyu Şehriye Çorbası',
        'soupCal': 130,
        'main': 'Kıymalı Biber Dolması',
        'mainCal': 340,
        'side': 'Süzme Yoğurt',
        'sideCal': 120,
        'dessert': 'Haşhaşlı Revani Tatlısı',
        'dessertCal': 240,
        'drink': 'Ayran / Su',
        'drinkCal': 80,
        'cal': 710,
        'veg': 'Zeytinyağlı Biber Dolması',
        'vegCal': 250,
        'note': 'Pazar nöbeti menüsü.',
      },

      // 2. Hafta (Gün 8 - Gün 14)
      {
        'soup': 'Düğün Çorbası',
        'soupCal': 170,
        'main': 'Kuzu Çoban Kavurma',
        'mainCal': 420,
        'side': 'Meyhane Pilavı (Bulgurlu)',
        'sideCal': 200,
        'dessert': 'Karamelli Trileçe',
        'dessertCal': 230,
        'drink': 'Ayran / Su',
        'drinkCal': 80,
        'cal': 870,
        'veg': 'Zeytinyağlı Taze Fasulye',
        'vegCal': 220,
        'note': '2. hafta başlangıç menüsü. Bol etli geleneksel kavurma.',
      },
      {
        'soup': 'Köz Patlıcan Çorbası',
        'soupCal': 130,
        'main': 'Fırında Soslu Somon Fileto',
        'mainCal': 350,
        'side': 'Buharda Sebze & Roka Salatası',
        'sideCal': 120,
        'dessert': 'Fıstıklı İrmik Helvası',
        'dessertCal': 240,
        'drink': 'Şalgam Suyu / Su',
        'drinkCal': 35,
        'cal': 680,
        'veg': 'Fırında Karnabahar Steak',
        'vegCal': 190,
        'note': 'Haftalık Omega-3 balık günü. Sağlıklı ve hafif!',
      },
      {
        'soup': 'Süzme Kırmızı Mercimek',
        'soupCal': 160,
        'main': 'Ev Yapımı Kayseri Mantısı',
        'mainCal': 440,
        'side': 'Sarımsaklı Yoğurt & Tereyağlı Sos',
        'sideCal': 120,
        'dessert': 'Vişneli Etimek Tatlısı',
        'dessertCal': 220,
        'drink': 'Kola / Gazoz / Su',
        'drinkCal': 90,
        'cal': 890,
        'veg': 'Ispanaklı Peynirli Mantı',
        'vegCal': 320,
        'note': 'Geleneksel el açması mantı günü.',
      },
      {
        'soup': 'Mevsim Sebze Çorbası',
        'soupCal': 120,
        'main': 'Dana Rosto & Mantar Sos',
        'mainCal': 380,
        'side': 'Tereyağlı Patates Püresi',
        'sideCal': 190,
        'dessert': 'Çikolata Soslu Profiterol',
        'dessertCal': 240,
        'drink': 'Nane Limonata',
        'drinkCal': 80,
        'cal': 810,
        'veg': 'Sebzeli Noodle & Çin Böreği',
        'vegCal': 280,
        'note': 'Özel şef soslu fırın dana rosto.',
      },
      {
        'soup': 'Kremalı Brokoli Çorbası',
        'soupCal': 130,
        'main': 'Güveçte Etli Türlü',
        'mainCal': 360,
        'side': 'Arpa Şehriyeli Pirinç Pilavı',
        'sideCal': 220,
        'dessert': 'Gaziantep Baklava & Havuç Dilimi',
        'dessertCal': 280,
        'drink': 'Ayran / Su',
        'drinkCal': 80,
        'cal': 860,
        'veg': 'Zeytinyağlı Kereviz & Havuç',
        'vegCal': 200,
        'note': 'Cuma gününe özel baklava ziyafeti.',
      },
      {
        'soup': 'Ezogelin Çorbası',
        'soupCal': 150,
        'main': 'Çıtır Tavuk Tenders & Dip Sos',
        'mainCal': 370,
        'side': 'Baharatlı Fırın Patates',
        'sideCal': 210,
        'dessert': 'Çikolatalı Puding & Bisküvi',
        'dessertCal': 190,
        'drink': 'Soğuk Çay / Su',
        'drinkCal': 80,
        'cal': 760,
        'veg': 'Fırın Sebzeli Çıtır Börek',
        'vegCal': 290,
        'note': 'Hafta sonu lezzetleri.',
      },
      {
        'soup': 'Mercimek Çorbası',
        'soupCal': 160,
        'main': 'Karnıyarık',
        'mainCal': 380,
        'side': 'Şehriyeli Pirinç Pilavı',
        'sideCal': 220,
        'dessert': 'Cacık & Mevsim Meyvesi',
        'dessertCal': 120,
        'drink': 'Ayran / Su',
        'drinkCal': 80,
        'cal': 800,
        'veg': 'İmam Bayıldı (Zeytinyağlı)',
        'vegCal': 250,
        'note': 'Klasik Türk mutfağı pazar kapanış menüsü.',
      },
    ];

    final list = <CafeteriaMenu>[];
    for (int i = 0; i < 14; i++) {
      final item = items[i];
      final dayDate = monday.add(Duration(days: i));
      list.add(CafeteriaMenu(
        date: dayDate,
        soup: item['soup'] as String,
        soupCalories: item['soupCal'] as int? ?? 160,
        mainDish: item['main'] as String,
        mainDishCalories: item['mainCal'] as int? ?? 380,
        sideDish: item['side'] as String,
        sideDishCalories: item['sideCal'] as int? ?? 210,
        dessertOrSalad: item['dessert'] as String,
        dessertCalories: item['dessertCal'] as int? ?? 140,
        drink: item['drink'] as String,
        drinkCalories: item['drinkCal'] as int? ?? 70,
        totalCalories: item['cal'] as int? ?? 800,
        vegetarianAlternative: item['veg'] as String?,
        vegetarianCalories: item['vegCal'] as int? ?? 280,
        chefNote: item['note'] as String?,
        updatedBy: 'Hasan Usta (Mutfak Şefi)',
      ));
    }
    return list;
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

  // İK & Patron Dashboard Sayaçları (Aktif Şirkete Göre Dinamik Gerçek Veriler)
  int get totalEmployeesCount => employees.length;
  int get presentEmployeesCount {
    final checkedInEmpIds = <int>{};
    for (final r in records) {
      if (r.type == AttendanceType.checkIn) {
        checkedInEmpIds.add(r.employeeId);
      } else if (r.type == AttendanceType.checkOut) {
        checkedInEmpIds.remove(r.employeeId);
      }
    }
    if (_isCheckedIn && _currentUser.companyId == _activeCompanyId) {
      checkedInEmpIds.add(_currentUser.id);
    }
    return checkedInEmpIds.length;
  }
  int get onLeaveEmployeesCount => leaves.where((l) => l.status == LeaveStatus.approved).length;
  int get lateEmployeesCount => records.where((r) => r.isLate).length;

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
      usedLeaveDays: 0,
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
      usedLeaveDays: 0,
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
      usedLeaveDays: 0,
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
      usedLeaveDays: 0,
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
      usedLeaveDays: 0,
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
      usedLeaveDays: 0,
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
      usedLeaveDays: 0,
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
      usedLeaveDays: 0,
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
      usedLeaveDays: 0,
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
      usedLeaveDays: 0,
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
      usedLeaveDays: 0,
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
      usedLeaveDays: 0,
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
      usedLeaveDays: 0,
    );

    _currentUser = personel; // Varsayılan personel
    _employees = [
      personel, ik, patron, admin, diger1, diger2, yemekhane,
      novaPersonel, novaIk, novaPatron, novaAdmin,
      ozdemirPersonel, ozdemirIk, ozdemirPatron, ozdemirAdmin,
    ];

    _records = [];
    _leaves = [];
    _payrolls = [];

    _shifts = [
      ShiftSchedule(
        id: 1,
        companyId: 'cmp_acme',
        title: 'Standart Ofis Vardiyası',
        startTime: '08:30',
        endTime: '17:30',
        breakMinutes: 60,
        activeDays: ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma'],
        assignedEmployeeCount: 0,
      ),
      ShiftSchedule(
        id: 2,
        companyId: 'cmp_acme',
        title: 'Geç / Esnek Vardiya',
        startTime: '10:00',
        endTime: '19:00',
        breakMinutes: 60,
        activeDays: ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma'],
        assignedEmployeeCount: 0,
      ),
      ShiftSchedule(
        id: 3,
        companyId: 'cmp_acme',
        title: 'Hafta Sonu Nöbetçi Ekip',
        startTime: '09:00',
        endTime: '15:00',
        breakMinutes: 45,
        activeDays: ['Cumartesi'],
        assignedEmployeeCount: 0,
      ),
      ShiftSchedule(
        id: 4,
        companyId: 'cmp_nova',
        title: 'Savunma Ar-Ge Mühendislik Vardiyası',
        startTime: '08:00',
        endTime: '17:00',
        breakMinutes: 60,
        activeDays: ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma'],
        assignedEmployeeCount: 0,
      ),
      ShiftSchedule(
        id: 5,
        companyId: 'cmp_ozdemir',
        title: 'Lojistik & Operasyon Vardiyası',
        startTime: '07:30',
        endTime: '16:30',
        breakMinutes: 60,
        activeDays: ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi'],
        assignedEmployeeCount: 0,
      ),
    ];

    _isCheckedIn = false;
    _lastCheckInTime = null;
    _workedToday = Duration.zero;
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
    _isAdminEditMode = false;
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
