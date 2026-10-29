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
import '../models/chat_message.dart';
import '../core/services/api_service.dart';
import '../core/services/location_service.dart';
import '../core/services/database_service.dart';
import '../core/services/firebase_service.dart';
import '../core/services/ios_notification_service.dart';
import '../core/theme/app_theme_type.dart';
import '../core/theme/app_theme.dart';

class PdksState extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final DatabaseService _db = DatabaseService();
  final FirebaseService _firebase = FirebaseService();
  Timer? _cloudSyncTimer;

  // Aktif Giriş Yapan Kullanıcı
  late Employee _currentUser;
  bool _isLoggedIn = false;

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
      _employees.where((e) => e.companyId == _activeCompanyId && e.isApproved).toList();
  List<Employee> get pendingEmployees =>
      _employees.where((e) => e.companyId == _activeCompanyId && !e.isApproved).toList();
  List<Employee> get allPendingEmployees =>
      _employees.where((e) => !e.isApproved).toList();
  int get pendingApprovalsCount => pendingEmployees.length;
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

  AppNotification? _lastDispatchedPhoneNotification;
  AppNotification? get lastDispatchedPhoneNotification => _lastDispatchedPhoneNotification;

  void addNotification(AppNotification notif) {
    _notifications.insert(0, notif);
    notifyListeners();
  }

  // ==========================================
  // ŞİRKET İÇİ MESAJLAŞMA & ANLIK SOHBET SİSTEMİ
  // ==========================================
  final List<ChatChannel> _systemChatChannels = [
    const ChatChannel(
      id: 'company_general',
      title: 'Genel Şirket Kanalı',
      subtitle: 'Tüm departmanlar ve çalışma arkadaşları',
      icon: Icons.corporate_fare_rounded,
      iconColor: Color(0xFF2563EB),
    ),
    const ChatChannel(
      id: 'hr_support',
      title: 'İK & Personel Destek',
      subtitle: 'İnsan kaynakları soru, talep ve izin danışma',
      icon: Icons.support_agent_rounded,
      iconColor: Color(0xFF0284C7),
    ),
    const ChatChannel(
      id: 'management_announcements',
      title: 'Yönetim & Duyurular',
      subtitle: 'Şirket yönetimi resmi duyuru ve bilgi akışı',
      icon: Icons.campaign_rounded,
      iconColor: Color(0xFFD97706),
    ),
  ];

  final List<ChatMessage> _chatMessages = [
    ChatMessage(
      id: 'msg_init_1',
      senderId: 2, // Zeynep Kaya (İK Direktörü)
      senderName: 'Zeynep Kaya',
      senderRole: UserRole.hr,
      channelId: 'company_general',
      text: 'Herkese iyi çalışmalar dileriz! Şirket içi PDKS anlık mesajlaşma kanallarımız aktif edilmiştir. 🚀',
      timestamp: DateTime.now().subtract(const Duration(hours: 3, minutes: 20)),
      isRead: true,
    ),
    ChatMessage(
      id: 'msg_init_2',
      senderId: 3, // Mehmet Demir (CEO)
      senderName: 'Mehmet Demir',
      senderRole: UserRole.boss,
      channelId: 'company_general',
      text: 'Yeni mesajlaşma altyapımız tüm ekibimize hayırlı olsun. Verimli çalışmalar dilerim.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 45)),
      isRead: true,
    ),
    ChatMessage(
      id: 'msg_init_3',
      senderId: 1, // Ahmet Yılmaz (Personel)
      senderName: 'Ahmet Yılmaz',
      senderRole: UserRole.employee,
      channelId: 'company_general',
      text: 'Harika bir yenilik olmuş, teşekkürler!',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
      isRead: true,
    ),
    ChatMessage(
      id: 'msg_init_hr_1',
      senderId: 2, // Zeynep Kaya (İK)
      senderName: 'Zeynep Kaya (İK)',
      senderRole: UserRole.hr,
      channelId: 'hr_support',
      text: 'Merhaba, İnsan Kaynakları Destek Hattına hoş geldiniz. İzin, mesai, kıyafet bedenleri veya diğer kurumsal konulardaki sorularınızı buradan doğrudan bize iletebilirsiniz.',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      isRead: true,
    ),
  ];

  List<ChatChannel> get systemChatChannels => List.unmodifiable(_systemChatChannels);
  final List<ChatChannel> _customGroupChannels = [];
  List<ChatChannel> get allGroupChannels => [..._systemChatChannels, ..._customGroupChannels];

  bool get canCreateGroupChat => _currentUser.role == UserRole.boss || _currentUser.role == UserRole.admin;

  /// Yeni Grup Kanalı Oluşturma Metodu (Yalnızca Patron ve Admin Yetkili)
  ({bool success, String message, ChatChannel? channel}) createGroupChannel({
    required String title,
    required String subtitle,
    IconData? icon,
    Color? iconColor,
    List<int>? participantIds,
  }) {
    if (_currentUser.role != UserRole.boss && _currentUser.role != UserRole.admin) {
      return (
        success: false,
        message: 'Yetki Sınırı: Yalnızca Şirket Patronu (CEO) veya Sistem Yöneticisi (Admin) yeni grup kurabilir.',
        channel: null,
      );
    }

    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return (success: false, message: 'Lütfen grup için bir başlık giriniz.', channel: null);
    }

    if (allGroupChannels.any((c) => c.title.toLowerCase() == trimmed.toLowerCase())) {
      return (success: false, message: '"$trimmed" adında bir grup zaten mevcut.', channel: null);
    }

    final channelId = 'group_${DateTime.now().millisecondsSinceEpoch}';
    final newChannel = ChatChannel(
      id: channelId,
      title: trimmed,
      subtitle: subtitle.trim().isEmpty ? 'Grup Sohbeti' : subtitle.trim(),
      icon: icon ?? Icons.group_rounded,
      iconColor: iconColor ?? const Color(0xFF2563EB),
      participantIds: participantIds ?? _employees.map((e) => e.id).toList(),
    );

    _customGroupChannels.add(newChannel);
    _db.insertCustomChannel(newChannel);

    // Gruba ilk kurucu açılış mesajını ekle
    final creatorRole = _currentUser.role == UserRole.boss ? 'Patron (CEO)' : 'Sistem Yöneticisi (Admin)';
    final creatorMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _currentUser.id,
      senderName: _currentUser.fullName,
      senderRole: _currentUser.role,
      channelId: channelId,
      text: '🎉 "$trimmed" grubu ${_currentUser.fullName} ($creatorRole) tarafından kuruldu.',
      timestamp: DateTime.now(),
      isRead: true,
    );
    _chatMessages.add(creatorMsg);
    _db.insertChatMessage(creatorMsg);
    if (_firebase.isEnabled) {
      _firebase.pushMessageToCloud(creatorMsg);
    }

    // iPhone Bildirimi Gönder
    IosNotificationService.showIosNotification(
      title: '👥 Yeni Grup Kanalı Kuruldu',
      body: '"$trimmed" grubu ${_currentUser.fullName} tarafından oluşturuldu.',
      icon: newChannel.icon,
      iconColor: newChannel.iconColor,
    );

    notifyListeners();
    return (success: true, message: '"$trimmed" grubu başarıyla oluşturuldu.', channel: newChannel);
  }

  List<ChatMessage> get chatMessages => List.unmodifiable(_chatMessages);

  String getDirectChannelId(int userA, int userB) {
    return userA < userB ? 'dm_${userA}_$userB' : 'dm_${userB}_$userA';
  }

  List<ChatMessage> getMessagesForChannel(String channelId) {
    return _chatMessages.where((m) => m.channelId == channelId).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  ChatMessage? getLastMessageForChannel(String channelId) {
    final msgs = getMessagesForChannel(channelId);
    return msgs.isNotEmpty ? msgs.last : null;
  }

  int getUnreadCountForChannel(String channelId) {
    return _chatMessages
        .where((m) => m.channelId == channelId && !m.isRead && m.senderId != _currentUser.id)
        .length;
  }

  int get unreadChatCount {
    return _chatMessages
        .where((m) => !m.isRead && m.senderId != _currentUser.id)
        .length;
  }

  void markChannelAsRead(String channelId) {
    bool changed = false;
    for (int i = 0; i < _chatMessages.length; i++) {
      if (_chatMessages[i].channelId == channelId && !_chatMessages[i].isRead && _chatMessages[i].senderId != _currentUser.id) {
        _chatMessages[i] = _chatMessages[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  void sendMessage({
    required String channelId,
    required String text,
    int? receiverId,
    MessageType type = MessageType.text,
    String? attachmentName,
    String? attachmentSize,
  }) {
    if (text.trim().isEmpty && attachmentName == null) return;

    final newMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _currentUser.id,
      senderName: _currentUser.fullName,
      senderRole: _currentUser.role,
      receiverId: receiverId,
      channelId: channelId,
      text: text.trim(),
      timestamp: DateTime.now(),
      isRead: false,
      type: type,
      attachmentName: attachmentName,
      attachmentSize: attachmentSize,
    );

    _chatMessages.add(newMsg);
    _db.insertChatMessage(newMsg);
    if (_firebase.isEnabled) {
      _firebase.pushMessageToCloud(newMsg);
    }
    notifyListeners();

    // iPhone Bildirimi Tetikle (Ses + Web Push + iOS Dynamic Island Banner)
    IosNotificationService.showIosNotification(
      title: '💬 ${_currentUser.fullName}',
      body: type == MessageType.document
          ? '📄 Belge gönderildi: ${attachmentName ?? "Belge.pdf"}'
          : (type == MessageType.location ? '📍 Konum paylaşıldı' : newMsg.text),
      icon: Icons.chat_bubble_rounded,
      iconColor: const Color(0xFF2563EB),
    );

    // İK Destek kanalına yazıldığında otomatik destek yanıt simülasyonu
    if (channelId == 'hr_support' && _currentUser.role != UserRole.hr) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        final replyMsg = ChatMessage(
          id: 'msg_hr_auto_${DateTime.now().millisecondsSinceEpoch}',
          senderId: 2, // Zeynep Kaya (İK Direktörü)
          senderName: 'Zeynep Kaya (İK Destek)',
          senderRole: UserRole.hr,
          channelId: 'hr_support',
          text: 'Sayın ${_currentUser.fullName}, mesajınız İnsan Kaynakları birimimize ulaştı. Talebiniz incelenerek en kısa sürede dönüş sağlanacaktır. ✅',
          timestamp: DateTime.now(),
          isRead: false,
        );
        _chatMessages.add(replyMsg);
        _db.insertChatMessage(replyMsg);
        if (_firebase.isEnabled) {
          _firebase.pushMessageToCloud(replyMsg);
        }
        notifyListeners();

        // İK Destek yanıtı için iPhone Bildirimi
        IosNotificationService.showIosNotification(
          title: '💬 Zeynep Kaya (İK Destek)',
          body: replyMsg.text,
          icon: Icons.support_agent_rounded,
          iconColor: const Color(0xFF0284C7),
        );
      });
    }
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
    _initFirebase();
  }

  // ==========================================
  // FIREBASE BULUT VERİTABANI VE SENKRONİZASYON
  // ==========================================
  FirebaseService get firebase => _firebase;
  bool get isFirebaseConnected => _firebase.isConnected;
  bool get isFirebaseEnabled => _firebase.isEnabled;
  String get firebaseProjectId => _firebase.projectId;

  void _initFirebase() {
    _firebase.init().then((_) {
      notifyListeners();
      _startCloudSyncTimer();
    }).catchError((e) {
      debugPrint('Firebase init hatası: $e');
    });
  }

  void _startCloudSyncTimer() {
    _cloudSyncTimer?.cancel();
    _cloudSyncTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_firebase.isEnabled && _firebase.isConnected) {
        _syncCloudData();
      }
    });
  }

  Future<void> _syncCloudData() async {
    try {
      final cloudMsgs = await _firebase.fetchNewMessagesFromCloud();
      bool hasNew = false;
      for (final m in cloudMsgs) {
        if (!_chatMessages.any((local) => local.id == m.id)) {
          _chatMessages.add(m);
          _db.insertChatMessage(m);
          hasNew = true;
          if (m.senderId != _currentUser.id) {
            IosNotificationService.showIosNotification(
              title: '💬 ${m.senderName}',
              body: m.text,
              icon: Icons.chat_bubble_outline_rounded,
            );
          }
        }
      }
      if (hasNew) notifyListeners();
    } catch (_) {}
  }

  Future<bool> updateFirebaseConfig({
    required String projectId,
    String? apiKey,
    required bool isEnabled,
  }) async {
    final success = await _firebase.updateConfig(
      projectId: projectId,
      apiKey: apiKey,
      isEnabled: isEnabled,
    );
    notifyListeners();
    return success;
  }

  Future<bool> testFirebaseConnection() async {
    final ok = await _firebase.testConnection();
    notifyListeners();
    return ok;
  }

  Future<({int employees, int messages, int records, bool success})> syncLocalDbToFirebase() async {
    final res = await _firebase.syncLocalDbToFirebase(_db);
    notifyListeners();
    return res;
  }

  Future<bool> checkCloudDuplicate(String email, String phone) async {
    return await _firebase.checkUserExistsOnCloud(email, phone);
  }

  Future<({bool success, bool isPendingApproval, String message})> loginFromCloudAsync(String email, String pin) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPin = pin.trim();

    try {
      final cloudEmp = await _firebase.getEmployeeFromCloudByEmail(cleanEmail);
      if (cloudEmp != null) {
        if (!_employees.any((e) => e.id == cloudEmp.id)) {
          _employees.add(cloudEmp);
          _db.insertEmployee(cloudEmp);
        } else {
          final idx = _employees.indexWhere((e) => e.id == cloudEmp.id);
          _employees[idx] = cloudEmp;
          _db.updateEmployee(cloudEmp);
        }

        if (cloudEmp.pinCode != cleanPin) {
          return (
            success: false,
            isPendingApproval: false,
            message: 'Hatalı PIN kodu girdiniz. Lütfen 4 haneli PIN kodunuzu kontrol ediniz.',
          );
        }
        if (!cloudEmp.isApproved) {
          return (
            success: false,
            isPendingApproval: true,
            message: 'Sayın ${cloudEmp.fullName}, başvurunuz Firebase bulut veritabanında kayıtlıdır ancak henüz İK tarafından onaylanmamıştır.',
          );
        }

        _currentUser = cloudEmp;
        _activeCompanyId = _currentUser.companyId;
        _isLoggedIn = true;
        _startTimer();

        IosNotificationService.showIosNotification(
          title: '🔥 Firebase • Giriş Başarılı',
          body: 'Sayın ${cloudEmp.fullName}, Firebase bulut veritabanından başarıyla giriş yaptınız.',
          icon: Icons.verified_user_rounded,
          iconColor: const Color(0xFF10B981),
        );

        notifyListeners();
        return (
          success: true,
          isPendingApproval: false,
          message: 'Firebase bulut veritabanından giriş başarılı.',
        );
      }
    } catch (e) {
      debugPrint('Cloud login hatası: $e');
    }

    return (
      success: false,
      isPendingApproval: false,
      message: 'Veritabanında kayıtlı kullanıcı bulunamadı! Lütfen önce "Kayıt Ol" sekmesinden kaydolun.',
    );
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

    // Veritabanı Servisinden Verileri Yükle
    if (_db.getAllEmployees().isNotEmpty) {
      _employees = List.from(_db.getAllEmployees());
      _currentUser = _employees.firstWhere((e) => e.id == 1, orElse: () => _employees.first);
    } else {
      _currentUser = personel; // Varsayılan personel
      _employees = [
        personel, ik, patron, admin, diger1, diger2, yemekhane,
        novaPersonel, novaIk, novaPatron, novaAdmin,
        ozdemirPersonel, ozdemirIk, ozdemirPatron, ozdemirAdmin,
      ];
      for (final e in _employees) {
        _db.insertEmployee(e);
      }
    }

    if (_db.getAllRecords().isNotEmpty) {
      _records = List.from(_db.getAllRecords());
    } else {
      _records = [];
    }

    if (_db.getAllLeaves().isNotEmpty) {
      _leaves = List.from(_db.getAllLeaves());
    } else {
      _leaves = [];
    }

    _payrolls = [];

    if (_db.getAllShifts().isNotEmpty) {
      _shifts = List.from(_db.getAllShifts());
    } else {
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
      for (final s in _shifts) {
        _db.insertShift(s);
      }
    }

    if (_db.getCustomChannels().isNotEmpty) {
      _customGroupChannels.clear();
      _customGroupChannels.addAll(_db.getCustomChannels());
    }

    if (_db.getAllMessages().isNotEmpty) {
      _chatMessages.clear();
      _chatMessages.addAll(_db.getAllMessages());
    }

    if (_db.getAllNotifications().isNotEmpty) {
      _notifications.clear();
      _notifications.addAll(_db.getAllNotifications());
    }

    if (_db.getTodayMenu() != null) {
      _todayMenu = _db.getTodayMenu()!;
    }

    _isCheckedIn = false;
    _lastCheckInTime = null;
    _workedToday = Duration.zero;
  }

  // Giriş Yapma: YALNIZCA GİRİŞ BİLGİLERİNE GÖRE ROL BELİRLENİR
  // Giriş Yapma: VERİTABANI KONTROLÜ VE İK ONAYI İLE BİRLİKTE
  ({bool success, bool isPendingApproval, String message}) login(String email, String pin) {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPin = pin.trim();

    // 1. Veritabanından kullanıcıyı çek (Database lookup)
    final user = _db.getEmployeeByEmail(cleanEmail) ??
        _employees.cast<Employee?>().firstWhere(
          (e) => e?.email.trim().toLowerCase() == cleanEmail,
          orElse: () => null,
        );

    if (user != null) {
      if (user.pinCode != cleanPin) {
        return (
          success: false,
          isPendingApproval: false,
          message: 'Hatalı PIN kodu girdiniz. Lütfen 4 haneli PIN kodunuzu kontrol ediniz.',
        );
      }
      if (!user.isApproved) {
        return (
          success: false,
          isPendingApproval: true,
          message: 'Sayın ${user.fullName}, başvurunuz veritabanımızda kayıtlıdır ancak henüz İnsan Kaynakları (İK) tarafından onaylanmamıştır. Lütfen İK yöneticinizin onayını bekleyiniz.',
        );
      }
      _currentUser = user;
      _activeCompanyId = _currentUser.companyId;
      _isLoggedIn = true;
      _startTimer();

      // iPhone Bildirimi Tetikle (Ses + Web Push + iOS Dynamic Island Banner)
      IosNotificationService.showIosNotification(
        title: 'PDKS • Hoş Geldiniz 📱',
        body: 'Sayın ${user.fullName}, veritabanından başarıyla giriş yaptınız.',
        icon: Icons.verified_user_rounded,
        iconColor: const Color(0xFF10B981),
      );

      notifyListeners();
      return (
        success: true,
        isPendingApproval: false,
        message: 'Giriş başarılı.',
      );
    }

    // Demo Kısayolları (personel, ik, patron, admin)
    Employee? demoMatched;
    final pool = _employees.where((e) => e.companyId == _activeCompanyId && e.isApproved).toList();
    final fallbackPool = pool.isNotEmpty ? pool : _employees.where((e) => e.isApproved).toList();

    if (cleanEmail == 'personel@sirket.com' || cleanEmail == 'personel') {
      demoMatched = fallbackPool.firstWhere((e) => e.role == UserRole.employee, orElse: () => _employees.firstWhere((e) => e.role == UserRole.employee));
    } else if (cleanEmail == 'ik@sirket.com' || cleanEmail == 'ik') {
      demoMatched = fallbackPool.firstWhere((e) => e.role == UserRole.hr, orElse: () => _employees.firstWhere((e) => e.role == UserRole.hr));
    } else if (cleanEmail == 'patron@sirket.com' || cleanEmail == 'patron') {
      demoMatched = fallbackPool.firstWhere((e) => e.role == UserRole.boss, orElse: () => _employees.firstWhere((e) => e.role == UserRole.boss));
    } else if (cleanEmail == 'admin@sirket.com' || cleanEmail == 'admin') {
      demoMatched = fallbackPool.firstWhere((e) => e.role == UserRole.admin, orElse: () => _employees.firstWhere((e) => e.role == UserRole.admin));
    } else if (cleanEmail == 'yemekhane@sirket.com' || cleanEmail == 'yemekhane') {
      demoMatched = fallbackPool.firstWhere((e) => e.role == UserRole.cafeteria, orElse: () => _employees.firstWhere((e) => e.role == UserRole.cafeteria));
    }

    if (demoMatched != null && demoMatched.isApproved) {
      _currentUser = demoMatched;
      _activeCompanyId = _currentUser.companyId;
      _isLoggedIn = true;
      _startTimer();

      IosNotificationService.showIosNotification(
        title: 'PDKS • Hoş Geldiniz 📱',
        body: 'Sayın ${demoMatched.fullName}, giriş yapıldı.',
        icon: Icons.verified_user_rounded,
        iconColor: const Color(0xFF10B981),
      );

      notifyListeners();
      return (
        success: true,
        isPendingApproval: false,
        message: 'Giriş başarılı.',
      );
    }

    return (
      success: false,
      isPendingApproval: false,
      message: 'Veritabanında kayıtlı kullanıcı bulunamadı! Lütfen önce "Kayıt Ol" sekmesinden kaydolun.',
    );
  }

  // Yeni Personel Kaydı - Şirket Kodu ile Şirket Belirleme (Departman & Unvan İK onayında atanır)
  ({bool success, String message}) register({
    required String companyCode,
    required String fullName,
    required String email,
    required String phone,
    String? department,
    String? title,
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

    // 1. VERİTABANI MÜKERRER KAYIT KONTROLÜ (E-posta ve Telefon)
    final cleanEmail = email.trim().toLowerCase();
    final isAlreadyRegistered = _db.isEmailOrPhoneRegistered(cleanEmail, phone) ||
        _employees.any((e) => e.email.trim().toLowerCase() == cleanEmail);

    if (isAlreadyRegistered) {
      return (
        success: false,
        message: 'Kayıt Kabul Edilmedi: "$cleanEmail" e-posta adresi veya telefon numarası veritabanında zaten kayıtlıdır! Lütfen doğrudan Giriş Yapınız.',
      );
    }

    final targetCompany = _companies[idx];
    final newId = (_employees.isNotEmpty ? _employees.map((e) => e.id).reduce((a, b) => a > b ? a : b) : 0) + 1;
    final newEmployee = Employee(
      id: newId,
      companyId: targetCompany.id,
      fullName: fullName.trim(),
      email: cleanEmail,
      phone: phone.trim().isEmpty ? '+90 555 000 00 00' : phone.trim(),
      department: (department != null && department.trim().isNotEmpty) ? department.trim() : 'Onay Bekliyor',
      title: (title != null && title.trim().isNotEmpty) ? title.trim() : 'Personel Adayı',
      pinCode: pin.trim(),
      role: UserRole.employee, // Yeni kaydolanlar personel olarak başlar
      annualLeaveAllowance: 14,
      usedLeaveDays: 0,
      isActive: true,
      isApproved: false, // İLK ÖNCE İK ONAYI GEREKLİ!
      registeredAt: DateTime.now(),
    );

    // 2. VERİTABANINA KALICI OLARAK KAYDET
    _employees.add(newEmployee);
    _db.insertEmployee(newEmployee);

    // Firebase Bulutuna Aktar
    if (_firebase.isEnabled) {
      _firebase.saveEmployeeToCloud(newEmployee);
    }

    // İK yetkililerine sistem içi bildirim ekle & veritabanına kaydet
    final hrNotif = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Yeni Personel Kayıt Talebi ⏳',
      message: '${newEmployee.fullName} ("${targetCompany.name}") şirketine kayıt oldu. İK onayı, departman ve unvan ataması bekleniyor.',
      timestamp: DateTime.now(),
      type: NotificationType.system,
      icon: Icons.person_add_alt_1_rounded,
      color: const Color(0xFFF59E0B),
      isRead: false,
    );

    _notifications.insert(0, hrNotif);
    _db.insertNotification(hrNotif);

    if (_firebase.isEnabled) {
      _firebase.pushNotificationToCloud(hrNotif);
    }

    // 3. IPHONE PUSH BİLDİRİMİ GÖNDER
    IosNotificationService.showIosNotification(
      title: '📲 PDKS • Yeni Kayıt Alındı',
      body: '${newEmployee.fullName} veritabanına kaydedildi. İK onayı sonrası PIN ile giriş yapabilirsiniz.',
      icon: Icons.app_registration_rounded,
      iconColor: const Color(0xFF10B981),
    );

    // Oturum açılmaz, İK onayı beklenir
    _isLoggedIn = false;
    _isCheckedIn = false;
    notifyListeners();

    return (
      success: true,
      message: 'Kaydınız veritabanına başarıyla kaydedildi! Kurumsal güvenlik gereği ilk önce İnsan Kaynakları (İK) departmanı kaydınızı onaylayacak ve görevinizi atayacaktır. Onaylandıktan sonra PIN kodunuz ile giriş yapabilirsiniz.',
    );
  }

  /// İK Tarafından Personel Kaydı Onaylama ve Departman/Unvan Atama + Telefona Bildirim Gönderme
  ({bool success, String message, AppNotification? dispatchedNotification}) approveEmployeeRegistration({
    required int employeeId,
    required String department,
    required String title,
    double? baseSalary,
    UserRole? role,
  }) {
    if (_currentUser.role != UserRole.hr &&
        _currentUser.role != UserRole.boss &&
        _currentUser.role != UserRole.admin) {
      return (success: false, message: 'Bu onay işlemini yalnızca İK veya Yönetim yetkilileri yapabilir.', dispatchedNotification: null);
    }

    final index = _employees.indexWhere((e) => e.id == employeeId);
    if (index == -1) {
      return (success: false, message: 'Personel kaydı bulunamadı.', dispatchedNotification: null);
    }

    final existing = _employees[index];
    final updated = existing.copyWith(
      isApproved: true,
      department: department.trim().isEmpty ? 'Genel' : department.trim(),
      title: title.trim().isEmpty ? 'Personel' : title.trim(),
      baseGrossSalary: baseSalary ?? existing.baseGrossSalary,
      role: role ?? existing.role,
    );

    _employees[index] = updated;
    _db.updateEmployee(updated);

    // Firebase Bulutuna Aktar
    if (_firebase.isEnabled) {
      _firebase.saveEmployeeToCloud(updated);
    }

    final compName = _companies.firstWhere((c) => c.id == updated.companyId, orElse: () => activeCompany).name;

    // Personele Kayıt Olduğu E-Posta ve Telefona Gönderilen Özel Bildirim (E-Posta + Push Notification + SMS)
    final phoneNotification = AppNotification(
      id: 'phone_notif_${DateTime.now().millisecondsSinceEpoch}',
      title: '🎉 Tebrikler, Kaydınız Onaylandı!',
      message: 'Sayın ${updated.fullName}, "$compName" şirketindeki personel kaydınız İnsan Kaynakları tarafından onaylanmıştır. Departmanınız "${updated.department}" (${updated.title}) olarak atanmıştır. Belirlediğiniz PIN kodu ile PDKS uygulamasına hemen giriş yapabilirsiniz.',
      timestamp: DateTime.now(),
      type: NotificationType.system,
      icon: Icons.verified_user_rounded,
      color: const Color(0xFF10B981),
      targetPhone: updated.phone,
      targetEmail: updated.email,
      isPushSent: true,
      isSmsSent: true,
      isEmailSent: true,
      emailSubject: '🎉 Tebrikler, $compName Personel Kaydınız Onaylandı!',
      emailBody: 'Sayın ${updated.fullName},\n\n'
          '$compName bünyesinde gerçekleştirdiğiniz personel kaydınız İnsan Kaynakları (İK) tarafından incelenmiş ve başarıyla onaylanmıştır.\n\n'
          '📋 GÖREV VE HESAP BİLGİLERİNİZ:\n'
          '• Departman: ${updated.department}\n'
          '• Unvan / Görev: ${updated.title}\n'
          '• Kayıtlı E-Posta: ${updated.email}\n'
          '• Kayıtlı Telefon: ${updated.phone}\n'
          '• Hesap Durumu: Aktif Personel\n\n'
          'Kayıt sırasında belirlediğiniz PIN kodu ve kurumsal e-posta adresiniz ile PDKS mobil uygulamasına ve web paneline hemen giriş yapabilirsiniz.\n\n'
          'Aramıza hoş geldiniz, iyi çalışmalar dileriz.\n\n'
          '$compName İnsan Kaynakları Departmanı',
      isRead: false,
    );

    _notifications.insert(0, phoneNotification);
    _db.insertNotification(phoneNotification);
    _lastDispatchedPhoneNotification = phoneNotification;

    // iPhone Bildirimi Tetikle
    IosNotificationService.showIosNotification(
      title: '🎉 Kayıt Onaylandı: ${updated.fullName}',
      body: '$compName bünyesinde ${updated.department} • ${updated.title} olarak kaydı onaylandı.',
      icon: Icons.verified_user_rounded,
      iconColor: const Color(0xFF10B981),
    );

    notifyListeners();
    return (
      success: true,
      message: '${updated.fullName} personeli onaylandı. Kayıtlı e-posta (${updated.email}) ve telefonuna onay bildirimi iletildi.',
      dispatchedNotification: phoneNotification,
    );
  }

  /// İK Tarafından Personel Kaydını Reddetme
  ({bool success, String message}) rejectEmployeeRegistration(int employeeId) {
    if (_currentUser.role != UserRole.hr &&
        _currentUser.role != UserRole.boss &&
        _currentUser.role != UserRole.admin) {
      return (success: false, message: 'Yetkisiz işlem.');
    }

    final index = _employees.indexWhere((e) => e.id == employeeId);
    if (index == -1) {
      return (success: false, message: 'Personel kaydı bulunamadı.');
    }

    final name = _employees[index].fullName;
    _employees.removeAt(index);
    _db.deleteEmployee(employeeId);
    notifyListeners();
    return (success: true, message: '$name personelinin kayıt başvurusu reddedildi ve veritabanından kaldırıldı.');
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
  void updateProfile({
    required String fullName,
    required String phone,
    String? department,
    String? title,
    DateTime? hireDate,
    int? heightCm,
    int? weightKg,
    String? shirtSize,
    String? pantSize,
    int? shoeSize,
    String? outerwearSize,
  }) {
    final index = _employees.indexWhere((e) => e.id == _currentUser.id);

    // Güvenlik Kuralı: İK veya Admin haricinde ad-soyad, departman ve unvan değiştirilemez!
    final isHrOrAdmin = _currentUser.role == UserRole.hr || _currentUser.role == UserRole.admin;
    final finalName = (isHrOrAdmin && fullName.trim().isNotEmpty)
        ? fullName.trim()
        : _currentUser.fullName;
    final finalDept = (isHrOrAdmin && department != null && department.trim().isNotEmpty)
        ? department.trim()
        : _currentUser.department;
    final finalTitle = (isHrOrAdmin && title != null && title.trim().isNotEmpty)
        ? title.trim()
        : _currentUser.title;

    final updated = _currentUser.copyWith(
      fullName: finalName,
      phone: phone,
      department: finalDept,
      title: finalTitle,
      hireDate: hireDate ?? _currentUser.hireDate,
      heightCm: heightCm ?? _currentUser.heightCm,
      weightKg: weightKg ?? _currentUser.weightKg,
      shirtSize: shirtSize ?? _currentUser.shirtSize,
      pantSize: pantSize ?? _currentUser.pantSize,
      shoeSize: shoeSize ?? _currentUser.shoeSize,
      outerwearSize: outerwearSize ?? _currentUser.outerwearSize,
    );

    _currentUser = updated;
    if (index != -1) {
      _employees[index] = updated;
      _db.updateEmployee(updated);
    }
    notifyListeners();
  }

  /// İK ve Admin Yetkilisi Tarafından Personel Bilgilerini Güncelleme Metodu
  ({bool success, String message, AppNotification? dispatchedNotification}) updateEmployeeByHr({
    required int employeeId,
    required String fullName,
    required String phone,
    required String department,
    required String title,
    double? baseSalary,
    UserRole? role,
    DateTime? hireDate,
    int? heightCm,
    int? weightKg,
    String? shirtSize,
    String? pantSize,
    int? shoeSize,
    String? outerwearSize,
    int? annualLeaveAllowance,
  }) {
    if (_currentUser.role != UserRole.hr &&
        _currentUser.role != UserRole.boss &&
        _currentUser.role != UserRole.admin) {
      return (
        success: false,
        message: 'Personel bilgilerini yalnızca İK veya Yönetim yetkilisi güncelleyebilir.',
        dispatchedNotification: null,
      );
    }

    final index = _employees.indexWhere((e) => e.id == employeeId);
    if (index == -1) {
      return (success: false, message: 'Personel bulunamadı.', dispatchedNotification: null);
    }

    final existing = _employees[index];
    final updated = existing.copyWith(
      fullName: fullName.trim().isEmpty ? existing.fullName : fullName.trim(),
      phone: phone.trim().isEmpty ? existing.phone : phone.trim(),
      department: department.trim().isEmpty ? existing.department : department.trim(),
      title: title.trim().isEmpty ? existing.title : title.trim(),
      baseGrossSalary: baseSalary ?? existing.baseGrossSalary,
      role: role ?? existing.role,
      hireDate: hireDate ?? existing.hireDate,
      heightCm: heightCm ?? existing.heightCm,
      weightKg: weightKg ?? existing.weightKg,
      shirtSize: shirtSize ?? existing.shirtSize,
      pantSize: pantSize ?? existing.pantSize,
      shoeSize: shoeSize ?? existing.shoeSize,
      outerwearSize: outerwearSize ?? existing.outerwearSize,
      annualLeaveAllowance: annualLeaveAllowance ?? existing.annualLeaveAllowance,
    );

    _employees[index] = updated;
    _db.updateEmployee(updated);

    // Firebase Bulutuna Aktar
    if (_firebase.isEnabled) {
      _firebase.saveEmployeeToCloud(updated);
    }

    // Eğer o an aktif giriş yapan personel güncellendiyse oturumu senkronize et
    if (_currentUser.id == employeeId) {
      _currentUser = updated;
    }

    final compName = _companies.firstWhere((c) => c.id == updated.companyId, orElse: () => activeCompany).name;

    // Değiştirilen alanların özeti
    final List<String> changeList = [];
    if (existing.fullName != updated.fullName) changeList.add('• Ad Soyad: ${updated.fullName}');
    if (existing.department != updated.department) changeList.add('• Departman: ${updated.department}');
    if (existing.title != updated.title) changeList.add('• Unvan: ${updated.title}');
    if (existing.phone != updated.phone) changeList.add('• Telefon: ${updated.phone}');
    if (existing.baseGrossSalary != updated.baseGrossSalary) changeList.add('• Maaş: ${updated.baseGrossSalary.toStringAsFixed(0)} ₺');
    if (existing.role != updated.role) changeList.add('• Yetki Rolü: ${updated.role.label}');
    if (existing.hireDate != updated.hireDate && updated.hireDate != null) {
      changeList.add('• İşe Giriş: ${updated.hireDate!.day.toString().padLeft(2, '0')}.${updated.hireDate!.month.toString().padLeft(2, '0')}.${updated.hireDate!.year}');
    }
    if (existing.heightCm != updated.heightCm || existing.weightKg != updated.weightKg) {
      changeList.add('• Boy/Kilo: ${updated.heightCm ?? '-'} cm / ${updated.weightKg ?? '-'} kg');
    }
    if (existing.shirtSize != updated.shirtSize || existing.pantSize != updated.pantSize || existing.shoeSize != updated.shoeSize || existing.outerwearSize != updated.outerwearSize) {
      changeList.add('• Kıyafet/Beden: ${updated.shirtSize ?? '-'} / ${updated.pantSize ?? '-'} / ${updated.shoeSize ?? '-'} No');
    }

    final summaryText = changeList.isNotEmpty
        ? 'Güncellenen Bilgileriniz:\n${changeList.join('\n')}'
        : 'Profil ve kurumsal bilgileriniz İK tarafından güncellendi.';

    // İK bilgi güncelleme bildirimi (Telefona Push Notification + SMS + E-posta)
    final hrNotification = AppNotification(
      id: 'hr_update_${DateTime.now().millisecondsSinceEpoch}',
      title: '📝 Personel Bilgileriniz Güncellendi',
      message: 'Sayın ${updated.fullName}, İnsan Kaynakları yetkilisi sistemdeki kayıtlı bilgilerinizi güncelledi.\n\n$summaryText',
      timestamp: DateTime.now(),
      type: NotificationType.system,
      icon: Icons.assignment_ind_rounded,
      color: const Color(0xFF2563EB),
      targetPhone: updated.phone,
      targetEmail: updated.email,
      isPushSent: true,
      isSmsSent: true,
      isEmailSent: true,
      emailSubject: '📝 $compName - Personel Bilgileriniz Güncellendi',
      emailBody: 'Sayın ${updated.fullName},\n\n'
          '$compName İnsan Kaynakları (İK) departmanı tarafından sistemdeki personel bilgileriniz güncellenmiştir.\n\n'
          '$summaryText\n\n'
          'Değişiklikleri PDKS mobil uygulamasında "Profil" sekmesine giderek detaylıca görüntüleyebilirsiniz.\n\n'
          'Herhangi bir uyumsuzluk durumunda İK departmanınız ile iletişime geçebilirsiniz.\n\n'
          'İyi çalışmalar dileriz,\n'
          '$compName İnsan Kaynakları Departmanı',
      isRead: false,
    );

    _notifications.insert(0, hrNotification);
    _db.insertNotification(hrNotification);
    _lastDispatchedPhoneNotification = hrNotification;

    // iPhone Bildirimi Tetikle
    IosNotificationService.showIosNotification(
      title: '📝 Bilgileriniz Güncellendi',
      body: 'Sayın ${updated.fullName}, özlük ve unvan bilgileriniz İK tarafından güncellendi.',
      icon: Icons.assignment_ind_rounded,
      iconColor: const Color(0xFF2563EB),
    );

    notifyListeners();
    return (
      success: true,
      message: '${updated.fullName} personelinin bilgileri güncellendi. Personele bildirim iletildi.',
      dispatchedNotification: hrNotification,
    );
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
    _db.insertAttendanceRecord(newRecord);
    if (_firebase.isEnabled) {
      _firebase.pushAttendanceToCloud(newRecord);
    }

    if (type == AttendanceType.checkIn) {
      _isCheckedIn = true;
      _lastCheckInTime = now;
    } else {
      _isCheckedIn = false;
    }

    // iPhone Bildirimi Tetikle
    IosNotificationService.showIosNotification(
      title: type == AttendanceType.checkIn ? '⏰ Mesai Girişi Başarılı' : '🚪 Mesai Çıkışı Kaydedildi',
      body: '${_currentUser.fullName} • ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} • ${newRecord.methodLabel}',
      icon: type == AttendanceType.checkIn ? Icons.login_rounded : Icons.logout_rounded,
      iconColor: type == AttendanceType.checkIn ? const Color(0xFF10B981) : const Color(0xFFEF4444),
    );

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
    _db.insertLeaveRequest(newLeave);
    if (_firebase.isEnabled) {
      _firebase.pushLeaveToCloud(newLeave);
    }

    // iPhone Bildirimi Tetikle
    IosNotificationService.showIosNotification(
      title: '🏖️ İzin Talebi İletildi',
      body: '${newLeave.typeLabel} (${newLeave.totalDays} gün) onay için İK departmanına gönderildi.',
      icon: Icons.beach_access_rounded,
      iconColor: const Color(0xFF0284C7),
    );

    notifyListeners();
    return true;
  }

  // İK: İzin Onayla / Reddet
  void updateLeaveStatus(int leaveId, LeaveStatus newStatus, {String? comment}) {
    final index = _leaves.indexWhere((l) => l.id == leaveId);
    if (index != -1) {
      final old = _leaves[index];
      final updatedLeave = LeaveRequest(
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
      _leaves[index] = updatedLeave;
      _db.updateLeaveRequest(updatedLeave);
      if (_firebase.isEnabled) {
        _firebase.pushLeaveToCloud(updatedLeave);
      }

      if (newStatus == LeaveStatus.approved && old.type == LeaveType.annual) {
        final empIndex = _employees.indexWhere((e) => e.id == old.employeeId);
        if (empIndex != -1) {
          final emp = _employees[empIndex];
          final updatedEmp = emp.copyWith(
            usedLeaveDays: emp.usedLeaveDays + old.totalDays,
          );
          _employees[empIndex] = updatedEmp;
          _db.updateEmployee(updatedEmp);
        }
      }

      // İzin Bildirimi
      final notif = AppNotification(
        id: 'leave_notif_${DateTime.now().millisecondsSinceEpoch}',
        title: newStatus == LeaveStatus.approved ? '✅ İzin Talebiniz Onaylandı' : '❌ İzin Talebiniz Reddedildi',
        message: 'Sayın ${old.employeeName}, ${old.typeLabel} (${old.totalDays} gün) talebiniz ${newStatus == LeaveStatus.approved ? "onaylanmıştır." : "reddedilmiştir."}',
        timestamp: DateTime.now(),
        type: NotificationType.leave,
        icon: newStatus == LeaveStatus.approved ? Icons.check_circle_rounded : Icons.cancel_rounded,
        color: newStatus == LeaveStatus.approved ? const Color(0xFF10B981) : const Color(0xFFEF4444),
      );
      _notifications.insert(0, notif);
      _db.insertNotification(notif);

      // iPhone Bildirimi Tetikle
      IosNotificationService.showIosNotification(
        title: notif.title,
        body: notif.message,
        icon: notif.icon,
        iconColor: notif.color,
      );

      notifyListeners();
    }
  }

  @override
  void dispose() {
    _workTimer?.cancel();
    _cloudSyncTimer?.cancel();
    super.dispose();
  }
}
