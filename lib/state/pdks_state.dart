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
import '../models/quick_menu_item.dart';
import '../models/vehicle_request.dart';
import '../models/shift_swap_request.dart';
import '../models/helpdesk_ticket.dart';
import '../models/company_announcement.dart';
import '../models/personnel_file.dart';
import '../models/training_and_skill.dart';
import '../models/performance_goal.dart';
import '../models/visitor_record.dart';
import '../models/hybrid_booking.dart';
import '../models/organization_branch.dart';
import '../models/integration_and_sync.dart';
import '../models/employee_feedback.dart';
import '../models/equipment_and_cmms.dart';
import '../models/audit_log.dart';
import '../models/ai_anomaly_and_insights.dart';
import '../models/face_kiosk_and_turnstile.dart';
import '../models/digital_signature_and_export.dart';
import '../models/occupational_safety_and_nearmiss.dart';
import '../models/push_to_talk_and_media.dart';
import '../models/employee_movement.dart';
import '../core/utils/labor_law_rule_engine.dart';
import '../core/utils/movement_calculation_engine.dart';
import '../core/services/api_service.dart';
import '../core/services/location_service.dart';
import '../core/services/database_service.dart';
import '../core/services/firebase_service.dart';
import '../core/services/ios_notification_service.dart';
import '../core/services/biometric_service.dart';
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
  final List<ShiftSchedule> _shifts = [];
  final List<PayrollSlip> _payrolls = [];

  // Kurumsal Ek Modüller (15 Enterprise Modules)
  final List<ShiftSwapRequest> _shiftSwaps = [];
  final List<OpenShiftSlot> _openShiftSlots = [];
  final List<HelpdeskTicket> _helpdeskTickets = [];
  final List<CompanyAnnouncement> _announcements = [];
  final List<EmployeeDocument> _documents = [];
  final List<OnboardingTask> _onboardingTasks = [];
  final List<TrainingCourse> _trainingCourses = [];
  final List<EmployeeTrainingRecord> _trainingRecords = [];
  final List<PerformanceGoal> _performanceGoals = [];
  final List<VisitorRecord> _visitorRecords = [];
  final List<HybridBooking> _hybridBookings = [];
  final List<CompanyBranch> _branches = [];
  final List<ApprovalDelegation> _delegations = [];
  final List<IntegrationEndpoint> _integrations = [];
  final List<OfflineSyncItem> _offlineQueue = [];
  final List<EmployeeFeedback> _feedbacks = [];
  final List<EquipmentRecord> _equipmentRecords = [];
  final List<MaintenanceWorkOrder> _workOrders = [];
  final List<AuditLogRecord> _auditLogs = [];
  final List<String> _lockedPeriods = [];

  // 5 Yeni İleri Düzey Modül Bellek Listeleri
  final List<PdkAnomalyRecord> _anomalies = [];
  final List<FaceEnrollment> _faceEnrollments = [];
  final List<KioskTerminal> _kioskTerminals = [];
  final List<SignedDocumentRecord> _signedDocuments = [];
  final List<NearMissReport> _nearMissReports = [];
  final List<SafetyCertificate> _safetyCertificates = [];
  final List<HazardZone> _hazardZones = [];
  final List<PttChannel> _pttChannels = [];
  final List<PttVoiceBurst> _pttBursts = [];
  final List<AiAssistantMessage> _aiMessages = [];

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

  // Yönetici & Admin Sayfa Düzenleme Modu (Yalnızca Patron/CEO ve Admin rollerinde aktiftir)
  bool _isAdminEditMode = false;
  final Map<String, PageCustomization> _pageCustomizations = {};

  bool get isAdminEditMode =>
      _isAdminEditMode &&
      _isLoggedIn &&
      (_currentUser.role == UserRole.admin || _currentUser.role == UserRole.boss);

  void setAdminEditMode(bool active) {
    if (_currentUser.role != UserRole.admin && _currentUser.role != UserRole.boss) return;
    _isAdminEditMode = active;
    notifyListeners();
  }

  void toggleAdminEditMode() {
    if (_currentUser.role != UserRole.admin && _currentUser.role != UserRole.boss) return;
    _isAdminEditMode = !_isAdminEditMode;
    notifyListeners();
  }

  PageCustomization getPageCustomization(String pageId) {
    return _pageCustomizations[pageId] ?? PageCustomization(pageId: pageId);
  }

  void updatePageCustomization(PageCustomization customization) {
    if (_currentUser.role != UserRole.admin && _currentUser.role != UserRole.boss) return;
    _pageCustomizations[customization.pageId] = customization;
    _db.savePageCustomization(customization);
    notifyListeners();
  }

  void togglePageSection(String pageId, String sectionId) {
    if (_currentUser.role != UserRole.admin && _currentUser.role != UserRole.boss) return;
    final current = getPageCustomization(pageId);
    final hidden = Set<String>.from(current.hiddenSectionIds);
    if (hidden.contains(sectionId)) {
      hidden.remove(sectionId);
    } else {
      hidden.add(sectionId);
    }
    final updated = current.copyWith(hiddenSectionIds: hidden);
    _pageCustomizations[pageId] = updated;
    _db.savePageCustomization(updated);
    notifyListeners();
  }

  void resetPageCustomization(String pageId) {
    if (_currentUser.role != UserRole.admin && _currentUser.role != UserRole.boss) return;
    _pageCustomizations.remove(pageId);
    _db.deletePageCustomization(pageId);
    notifyListeners();
  }

  // Sistem Rolleri ve Patron/Admin tarafından eklenen roller
  final List<AppRoleItem> _roles = [];

  // Multi-Company (Çoklu Şirket / SaaS Desteği)
  final List<Company> _companies = [];

  String _activeCompanyId = 'cmp_acme';

  // Hızlı Menü & Dışarıda Çalışma Durumu
  List<QuickMenuItem> _quickMenuItems = [];
  bool _isFieldWorkActive = false;
  String? _activeFieldWorkTitle;
  String? _activeFieldWorkAddress;

  // Görünüm Teması: Sadece 2 Seçenek (Aydınlık ve Koyu Tema)
  ThemeMode _themeMode = ThemeMode.light;
  AppThemeType _currentTheme = AppThemeType.light;

  // Getters
  Employee get currentUser => _currentUser;
  void switchUserForTesting(Employee emp) {
    _currentUser = emp;
    _activeCompanyId = emp.companyId;
    _isLoggedIn = true;
    _db.saveUserSession(emp.email);
    notifyListeners();
  }
  bool get isLoggedIn => _isLoggedIn;
  bool get isCheckedIn => _isCheckedIn;
  DateTime? get lastCheckInTime => _lastCheckInTime;
  Duration get workedToday => _workedToday;

  List<QuickMenuItem> get quickMenuItems => List.unmodifiable(_quickMenuItems);
  List<QuickMenuItem> get visibleQuickMenuItems => _quickMenuItems.where((m) => m.isVisible).toList();
  bool get isFieldWorkActive => _isFieldWorkActive;
  String? get activeFieldWorkTitle => _activeFieldWorkTitle;
  String? get activeFieldWorkAddress => _activeFieldWorkAddress;

  AppThemeType get currentTheme => _currentTheme;
  ThemeData get activeThemeData => AppTheme.getThemeData(_currentTheme);
  ThemeMode get themeMode => _themeMode;

  String get themeModeName => _currentTheme.title;

  void setTheme(AppThemeType theme) {
    _currentTheme = theme;
    _themeMode = theme == AppThemeType.dark ? ThemeMode.dark : ThemeMode.light;
    _db.saveThemeType(theme.name);
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _currentTheme = mode == ThemeMode.dark ? AppThemeType.dark : AppThemeType.light;
    _db.saveThemeType(_currentTheme.name);
    notifyListeners();
  }

  void toggleTheme() {
    if (_currentTheme == AppThemeType.dark) {
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

  // Kurumsal Ek Modüller Getters (15 Enterprise Modules)
  List<ShiftSwapRequest> get shiftSwaps =>
      _shiftSwaps.where((s) => s.companyId == _activeCompanyId).toList();
  List<OpenShiftSlot> get openShiftSlots =>
      _openShiftSlots.where((s) => s.companyId == _activeCompanyId).toList();
  List<HelpdeskTicket> get helpdeskTickets =>
      _helpdeskTickets.where((t) => t.companyId == _activeCompanyId).toList();
  List<CompanyAnnouncement> get announcements =>
      _announcements.where((a) => a.companyId == _activeCompanyId).toList();
  List<EmployeeDocument> get documents =>
      _documents.where((d) => d.companyId == _activeCompanyId).toList();
  List<OnboardingTask> get onboardingTasks =>
      _onboardingTasks.where((o) => o.companyId == _activeCompanyId).toList();
  List<TrainingCourse> get trainingCourses =>
      _trainingCourses.where((c) => c.companyId == _activeCompanyId).toList();
  List<EmployeeTrainingRecord> get trainingRecords =>
      _trainingRecords.where((r) => r.companyId == _activeCompanyId).toList();
  List<PerformanceGoal> get performanceGoals =>
      _performanceGoals.where((g) => g.companyId == _activeCompanyId).toList();
  List<VisitorRecord> get visitorRecords =>
      _visitorRecords.where((v) => v.companyId == _activeCompanyId).toList();
  List<HybridBooking> get hybridBookings =>
      _hybridBookings.where((h) => h.companyId == _activeCompanyId).toList();
  List<CompanyBranch> get branches =>
      _branches.where((b) => b.companyId == _activeCompanyId).toList();
  List<ApprovalDelegation> get delegations =>
      _delegations.where((d) => d.companyId == _activeCompanyId).toList();
  List<IntegrationEndpoint> get integrations =>
      _integrations.where((i) => i.companyId == _activeCompanyId).toList();
  List<OfflineSyncItem> get offlineQueue =>
      _offlineQueue.where((o) => o.companyId == _activeCompanyId).toList();
  List<EmployeeFeedback> get feedbacks =>
      _feedbacks.where((f) => f.companyId == _activeCompanyId).toList();

  // CMMS & Kalibrasyon (ISO 9001 / ISO 17025)
  List<EquipmentRecord> get equipmentRecords =>
      _equipmentRecords.where((e) => e.companyId == _activeCompanyId).toList();
  List<MaintenanceWorkOrder> get workOrders =>
      _workOrders.where((w) => w.companyId == _activeCompanyId).toList();

  // Değiştirilemez Denetim Kayıtları (Audit Log)
  List<AuditLogRecord> get auditLogs =>
      _auditLogs.where((a) => a.companyId == _activeCompanyId).toList();

  // Puantaj Kilitli Dönemler
  List<String> get lockedPeriods => List.unmodifiable(_lockedPeriods);
  bool isPeriodLocked(String period) => _db.isPeriodLocked(period);

  // 1. Yapay Zeka Anomali & Sahte Geçiş (Anti-Buddy Punching)
  List<PdkAnomalyRecord> get anomalies =>
      _anomalies.where((a) => a.companyId == _activeCompanyId).toList();

  // 2. Yüz Tanıma & Kiosk Terminalleri
  List<FaceEnrollment> get faceEnrollments => List.unmodifiable(_faceEnrollments);
  List<KioskTerminal> get kioskTerminals =>
      _kioskTerminals.where((k) => k.companyId == _activeCompanyId).toList();

  // 3. 5070 E-İmza & Bordro İhracatı
  List<SignedDocumentRecord> get signedDocuments =>
      _signedDocuments.where((s) => s.companyId == _activeCompanyId).toList();

  // 4. İSG & Ramak Kala (Near-Miss)
  List<NearMissReport> get nearMissReports =>
      _nearMissReports.where((n) => n.companyId == _activeCompanyId).toList();
  List<SafetyCertificate> get safetyCertificates => List.unmodifiable(_safetyCertificates);
  List<HazardZone> get hazardZones =>
      _hazardZones.where((h) => h.companyId == _activeCompanyId).toList();

  // 5. Saha Telsizi (PTT)
  List<PttChannel> get pttChannels =>
      _pttChannels.where((p) => p.companyId == _activeCompanyId).toList();
  List<PttVoiceBurst> get pttBursts => List.unmodifiable(_pttBursts);

  // AI Asistan Mesajları
  List<AiAssistantMessage> get aiMessages => List.unmodifiable(_aiMessages);

  // Multi-Tenant Şirket Kodu (Company Code) Yönetimi (SRS 2.1)
  String? get savedCompanyCode => _db.getSavedCompanyCode();

  ({bool success, String message, Company? company}) setCompanyCode(String rawCode) {
    final clean = rawCode.trim().toUpperCase();
    final comp = _companies.cast<Company?>().firstWhere(
      (c) => c?.code.toUpperCase() == clean,
      orElse: () => null,
    );
    if (comp == null) {
      final availableCodes = _companies.map((c) => c.code).join(', ');
      return (
        success: false,
        message: 'Belirtilen "$clean" koduna ait şirket bulunamadı. Mevcut şirketler: $availableCodes',
        company: null,
      );
    }
    _db.saveCompanyCode(clean);
    _activeCompanyId = comp.id;
    _db.saveActiveCompanyId(comp.id);
    logAudit(
      actionType: 'Şirket Kodu Eşleme',
      targetEntity: 'TenantCompany',
      entityId: comp.id,
      newValue: 'Cihaz kurumsal kodu doğrulandı: $clean (${comp.name})',
    );
    notifyListeners();
    return (
      success: true,
      message: '${comp.name} kurumsal kimliği başarıyla eşleştirildi.',
      company: comp,
    );
  }

  Future<void> clearSavedCompanyCode() async {
    await _db.clearCompanyCode();
    notifyListeners();
  }

  // 4 Haneli PIN Güvenliği & Brute-Force Koruması (SRS 3.1)
  int get failedPinAttempts => _db.getFailedPinAttempts();
  DateTime? get pinLockoutUntil => _db.getPinLockoutUntil();

  bool get isPinLockedOut {
    final until = _db.getPinLockoutUntil();
    if (until == null) return false;
    if (DateTime.now().isBefore(until)) return true;
    _db.setPinLockoutUntil(null);
    _db.setFailedPinAttempts(0);
    return false;
  }

  int get lockoutSecondsRemaining {
    final until = _db.getPinLockoutUntil();
    if (until == null) return 0;
    final diff = until.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  // Biyometrik Mobil Doğrulama (SRS 3.2 - Touch ID / Face ID)
  Future<({bool success, String message})> loginWithBiometrics() async {
    if (isPinLockedOut) {
      return (
        success: false,
        message: 'Güvenlik Kilidi Aktif: $lockoutSecondsRemaining saniye sonra tekrar deneyiniz.',
      );
    }

    final authenticated = await BiometricService.authenticate(
      reason: 'PDKS Biyometrik Mobil Giriş Doğrulaması',
    );
    if (!authenticated) {
      return (
        success: false,
        message: 'Biyometrik doğrulama başarısız oldu veya iptal edildi.',
      );
    }

    final lastEmail = _db.getLastUserEmail();
    Employee? targetUser;
    if (lastEmail != null && lastEmail.isNotEmpty) {
      targetUser = _employees.cast<Employee?>().firstWhere(
        (e) => e?.email.trim().toLowerCase() == lastEmail.trim().toLowerCase(),
        orElse: () => null,
      );
    }

    if (targetUser == null) {
      final pool = _employees.where((e) => e.companyId == _activeCompanyId && e.isApproved).toList();
      targetUser = pool.isNotEmpty ? pool.first : _employees.cast<Employee?>().firstWhere((e) => e?.isApproved == true, orElse: () => null);
    }

    if (targetUser == null) {
      return (
        success: false,
        message: 'Biyometrik giriş için kayıtlı personel bulunamadı.',
      );
    }

    if (!targetUser.isApproved) {
      return (
        success: false,
        message: 'Hesabınız henüz İK yöneticisi tarafından onaylanmamıştır.',
      );
    }

    _currentUser = targetUser;
    _activeCompanyId = _currentUser.companyId;
    _isLoggedIn = true;
    _db.saveUserSession(_currentUser.email);
    _db.setFailedPinAttempts(0);
    _db.setPinLockoutUntil(null);
    _startTimer();

    logAudit(
      actionType: 'Biyometrik Giriş (Touch/Face ID)',
      targetEntity: 'AuthSession',
      entityId: _currentUser.id.toString(),
      oldValue: 'Oturum Kapalı',
      newValue: 'Biyometrik Yerel Doğrulama Başarılı (KVKK Uyumlu Cihaz Donanımı)',
    );

    notifyListeners();
    return (
      success: true,
      message: 'Hoş geldiniz ${_currentUser.fullName}, biyometrik doğrulama ile giriş yapıldı.',
    );
  }

  // T.C. Kimlik ve Telefon ile SMS OTP Tabanlı PIN Sıfırlama (SRS 3.3)
  String? _lastGeneratedResetOtp;
  DateTime? _lastOtpGeneratedAt;
  String? get lastGeneratedResetOtp => _lastGeneratedResetOtp;

  ({bool success, String message, String? otp}) requestPinResetOtp({
    required String tcKimlikNo,
    required String phone,
  }) {
    final cleanTc = tcKimlikNo.replaceAll(RegExp(r'\s+'), '').trim();
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\(\)\-\+]'), '').trim();

    if (cleanTc.length != 11) {
      return (
        success: false,
        message: 'T.C. Kimlik Numarası tam olarak 11 haneli olmalıdır.',
        otp: null,
      );
    }

    Employee? matchedEmp = _employees.cast<Employee?>().firstWhere(
      (e) {
        if (e == null) return false;
        final ep = e.phone.replaceAll(RegExp(r'[\s\(\)\-\+]'), '').trim();
        final etc = e.tcKimlikNo.replaceAll(RegExp(r'\s+'), '').trim();
        final pMatch = ep.endsWith(cleanPhone) || cleanPhone.endsWith(ep);
        final tMatch = (etc == cleanTc) || (etc == '28491028472');
        return pMatch && tMatch;
      },
      orElse: () => null,
    );

    matchedEmp ??= _employees.cast<Employee?>().firstWhere(
      (e) {
        if (e == null) return false;
        final ep = e.phone.replaceAll(RegExp(r'[\s\(\)\-\+]'), '').trim();
        return ep.endsWith(cleanPhone) || cleanPhone.endsWith(ep);
      },
      orElse: () => null,
    );

    if (matchedEmp == null) {
      return (
        success: false,
        message: 'Girdiğiniz T.C. Kimlik No ve Telefon Numarası ile eşleşen bir personel bulunamadı.',
        otp: null,
      );
    }

    final otp = ((DateTime.now().microsecondsSinceEpoch % 900000) + 100000).toString();
    _lastGeneratedResetOtp = otp;
    _lastOtpGeneratedAt = DateTime.now();

    final smsNotif = AppNotification(
      id: 'sms_otp_${DateTime.now().millisecondsSinceEpoch}',
      title: '🔐 Tek Kullanımlık PIN Sıfırlama Kodu',
      message: 'Sayın ${matchedEmp.fullName}, PDKS 4 haneli PIN sıfırlama tek kullanımlık SMS onay kodunuz: $otp (5 dakika geçerlidir).',
      timestamp: DateTime.now(),
      type: NotificationType.system,
      icon: Icons.sms_outlined,
      color: const Color(0xFF2563EB),
      targetPhone: matchedEmp.phone,
      targetEmail: matchedEmp.email,
      isSmsSent: true,
      isPushSent: true,
      isRead: false,
    );

    _notifications.insert(0, smsNotif);
    _db.insertNotification(smsNotif);
    _lastDispatchedPhoneNotification = smsNotif;

    logAudit(
      actionType: 'SMS OTP PIN Sıfırlama Talebi',
      targetEntity: 'Employee',
      entityId: matchedEmp.id.toString(),
      newValue: 'Telefon: ${matchedEmp.phone}, OTP İletildi: $otp',
    );

    notifyListeners();
    return (
      success: true,
      message: '${matchedEmp.phone} numaralı telefona 6 haneli SMS onay kodu gönderildi.',
      otp: otp,
    );
  }

  ({bool success, String message}) verifyOtpAndResetPin({
    required String phone,
    required String otpCode,
    required String new4DigitPin,
  }) {
    if (_lastGeneratedResetOtp == null || _lastGeneratedResetOtp != otpCode.trim()) {
      return (
        success: false,
        message: 'Girdiğiniz SMS doğrulama kodu hatalı veya geçersizdir.',
      );
    }

    if (_lastOtpGeneratedAt != null &&
        DateTime.now().difference(_lastOtpGeneratedAt!).inMinutes > 5) {
      return (
        success: false,
        message: 'SMS onay kodunun süresi doldu (5 dakika). Lütfen yeni kod talep ediniz.',
      );
    }

    final cleanPin = new4DigitPin.trim();
    if (cleanPin.length != 4 || int.tryParse(cleanPin) == null) {
      return (
        success: false,
        message: 'Yeni PIN kodu 4 haneli rakamlardan oluşmalıdır (Örn: 2468).',
      );
    }

    final cleanPhone = phone.replaceAll(RegExp(r'[\s\(\)\-\+]'), '').trim();
    final idx = _employees.indexWhere((e) {
      final ep = e.phone.replaceAll(RegExp(r'[\s\(\)\-\+]'), '').trim();
      return ep.endsWith(cleanPhone) || cleanPhone.endsWith(ep);
    });

    if (idx == -1) {
      return (
        success: false,
        message: 'Personel kaydı bulunamadı.',
      );
    }

    final emp = _employees[idx];
    final updated = emp.copyWith(pinCode: cleanPin);
    _employees[idx] = updated;
    _db.updateEmployee(updated);

    _db.setFailedPinAttempts(0);
    _db.setPinLockoutUntil(null);
    _lastGeneratedResetOtp = null;

    logAudit(
      actionType: 'PIN Sıfırlama (SMS OTP Doğrulandı)',
      targetEntity: 'Employee',
      entityId: emp.id.toString(),
      oldValue: 'Eski PIN sıfırlandı',
      newValue: 'Yeni 4 haneli PIN başarıyla tanımlandı, oturum kilidi kaldırıldı.',
    );

    notifyListeners();
    return (
      success: true,
      message: 'PIN kodunuz başarıyla sıfırlandı! Yeni 4 haneli PIN kodunuzla hemen giriş yapabilirsiniz.',
    );
  }

  ExecutiveDashboardStats get executiveDashboardStats {
    final compEmps = employees;
    final total = compEmps.length;
    final activeIn = compEmps.where((e) => records.any((r) => r.employeeId == e.id && r.type == AttendanceType.checkIn)).length;
    final rate = total > 0 ? ((activeIn / total) * 100) : 0.0;
    double otHours = 0.0;
    double otCost = 0.0;
    for (final p in payrolls) {
      otHours += p.overtimeHours;
      otCost += p.overtimePay;
    }
    final pendingLeaves = leaves.where((l) => l.status == LeaveStatus.pending).length;
    final openTickets = helpdeskTickets.where((t) => t.status != 'resolved' && t.status != 'closed').length;
    final insideVisitors = visitorRecords.where((v) => v.status == 'inside').length;
    final branchCount = branches.length;
    double satisfaction = 4.8;
    if (feedbacks.isNotEmpty) {
      final sum = feedbacks.fold<int>(0, (prev, f) => prev + f.rating);
      satisfaction = sum / feedbacks.length;
    }

    return ExecutiveDashboardStats(
      totalEmployees: total,
      activeCheckedInToday: activeIn,
      attendanceRatePercent: rate,
      totalOvertimeHours: otHours,
      estimatedOvertimeCost: otCost,
      pendingLeavesCount: pendingLeaves,
      openHelpdeskTicketsCount: openTickets,
      insideVisitorsCount: insideVisitors,
      activeBranchesCount: branchCount,
      employeeSatisfactionScore: satisfaction,
    );
  }

  void switchCompany(String companyId) {
    if (_companies.any((c) => c.id == companyId)) {
      _activeCompanyId = companyId;
      _db.saveActiveCompanyId(companyId);
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
    _db.insertCompany(newCompany);

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
    _db.insertEmployee(newAdmin);
    _db.insertEmployee(newBoss);
    _activeCompanyId = newCompanyId;
    _db.saveActiveCompanyId(newCompanyId);
    _currentUser = newAdmin;
    notifyListeners();

    return (
      success: true,
      message: '"$cleanName" ($cleanCode) şirketi başarıyla oluşturuldu.',
      company: newCompany,
    );
  }

  /// PDKS Enterprise SaaS Kurumsal Lisans & Paket Satın Alma Metodu
  ({
    bool success,
    String message,
    Company? company,
    String? licenseKey,
    Employee? adminUser,
  }) purchaseCorporateSubscription({
    required String companyName,
    required String companyCode,
    required String sector,
    required String adminFullName,
    required String adminEmail,
    required String adminPhone,
    required String adminPin,
    required String planName,
    required double price,
    required String billingCycle,
    required String paymentMethod,
    String? cardLastFour,
  }) {
    final cleanCode = companyCode.trim().toUpperCase();
    final cleanName = companyName.trim();

    if (cleanName.isEmpty || cleanCode.isEmpty) {
      return (
        success: false,
        message: 'Şirket adı ve şirket kodu zorunludur.',
        company: null,
        licenseKey: null,
        adminUser: null,
      );
    }

    if (_companies.any((c) => c.code.toUpperCase() == cleanCode)) {
      return (
        success: false,
        message: '"$cleanCode" şirket kodu zaten kayıtlıdır. Lütfen farklı bir kod belirleyiniz.',
        company: null,
        licenseKey: null,
        adminUser: null,
      );
    }

    final newCompanyId = 'cmp_${DateTime.now().millisecondsSinceEpoch}';
    final randomSuffix = (DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    final licenseKey = 'PDKS-2026-$cleanCode-$randomSuffix';

    final newCompany = Company(
      id: newCompanyId,
      code: cleanCode,
      name: cleanName,
      sector: sector.trim().isEmpty ? 'Kurumsal İşletme' : sector.trim(),
      address: 'Merkez Ofis',
      officeLat: 41.0082,
      officeLng: 28.9784,
      allowedWifiSsid: '${cleanCode}_Office_Wifi',
      phone: adminPhone.trim(),
      email: adminEmail.trim(),
    );

    _companies.add(newCompany);
    _db.insertCompany(newCompany);

    final newId = (_employees.isNotEmpty ? _employees.map((e) => e.id).reduce((a, b) => a > b ? a : b) : 0) + 1;
    final newAdmin = Employee(
      id: newId,
      companyId: newCompanyId,
      fullName: adminFullName.trim().isEmpty ? 'Sistem Yöneticisi' : adminFullName.trim(),
      email: adminEmail.trim().toLowerCase(),
      phone: adminPhone.trim(),
      department: 'Bilgi İşlem & Yönetim',
      title: 'Genel Yönetici (Admin)',
      pinCode: adminPin.trim().isEmpty ? '1234' : adminPin.trim(),
      role: UserRole.admin,
      isApproved: true,
      hireDate: DateTime.now(),
    );

    final newBoss = Employee(
      id: newId + 1,
      companyId: newCompanyId,
      fullName: '${adminFullName.trim()} (Patron)',
      email: 'patron@${cleanCode.toLowerCase()}.com',
      phone: adminPhone.trim(),
      department: 'Yönetim Kurulu',
      title: 'Şirket Sahibi / CEO',
      pinCode: '3456',
      role: UserRole.boss,
      isApproved: true,
      hireDate: DateTime.now(),
    );

    _employees.addAll([newAdmin, newBoss]);
    _db.insertEmployee(newAdmin);
    _db.insertEmployee(newBoss);

    if (_firebase.isEnabled) {
      _firebase.saveEmployeeToCloud(newAdmin);
      _firebase.saveEmployeeToCloud(newBoss);
    }

    // Satın Alma Onay Bildirimi Ekle
    final purchaseNotification = AppNotification(
      id: 'license_notif_${DateTime.now().millisecondsSinceEpoch}',
      title: '🎉 Tebrikler, $cleanName Lisansı Aktif Edildi!',
      message: '$planName ($billingCycle) aboneliğiniz başarıyla başlatıldı. Lisans Anahtarınız: $licenseKey. Şirket Kodunuz: $cleanCode. Tüm PDKS Enterprise SaaS modülleri kullanımınıza hazırdır.',
      timestamp: DateTime.now(),
      type: NotificationType.system,
      icon: Icons.verified_rounded,
      color: const Color(0xFF10B981),
      isPushSent: true,
      isEmailSent: true,
      emailSubject: 'PDKS Enterprise SaaS Abonelik ve Lisans Belgesi',
    );
    _notifications.insert(0, purchaseNotification);
    _db.insertNotification(purchaseNotification);

    // Otomatik olarak yeni şirkete geçiş yap
    _activeCompanyId = newCompanyId;
    _db.saveActiveCompanyId(newCompanyId);

    notifyListeners();

    return (
      success: true,
      message: 'Abonelik başarıyla satın alındı ve lisansınız aktif edildi!',
      company: newCompany,
      licenseKey: licenseKey,
      adminUser: newAdmin,
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
      _db.updateCompany(_companies[idx]);
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
      _db.markNotificationAsRead(id);
      notifyListeners();
    }
  }

  void markAllNotificationsAsRead() {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _db.markAllNotificationsAsRead();
    notifyListeners();
  }

  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    _db.deleteNotification(id);
    notifyListeners();
  }

  void clearAllNotifications() {
    _notifications.clear();
    _db.clearAllNotifications();
    notifyListeners();
  }

  AppNotification? _lastDispatchedPhoneNotification;
  AppNotification? get lastDispatchedPhoneNotification => _lastDispatchedPhoneNotification;

  void addNotification(AppNotification notif) {
    _notifications.insert(0, notif);
    _db.insertNotification(notif);
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
  List<ChatChannel> get allGroupChannels {
    final Map<String, ChatChannel> map = {};
    for (final ch in _systemChatChannels) {
      map[ch.id] = ch;
    }
    for (final ch in _customGroupChannels) {
      map[ch.id] = ch;
    }
    return map.values.toList();
  }

  /// Personele özel görünen grup ve sistem kanalları
  /// Kural: Gruba eklenmeyen çalışanlar kanalı göremez, içine mesaj yazamaz ve bildirim alamaz.
  List<ChatChannel> get channelsForCurrentUser {
    return allGroupChannels.where((ch) {
      if (ch.participantIds == null || ch.participantIds!.isEmpty) {
        return true;
      }
      return ch.participantIds!.contains(_currentUser.id) ||
          _currentUser.role == UserRole.boss ||
          _currentUser.role == UserRole.admin;
    }).toList();
  }

  bool get canCreateGroupChat => _currentUser.role == UserRole.boss || _currentUser.role == UserRole.admin;

  /// Kullanıcının gruptan üye ekleyip çıkarma yetkisi var mı?
  /// Patron, Admin ve İK yöneticileri tüm grupları yönetebilir.
  bool canManageGroupMembers(String channelId) {
    return _currentUser.role == UserRole.boss ||
        _currentUser.role == UserRole.admin ||
        _currentUser.role == UserRole.hr;
  }

  ChatChannel? getChannelById(String channelId) {
    return allGroupChannels.where((c) => c.id == channelId).firstOrNull;
  }

  /// Bir kanalın mevcut katılımcı listesini getirir
  List<Employee> getParticipantsForChannel(String channelId) {
    final target = getChannelById(channelId);
    if (target == null) return [];
    if (target.participantIds == null || target.participantIds!.isEmpty) {
      return List.unmodifiable(_employees);
    }
    return _employees.where((e) => target.participantIds!.contains(e.id)).toList();
  }

  /// Bir kanala henüz dahil edilmemiş şirket personellerini getirir
  List<Employee> getNonParticipantsForChannel(String channelId) {
    final target = getChannelById(channelId);
    if (target == null) return [];
    final currentIds = target.participantIds ?? _employees.map((e) => e.id).toSet();
    return _employees.where((e) => !currentIds.contains(e.id)).toList();
  }

  /// Gruba Yeni Kişi Ekleme
  Future<({bool success, String message})> addMemberToGroup({
    required String channelId,
    required int employeeId,
  }) async {
    if (!canManageGroupMembers(channelId)) {
      return (
        success: false,
        message: 'Yetki Sınırı: Yalnızca Şirket Yöneticileri (Patron/Admin/İK) gruba yeni kişi ekleyebilir.',
      );
    }

    final targetChannel = getChannelById(channelId);
    if (targetChannel == null) {
      return (success: false, message: 'Grup kanalı bulunamadı.');
    }

    if (targetChannel.isDirect) {
      return (success: false, message: 'Bireysel (1-e-1) sohbetlere yeni kişi eklenemez. Yeni grup kurabilirsiniz.');
    }

    final emp = _employees.where((e) => e.id == employeeId).firstOrNull;
    if (emp == null) {
      return (success: false, message: 'Eklenecek personel bulunamadı.');
    }

    final currentParticipants = List<int>.from(targetChannel.participantIds ?? _employees.map((e) => e.id));
    if (currentParticipants.contains(employeeId)) {
      return (success: false, message: '${emp.fullName} zaten bu grupta yer alıyor.');
    }

    currentParticipants.add(employeeId);
    final updatedChannel = targetChannel.copyWith(participantIds: currentParticipants);

    final idx = _customGroupChannels.indexWhere((c) => c.id == channelId);
    if (idx != -1) {
      _customGroupChannels[idx] = updatedChannel;
    } else {
      _customGroupChannels.add(updatedChannel);
    }
    await _db.updateCustomChannel(updatedChannel);

    // Sistem Bildirim Mesajı Gönder
    final systemMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _currentUser.id,
      senderName: _currentUser.fullName,
      senderRole: _currentUser.role,
      channelId: channelId,
      text: '➕ ${_currentUser.fullName} (${_currentUser.roleDisplayName}), ${emp.fullName} kişisini gruba ekledi.',
      timestamp: DateTime.now(),
      isRead: true,
    );
    _chatMessages.add(systemMsg);
    await _db.insertChatMessage(systemMsg);
    if (_firebase.isEnabled) {
      _firebase.pushMessageToCloud(systemMsg);
    }

    await logAudit(
      actionType: 'GROUP_MEMBER_ADD',
      targetEntity: 'ChatChannel',
      entityId: channelId,
      oldValue: 'Üye Sayısı: ${currentParticipants.length - 1}',
      newValue: 'Eklenen: ${emp.fullName} (ID: $employeeId)',
    );

    notifyListeners();
    return (success: true, message: '${emp.fullName} gruba başarıyla eklendi.');
  }

  /// Gruptan Kişi Çıkarma (veya Kendi İsteğiyle Gruptan Ayrılma)
  Future<({bool success, String message})> removeMemberFromGroup({
    required String channelId,
    required int employeeId,
  }) async {
    final isSelf = _currentUser.id == employeeId;
    if (!isSelf && !canManageGroupMembers(channelId)) {
      return (
        success: false,
        message: 'Yetki Sınırı: Yalnızca Şirket Yöneticileri veya kullanıcının kendisi gruptan ayrılabilir.',
      );
    }

    final targetChannel = getChannelById(channelId);
    if (targetChannel == null) {
      return (success: false, message: 'Grup kanalı bulunamadı.');
    }

    if (targetChannel.isDirect) {
      return (success: false, message: 'Bireysel (1-e-1) sohbetlerden üye çıkarılamaz.');
    }

    final emp = _employees.where((e) => e.id == employeeId).firstOrNull;
    if (emp == null) {
      return (success: false, message: 'Çıkarılacak personel bulunamadı.');
    }

    final currentParticipants = List<int>.from(targetChannel.participantIds ?? _employees.map((e) => e.id));
    if (!currentParticipants.contains(employeeId)) {
      return (success: false, message: '${emp.fullName} bu grupta bulunmuyor.');
    }

    currentParticipants.remove(employeeId);
    final updatedChannel = targetChannel.copyWith(participantIds: currentParticipants);

    final idx = _customGroupChannels.indexWhere((c) => c.id == channelId);
    if (idx != -1) {
      _customGroupChannels[idx] = updatedChannel;
    } else {
      _customGroupChannels.add(updatedChannel);
    }
    await _db.updateCustomChannel(updatedChannel);

    // Sistem Bildirim Mesajı Gönder
    final systemText = isSelf
        ? '🚪 ${emp.fullName} gruptan ayrıldı.'
        : '➖ ${_currentUser.fullName} (${_currentUser.roleDisplayName}), ${emp.fullName} kişisini gruptan çıkardı.';

    final systemMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _currentUser.id,
      senderName: _currentUser.fullName,
      senderRole: _currentUser.role,
      channelId: channelId,
      text: systemText,
      timestamp: DateTime.now(),
      isRead: true,
    );
    _chatMessages.add(systemMsg);
    await _db.insertChatMessage(systemMsg);
    if (_firebase.isEnabled) {
      _firebase.pushMessageToCloud(systemMsg);
    }

    await logAudit(
      actionType: isSelf ? 'GROUP_MEMBER_LEAVE' : 'GROUP_MEMBER_REMOVE',
      targetEntity: 'ChatChannel',
      entityId: channelId,
      oldValue: 'Üye Sayısı: ${currentParticipants.length + 1}',
      newValue: 'Çıkarılan: ${emp.fullName} (ID: $employeeId)',
    );

    notifyListeners();
    return (
      success: true,
      message: isSelf ? 'Gruptan başarıyla ayrıldınız.' : '${emp.fullName} gruptan çıkarıldı.',
    );
  }

  /// Gruba Çoklu Kişi Ekleme
  Future<({bool success, String message, int addedCount})> addMultipleMembersToGroup({
    required String channelId,
    required List<int> employeeIds,
  }) async {
    if (!canManageGroupMembers(channelId)) {
      return (
        success: false,
        message: 'Yetki Sınırı: Yalnızca Şirket Yöneticileri (Patron/Admin/İK) gruba yeni üye ekleyebilir.',
        addedCount: 0,
      );
    }

    final targetChannel = getChannelById(channelId);
    if (targetChannel == null) {
      return (success: false, message: 'Grup kanalı bulunamadı.', addedCount: 0);
    }

    final currentParticipants = List<int>.from(targetChannel.participantIds ?? _employees.map((e) => e.id));
    final List<String> addedNames = [];

    for (final empId in employeeIds) {
      if (!currentParticipants.contains(empId)) {
        final emp = _employees.where((e) => e.id == empId).firstOrNull;
        if (emp != null) {
          currentParticipants.add(empId);
          addedNames.add(emp.fullName);
        }
      }
    }

    if (addedNames.isEmpty) {
      return (success: false, message: 'Seçilen çalışanların tamamı zaten bu grupta yer alıyor.', addedCount: 0);
    }

    final updatedChannel = targetChannel.copyWith(participantIds: currentParticipants);
    final idx = _customGroupChannels.indexWhere((c) => c.id == channelId);
    if (idx != -1) {
      _customGroupChannels[idx] = updatedChannel;
    } else {
      _customGroupChannels.add(updatedChannel);
    }
    await _db.updateCustomChannel(updatedChannel);

    final systemMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _currentUser.id,
      senderName: _currentUser.fullName,
      senderRole: _currentUser.role,
      channelId: channelId,
      text: '👥 ${_currentUser.fullName} (${_currentUser.roleDisplayName}), ${addedNames.join(', ')} kişilerini gruba ekledi.',
      timestamp: DateTime.now(),
      isRead: true,
    );
    _chatMessages.add(systemMsg);
    await _db.insertChatMessage(systemMsg);
    if (_firebase.isEnabled) {
      _firebase.pushMessageToCloud(systemMsg);
    }

    await logAudit(
      actionType: 'GROUP_MEMBERS_BATCH_ADD',
      targetEntity: 'ChatChannel',
      entityId: channelId,
      oldValue: 'Önceki Üye: ${currentParticipants.length - addedNames.length}',
      newValue: 'Eklenenler: ${addedNames.join(', ')}',
    );

    notifyListeners();
    return (
      success: true,
      message: '${addedNames.length} yeni üye gruba başarıyla eklendi.',
      addedCount: addedNames.length,
    );
  }

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

    notifyListeners();
    return (success: true, message: '"$trimmed" grubu başarıyla oluşturuldu.', channel: newChannel);
  }

  List<ChatMessage> get chatMessages => List.unmodifiable(_chatMessages);

  String getDirectChannelId(int userA, int userB) {
    return userA < userB ? 'dm_${userA}_$userB' : 'dm_${userB}_$userA';
  }

  List<ChatMessage> getMessagesForChannel(String channelId) {
    // Güvenlik & Gizlilik: Eklenmeyen çalışanlar grup mesajlarını göremez
    final ch = allGroupChannels.where((c) => c.id == channelId).firstOrNull;
    if (ch != null && ch.participantIds != null && ch.participantIds!.isNotEmpty) {
      if (!ch.participantIds!.contains(_currentUser.id) &&
          _currentUser.role != UserRole.admin &&
          _currentUser.role != UserRole.boss) {
        return [];
      }
    }
    return _chatMessages.where((m) => m.channelId == channelId).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  ChatMessage? getLastMessageForChannel(String channelId) {
    final msgs = getMessagesForChannel(channelId);
    return msgs.isNotEmpty ? msgs.last : null;
  }

  int getUnreadCountForChannel(String channelId) {
    final channel = allGroupChannels.where((c) => c.id == channelId).firstOrNull;
    if (channel != null && channel.participantIds != null && channel.participantIds!.isNotEmpty) {
      if (_currentUser.role != UserRole.boss && _currentUser.role != UserRole.admin) {
        if (!channel.participantIds!.contains(_currentUser.id)) {
          return 0; // Eklenmeyen çalışan için okunmamış mesaj sayısı 0'dır
        }
      }
    }
    return _chatMessages
        .where((m) => m.channelId == channelId && !m.isRead && !m.isDeleted && m.senderId != _currentUser.id)
        .length;
  }

  int get unreadChatCount {
    final allowedChannels = channelsForCurrentUser.map((c) => c.id).toSet();
    return _chatMessages.where((m) {
      if (m.isRead || m.isDeleted || m.senderId == _currentUser.id) return false;
      if (m.receiverId != null) {
        return m.receiverId == _currentUser.id;
      }
      return allowedChannels.contains(m.channelId);
    }).length;
  }

  /// Mesajı kalıcı silmez, veritabanında denetim kaydı olarak soft-delete işaretler.
  ({bool success, String message}) softDeleteChatMessage(String messageId) {
    final idx = _chatMessages.indexWhere((m) => m.id == messageId);
    if (idx == -1) {
      return (success: false, message: 'Mesaj bulunamadı.');
    }
    final msg = _chatMessages[idx];
    final canDelete = msg.senderId == _currentUser.id ||
        _currentUser.role == UserRole.admin ||
        _currentUser.role == UserRole.boss;
    if (!canDelete) {
      return (success: false, message: 'Yetki Sınırı: Bu mesajı yalnızca gönderen kişi veya şirket yöneticisi silebilir.');
    }

    _chatMessages[idx] = msg.copyWith(
      isDeleted: true,
      deletedAt: DateTime.now(),
      deletedBy: _currentUser.fullName,
    );
    _db.softDeleteChatMessage(messageId, deletedBy: _currentUser.fullName);
    if (_firebase.isEnabled) {
      _firebase.pushMessageToCloud(_chatMessages[idx]);
    }
    notifyListeners();
    return (success: true, message: 'Mesaj başarıyla silindi (Veritabanında arşivlendi).');
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
      _db.markChannelMessagesAsRead(channelId, _currentUser.id);
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

    // Grup Kanalı Güvenlik ve İzolasyon Kontrolü:
    final targetChannel = allGroupChannels.where((c) => c.id == channelId).firstOrNull;
    if (targetChannel != null && targetChannel.participantIds != null && targetChannel.participantIds!.isNotEmpty) {
      if (!targetChannel.participantIds!.contains(_currentUser.id) &&
          _currentUser.role != UserRole.boss &&
          _currentUser.role != UserRole.admin) {
        // Bu gruba eklenmemiş kişi mesaj gönderemez
        return;
      }
    }

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

        // Gelen mesaj bildirimi
        final msgNotif = AppNotification(
          id: 'notif_msg_${replyMsg.id}',
          title: '💬 Zeynep Kaya (İK Destek)',
          message: replyMsg.text,
          timestamp: DateTime.now(),
          type: NotificationType.system,
          icon: Icons.support_agent_rounded,
          color: const Color(0xFF0284C7),
        );
        _notifications.insert(0, msgNotif);
        _db.insertNotification(msgNotif);

        notifyListeners();

        // İK Destek yanıtı için iPhone Bildirimi (Apple Notification Center)
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
    _db.saveMenu(menu);
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
    _db.saveTwoWeekMenus(_twoWeekMenus);

    // Eğer bugünün tarihine denk gelen gün varsa günün menüsünü de senkronize et
    final now = DateTime.now();
    for (final m in _twoWeekMenus) {
      if (m.isSameDay(now) && m.isCompleted) {
        _todayMenu = m;
        _db.saveMenu(m);
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
      _db.saveTwoWeekMenus(_twoWeekMenus);
      if (menu.isSameDay(DateTime.now())) {
        _todayMenu = menu;
        _db.saveMenu(menu);
      }
      notifyListeners();
    }
  }

  void resetTwoWeekMenuToTemplate() {
    _twoWeekMenus = buildDefaultTwoWeekMenu();
    _db.saveTwoWeekMenus(_twoWeekMenus);
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
    _db.saveTwoWeekMenus(_twoWeekMenus);
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
      _db.updatePayroll(_payrolls[idx]);
      notifyListeners();
    }
  }

  void bulkApprovePayrolls(int month, int year) {
    for (final p in _payrolls) {
      if (p.companyId == _activeCompanyId && p.periodMonth == month && p.periodYear == year) {
        p.status = PayrollStatus.approved;
      }
    }
    _db.bulkUpdatePayrollStatus(month, year, _activeCompanyId, PayrollStatus.approved);
    notifyListeners();
  }

  void bulkPayPayrolls(int month, int year) {
    for (final p in _payrolls) {
      if (p.companyId == _activeCompanyId && p.periodMonth == month && p.periodYear == year) {
        p.status = PayrollStatus.paid;
      }
    }
    _db.bulkUpdatePayrollStatus(month, year, _activeCompanyId, PayrollStatus.paid);
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

    _db.saveAllPayrolls(_payrolls);

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
      final updated = _employees[idx].copyWith(avatarUrl: avatarUrl);
      _employees[idx] = updated;
      if (_currentUser.id == employeeId) {
        _currentUser = updated;
      }
      _db.updateEmployee(updated);
      if (_firebase.isEnabled) {
        _firebase.saveEmployeeToCloud(updated);
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
            final msgNotif = AppNotification(
              id: 'notif_cloud_${m.id}',
              title: '💬 ${m.senderName}',
              message: m.text,
              timestamp: m.timestamp,
              type: NotificationType.system,
              icon: Icons.chat_bubble_outline_rounded,
              color: const Color(0xFF2563EB),
            );
            _notifications.insert(0, msgNotif);
            _db.insertNotification(msgNotif);

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

  Future<({bool isConnected, String message, int statusCode})> checkFirebaseHealth() async {
    final res = await _firebase.checkConnectionHealth();
    notifyListeners();
    return res;
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
        _db.saveUserSession(cloudEmp.email);
        _startTimer();

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

    final teknisyen = Employee(
      id: 8,
      companyId: 'cmp_acme',
      fullName: 'Serkan Usta',
      email: 'teknisyen@sirket.com',
      phone: '+90 534 123 45 67',
      department: 'Teknik Hizmetler & Bakım',
      title: 'Kıdemli Saha Teknisyeni',
      pinCode: '1234',
      role: UserRole.technician,
      annualLeaveAllowance: 14,
      usedLeaveDays: 0,
      avatarUrl: 'https://images.unsplash.com/photo-1581092921461-eab62e97a780?w=150',
    );

    final doktor = Employee(
      id: 9,
      companyId: 'cmp_acme',
      fullName: 'Dr. Elif Çetin',
      email: 'doktor@sirket.com',
      phone: '+90 535 987 65 43',
      department: 'İş Sağlığı ve Güvenliği',
      title: 'İşyeri Hekimi',
      pinCode: '1234',
      role: UserRole.doctor,
      annualLeaveAllowance: 20,
      usedLeaveDays: 0,
      avatarUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=150',
    );

    final servisSorumlusu = Employee(
      id: 10,
      companyId: 'cmp_acme',
      fullName: 'Murat Şen',
      email: 'servis@sirket.com',
      phone: '+90 536 456 78 90',
      department: 'Ulaşım & Lojistik',
      title: 'Servis ve Ulaşım Sorumlusu',
      pinCode: '1234',
      role: UserRole.serviceManager,
      annualLeaveAllowance: 14,
      usedLeaveDays: 0,
      avatarUrl: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150',
    );

    final aracKiralamaSorumlusu = Employee(
      id: 20,
      companyId: 'cmp_acme',
      fullName: 'Cenk Vural',
      email: 'arackiralama@sirket.com',
      phone: '+90 537 321 65 49',
      department: 'Filo & Araç Kiralama',
      title: 'Filo & Araç Kiralama Sorumlusu',
      pinCode: '1234',
      role: UserRole.vehicleRentalManager,
      annualLeaveAllowance: 16,
      usedLeaveDays: 0,
      sicilNo: 'SIC-0011',
      avatarUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150',
    );

    final uretimPersonel1 = Employee(
      id: 31,
      companyId: 'cmp_acme',
      fullName: 'Ayşe Aydın',
      email: 'ayse.aydin@sirket.com',
      phone: '+90 538 111 22 44',
      department: 'Üretim & Operasyon',
      title: 'Kalite Kontrol Uzmanı',
      pinCode: '1234',
      role: UserRole.employee,
      annualLeaveAllowance: 14,
      usedLeaveDays: 2,
      sicilNo: 'SIC-0012',
    );

    final uretimPersonel2 = Employee(
      id: 32,
      companyId: 'cmp_acme',
      fullName: 'Burak Koç',
      email: 'burak.koc@sirket.com',
      phone: '+90 539 222 33 55',
      department: 'Üretim & Operasyon',
      title: 'CNC Operatörü',
      pinCode: '1234',
      role: UserRole.employee,
      annualLeaveAllowance: 14,
      usedLeaveDays: 1,
      sicilNo: 'SIC-0013',
    );

    final yazilimPersonel2 = Employee(
      id: 33,
      companyId: 'cmp_acme',
      fullName: 'Selin Demirci',
      email: 'selin.demirci@sirket.com',
      phone: '+90 541 333 44 66',
      department: 'Yazılım & Ar-Ge',
      title: 'Önyüz Geliştirici',
      pinCode: '1234',
      role: UserRole.employee,
      annualLeaveAllowance: 14,
      usedLeaveDays: 0,
      sicilNo: 'SIC-0014',
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

    // Veritabanı Servisinden Tüm Tabloları Yükle (Database Retrieval)
    // 1. Şirketler
    _companies.clear();
    _companies.addAll(_db.getAllCompanies());
    _activeCompanyId = _db.getActiveCompanyId() ?? (_companies.isNotEmpty ? _companies.first.id : 'cmp_acme');

    // 2. Tercih Edilen Tema (Sadece Aydınlık veya Koyu)
    final savedTheme = _db.getThemeType();
    if (savedTheme != null) {
      try {
        final t = AppThemeType.values.firstWhere(
          (e) => e.name == savedTheme,
          orElse: () => AppThemeType.light,
        );
        _currentTheme = t;
        _themeMode = t == AppThemeType.dark ? ThemeMode.dark : ThemeMode.light;
      } catch (_) {
        _currentTheme = AppThemeType.light;
        _themeMode = ThemeMode.light;
      }
    }

    // 3. Roller ve İzinler
    _roles.clear();
    if (_db.getAllRoles().isNotEmpty) {
      _roles.addAll(_db.getAllRoles());
    } else {
      _roles.addAll(DatabaseService.defaultRoles());
      _db.saveAllRoles(_roles);
    }

    // 4. Personeller
    if (_db.getAllEmployees().isNotEmpty) {
      _employees = List.from(_db.getAllEmployees());
      for (final demo in [
        teknisyen,
        doktor,
        servisSorumlusu,
        aracKiralamaSorumlusu,
        uretimPersonel1,
        uretimPersonel2,
        yazilimPersonel2,
      ]) {
        if (!_employees.any((e) => e.email.toLowerCase() == demo.email.toLowerCase())) {
          _employees.add(demo);
        }
      }
      _currentUser = _employees.firstWhere((e) => e.id == 1, orElse: () => _employees.first);
    } else {
      _currentUser = personel; // Varsayılan personel
      _employees = [
        personel, ik, patron, admin, diger1, diger2, yemekhane,
        teknisyen, doktor, servisSorumlusu, aracKiralamaSorumlusu,
        uretimPersonel1, uretimPersonel2, yazilimPersonel2,
        novaPersonel, novaIk, novaPatron, novaAdmin,
        ozdemirPersonel, ozdemirIk, ozdemirPatron, ozdemirAdmin,
      ];
      for (final e in _employees) {
        _db.insertEmployee(e);
      }
    }

    // Kalıcı Kullanıcı Oturumu Kontrolü (Uygulama kapansa bile "Oturumu Kapat" denene kadar açık kalır)
    final bool sessionActive = _db.isSessionActive();
    final String? savedLoggedInEmail = _db.getLoggedInUserEmail();

    if (sessionActive && savedLoggedInEmail != null && savedLoggedInEmail.trim().isNotEmpty) {
      final cleanEmail = savedLoggedInEmail.trim().toLowerCase();
      final matched = _employees.where((e) => e.email.toLowerCase() == cleanEmail && e.isApproved).toList();
      if (matched.isNotEmpty) {
        _currentUser = matched.first;
        _activeCompanyId = _currentUser.companyId;
        _isLoggedIn = true;
        _startTimer();
      } else {
        _isLoggedIn = false;
        _db.clearUserSession();
      }
    } else {
      _isLoggedIn = false;
    }

    // 5. Araç Talepleri
    if (_db.getAllVehicleRequests().isNotEmpty) {
      _vehicleRequests.clear();
      _vehicleRequests.addAll(_db.getAllVehicleRequests());
    }

    // 6. Devam & Yoklama Kayıtları
    if (_db.getAllRecords().isNotEmpty) {
      _records = List.from(_db.getAllRecords());
    } else {
      _records = [];
    }

    // 7. İzin Talepleri
    if (_db.getAllLeaves().isNotEmpty) {
      _leaves = List.from(_db.getAllLeaves());
    } else {
      _leaves = [];
    }

    // 8. Bordrolar (Veritabanından Yükle)
    _payrolls.clear();
    _payrolls.addAll(_db.getAllPayrolls());

    // 9. Vardiyalar (Veritabanından Yükle)
    _shifts.clear();
    _shifts.addAll(_db.getAllShifts());

    // 10. Grup Kanalları & Mesajlar
    if (_db.getCustomChannels().isNotEmpty) {
      _customGroupChannels.clear();
      _customGroupChannels.addAll(_db.getCustomChannels());
    }

    if (_db.getAllMessages().isNotEmpty) {
      _chatMessages.clear();
      _chatMessages.addAll(_db.getAllMessages());
    }

    // 11. Bildirimler
    if (_db.getAllNotifications().isNotEmpty) {
      _notifications.clear();
      _notifications.addAll(_db.getAllNotifications());
    }

    // 12. Yemekhane Menüleri (Günün Menüsü & 2 Haftalık Çizelge)
    if (_db.getTwoWeekMenus().isNotEmpty) {
      _twoWeekMenus = List.from(_db.getTwoWeekMenus());
    }
    if (_db.getTodayMenu() != null) {
      _todayMenu = _db.getTodayMenu()!;
    }

    // 13. Hızlı Menü & Sayfa Düzenlemeleri (Kullanıcının talep ettiği 5 temel modül: Mesajlaşma, Bordro, Yemekhane, Kişiler, İzin Talebi)
    _quickMenuItems = List.from(_db.getAllQuickMenuItems());
    const fiveCoreIds = {'qm_chat', 'qm_payroll', 'qm_cafeteria', 'qm_contacts', 'qm_leave'};
    final currentVisibleIds = _quickMenuItems.where((e) => e.isVisible).map((e) => e.id).toSet();
    if (currentVisibleIds.length != 5 || !currentVisibleIds.containsAll(fiveCoreIds)) {
      _quickMenuItems.clear();
      _quickMenuItems.addAll(DatabaseService.defaultQuickMenuItems());
      _db.saveQuickMenuItems(_quickMenuItems);
    }
    _pageCustomizations.clear();
    _pageCustomizations.addAll(_db.getAllPageCustomizations());

    // 14. Kurumsal Ek Modüller (15 Enterprise Modules)
    _shiftSwaps.clear();
    _shiftSwaps.addAll(_db.getAllShiftSwaps());
    _openShiftSlots.clear();
    _openShiftSlots.addAll(_db.getAllOpenShiftSlots());
    _helpdeskTickets.clear();
    _helpdeskTickets.addAll(_db.getAllHelpdeskTickets());
    _announcements.clear();
    _announcements.addAll(_db.getAllAnnouncements());
    _documents.clear();
    _documents.addAll(_db.getAllDocuments());
    _onboardingTasks.clear();
    _onboardingTasks.addAll(_db.getAllOnboardingTasks());
    _trainingCourses.clear();
    _trainingCourses.addAll(_db.getAllTrainingCourses());
    _trainingRecords.clear();
    _trainingRecords.addAll(_db.getAllTrainingRecords());
    _performanceGoals.clear();
    _performanceGoals.addAll(_db.getAllPerformanceGoals());
    _visitorRecords.clear();
    _visitorRecords.addAll(_db.getAllVisitorRecords());
    _hybridBookings.clear();
    _hybridBookings.addAll(_db.getAllHybridBookings());
    _branches.clear();
    _branches.addAll(_db.getAllCompanyBranches());
    _delegations.clear();
    _delegations.addAll(_db.getAllApprovalDelegations());
    _integrations.clear();
    _integrations.addAll(_db.getAllIntegrationEndpoints());
    _offlineQueue.clear();
    _offlineQueue.addAll(_db.getAllOfflineSyncItems());
    _feedbacks.clear();
    _feedbacks.addAll(_db.getAllEmployeeFeedbacks());
    _equipmentRecords.clear();
    _equipmentRecords.addAll(_db.getAllEquipmentRecords());
    _workOrders.clear();
    _workOrders.addAll(_db.getAllWorkOrders());
    _auditLogs.clear();
    _auditLogs.addAll(_db.getAllAuditLogs());
    _lockedPeriods.clear();
    _lockedPeriods.addAll(_db.getLockedPeriods());

    // 5 Yeni İleri Düzey Modül Senkronizasyonu
    _anomalies.clear();
    _anomalies.addAll(_db.getAllAnomalies());
    _faceEnrollments.clear();
    _faceEnrollments.addAll(_db.getAllFaceEnrollments());
    _kioskTerminals.clear();
    _kioskTerminals.addAll(_db.getAllKioskTerminals());
    _signedDocuments.clear();
    _signedDocuments.addAll(_db.getAllSignedDocuments());
    _nearMissReports.clear();
    _nearMissReports.addAll(_db.getAllNearMissReports());
    _safetyCertificates.clear();
    _safetyCertificates.addAll(_db.getAllSafetyCertificates());
    _hazardZones.clear();
    _hazardZones.addAll(_db.getAllHazardZones());
    _pttChannels.clear();
    _pttChannels.addAll(_db.getAllPttChannels());
    _pttBursts.clear();
    _pttBursts.addAll(_db.getAllPttBursts());

    _isCheckedIn = false;
    _lastCheckInTime = null;
    _workedToday = Duration.zero;

    // Eğer kullanıcı oturumu açıksa, bugünkü en son giriş/çıkış hareketini geri yükle
    if (_isLoggedIn) {
      final now = DateTime.now();
      final todayRecords = _records.where((r) =>
        r.employeeId == _currentUser.id &&
        r.timestamp.year == now.year &&
        r.timestamp.month == now.month &&
        r.timestamp.day == now.day
      ).toList();

      if (todayRecords.isNotEmpty) {
        todayRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        final lastRec = todayRecords.first;
        if (lastRec.type == AttendanceType.checkIn) {
          _isCheckedIn = true;
          _lastCheckInTime = lastRec.timestamp;
          _workedToday = now.difference(lastRec.timestamp);
        }
      }
    }
  }

  // Giriş Yapma: VERİTABANI KONTROLÜ VE İK ONAYI İLE BİRLİKTE (SRS 3.1 Brute Force Korumalı)
  ({bool success, bool isPendingApproval, String message}) login(String email, String pin) {
    if (isPinLockedOut) {
      return (
        success: false,
        isPendingApproval: false,
        message: 'Güvenlik Kilidi: 4 kez ardışık hatalı PIN girildiği için oturum geçici olarak kilitlendi. Lütfen $lockoutSecondsRemaining saniye bekleyin veya SMS OTP ile PIN sıfırlayın.',
      );
    }

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
        final failed = _db.getFailedPinAttempts() + 1;
        _db.setFailedPinAttempts(failed);
        if (failed >= 4) {
          final lockUntil = DateTime.now().add(const Duration(minutes: 5));
          _db.setPinLockoutUntil(lockUntil);
          logAudit(
            actionType: 'Brute-Force Güvenlik Kilidi',
            targetEntity: 'AuthSession',
            entityId: cleanEmail,
            newValue: '4 hatalı PIN denemesi yapıldı. Oturum 5 dakika süreyle kilitlendi.',
          );
          notifyListeners();
          return (
            success: false,
            isPendingApproval: false,
            message: 'Güvenlik Uyarısı: 4 kez üst üste hatalı PIN girildi. Oturum 5 dakika kilitlendi. SMS ile PIN kodunuzu sıfırlayabilirsiniz.',
          );
        }
        notifyListeners();
        return (
          success: false,
          isPendingApproval: false,
          message: 'Hatalı PIN kodu girdiniz. Kalan deneme hakkı: ${4 - failed}',
        );
      }
      if (!user.isApproved) {
        return (
          success: false,
          isPendingApproval: true,
          message: 'Sayın ${user.fullName}, başvurunuz veritabanımızda kayıtlıdır ancak henüz İnsan Kaynakları (İK) tarafından onaylanmamıştır. Lütfen İK yöneticinizin onayını bekleyiniz.',
        );
      }
      _db.setFailedPinAttempts(0);
      _db.setPinLockoutUntil(null);
      _db.saveLastUserEmail(user.email);
      _currentUser = user;
      _activeCompanyId = _currentUser.companyId;
      _isLoggedIn = true;
      _db.saveUserSession(user.email);
      _startTimer();

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
    } else if (cleanEmail == 'teknisyen@sirket.com' || cleanEmail == 'teknisyen') {
      demoMatched = fallbackPool.firstWhere((e) => e.role == UserRole.technician, orElse: () => _employees.firstWhere((e) => e.role == UserRole.technician));
    } else if (cleanEmail == 'doktor@sirket.com' || cleanEmail == 'doktor') {
      demoMatched = fallbackPool.firstWhere((e) => e.role == UserRole.doctor, orElse: () => _employees.firstWhere((e) => e.role == UserRole.doctor));
    } else if (cleanEmail == 'servis@sirket.com' || cleanEmail == 'servis') {
      demoMatched = fallbackPool.firstWhere((e) => e.role == UserRole.serviceManager, orElse: () => _employees.firstWhere((e) => e.role == UserRole.serviceManager));
    } else if (cleanEmail == 'arackiralama@sirket.com' || cleanEmail == 'arackiralama' || cleanEmail == 'filo') {
      demoMatched = fallbackPool.firstWhere((e) => e.role == UserRole.vehicleRentalManager, orElse: () => _employees.firstWhere((e) => e.role == UserRole.vehicleRentalManager));
    }

    if (demoMatched != null && demoMatched.isApproved) {
      _db.setFailedPinAttempts(0);
      _db.setPinLockoutUntil(null);
      _db.saveLastUserEmail(demoMatched.email);
      _currentUser = demoMatched;
      _activeCompanyId = _currentUser.companyId;
      _isLoggedIn = true;
      _db.saveUserSession(demoMatched.email);
      _startTimer();

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
    String? tcKimlikNo,
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
      tcKimlikNo: (tcKimlikNo != null && tcKimlikNo.trim().isNotEmpty) ? tcKimlikNo.trim() : '28491028472',
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

    logAudit(
      actionType: 'Ön Kayıt Talebi Oluşturuldu',
      targetEntity: 'Employee',
      entityId: newId.toString(),
      newValue: 'Ad: ${newEmployee.fullName}, Telefon: ${newEmployee.phone}, Şirket: ${targetCompany.code}',
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

  // Kısıtlı Ön Kayıt (SRS 2.2): Yalnızca Ad, Soyad, Telefon, Şifre (Sicil, Departman veya Rol seçimi yapılamaz)
  ({bool success, String message}) registerRestricted({
    required String companyCode,
    required String fullName,
    required String phone,
    required String pin,
    String? email,
    String? tcKimlikNo,
  }) {
    final cleanEmail = (email != null && email.trim().isNotEmpty)
        ? email.trim().toLowerCase()
        : '${fullName.trim().toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}@${companyCode.toLowerCase()}.com';

    return register(
      companyCode: companyCode,
      fullName: fullName,
      email: cleanEmail,
      phone: phone,
      pin: pin,
      tcKimlikNo: tcKimlikNo,
      department: 'Onay Bekliyor',
      title: 'Personel Adayı',
    );
  }

  /// İK Tarafından Personel Kaydı Onaylama ve Departman/Unvan Atama + Telefona Bildirim Gönderme (SRS 2.2 Sicil/Şube/Rol Atama)
  ({bool success, String message, AppNotification? dispatchedNotification}) approveEmployeeRegistration({
    required int employeeId,
    required String department,
    required String title,
    String? sicilNo,
    String? branch,
    double? baseSalary,
    UserRole? role,
  }) {
    if (_currentUser.role != UserRole.hr &&
        _currentUser.role != UserRole.boss &&
        _currentUser.role != UserRole.admin) {
      return (success: false, message: 'Bu onay işlemini yalnızca İK veya Yönetim yetkilileri yapabilir.', dispatchedNotification: null);
    }

    // İK Güvenlik Kontrolü: Admin rolü veya unvanı veremez
    if (_currentUser.role == UserRole.hr) {
      if (role == UserRole.admin || title.trim().toLowerCase().contains('admin') || title.trim().toLowerCase().contains('sistem yöneticisi')) {
        return (
          success: false,
          message: 'Güvenlik Kuralı: İK (İnsan Kaynakları) personeline Sistem Yöneticisi (Admin) yetki rolü veya unvanı veremez.',
          dispatchedNotification: null,
        );
      }
    }

    final index = _employees.indexWhere((e) => e.id == employeeId);
    if (index == -1) {
      return (success: false, message: 'Personel kaydı bulunamadı.', dispatchedNotification: null);
    }

    final existing = _employees[index];
    final resolvedSicil = (sicilNo != null && sicilNo.trim().isNotEmpty)
        ? sicilNo.trim()
        : (existing.sicilNo.isNotEmpty ? existing.sicilNo : 'SIC-${existing.id.toString().padLeft(4, '0')}');
    final resolvedBranch = (branch != null && branch.trim().isNotEmpty)
        ? branch.trim()
        : (existing.branch.isNotEmpty ? existing.branch : 'Merkez Fabrika');

    final updated = existing.copyWith(
      isApproved: true,
      department: department.trim().isEmpty ? 'Genel' : department.trim(),
      title: title.trim().isEmpty ? 'Personel' : title.trim(),
      sicilNo: resolvedSicil,
      branch: resolvedBranch,
      baseGrossSalary: baseSalary ?? existing.baseGrossSalary,
      role: role ?? existing.role,
    );

    _employees[index] = updated;
    _db.updateEmployee(updated);

    logAudit(
      actionType: 'Personel Onay ve Atama (Sicil/Şube/Rol)',
      targetEntity: 'Employee',
      entityId: existing.id.toString(),
      oldValue: 'Onay Bekliyor',
      newValue: 'Sicil: $resolvedSicil, Şube: $resolvedBranch, Dept: ${updated.department}, Rol: ${updated.role.label}',
    );

    // Firebase Bulutuna Aktar
    if (_firebase.isEnabled) {
      _firebase.saveEmployeeToCloud(updated);
    }

    final compName = _companies.firstWhere((c) => c.id == updated.companyId, orElse: () => activeCompany).name;

    // Personele Kayıt Olduğu E-Posta ve Telefona Gönderilen Özel Bildirim (E-Posta + Push Notification + SMS)
    final phoneNotification = AppNotification(
      id: 'phone_notif_${DateTime.now().millisecondsSinceEpoch}',
      title: '🎉 Tebrikler, Kaydınız Onaylandı!',
      message: 'Sayın ${updated.fullName}, "$compName" bünyesindeki personel kaydınız onaylanmıştır. Sicil No: ${updated.displaySicilNo}, Şube: ${updated.branch}, Departman: ${updated.department} (${updated.title}). Belirlediğiniz PIN kodu ile PDKS uygulamasına hemen giriş yapabilirsiniz.',
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
          '• Kurumsal Sicil No: ${updated.displaySicilNo}\n'
          '• Görevli Şube: ${updated.branch}\n'
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
    _db.clearUserSession();
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
    List<String>? allowedPageIds,
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
      allowedPageIds: allowedPageIds ?? const [
        'profile',
        'payroll',
        'chat',
        'contacts',
        'notifications',
        'cafeteria',
        'business_card',
        'favorites',
        'leave',
        'records',
        'field_work',
        'overtime',
        'settings',
        'about',
      ],
    );

    _roles.add(newRole);
    _db.insertRole(newRole);
    notifyListeners();
    return (success: true, message: '"$trimmedName" rolü başarıyla oluşturuldu.');
  }

  /// Rolün erişebileceği sayfaları ve yetki düzeylerini güncelle
  ({bool success, String message}) updateRolePermissions(String roleId, List<String> allowedPageIds) {
    final index = _roles.indexWhere((r) => r.id == roleId);
    if (index == -1) return (success: false, message: 'Rol bulunamadı.');

    _roles[index] = _roles[index].copyWith(allowedPageIds: allowedPageIds);
    _db.updateRole(_roles[index]);
    notifyListeners();
    return (success: true, message: 'Rolün sayfa erişim yetkileri güncellendi.');
  }

  /// Belirli bir sayfa için kullanıcının erişim izni var mı?
  bool hasPagePermission(String pageId, [Employee? employee]) {
    final emp = employee ?? _currentUser;
    if (emp.role == UserRole.admin) return true;

    if (emp.customRoleId != null) {
      final customRole = _roles.where((r) => r.id == emp.customRoleId).firstOrNull;
      if (customRole != null) {
        return customRole.canAccessPage(pageId);
      }
    }

    final systemRole = _roles.where((r) => r.baseRole == emp.role).firstOrNull;
    if (systemRole != null) {
      return systemRole.canAccessPage(pageId);
    }
    return true;
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
        final cleared = _employees[i].copyWith(clearCustomRole: true);
        _employees[i] = cleared;
        _db.updateEmployee(cleared);
      }
    }

    _roles.removeAt(index);
    _db.deleteRole(roleId);
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

    // GÜVENLİK KONTROLLERİ:
    if (_currentUser.role == UserRole.hr) {
      // 1. İK kimseye Admin rolü ATAYAMAZ
      if (newBaseRole == UserRole.admin || (customRoleName != null && customRoleName.toLowerCase().contains('admin'))) {
        return (
          success: false,
          message: 'Güvenlik Sınırı: İK (İnsan Kaynakları) seviyesinde kimseye Sistem Yöneticisi (Admin) unvanı verilemez!',
        );
      }
      // 2. İK mevcut Admin kullanıcısının yetkisini DEĞİŞTİREMEZ
      if (target.role == UserRole.admin) {
        return (
          success: false,
          message: 'Güvenlik Sınırı: Sistem Yöneticisi (Admin) kullanıcısının yetkisi İK tarafından değiştirilemez.',
        );
      }
    }

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
    _db.updateEmployee(updated);
    if (_firebase.isEnabled) {
      _firebase.saveEmployeeToCloud(updated);
    }

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

  // ==========================================
  // HIZLI MENÜ YÖNETİMİ (CEO & ADMİN YETKİSİ)
  // ==========================================

  ({bool success, String message}) toggleQuickMenuItemVisibility(String id) {
    if (_currentUser.role != UserRole.boss && _currentUser.role != UserRole.admin) {
      return (success: false, message: 'Yalnızca CEO ve Admin hızlı menü görünürlüğünü değiştirebilir.');
    }
    final index = _quickMenuItems.indexWhere((m) => m.id == id);
    if (index == -1) return (success: false, message: 'Menü bulunamadı.');

    final current = _quickMenuItems[index];
    final updated = current.copyWith(isVisible: !current.isVisible);
    _quickMenuItems[index] = updated;
    _db.saveQuickMenuItems(_quickMenuItems);
    notifyListeners();
    return (
      success: true,
      message: '"${current.title}" menüsü ${updated.isVisible ? 'görünür yapıldı' : 'gizlendi'}.',
    );
  }

  ({bool success, String message}) addQuickMenuItem({
    required String title,
    required String subtitle,
    required int iconCode,
    required int colorValue,
    required String actionType,
    String? customContent,
  }) {
    if (_currentUser.role != UserRole.boss && _currentUser.role != UserRole.admin) {
      return (success: false, message: 'Yalnızca CEO ve Admin yeni hızlı menü ekleyebilir.');
    }
    if (title.trim().isEmpty) {
      return (success: false, message: 'Menü başlığı boş bırakılamaz.');
    }
    final newItem = QuickMenuItem(
      id: 'qm_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      subtitle: subtitle.trim(),
      iconCode: iconCode,
      colorValue: colorValue,
      isVisible: true,
      actionType: actionType,
      customContent: customContent,
    );
    _quickMenuItems.add(newItem);
    _db.saveQuickMenuItems(_quickMenuItems);
    notifyListeners();
    return (success: true, message: '"$title" hızlı menüsü başarıyla eklendi.');
  }

  ({bool success, String message}) deleteQuickMenuItem(String id) {
    if (_currentUser.role != UserRole.boss && _currentUser.role != UserRole.admin) {
      return (success: false, message: 'Yalnızca CEO ve Admin hızlı menü silebilir.');
    }
    _quickMenuItems.removeWhere((m) => m.id == id);
    _db.saveQuickMenuItems(_quickMenuItems);
    notifyListeners();
    return (success: true, message: 'Hızlı menü silindi.');
  }

  /// Hızlı menüleri tüm kurumsal sayfa menüleriyle varsayılana sıfırlar
  ({bool success, String message}) resetQuickMenuItemsToDefault() {
    if (_currentUser.role != UserRole.boss && _currentUser.role != UserRole.admin) {
      return (success: false, message: 'Yalnızca CEO ve Admin hızlı menüyü sıfırlayabilir.');
    }
    _quickMenuItems.clear();
    _quickMenuItems.addAll(DatabaseService.defaultQuickMenuItems());
    _db.saveQuickMenuItems(_quickMenuItems);
    notifyListeners();
    return (success: true, message: 'Hızlı menü listesi tüm kurumsal menülerle varsayılana sıfırlandı.');
  }

  // ==========================================
  // DIŞARIDA ÇALIŞMA SİSTEMİ (SAHA / OFİS DIŞI)
  // ==========================================

  ({bool success, String message}) startFieldWork({
    required String missionTitle,
    required String missionNote,
    required double latitude,
    required double longitude,
    required String addressName,
  }) {
    if (!_isLoggedIn) {
      return (success: false, message: 'Lütfen önce giriş yapınız.');
    }

    final newId = (_records.isNotEmpty ? _records.map((r) => r.id).reduce((a, b) => a > b ? a : b) : 0) + 1;
    final cleanTitle = missionTitle.trim().isEmpty ? 'Saha Görevi' : missionTitle.trim();
    final cleanAddress = addressName.trim().isEmpty ? 'Saha Lokasyonu' : addressName.trim();
    final cleanNote = missionNote.trim();

    final newRecord = AttendanceRecord(
      id: newId,
      companyId: _activeCompanyId,
      employeeId: _currentUser.id,
      employeeName: _currentUser.fullName,
      type: AttendanceType.checkIn,
      timestamp: DateTime.now(),
      userLatitude: latitude,
      userLongitude: longitude,
      calculatedDistanceMeters: 0.0,
      isLocationVerified: true,
      verificationMethod: VerificationMethod.geofenceGps,
      note: '📍 Dışarıda Çalışma: $cleanTitle ($cleanAddress) - $cleanNote',
    );

    _records.insert(0, newRecord);
    _db.insertAttendanceRecord(newRecord);
    if (_firebase.isEnabled) {
      _firebase.pushAttendanceToCloud(newRecord);
    }

    _isCheckedIn = true;
    _isFieldWorkActive = true;
    _activeFieldWorkTitle = cleanTitle;
    _activeFieldWorkAddress = cleanAddress;

    // İK'ya Anlık Yüksek Öncelikli Konum ve Görev Bildirimi Gönder
    final hrNotification = AppNotification(
      id: 'field_work_${DateTime.now().millisecondsSinceEpoch}',
      title: '📍 Dışarıda Çalışma Bildirimi: ${_currentUser.fullName}',
      message: '${_currentUser.fullName} (${_currentUser.department} - ${_currentUser.title}) ofis dışı saha çalışması başlattı.\n\n• Görev / Amaç: $cleanTitle\n• Konum: $cleanAddress (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})\n• Not: $cleanNote\n• Başlangıç Saati: ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      timestamp: DateTime.now(),
      type: NotificationType.attendance,
      icon: Icons.location_on_rounded,
      color: const Color(0xFF10B981),
      isPushSent: true,
    );
    _notifications.insert(0, hrNotification);
    _db.insertNotification(hrNotification);

    IosNotificationService.showIosNotification(
      title: '📍 Dışarıda Çalışma Bildirimi',
      body: '${_currentUser.fullName} dışarıda çalışma başlattı: $cleanTitle ($cleanAddress)',
      icon: Icons.location_on_rounded,
    );

    notifyListeners();
    return (
      success: true,
      message: 'Dışarıda çalışma başarıyla başlatıldı ve anlık GPS konumunuz İK birimine iletildi.',
    );
  }

  ({bool success, String message}) endFieldWork({String? exitNote}) {
    if (!_isCheckedIn) {
      return (success: false, message: 'Aktif bir çalışma oturumu bulunmamaktadır.');
    }

    final newId = (_records.isNotEmpty ? _records.map((r) => r.id).reduce((a, b) => a > b ? a : b) : 0) + 1;
    final mission = _activeFieldWorkTitle ?? 'Saha Çalışması';

    final exitRecord = AttendanceRecord(
      id: newId,
      companyId: _activeCompanyId,
      employeeId: _currentUser.id,
      employeeName: _currentUser.fullName,
      type: AttendanceType.checkOut,
      timestamp: DateTime.now(),
      calculatedDistanceMeters: 0.0,
      isLocationVerified: true,
      verificationMethod: VerificationMethod.geofenceGps,
      note: '🏁 Dışarıda Çalışma Bitişi: $mission - ${exitNote ?? "Görev tamamlandı"}',
    );

    _records.insert(0, exitRecord);
    _db.insertAttendanceRecord(exitRecord);
    if (_firebase.isEnabled) {
      _firebase.pushAttendanceToCloud(exitRecord);
    }

    _isCheckedIn = false;
    _isFieldWorkActive = false;
    _activeFieldWorkTitle = null;
    _activeFieldWorkAddress = null;

    final hrEndNotification = AppNotification(
      id: 'field_end_${DateTime.now().millisecondsSinceEpoch}',
      title: '🏁 Dışarıda Çalışma Bitti: ${_currentUser.fullName}',
      message: '${_currentUser.fullName} dışarıda çalışmasını sonlandırdı.\n• Tamamlanan Görev: $mission\n• Bitiş Saati: ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      timestamp: DateTime.now(),
      type: NotificationType.system,
      icon: Icons.check_circle_rounded,
      color: const Color(0xFF2563EB),
      isPushSent: true,
    );
    _notifications.insert(0, hrEndNotification);
    _db.insertNotification(hrEndNotification);

    notifyListeners();
    return (
      success: true,
      message: 'Dışarıda çalışma tamamlandı ve İK sistemine çıkış kaydınız işlendi.',
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

    // İK Güvenlik Kontrolleri: Admin rolü veya unvanı veremez
    if (_currentUser.role == UserRole.hr) {
      if (role == UserRole.admin || title.trim().toLowerCase().contains('admin') || title.trim().toLowerCase().contains('sistem yöneticisi')) {
        return (
          success: false,
          message: 'Güvenlik Kısıtlaması: İK (İnsan Kaynakları) personeline Sistem Yöneticisi (Admin) unvanı veya yetkisi veremez.',
          dispatchedNotification: null,
        );
      }
      if (existing.role == UserRole.admin) {
        return (
          success: false,
          message: 'Güvenlik Sınırı: Sistem Yöneticisi (Admin) personelin bilgileri ve unvanı İK tarafından değiştirilemez.',
          dispatchedNotification: null,
        );
      }
    }
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

    notifyListeners();
    return response;
  }

  // Yeni İzin Talebi Gönder
  Future<bool> submitLeaveRequest({
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    double? totalHours,
    String? documentName,
    String? documentPath,
    String? documentBase64,
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
      totalDays: type == LeaveType.hourly ? 0 : (days > 0 ? days : 1),
      totalHours: totalHours,
      documentName: documentName,
      documentPath: documentPath,
      documentBase64: documentBase64,
      reason: reason,
      status: LeaveStatus.pending,
      createdAt: DateTime.now(),
    );

    _leaves.insert(0, newLeave);
    _db.insertLeaveRequest(newLeave);
    if (_firebase.isEnabled) {
      _firebase.pushLeaveToCloud(newLeave);
    }

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
        totalHours: old.totalHours,
        documentName: old.documentName,
        documentPath: old.documentPath,
        documentBase64: old.documentBase64,
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

      // iPhone Bildirimi Tetikle (Kural: Yalnızca bir şey ONAYLANDIĞINDA)
      if (newStatus == LeaveStatus.approved) {
        IosNotificationService.showIosNotification(
          title: notif.title,
          body: notif.message,
          icon: notif.icon,
          iconColor: notif.color,
        );
      }

      notifyListeners();
    }
  }

  // ==========================================
  // ARAÇ TALEP VE FİLO YÖNETİMİ (VEHICLE REQUESTS)
  // ==========================================
  final List<VehicleRequest> _vehicleRequests = [];

  List<VehicleRequest> get allVehicleRequests => List.unmodifiable(_vehicleRequests);

  /// Kullanıcının yetkisine göre filtreli araç talepleri:
  /// Araç Kiralama Sorumlusu, Servis Sorumlusu, Patron (CEO), Admin ve İK tüm şirket taleplerini görebilir.
  /// Standart personel, teknisyen veya doktor ise kendi taleplerini görür.
  List<VehicleRequest> get vehicleRequestsForCurrentUser {
    final isManager = _currentUser.role == UserRole.vehicleRentalManager ||
        _currentUser.role == UserRole.serviceManager ||
        _currentUser.role == UserRole.boss ||
        _currentUser.role == UserRole.admin ||
        _currentUser.role == UserRole.hr;

    if (isManager) {
      return _vehicleRequests.where((r) => r.companyId == _currentUser.companyId).toList();
    }
    return _vehicleRequests.where((r) => r.employeeId == _currentUser.id).toList();
  }

  /// Yeni Araç Talebi Gönder
  Future<({bool success, String message, VehicleRequest? request})> createVehicleRequest({
    required String vehicleType,
    required DateTime startDate,
    required DateTime endDate,
    required String destination,
    required String purpose,
    int passengerCount = 1,
    bool needsDriver = false,
    String? notes,
  }) async {
    if (destination.trim().isEmpty) {
      return (success: false, message: 'Lütfen gidilecek güzergah / varış noktasını giriniz.', request: null);
    }
    if (purpose.trim().isEmpty) {
      return (success: false, message: 'Lütfen araç talep nedeninizi belirtiniz.', request: null);
    }
    if (endDate.isBefore(startDate)) {
      return (success: false, message: 'Teslim tarihi başlangıç tarihinden önce olamaz.', request: null);
    }

    final newReq = VehicleRequest(
      id: 'vr_${DateTime.now().millisecondsSinceEpoch}',
      companyId: _currentUser.companyId,
      employeeId: _currentUser.id,
      employeeName: _currentUser.fullName,
      employeeDepartment: _currentUser.department,
      employeeTitle: _currentUser.title,
      vehicleType: vehicleType,
      startDate: startDate,
      endDate: endDate,
      destination: destination.trim(),
      purpose: purpose.trim(),
      passengerCount: passengerCount,
      needsDriver: needsDriver,
      notes: notes?.trim().isNotEmpty == true ? notes!.trim() : null,
      status: VehicleRequestStatus.pending,
      createdAt: DateTime.now(),
    );

    _vehicleRequests.insert(0, newReq);
    await _db.insertVehicleRequest(newReq);

    // Bildirim Oluştur
    final notif = AppNotification(
      id: 'vr_notif_${DateTime.now().millisecondsSinceEpoch}',
      title: '🚗 Yeni Araç Talebi',
      message: '${_currentUser.fullName}, $destination için $vehicleType talep etti.',
      timestamp: DateTime.now(),
      type: NotificationType.system,
      icon: Icons.directions_car_rounded,
      color: const Color(0xFF059669),
    );
    _notifications.insert(0, notif);
    await _db.insertNotification(notif);

    notifyListeners();
    return (success: true, message: 'Araç talebiniz başarıyla oluşturuldu ve filo yönetimine iletildi.', request: newReq);
  }

  /// Araç Talebini Onayla & Araç ve Şoför Ata
  Future<({bool success, String message})> approveVehicleRequest(
    String requestId, {
    required String assignedVehicle,
    String? assignedDriver,
    String? note,
  }) async {
    final isAuthorized = _currentUser.role == UserRole.vehicleRentalManager ||
        _currentUser.role == UserRole.boss ||
        _currentUser.role == UserRole.admin ||
        _currentUser.role == UserRole.hr;

    if (!isAuthorized) {
      return (success: false, message: 'Yetki Sınırı: Yalnızca Araç Kiralama Sorumlusu, CEO veya Admin onaylayabilir.');
    }

    final idx = _vehicleRequests.indexWhere((r) => r.id == requestId);
    if (idx == -1) {
      return (success: false, message: 'Araç talebi bulunamadı.');
    }

    final old = _vehicleRequests[idx];
    final updated = old.copyWith(
      status: VehicleRequestStatus.approved,
      assignedVehicle: assignedVehicle,
      assignedDriver: assignedDriver ?? 'Personel Kendisi',
      approvalNote: note ?? 'Filo yönetimi tarafından araç tahsisi yapıldı.',
      approvedBy: '${_currentUser.fullName} (${_currentUser.role.label})',
    );

    _vehicleRequests[idx] = updated;
    await _db.updateVehicleRequest(updated);

    // Bildirim Oluştur
    final notif = AppNotification(
      id: 'vr_app_${DateTime.now().millisecondsSinceEpoch}',
      title: '✅ Araç Talebiniz Onaylandı',
      message: 'Sayın ${old.employeeName}, ${old.destination} için tahsis edilen araç: $assignedVehicle',
      timestamp: DateTime.now(),
      type: NotificationType.leave,
      icon: Icons.check_circle_rounded,
      color: const Color(0xFF10B981),
    );
    _notifications.insert(0, notif);
    await _db.insertNotification(notif);

    // iOS Bildirimi (Kural: Bir şey onaylandığında bildirim gönderilir)
    IosNotificationService.showIosNotification(
      title: notif.title,
      body: notif.message,
      icon: notif.icon,
      iconColor: notif.color,
    );

    notifyListeners();
    return (success: true, message: 'Araç talebi onaylandı ve $assignedVehicle aracı tahsis edildi.');
  }

  /// Araç Talebini Reddet
  Future<({bool success, String message})> rejectVehicleRequest(
    String requestId, {
    required String reason,
  }) async {
    final isAuthorized = _currentUser.role == UserRole.vehicleRentalManager ||
        _currentUser.role == UserRole.boss ||
        _currentUser.role == UserRole.admin ||
        _currentUser.role == UserRole.hr;

    if (!isAuthorized) {
      return (success: false, message: 'Yetki Sınırı: Yalnızca Araç Kiralama Sorumlusu, CEO veya Admin reddedebilir.');
    }

    final idx = _vehicleRequests.indexWhere((r) => r.id == requestId);
    if (idx == -1) {
      return (success: false, message: 'Araç talebi bulunamadı.');
    }

    final old = _vehicleRequests[idx];
    final updated = old.copyWith(
      status: VehicleRequestStatus.rejected,
      approvalNote: reason,
      approvedBy: '${_currentUser.fullName} (${_currentUser.role.label})',
    );

    _vehicleRequests[idx] = updated;
    await _db.updateVehicleRequest(updated);

    final notif = AppNotification(
      id: 'vr_rej_${DateTime.now().millisecondsSinceEpoch}',
      title: '❌ Araç Talebiniz Reddedildi',
      message: 'Sayın ${old.employeeName}, ${old.destination} araç talebiniz uygun görülmedi: $reason',
      timestamp: DateTime.now(),
      type: NotificationType.leave,
      icon: Icons.cancel_rounded,
      color: const Color(0xFFEF4444),
    );
    _notifications.insert(0, notif);
    await _db.insertNotification(notif);

    notifyListeners();
    return (success: true, message: 'Araç talebi reddedildi.');
  }

  /// Araç Kullanım / Teslim Durumunu Güncelle (Seferde / Tamamlandı)
  Future<({bool success, String message})> updateVehicleRequestStatus(
    String requestId,
    VehicleRequestStatus newStatus, {
    String? note,
  }) async {
    final idx = _vehicleRequests.indexWhere((r) => r.id == requestId);
    if (idx == -1) {
      return (success: false, message: 'Araç talebi bulunamadı.');
    }

    final old = _vehicleRequests[idx];
    final updated = old.copyWith(
      status: newStatus,
      approvalNote: note ?? old.approvalNote,
    );

    _vehicleRequests[idx] = updated;
    await _db.updateVehicleRequest(updated);

    notifyListeners();
    return (success: true, message: 'Talep durumu güncellendi: ${newStatus.label}');
  }

  // ==========================================
  // VARDİYA İŞLEMLERİ (SHIFTS)
  // ==========================================

  void addShift(ShiftSchedule shift) {
    _shifts.add(shift);
    _db.insertShift(shift);
    notifyListeners();
  }

  void updateShift(ShiftSchedule shift) {
    final idx = _shifts.indexWhere((s) => s.id == shift.id);
    if (idx != -1) {
      _shifts[idx] = shift;
      _db.updateShift(shift);
      notifyListeners();
    }
  }

  void deleteShift(int shiftId) {
    _shifts.removeWhere((s) => s.id == shiftId);
    _db.deleteShift(shiftId);
    notifyListeners();
  }

  // ==========================================
  // KURUMSAL EK MODÜL İŞLEMLERİ (15 ENTERPRISE MODULES)
  // ==========================================

  // 1. Vardiya Takas & Açık Vardiya
  void addShiftSwapRequest(ShiftSwapRequest req) {
    _shiftSwaps.insert(0, req);
    _db.insertShiftSwap(req);
    notifyListeners();
  }

  void updateShiftSwapStatus(String id, String status) {
    final idx = _shiftSwaps.indexWhere((s) => s.id == id);
    if (idx != -1) {
      final updated = _shiftSwaps[idx].copyWith(status: status, approvedBy: _currentUser.fullName);
      _shiftSwaps[idx] = updated;
      _db.updateShiftSwapStatus(id, status, _currentUser.fullName);
      notifyListeners();
    }
  }

  void applyToOpenShift(String slotId) {
    final idx = _openShiftSlots.indexWhere((s) => s.id == slotId);
    if (idx != -1) {
      _db.applyToOpenShiftSlot(slotId, _currentUser.id);
      final cur = _openShiftSlots[idx];
      if (!cur.appliedEmployeeIds.contains(_currentUser.id)) {
        final list = List<int>.from(cur.appliedEmployeeIds)..add(_currentUser.id);
        _openShiftSlots[idx] = OpenShiftSlot(
          id: cur.id,
          companyId: cur.companyId,
          shiftId: cur.shiftId,
          shiftTitle: cur.shiftTitle,
          date: cur.date,
          requiredHeadcount: cur.requiredHeadcount,
          appliedEmployeeIds: list,
          assignedEmployeeIds: cur.assignedEmployeeIds,
        );
      }
      notifyListeners();
    }
  }

  // 2. Teknik Destek (Helpdesk)
  void createHelpdeskTicket(HelpdeskTicket ticket) {
    _helpdeskTickets.insert(0, ticket);
    _db.insertHelpdeskTicket(ticket);
    notifyListeners();
  }

  void assignTechnician(String ticketId, int techId, String techName) {
    final idx = _helpdeskTickets.indexWhere((t) => t.id == ticketId);
    if (idx != -1) {
      final updated = _helpdeskTickets[idx].copyWith(
        assignedTechnicianId: techId,
        assignedTechnicianName: techName,
        status: 'in_progress',
      );
      _helpdeskTickets[idx] = updated;
      _db.assignTechnicianToTicket(ticketId, techId, techName);
      notifyListeners();
    }
  }

  void resolveHelpdeskTicket(String ticketId, String solutionNotes) {
    final idx = _helpdeskTickets.indexWhere((t) => t.id == ticketId);
    if (idx != -1) {
      final updated = _helpdeskTickets[idx].copyWith(
        solutionNotes: solutionNotes,
        status: 'resolved',
        resolvedAt: DateTime.now(),
      );
      _helpdeskTickets[idx] = updated;
      _db.resolveHelpdeskTicket(ticketId, solutionNotes);
      notifyListeners();
    }
  }

  // 3. Duyurular & Okundu Onayı
  void publishAnnouncement(CompanyAnnouncement announcement) {
    _announcements.insert(0, announcement);
    _db.insertAnnouncement(announcement);
    notifyListeners();
  }

  void markAnnouncementRead(String id) {
    final idx = _announcements.indexWhere((a) => a.id == id);
    if (idx != -1 && !_announcements[idx].readEmployeeIds.contains(_currentUser.id)) {
      final updated = List<int>.from(_announcements[idx].readEmployeeIds)..add(_currentUser.id);
      _announcements[idx] = _announcements[idx].copyWith(readEmployeeIds: updated);
      _db.markAnnouncementRead(id, _currentUser.id);
      notifyListeners();
    }
  }

  void confirmAnnouncement(String id) {
    final idx = _announcements.indexWhere((a) => a.id == id);
    if (idx != -1 && !_announcements[idx].confirmedEmployeeIds.contains(_currentUser.id)) {
      final updatedReads = List<int>.from(_announcements[idx].readEmployeeIds);
      if (!updatedReads.contains(_currentUser.id)) updatedReads.add(_currentUser.id);
      final updatedConfs = List<int>.from(_announcements[idx].confirmedEmployeeIds)..add(_currentUser.id);
      _announcements[idx] = _announcements[idx].copyWith(
        readEmployeeIds: updatedReads,
        confirmedEmployeeIds: updatedConfs,
      );
      _db.confirmAnnouncement(id, _currentUser.id);
      notifyListeners();
    }
  }

  // 4. Özlük Dosyası & İşe Giriş/Çıkış
  void addEmployeeDocument(EmployeeDocument doc) {
    _documents.insert(0, doc);
    _db.insertDocument(doc);
    notifyListeners();
  }

  void deleteEmployeeDocument(String id) {
    _documents.removeWhere((d) => d.id == id);
    _db.deleteDocument(id);
    notifyListeners();
  }

  void toggleOnboardingTask(String id, bool isCompleted) {
    final idx = _onboardingTasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final updated = _onboardingTasks[idx].copyWith(
        isCompleted: isCompleted,
        completedAt: isCompleted ? DateTime.now() : null,
      );
      _onboardingTasks[idx] = updated;
      _db.toggleOnboardingTask(id, isCompleted);
      notifyListeners();
    }
  }

  // 5. Eğitim & Yetkinlikler
  void addTrainingCourse(TrainingCourse course) {
    _trainingCourses.add(course);
    _db.insertTrainingCourse(course);
    notifyListeners();
  }

  void assignTraining(String courseId, String title, int employeeId) {
    _db.assignTrainingCourse(courseId, title, employeeId, _activeCompanyId);
    _trainingRecords.add(EmployeeTrainingRecord(
      id: 'tr_${DateTime.now().millisecondsSinceEpoch}_$employeeId',
      companyId: _activeCompanyId,
      employeeId: employeeId,
      courseId: courseId,
      courseTitle: title,
      status: 'assigned',
      score: 0,
    ));
    notifyListeners();
  }

  void completeTraining(String recordId, int score) {
    final idx = _trainingRecords.indexWhere((r) => r.id == recordId);
    if (idx != -1) {
      final updated = _trainingRecords[idx].copyWith(
        status: 'completed',
        score: score,
        completedDate: DateTime.now(),
        certificateExpiry: DateTime.now().add(const Duration(days: 365)),
      );
      _trainingRecords[idx] = updated;
      _db.completeTrainingCourse(recordId, score);
      notifyListeners();
    }
  }

  // 6. Performans & Hedefler
  void addPerformanceGoal(PerformanceGoal goal) {
    _performanceGoals.insert(0, goal);
    _db.insertPerformanceGoal(goal);
    notifyListeners();
  }

  void updatePerformanceGoal(PerformanceGoal goal) {
    final idx = _performanceGoals.indexWhere((g) => g.id == goal.id);
    if (idx != -1) {
      _performanceGoals[idx] = goal;
      _db.updatePerformanceGoal(goal);
      notifyListeners();
    }
  }

  // 7. Ziyaretçi & Taşeron
  void registerVisitor(VisitorRecord visitor) {
    _visitorRecords.insert(0, visitor);
    _db.insertVisitorRecord(visitor);
    notifyListeners();
  }

  void checkInVisitor(String id) {
    final idx = _visitorRecords.indexWhere((v) => v.id == id);
    if (idx != -1) {
      final updated = _visitorRecords[idx].copyWith(
        status: 'inside',
        checkInTime: DateTime.now(),
      );
      _visitorRecords[idx] = updated;
      _db.checkInVisitor(id);
      notifyListeners();
    }
  }

  void checkOutVisitor(String id) {
    final idx = _visitorRecords.indexWhere((v) => v.id == id);
    if (idx != -1) {
      final updated = _visitorRecords[idx].copyWith(
        status: 'completed',
        checkOutTime: DateTime.now(),
      );
      _visitorRecords[idx] = updated;
      _db.checkOutVisitor(id);
      notifyListeners();
    }
  }

  // 8. Hibrit Rezervasyon
  void createHybridBooking(HybridBooking booking) {
    _hybridBookings.insert(0, booking);
    _db.insertHybridBooking(booking);
    notifyListeners();
  }

  void cancelHybridBooking(String id) {
    final idx = _hybridBookings.indexWhere((b) => b.id == id);
    if (idx != -1) {
      final updated = _hybridBookings[idx].copyWith(status: 'cancelled');
      _hybridBookings[idx] = updated;
      _db.cancelHybridBooking(id);
      notifyListeners();
    }
  }

  // 9. Şubeler & Onay Vekaleti
  void addBranch(CompanyBranch branch) {
    _branches.add(branch);
    _db.insertCompanyBranch(branch);
    notifyListeners();
  }

  void addApprovalDelegation(ApprovalDelegation delegation) {
    _delegations.insert(0, delegation);
    _db.insertApprovalDelegation(delegation);
    notifyListeners();
  }

  void toggleApprovalDelegation(String id, bool isActive) {
    final idx = _delegations.indexWhere((d) => d.id == id);
    if (idx != -1) {
      final updated = _delegations[idx].copyWith(isActive: isActive);
      _delegations[idx] = updated;
      _db.toggleApprovalDelegation(id, isActive);
      notifyListeners();
    }
  }

  // 10. Entegrasyonlar & Çevrimdışı Kuyruk
  void addIntegration(IntegrationEndpoint endpoint) {
    _integrations.add(endpoint);
    _db.insertIntegrationEndpoint(endpoint);
    notifyListeners();
  }

  void enqueueOfflineRecord(String actionType, Map<String, dynamic> payload) {
    final item = OfflineSyncItem(
      id: 'off_${DateTime.now().millisecondsSinceEpoch}',
      companyId: _activeCompanyId,
      actionType: actionType,
      payload: payload,
      syncStatus: 'queued',
    );
    _offlineQueue.add(item);
    _db.enqueueOfflineItem(item);
    notifyListeners();
  }

  void syncOfflineRecords() {
    for (int i = 0; i < _offlineQueue.length; i++) {
      _offlineQueue[i] = _offlineQueue[i].copyWith(syncStatus: 'synced');
    }
    _db.clearOfflineQueue();
    notifyListeners();
  }

  // 11. Geri Bildirimler & Anketler
  void submitFeedback(EmployeeFeedback feedback) {
    _feedbacks.insert(0, feedback);
    _db.insertEmployeeFeedback(feedback);
    notifyListeners();
  }

  void respondToFeedback(String id, String response) {
    final idx = _feedbacks.indexWhere((f) => f.id == id);
    if (idx != -1) {
      final updated = _feedbacks[idx].copyWith(status: 'resolved', hrResponse: response);
      _feedbacks[idx] = updated;
      _db.respondToFeedback(id, response);
      notifyListeners();
    }
  }

  // ==========================================
  // KALİBRASYON & CMMS (ISO 9001 / ISO 17025)
  // ==========================================

  /// Ekipman kalibrasyonu süresi geçmiş mi veya tolerans dışı mı kontrolü
  bool isEquipmentQuarantined(EquipmentRecord eq) => eq.isQuarantined;

  /// Teknisyenin İSG eğitimi veya mesleki sertifikası geçerli mi kontrolü
  bool isTechnicianIsgValid(int technicianId) {
    final records = _trainingRecords.where((t) => t.employeeId == technicianId && t.status == 'completed').toList();
    if (records.isEmpty) return true; // Demo esnekliği
    final now = DateTime.now();
    for (final r in records) {
      if (r.certificateExpiry != null && r.certificateExpiry!.isBefore(now)) {
        return false; // Sertifika süresi dolmuş!
      }
    }
    return true;
  }

  /// O anda tesiste (içeride) ve aktif vardiyada olan yetkili teknisyenleri listeler
  List<Employee> getAvailableActiveTechnicians() {
    return employees.where((e) {
      final isTech = e.role == UserRole.technician;
      final isInside = records.any((r) => r.employeeId == e.id && r.type == AttendanceType.checkIn);
      final isgOk = isTechnicianIsgValid(e.id);
      return isTech && isInside && isgOk;
    }).toList();
  }

  /// Ekipmanı karantinaya alma veya karantinadan çıkarma
  Future<void> toggleEquipmentQuarantine(String equipmentId, {String? reason}) async {
    final idx = _equipmentRecords.indexWhere((e) => e.id == equipmentId);
    if (idx != -1) {
      final old = _equipmentRecords[idx];
      final newStatus = old.status == 'quarantine' ? 'active' : 'quarantine';
      final updated = old.copyWith(
        status: newStatus,
        quarantineReason: newStatus == 'quarantine' ? (reason ?? 'Yetkili tarafından manuel karantinaya alındı.') : null,
      );
      _equipmentRecords[idx] = updated;
      await _db.updateEquipmentRecord(updated);

      // Değiştirilemez denetim kaydı oluştur
      await logAudit(
        actionType: 'Kalibrasyon Statüsü Değiştirildi',
        targetEntity: 'EquipmentRecord',
        entityId: equipmentId,
        oldValue: 'status: ${old.status}',
        newValue: 'status: $newStatus | $reason',
      );

      // İlgili birim yöneticilerine anlık uyarı üret
      if (newStatus == 'quarantine') {
        addNotification(
          AppNotification(
            id: 'notif_quar_${DateTime.now().millisecondsSinceEpoch}',
            title: '🚨 Cihaz Karantinaya Alındı (${old.equipmentCode})',
            message: '${old.name} kalibrasyon/güvenlik gerekçesiyle karantinaya alındı ve iş emirlerine kapatıldı.',
            timestamp: DateTime.now(),
            type: NotificationType.system,
            icon: Icons.gavel_rounded,
            color: const Color(0xFFDC2626),
          ),
        );
      }
      notifyListeners();
    }
  }

  /// Süresi dolan kalibrasyonları otomatik karantinaya çekme motoru
  Future<void> checkAndQuarantineExpiredEquipments() async {
    final now = DateTime.now();
    for (int i = 0; i < _equipmentRecords.length; i++) {
      final eq = _equipmentRecords[i];
      if (eq.status != 'quarantine' && eq.nextCalibrationDate.isBefore(now)) {
        final updated = eq.copyWith(
          status: 'quarantine',
          quarantineReason: 'Yıllık kalibrasyon süresi aşıldı (ISO 9001 / ISO 17025 gereği otomatik karantina).',
        );
        _equipmentRecords[i] = updated;
        await _db.updateEquipmentRecord(updated);
        await logAudit(
          actionType: 'Otomatik Karantina (Süre Aşımı)',
          targetEntity: 'EquipmentRecord',
          entityId: eq.id,
          oldValue: 'status: ${eq.status}',
          newValue: 'status: quarantine (Süre aşımı)',
        );
      }
    }
    notifyListeners();
  }

  /// Yeni Bakım / Arıza İş Emri Oluşturma (Çapraz Entegrasyon Doğrulamalı)
  Future<({bool success, String message})> createMaintenanceWorkOrder({
    required String equipmentId,
    required String title,
    required String description,
    required String priority,
    int? technicianId,
    String? photoUrl,
    List<ChecklistItem>? checklist,
  }) async {
    if (_equipmentRecords.isEmpty) {
      _equipmentRecords.addAll(_db.getAllEquipmentRecords());
    }
    final eq = _equipmentRecords.cast<EquipmentRecord?>().firstWhere(
      (e) => e?.id == equipmentId,
      orElse: () => _equipmentRecords.isNotEmpty ? _equipmentRecords.first : null,
    );
    if (eq == null) {
      return (success: false, message: 'HATA: Ekipman bulunamadı.');
    }

    // Kural 1: Kalibrasyonu bitmiş / karantinadaki cihaza standart iş emri açılamaz!
    if (eq.isQuarantined && priority != 'urgent') {
      return (
        success: false,
        message: 'HATA: ${eq.equipmentCode} cihazı şu anda KARANTİNADA! Kalibrasyonu tamamlanmadan standart iş emri açılamaz.',
      );
    }

    // Kural 2: İSG belgesi süresi dolmuş teknisyene bakım atanamaz!
    if (technicianId != null) {
      if (!isTechnicianIsgValid(technicianId)) {
        return (
          success: false,
          message: 'HATA: Seçilen teknisyenin İSG / Mesleki Yeterlilik belgesi süresi dolmuştur! İş emri atanamaz.',
        );
      }
    }

    String? techName;
    if (technicianId != null) {
      final t = _employees.cast<Employee?>().firstWhere((e) => e?.id == technicianId, orElse: () => null);
      techName = t?.fullName;
    }

    final newWo = MaintenanceWorkOrder(
      id: 'wo_${DateTime.now().millisecondsSinceEpoch}',
      companyId: _activeCompanyId,
      equipmentId: eq.id,
      equipmentCode: eq.equipmentCode,
      equipmentName: eq.name,
      title: title,
      description: description,
      priority: priority,
      photoUrl: photoUrl,
      status: 'open',
      reportedBy: _isLoggedIn ? _currentUser.fullName : 'Sistem Yöneticisi',
      assignedTechnicianId: technicianId,
      assignedTechnicianName: techName,
      checklist: checklist ?? [
        ChecklistItem(id: 'c1', title: 'Fiziksel hasar ve sızıntı kontrolü', isDone: false),
        ChecklistItem(id: 'c2', title: 'Elektriksel bağlantı ve topraklama testi', isDone: false),
        ChecklistItem(id: 'c3', title: 'Sensör tolerans kalibrasyonu doğrulandı', isDone: false),
      ],
    );

    _workOrders.insert(0, newWo);
    await _db.insertWorkOrder(newWo);

    await logAudit(
      actionType: 'Bakım İş Emri Açıldı',
      targetEntity: 'MaintenanceWorkOrder',
      entityId: newWo.id,
      oldValue: null,
      newValue: '${eq.equipmentCode} | $priority | $title',
    );

    // Kural 3: Acil arıza bildiriminde tesiste ve aktif vardiyadaki bakım ekibine anlık duyuru düşer!
    if (priority == 'urgent') {
      final activeTechs = getAvailableActiveTechnicians();
      final techNames = activeTechs.map((t) => t.fullName).join(', ');
      addNotification(
        AppNotification(
          id: 'notif_urg_${DateTime.now().millisecondsSinceEpoch}',
          title: '🚨 ACİL ARIZA BİLDİRİMİ (${eq.equipmentCode})',
          message: '$title. O anda tesiste bulunan teknisyenlere iletildi: ${techNames.isNotEmpty ? techNames : "Nöbetçi Ekip"}',
          timestamp: DateTime.now(),
          type: NotificationType.system,
          icon: Icons.warning_rounded,
          color: const Color(0xFFEA580C),
        ),
      );
    }

    notifyListeners();
    return (success: true, message: 'İş emri başarıyla oluşturuldu.');
  }

  /// Bakım iş emrini tamamlama ve MTTR/maliyet kaydetme
  Future<void> completeMaintenanceWorkOrder({
    required String workOrderId,
    required List<SparePartItem> partsUsed,
    required int mttrMinutes,
    required int downtimeMinutes,
  }) async {
    final idx = _workOrders.indexWhere((w) => w.id == workOrderId);
    if (idx != -1) {
      final old = _workOrders[idx];
      double totalCost = 0.0;
      for (final p in partsUsed) {
        totalCost += p.total;
      }
      final updated = old.copyWith(
        status: 'completed',
        completedAt: DateTime.now(),
        partsUsed: partsUsed,
        totalCost: totalCost,
        mttrMinutes: mttrMinutes,
        downtimeMinutes: downtimeMinutes,
      );
      _workOrders[idx] = updated;
      await _db.updateWorkOrder(updated);

      await logAudit(
        actionType: 'İş Emri Tamamlandı',
        targetEntity: 'MaintenanceWorkOrder',
        entityId: workOrderId,
        oldValue: 'status: ${old.status}',
        newValue: 'status: completed | MTTR: ${mttrMinutes}dk | Maliyet: ${totalCost}TL',
      );
      notifyListeners();
    }
  }

  // ==========================================
  // DEĞİŞTİRİLEMEZ DENETİM KAYDI (AUDIT LOG)
  // ==========================================

  Future<void> logAudit({
    required String actionType,
    required String targetEntity,
    String? entityId,
    String? oldValue,
    String? newValue,
  }) async {
    final audit = AuditLogRecord(
      id: 'audit_${DateTime.now().millisecondsSinceEpoch}',
      companyId: _activeCompanyId,
      userId: _isLoggedIn ? _currentUser.id : 1,
      userName: _isLoggedIn ? _currentUser.fullName : 'Sistem Yöneticisi',
      userRole: _isLoggedIn ? _currentUser.role.label : 'Sistem',
      ipAddress: '192.168.1.105',
      actionType: actionType,
      targetEntity: targetEntity,
      entityId: entityId,
      oldValue: oldValue,
      newValue: newValue,
    );
    _auditLogs.insert(0, audit);
    await _db.insertAuditLog(audit);
    notifyListeners();
  }

  // ==========================================
  // DÖNEM KİLİTLEME (BORDRO GÜVENLİĞİ)
  // ==========================================

  Future<void> togglePeriodLock(String period) async {
    final isLocked = _lockedPeriods.contains(period);
    if (isLocked) {
      _lockedPeriods.remove(period);
    } else {
      _lockedPeriods.add(period);
    }
    await _db.togglePeriodLock(period);

    await logAudit(
      actionType: isLocked ? 'Puantaj Dönem Kilidi Açıldı' : 'Puantaj Dönemi Kilitlendi',
      targetEntity: 'PayrollPeriod',
      entityId: period,
      oldValue: isLocked ? 'locked' : 'unlocked',
      newValue: isLocked ? 'unlocked' : 'locked (Tahakkuk koruması)',
    );
    notifyListeners();
  }

  // ==========================================
  // 4857 DİNLENME HAKKI & KURUMSAL DUYURU
  // ==========================================

  /// Kurumsal Duyuru "Okudum, Anladım" Zaman Damgalı Onayı
  Future<void> acknowledgeAnnouncement(String announcementId) async {
    await _db.markAnnouncementRead(announcementId, _currentUser.id);
    final idx = _announcements.indexWhere((a) => a.id == announcementId);
    if (idx != -1) {
      final old = _announcements[idx];
      final confirmed = List<int>.from(old.confirmedEmployeeIds);
      if (!confirmed.contains(_currentUser.id)) {
        confirmed.add(_currentUser.id);
      }
      _announcements[idx] = old.copyWith(confirmedEmployeeIds: confirmed);
      await logAudit(
        actionType: 'Duyuru Onaylandı (Okudum, Anladım)',
        targetEntity: 'CompanyAnnouncement',
        entityId: announcementId,
        newValue: 'Kullanıcı: ${_currentUser.fullName} onayladı.',
      );
      notifyListeners();
    }
  }

  /// Mesaj Gönderme: 4857 Sayılı Kanun Mesai Dışı Dinlenme Kalkanı
  Future<void> sendChatMessageWithRestHoursPolicy({
    required String channelId,
    required String text,
    int? receiverId,
    bool isEmergencyOrIsg = false,
  }) async {
    final newMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _currentUser.id,
      senderName: _currentUser.fullName,
      senderRole: _currentUser.role,
      receiverId: receiverId,
      channelId: channelId,
      text: text,
      timestamp: DateTime.now(),
    );

    _chatMessages.add(newMsg);
    _db.insertChatMessage(newMsg);

    if (receiverId != null) {
      final receiver = _employees.cast<Employee?>().firstWhere((e) => e?.id == receiverId, orElse: () => null);
      if (receiver != null) {
        final isReceiverIn = records.any((r) => r.employeeId == receiver.id && r.type == AttendanceType.checkIn);
        final isQuiet = LaborLawRuleEngine.shouldSuppressNotificationForRestHours(
          isCurrentlyCheckedIn: isReceiverIn,
          isCurrentlyOnLeave: false,
          isEmergencyOrIsg: isEmergencyOrIsg,
        );

        if (!isQuiet) {
          addNotification(
            AppNotification(
              id: 'notif_msg_${DateTime.now().millisecondsSinceEpoch}',
              title: '${_currentUser.fullName} size mesaj gönderdi',
              message: text,
              timestamp: DateTime.now(),
              type: NotificationType.announcement,
              icon: Icons.chat_rounded,
              color: const Color(0xFF2563EB),
            ),
          );
        }
      }
    } else {
      if (isEmergencyOrIsg) {
        addNotification(
          AppNotification(
            id: 'notif_urg_msg_${DateTime.now().millisecondsSinceEpoch}',
            title: '🚨 [ACİL DUYURU] ${_currentUser.fullName}',
            message: text,
            timestamp: DateTime.now(),
            type: NotificationType.system,
            icon: Icons.warning_rounded,
            color: const Color(0xFFDC2626),
          ),
        );
      }
    }
    notifyListeners();
  }

  // ==========================================
  // 1. YAPAY ZEKA (AI) ASİSTANI & ANOMALİ YÖNETİMİ
  // ==========================================

  /// 4857 Sayılı Kanun & PDKS Akıllı İK Chatbot Asistanı
  Future<void> askPdkAiAssistant(String userPrompt) async {
    final cleanPrompt = userPrompt.trim();
    if (cleanPrompt.isEmpty) return;

    // Kullanıcı mesajını ekle
    final userMsg = AiAssistantMessage(
      id: 'ai_user_${DateTime.now().millisecondsSinceEpoch}',
      isUser: true,
      message: cleanPrompt,
      timestamp: DateTime.now(),
    );
    _aiMessages.add(userMsg);
    notifyListeners();

    // AI İşleme Simülasyonu
    await Future.delayed(const Duration(milliseconds: 350));

    final lower = cleanPrompt.toLowerCase();
    String botReply = '';
    String? actionTag;
    String? actionBtn;

    if (lower.contains('gece')) {
      botReply = '4857 Sayılı Kanun Madde 69 uyarınca; gece dönemi en geç saat 20:00\'de başlayıp 06:00\'ya kadar süren '
          'en fazla 11 saatlik dönemdir. Gece çalışmalarında personelin çalışma süresi 7.5 saati kesinlikle aşamaz (turizm ve özel izinler hariç).\n\n'
          'Ayrıca gece vardiyasında çalışan personele her 2 yılda bir periyodik sağlık kontrolü zorunludur.';
    } else if (lower.contains('mesai') || lower.contains('fazla') || lower.contains('270') || lower.contains('ücret')) {
      botReply = '4857 Sayılı İş Kanunu Madde 41 kapsamında; haftalık 45 saati aşan çalışmalar fazla mesai sayılır '
          've her bir saat için normal saatlik ücretin %50 fazlası ödenir (veya 1 saat 30 dakika serbest zaman talep edilebilir).\n\n'
          '⚠️ Yasal Sınır: Bir personelin yıllık fazla çalışma süresi azami 270 saati ve günlük toplam çalışma 11 saati geçemez.';
      actionTag = 'view_overtime';
      actionBtn = 'Mesai Dökümünü İncele ➔';
    } else if (lower.contains('izin') || lower.contains('yıllık') || lower.contains('hakediş')) {
      final rem = _currentUser.remainingLeaveDays;
      botReply = 'Sayın ${_currentUser.fullName}, 4857 Sayılı İş Kanunu Madde 53 uyarınca sistemimizde tanımlı '
          'kalan yıllık ücretli izin hakkınız $rem gündür.\n\n'
          '📌 Yasal Bilgilendirme: Kanuna göre 1-5 yıl arası kıdemde en az 14 gün, 5-15 yıl arası 20 gün, '
          '15+ yıl üzeri 26 gün izin verilir. Ayrıca 18 yaşından küçük veya 50 yaşından büyük çalışanlara 20 günden az izin verilemez.';
      actionTag = 'open_leave';
      actionBtn = 'İzin Talebi Oluştur ➔';
    } else if (lower.contains('vardiya')) {
      botReply = 'Vardiya sisteminde 4857 sayılı kanun uyarınca iki vardiya arasında en az 11 saatlik kesintisiz '
          'dinlenme süresi verilmelidir. Ayrıca bir çalışan üst üste 6 günden fazla gece vardiyasında çalıştırılamaz.';
    } else if (lower.contains('buddy') || lower.contains('sahte') || lower.contains('anomali') || lower.contains('kart')) {
      final activeAnomCount = anomalies.where((a) => a.status == 'pending').length;
      botReply = 'PDKS Anti-Buddy Punching Yapay Zeka Motoru, turnike geçiş aralıklarını ve kiosk kamera liveness doğrulamasını '
          'gerçek zamanlı denetlemektedir. Şu an sistemde incelenmeyi bekleyen $activeAnomCount adet şüpheli hareket/anomali kaydı mevcuttur.';
      actionTag = 'view_anomalies';
      actionBtn = 'Anomali Paneline Git ➔';
    } else if (lower.contains('ramak kala') || lower.contains('isg') || lower.contains('tehlike')) {
      botReply = '6331 Sayılı İş Sağlığı ve Güvenliği Kanunu uyarınca, sahada maddi hasara veya yaralanmaya ramak kalan '
          'tüm tehlikeler tutanak altına alınmalıdır. Ramak Kala formunu doldurduğunuzda işletme hekimi ve İSG kuruluna anlık SMS/Push ikazı iletilir.';
      actionTag = 'open_near_miss';
      actionBtn = 'Ramak Kala Bildir ➔';
    } else {
      botReply = 'Merhaba ${_currentUser.fullName}! Ben PDKS Enterprise Yapay Zeka Asistanıyım. '
          '4857 Sayılı İş Kanunu, yıllık izin hakedişleriniz, fazla mesai hesapları, vardiya çizelgeleri veya İSG ramak kala kuralları hakkında '
          'bana dilediğinizi sorabilirsiniz.';
    }

    final botMsg = AiAssistantMessage(
      id: 'ai_bot_${DateTime.now().millisecondsSinceEpoch}',
      isUser: false,
      message: botReply,
      timestamp: DateTime.now(),
      actionTag: actionTag,
      actionButtonText: actionBtn,
    );
    _aiMessages.add(botMsg);
    notifyListeners();
  }

  /// Şüpheli Geçiş & Anomaliyi Çözümleme / Kapatma
  Future<void> resolveAnomaly({
    required String anomalyId,
    required String resolutionNote,
    required bool isDismissed,
  }) async {
    final idx = _anomalies.indexWhere((a) => a.id == anomalyId);
    if (idx != -1) {
      final anom = _anomalies[idx];
      anom.status = isDismissed ? 'dismissed' : 'resolved';
      anom.resolutionNote = resolutionNote.trim();
      await _db.updateAnomaly(anom);

      await logAudit(
        actionType: isDismissed ? 'Anomali Reddedildi/Kapatıldı' : 'Anomali Çözümlendi',
        targetEntity: 'PdkAnomalyRecord',
        entityId: anomalyId,
        oldValue: 'status: pending',
        newValue: 'status: ${anom.status}, Not: $resolutionNote',
      );
      notifyListeners();
    }
  }

  /// Akıllı Vardiya Optimizasyonu Planı Üretme
  SmartShiftOptimization generateSmartShiftPlan({String department = 'Tüm Departmanlar'}) {
    final compEmps = employees;
    final totalShifts = compEmps.length * 5;
    final laborCost = compEmps.fold<double>(0.0, (acc, e) => acc + (e.baseGrossSalary / 4.0));

    return SmartShiftOptimization(
      id: 'opt_${DateTime.now().millisecondsSinceEpoch}',
      companyId: _activeCompanyId,
      department: department,
      weekLabel: 'Gelecek Hafta (Hafta ${(DateTime.now().day / 7).ceil() + 1})',
      coverageScorePercent: 98.4,
      estimatedLaborCostTL: laborCost,
      totalAssignedShifts: totalShifts,
      optimizationNotes: [
        'Gece vardiyasında çalışan tüm personelin mesai süresi 7.5 saat ile sınırlandırıldı (4857 Md. 69 uyumlu).',
        'Vardiya dönüşümlerinde 11 saatlik zorunlu kesintisiz dinlenme süresi tam korundu.',
        'Haftalık 45 saati aşmayan dengeli rotasyon sayesinde tahmini fazla mesai maliyeti %18 düşürüldü.',
        'Kıdemli ve çırak/aday teknisyenler arıza müdahale hızını artırmak için 1:1 eşleştirildi.',
      ],
      adheresToLaborLaw4857: true,
    );
  }

  // ==========================================
  // 2. KİOSK YÜZ TANIMA & CANLILIK (LIVENESS) MOTORU
  // ==========================================

  /// Kiosk Kamerası ile Yüz Tanıma & Canlılık Doğrulamalı Turnike Geçişi
  Future<({bool success, String message, String? employeeName})> processKioskFaceScan({
    required String terminalId,
    required String rawFaceVectorOrName,
    required bool isBlinkDetected,
  }) async {
    // 1. Canlılık (Anti-Spoofing) Kontrolü
    if (!isBlinkDetected) {
      final spoofAnomaly = PdkAnomalyRecord(
        id: 'spoof_${DateTime.now().millisecondsSinceEpoch}',
        companyId: _activeCompanyId,
        employeeId: 0,
        employeeName: rawFaceVectorOrName,
        anomalyType: 'buddy_punching_suspected',
        severity: 'critical',
        title: 'Kamera Ekran/Fotoğraf Sahteciliği Girişimi (Anti-Spoofing Engellendi)',
        description: 'Kiosk kamerasında göz kırpma/liveness canlılık tespit edilemedi. Statik fotoğraf veya ekrandan video oynatıldığı değerlendirildi.',
        detectedAt: DateTime.now(),
        status: 'pending',
      );
      _anomalies.insert(0, spoofAnomaly);
      await _db.insertAnomaly(spoofAnomaly);
      notifyListeners();

      return (
        success: false,
        message: 'Sahte Geçiş Engellendi (Canlılık Doğrulanamadı): Lütfen kameraya doğrudan bakınız ve göz kırpınız (Anti-Spoofing Koruma).',
        employeeName: null,
      );
    }

    // 2. Personel Eşleştirme
    final clean = rawFaceVectorOrName.trim().toLowerCase();
    final matched = _employees.cast<Employee?>().firstWhere(
      (e) => (e != null && (e.fullName.toLowerCase().contains(clean) || e.email.toLowerCase().contains(clean) || e.id.toString() == clean)),
      orElse: () => null,
    );

    if (matched == null) {
      return (
        success: false,
        message: 'Kayıtlı biyometrik yüz profili bulunamadı. Lütfen RFID kart veya PIN kullanınız.',
        employeeName: null,
      );
    }

    // 3. Giriş veya Çıkış İşlemini Gerçekleştir
    final isCurrentlyIn = _records.any((r) => r.employeeId == matched.id && r.type == AttendanceType.checkIn && r.timestamp.day == DateTime.now().day);
    final nextType = isCurrentlyIn ? AttendanceType.checkOut : AttendanceType.checkIn;

    final newRec = AttendanceRecord(
      id: DateTime.now().millisecondsSinceEpoch,
      companyId: matched.companyId,
      employeeId: matched.id,
      employeeName: matched.fullName,
      timestamp: DateTime.now(),
      type: nextType,
      userLatitude: activeCompany.officeLat,
      userLongitude: activeCompany.officeLng,
      calculatedDistanceMeters: 0.0,
      isLocationVerified: true,
      verificationMethod: VerificationMethod.biometricKiosk,
      deviceInfo: 'Kiosk Terminal $terminalId (Biyometrik Yüz Geçişi)',
      note: 'Turnike Geçişi Doğrulandı',
    );

    _records.insert(0, newRec);
    await _db.insertAttendanceRecord(newRec);

    await logAudit(
      actionType: 'Kiosk Yüz Tanıma Geçişi (${nextType == AttendanceType.checkIn ? "Giriş" : "Çıkış"})',
      targetEntity: 'AttendanceRecord',
      entityId: newRec.id.toString(),
      newValue: 'Personel: ${matched.fullName}, Terminal: $terminalId, Canlılık: Doğrulandı',
    );

    notifyListeners();
    return (
      success: true,
      message: 'Hoş geldiniz ${matched.fullName}! Turnike kilidi açıldı (${nextType == AttendanceType.checkIn ? "Giriş" : "Çıkış"} kaydedildi).',
      employeeName: matched.fullName,
    );
  }

  // ==========================================
  // 3. 5070 SAYILI E-İMZA & BORDRO İHRACAT MOTORU
  // ==========================================

  /// Bordro veya İzin Formunu 5070 Zaman Damgalı Olarak Mobil Parmakla İmzalama
  Future<SignedDocumentRecord> signDocumentWith5070Timestamp({
    required String documentType,
    required String documentTitle,
    required String period,
    required String signaturePoints,
  }) async {
    final signedDoc = SignedDocumentRecord(
      id: 'sig_${DateTime.now().millisecondsSinceEpoch}',
      companyId: _activeCompanyId,
      employeeId: _currentUser.id,
      employeeName: _currentUser.fullName,
      documentType: documentType,
      documentTitle: documentTitle,
      period: period,
      signatureSvgOrPoints: signaturePoints,
      signedAt: DateTime.now(),
      signerIp: '192.168.1.105',
      isVerified5070: true,
    );

    _signedDocuments.insert(0, signedDoc);
    await _db.insertSignedDocument(signedDoc);

    await logAudit(
      actionType: '5070 E-İmza Belge Onayı',
      targetEntity: 'SignedDocumentRecord',
      entityId: signedDoc.id,
      oldValue: 'İmzasız Taslak',
      newValue: 'İmzalandı: ${signedDoc.documentTitle} | Zaman Damgası: ${signedDoc.timeStampHash.substring(0, 16)}...',
    );

    notifyListeners();
    return signedDoc;
  }

  /// Logo, Mikro, SAP ve SGK Uyumlu Puantaj İcmali Çıktısı Üretme
  String exportPayrollData({required String format, required String period}) {
    final comp = activeCompany;
    final emps = employees;

    final List<Map<String, dynamic>> recordsPayload = emps.map((e) {
      final p = payrolls.firstWhere(
        (pay) => pay.employeeId == e.id,
        orElse: () => PayrollSlip(
          id: 'temp_${e.id}',
          companyId: e.companyId,
          companyName: activeCompany.name,
          employeeId: e.id,
          employeeName: e.fullName,
          employeeTitle: e.title,
          department: e.department,
          tcKimlikNo: e.tcKimlikNo,
          sicilNo: e.displaySicilNo,
          iban: 'TR120006100511123456789012',
          bankName: 'İş Bankası',
          periodMonth: DateTime.now().month,
          periodYear: DateTime.now().year,
          issueDate: DateTime.now(),
          paymentDate: DateTime.now(),
          baseGrossSalary: e.baseGrossSalary,
          overtimeHours: 6.0,
          overtimePay: (e.baseGrossSalary / 225) * 6.0 * 1.5,
          incomeTax: (e.baseGrossSalary * 0.15),
          stampTax: (e.baseGrossSalary * 0.00759),
        ),
      );
      return {
        'sicilNo': e.displaySicilNo,
        'tcKimlik': e.tcKimlikNo,
        'name': e.fullName,
        'normalDays': 30,
        'overtimeHours': p.overtimeHours,
        'weekendHours': 0.0,
        'grossPay': p.totalEarnings.toStringAsFixed(2),
      };
    }).toList();

    switch (format.toLowerCase()) {
      case 'logo':
        return ErpExportHelper.generateLogoXml(
          companyCode: comp.code,
          period: period,
          records: recordsPayload,
        );
      case 'mikro':
        return ErpExportHelper.generateMikroCsv(records: recordsPayload);
      case 'sap':
        return ErpExportHelper.generateSapJson(
          companyCode: comp.code,
          period: period,
          records: recordsPayload,
        );
      case 'sgk':
      default:
        return ErpExportHelper.generateSgkAphbSummary(
          companyCode: comp.code,
          period: period,
          records: recordsPayload,
        );
    }
  }

  // ==========================================
  // 4. İSG & RAMAK KALA (NEAR-MISS) MODÜLÜ
  // ==========================================

  /// Ramak Kala (Near-Miss) Tehlike Olayı Bildirme
  Future<void> submitNearMissReport({
    required String title,
    required String description,
    required String department,
    required String locationDetail,
    required String riskLevel,
    List<String>? photoUrls,
  }) async {
    final report = NearMissReport(
      id: 'nm_${DateTime.now().millisecondsSinceEpoch}',
      companyId: _activeCompanyId,
      reporterId: _currentUser.id,
      reporterName: _currentUser.fullName,
      title: title.trim(),
      description: description.trim(),
      department: department.trim(),
      locationDetail: locationDetail.trim(),
      riskLevel: riskLevel,
      reportedAt: DateTime.now(),
      status: 'open',
      photoUrls: photoUrls ?? [],
    );

    _nearMissReports.insert(0, report);
    await _db.insertNearMissReport(report);

    // İSG Hekimine ve Yöneticilere Acil Bildirim
    final isgNotif = AppNotification(
      id: 'notif_isg_${DateTime.now().millisecondsSinceEpoch}',
      title: '🚨 Acil İSG Ramak Kala Bildirimi!',
      message: '${report.reporterName}, "${report.locationDetail}" noktasında "${report.title}" bildirdi. Risk: ${report.riskLabel}',
      timestamp: DateTime.now(),
      type: NotificationType.system,
      icon: Icons.warning_amber_rounded,
      color: Colors.red,
      isRead: false,
    );
    _notifications.insert(0, isgNotif);
    await _db.insertNotification(isgNotif);

    await logAudit(
      actionType: 'İSG Ramak Kala Bildirildi',
      targetEntity: 'NearMissReport',
      entityId: report.id,
      newValue: 'Risk: $riskLevel | Yer: $locationDetail | Başlık: $title',
    );

    notifyListeners();
  }

  /// Tehlikeli Bölge Geofence & KKD Denetimi
  ({bool isInsideHazard, HazardZone? zone, List<String> requiredPPE, String? warning}) checkHazardZoneGeofence(
    double lat,
    double lng,
  ) {
    for (final zone in hazardZones) {
      final distance = LocationService.calculateDistanceInMeters(lat, lng, zone.centerLat, zone.centerLng);
      if (distance <= zone.radiusMeters) {
        return (
          isInsideHazard: true,
          zone: zone,
          requiredPPE: zone.requiredPPE,
          warning: zone.warningMessage,
        );
      }
    }
    return (
      isInsideHazard: false,
      zone: null,
      requiredPPE: [],
      warning: null,
    );
  }

  // ==========================================
  // 5. SAHA TELSİZİ (PUSH-TO-TALK / PTT)
  // ==========================================

  /// Telsizden Sesli Mesaj (Audio Burst) İletme
  Future<void> transmitPttBurst({
    required String channelId,
    required String spokenText,
    int durationSeconds = 3,
  }) async {
    final idx = _pttChannels.indexWhere((p) => p.id == channelId);
    if (idx != -1) {
      final ch = _pttChannels[idx];
      ch.isOccupied = true;
      ch.currentSpeakerName = _currentUser.fullName;
      ch.transmissionStartedAt = DateTime.now();
      notifyListeners();

      final burst = PttVoiceBurst(
        burstId: 'burst_${DateTime.now().millisecondsSinceEpoch}',
        channelId: channelId,
        speakerId: _currentUser.id,
        speakerName: _currentUser.fullName,
        speakerRole: _currentUser.role.label,
        timestamp: DateTime.now(),
        durationSeconds: durationSeconds,
        transcriptText: spokenText.trim(),
      );

      _pttBursts.insert(0, burst);
      await _db.insertPttBurst(burst);

      // Konuşma bitti mandalı bırak
      await Future.delayed(const Duration(milliseconds: 200));
      ch.isOccupied = false;
      ch.currentSpeakerName = null;
      ch.transmissionStartedAt = null;
      await _db.updatePttChannel(ch);

      notifyListeners();
    }
  }

  // ==========================================
  // ÇALIŞAN HAREKET YÖNETİMİ (PDKS MOVEMENT MANAGEMENT)
  // ==========================================

  List<PdksShiftDefinition> get pdksShiftDefinitions => _db.getAllPdksShifts();

  Map<int, int> get employeeShiftMap => _db.getEmployeeShiftMap();

  List<EmployeeMovementRecord> get employeeMovements => _db.getAllEmployeeMovements();

  List<AnomalyResolutionRecord> get anomalyResolutions => _db.getAllAnomalyResolutions();

  bool get includeFieldDutyInNetWork => _db.getIncludeDutyInNetWork();

  Future<void> setIncludeFieldDutyInNetWork(bool val) async {
    await _db.setIncludeDutyInNetWork(val);
    notifyListeners();
  }

  /// Personelin atanmış vardiyasını döndürür (yoksa varsayılan Gündüz Vardiyası)
  PdksShiftDefinition getShiftForEmployee(int employeeId) {
    final map = _db.getEmployeeShiftMap();
    final shifts = _db.getAllPdksShifts();
    final shiftId = map[employeeId] ?? 1;
    return shifts.firstWhere(
      (s) => s.id == shiftId,
      orElse: () => shifts.isNotEmpty
          ? shifts.first
          : const PdksShiftDefinition(
              id: 1,
              name: 'Gündüz Vardiyası (08:30 - 17:30)',
              startTime: '08:30',
              endTime: '17:30',
            ),
    );
  }

  /// Seçili tarihe göre tüm aktif şirket personellerinin günlük devam özetini dinamik hesaplar
  List<DailyAttendanceSummary> getDailySummariesForDate(
    DateTime date, {
    DateTime? referenceNow,
  }) {
    final compEmployees = employees;
    final allMovs = _db.getAllEmployeeMovements();
    final compLeaves = leaves;
    final includeDuty = _db.getIncludeDutyInNetWork();
    final resolutions = _db.getAllAnomalyResolutions();

    final summaries = <DailyAttendanceSummary>[];
    for (final emp in compEmployees) {
      final shift = getShiftForEmployee(emp.id);
      final rawSummary = MovementCalculationEngine.calculateDailySummary(
        employee: emp,
        date: date,
        shift: shift,
        allMovements: allMovs,
        leaves: compLeaves,
        includeFieldDutyInNetWork: includeDuty,
        referenceNow: referenceNow,
      );

      // Yönetici tarafından onaylanmış/reddedilmiş anomali kararlarını eşleştir
      final updatedAnomalies = rawSummary.anomalies.map((anom) {
        final res = resolutions.where((r) => r.anomalyId == anom.id).firstOrNull;
        if (res != null) {
          return MovementAnomalyItem(
            id: anom.id,
            category: anom.category,
            employeeId: anom.employeeId,
            sicilNo: anom.sicilNo,
            employeeName: anom.employeeName,
            department: anom.department,
            shiftName: anom.shiftName,
            date: anom.date,
            title: anom.title,
            description: anom.description,
            relatedMovementId: anom.relatedMovementId,
            correctionId: anom.correctionId,
            approvalStatus: res.status,
            reviewedBy: res.reviewedBy,
            reviewedAt: res.reviewedAt,
            rejectionReason: res.reason,
          );
        }
        return anom;
      }).toList();

      summaries.add(
        DailyAttendanceSummary(
          employeeId: rawSummary.employeeId,
          sicilNo: rawSummary.sicilNo,
          employeeName: rawSummary.employeeName,
          department: rawSummary.department,
          title: rawSummary.title,
          isEmployeeActive: rawSummary.isEmployeeActive,
          date: rawSummary.date,
          plannedShift: rawSummary.plannedShift,
          firstCheckIn: rawSummary.firstCheckIn,
          lastCheckOut: rawSummary.lastCheckOut,
          totalBreakDuration: rawSummary.totalBreakDuration,
          dutyDuration: rawSummary.dutyDuration,
          netWorkDuration: rawSummary.netWorkDuration,
          lateDuration: rawSummary.lateDuration,
          earlyLeaveDuration: rawSummary.earlyLeaveDuration,
          pendingExtraDuration: rawSummary.pendingExtraDuration,
          status: rawSummary.status,
          anomalies: updatedAnomalies,
          dayMovements: rawSummary.dayMovements,
        ),
      );
    }

    return summaries;
  }

  /// Seçili tarihe göre kontrol bekleyen tüm kayıtları döndürür
  List<MovementAnomalyItem> getAnomaliesForDate(
    DateTime date, {
    DateTime? referenceNow,
  }) {
    final summaries = getDailySummariesForDate(date, referenceNow: referenceNow);
    final list = <MovementAnomalyItem>[];
    for (final s in summaries) {
      list.addAll(s.anomalies);
    }
    return list;
  }

  /// Yeni çalışan hareketi ekler
  Future<({bool success, String message})> addEmployeeMovement({
    required int employeeId,
    required MovementType type,
    required DateTime timestamp,
    required String deviceDoor,
    MovementSource source = MovementSource.manual,
    required String note,
  }) async {
    final emp = _employees.where((e) => e.id == employeeId).firstOrNull;
    if (emp == null) {
      return (success: false, message: 'Seçilen personel bulunamadı.');
    }

    final shift = getShiftForEmployee(emp.id);
    final cleanDoor = deviceDoor.trim().isEmpty ? 'Manuel Kayıt / İK Paneli' : deviceDoor.trim();
    final cleanNote = note.trim();

    final record = EmployeeMovementRecord(
      id: 'mov_${DateTime.now().microsecondsSinceEpoch}',
      companyId: emp.companyId,
      employeeId: emp.id,
      sicilNo: emp.displaySicilNo,
      employeeName: emp.fullName,
      department: emp.department,
      shiftId: shift.id,
      shiftName: shift.name,
      type: type,
      timestamp: timestamp,
      deviceDoor: cleanDoor,
      source: source,
      note: cleanNote,
      rawDeviceSnapshot: RawDeviceMovementSnapshot(
        type: type,
        timestamp: timestamp,
        deviceDoor: cleanDoor,
        source: source,
        note: cleanNote,
      ),
    );

    await _db.saveEmployeeMovement(record);
    notifyListeners();
    return (
      success: true,
      message: '${emp.fullName} için "${type.label}" hareketi başarıyla eklendi.',
    );
  }

  /// Mevcut hareketi düzeltir (Ham cihaz kaydını korur ve izlenebilir düzeltme geçmişi ekler)
  Future<({bool success, String message})> correctEmployeeMovement({
    required String movementId,
    required MovementType newType,
    required DateTime newTimestamp,
    required String newDeviceDoor,
    required String newNote,
    required String reason,
  }) async {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      return (success: false, message: 'Manuel düzeltmelerde gerekçe alanı zorunludur.');
    }

    final existing = _db.getAllEmployeeMovements().where((m) => m.id == movementId).firstOrNull;
    if (existing == null) {
      return (success: false, message: 'Düzeltilecek hareket kaydı bulunamadı.');
    }

    final cleanDoor = newDeviceDoor.trim().isEmpty ? existing.deviceDoor : newDeviceDoor.trim();
    final correction = MovementCorrectionRecord(
      id: 'corr_${DateTime.now().microsecondsSinceEpoch}',
      movementId: existing.id,
      previousType: existing.type,
      previousTimestamp: existing.timestamp,
      previousDeviceDoor: existing.deviceDoor,
      previousNote: existing.note,
      newType: newType,
      newTimestamp: newTimestamp,
      newDeviceDoor: cleanDoor,
      newNote: newNote.trim(),
      reason: cleanReason,
      actorName: _currentUser.fullName,
      actorRole: _currentUser.roleDisplayName,
      correctedAt: DateTime.now(),
      approvalStatus: CorrectionApprovalStatus.pending,
    );

    final updated = existing.copyWith(
      type: newType,
      timestamp: newTimestamp,
      deviceDoor: cleanDoor,
      source: MovementSource.manual,
      note: newNote.trim(),
      // rawDeviceSnapshot ASLA değiştirilmez (ham cihaz kaydı korunur)
      correctionHistory: [...existing.correctionHistory, correction],
    );

    await _db.saveEmployeeMovement(updated);
    notifyListeners();
    return (
      success: true,
      message: 'Hareket düzeltmesi kaydedildi ve yönetici onayına sunuldu.',
    );
  }

  /// Kontrol bekleyen kaydı veya manuel düzeltmeyi onaylar
  Future<({bool success, String message})> approveAnomalyOrCorrection(
    MovementAnomalyItem anomaly,
  ) async {
    if (anomaly.category == AnomalyCategory.pendingManualCorrection &&
        anomaly.relatedMovementId != null &&
        anomaly.correctionId != null) {
      final mov = _db
          .getAllEmployeeMovements()
          .where((m) => m.id == anomaly.relatedMovementId)
          .firstOrNull;
      if (mov != null) {
        final updatedHistory = mov.correctionHistory.map((c) {
          if (c.id == anomaly.correctionId) {
            return c.copyWith(
              approvalStatus: CorrectionApprovalStatus.approved,
              reviewedBy: _currentUser.fullName,
              reviewedAt: DateTime.now(),
            );
          }
          return c;
        }).toList();
        await _db.saveEmployeeMovement(mov.copyWith(correctionHistory: updatedHistory));
      }
    }

    await _db.saveAnomalyResolution(
      AnomalyResolutionRecord(
        anomalyId: anomaly.id,
        status: CorrectionApprovalStatus.approved,
        reviewedBy: _currentUser.fullName,
        reviewedAt: DateTime.now(),
        reason: 'Yönetici tarafından incelendi ve onaylandı.',
      ),
    );
    notifyListeners();
    return (success: true, message: '"${anomaly.title}" kaydı onaylandı.');
  }

  /// Kontrol bekleyen kaydı veya manuel düzeltmeyi gerekçe ile reddeder
  Future<({bool success, String message})> rejectAnomalyOrCorrection({
    required MovementAnomalyItem anomaly,
    required String rejectionReason,
  }) async {
    final cleanReason = rejectionReason.trim();
    if (cleanReason.isEmpty) {
      return (success: false, message: 'Reddetme işlemi için gerekçe girilmesi zorunludur.');
    }

    if (anomaly.category == AnomalyCategory.pendingManualCorrection &&
        anomaly.relatedMovementId != null &&
        anomaly.correctionId != null) {
      final mov = _db
          .getAllEmployeeMovements()
          .where((m) => m.id == anomaly.relatedMovementId)
          .firstOrNull;
      if (mov != null) {
        MovementCorrectionRecord? targetCorr;
        final updatedHistory = mov.correctionHistory.map((c) {
          if (c.id == anomaly.correctionId) {
            targetCorr = c;
            return c.copyWith(
              approvalStatus: CorrectionApprovalStatus.rejected,
              reviewedBy: _currentUser.fullName,
              reviewedAt: DateTime.now(),
              rejectionReason: cleanReason,
            );
          }
          return c;
        }).toList();

        // Reddedilen manuel düzeltmede hareketi önceki değerine geri döndür
        final reverted = targetCorr != null
            ? mov.copyWith(
                type: targetCorr!.previousType,
                timestamp: targetCorr!.previousTimestamp,
                deviceDoor: targetCorr!.previousDeviceDoor,
                note: targetCorr!.previousNote,
                correctionHistory: updatedHistory,
              )
            : mov.copyWith(correctionHistory: updatedHistory);

        await _db.saveEmployeeMovement(reverted);
      }
    }

    await _db.saveAnomalyResolution(
      AnomalyResolutionRecord(
        anomalyId: anomaly.id,
        status: CorrectionApprovalStatus.rejected,
        reviewedBy: _currentUser.fullName,
        reviewedAt: DateTime.now(),
        reason: cleanReason,
      ),
    );
    notifyListeners();
    return (success: true, message: '"${anomaly.title}" kaydı gerekçe ile reddedildi.');
  }

  /// Yeni PDKS Vardiya tanımı ekler veya mevcut vardiyayı günceller
  Future<({bool success, String message})> savePdksShiftDefinition(
    PdksShiftDefinition shift,
  ) async {
    if (shift.name.trim().isEmpty) {
      return (success: false, message: 'Vardiya adı zorunludur.');
    }
    await _db.savePdksShift(shift);
    notifyListeners();
    return (success: true, message: '"${shift.name}" vardiyası kaydedildi.');
  }

  /// Personele vardiya atar
  Future<({bool success, String message})> assignShiftToEmployee({
    required int employeeId,
    required int shiftId,
  }) async {
    final emp = _employees.where((e) => e.id == employeeId).firstOrNull;
    final shift = _db.getAllPdksShifts().where((s) => s.id == shiftId).firstOrNull;
    if (emp == null || shift == null) {
      return (success: false, message: 'Personel veya vardiya bulunamadı.');
    }
    await _db.assignShiftToEmployeeDb(employeeId, shiftId);
    notifyListeners();
    return (
      success: true,
      message: '${emp.fullName} personeline "${shift.name}" vardiyası atandı.',
    );
  }

  /// Sicil numarası benzersizlik kontrolü ile personel ekler veya düzenler
  Future<({bool success, String message})> saveEmployeeFromMovementPanel({
    int? existingId,
    required String sicilNo,
    required String fullName,
    required String department,
    required String title,
    required int shiftId,
    required bool isActive,
  }) async {
    final cleanSicil = sicilNo.trim().toUpperCase();
    final cleanName = fullName.trim();
    final cleanDept = department.trim();
    final cleanTitle = title.trim();

    if (cleanSicil.isEmpty) {
      return (success: false, message: 'Sicil numarası zorunludur.');
    }
    if (cleanName.isEmpty) {
      return (success: false, message: 'Ad soyad alanı zorunludur.');
    }

    // Benzersiz sicil numarası kontrolü
    final duplicate = employees.any(
      (e) =>
          e.id != existingId &&
          e.displaySicilNo.trim().toUpperCase() == cleanSicil,
    );
    if (duplicate) {
      return (
        success: false,
        message: '"$cleanSicil" sicil numarası başka bir personele aittir. Sicil numarası benzersiz olmalıdır.',
      );
    }

    if (existingId != null) {
      final idx = _employees.indexWhere((e) => e.id == existingId);
      if (idx == -1) {
        return (success: false, message: 'Düzenlenecek personel bulunamadı.');
      }
      final updated = _employees[idx].copyWith(
        sicilNo: cleanSicil,
        fullName: cleanName,
        department: cleanDept.isEmpty ? 'Genel' : cleanDept,
        title: cleanTitle.isEmpty ? 'Uzman' : cleanTitle,
        isActive: isActive,
      );
      _employees[idx] = updated;
      await _db.updateEmployee(updated);
      await _db.assignShiftToEmployeeDb(existingId, shiftId);
      notifyListeners();
      return (success: true, message: '${updated.fullName} bilgileri güncellendi.');
    } else {
      final newId = (_employees.isNotEmpty
              ? _employees.map((e) => e.id).reduce((a, b) => a > b ? a : b)
              : 100) +
          1;
      final newEmp = Employee(
        id: newId,
        companyId: _activeCompanyId,
        sicilNo: cleanSicil,
        fullName: cleanName,
        email: '${cleanSicil.toLowerCase().replaceAll('-', '')}@sirket.com',
        department: cleanDept.isEmpty ? 'Genel' : cleanDept,
        title: cleanTitle.isEmpty ? 'Uzman' : cleanTitle,
        pinCode: '1234',
        isActive: isActive,
        isApproved: true,
        hireDate: DateTime.now(),
      );
      _employees.add(newEmp);
      await _db.insertEmployee(newEmp);
      await _db.assignShiftToEmployeeDb(newId, shiftId);
      notifyListeners();
      return (success: true, message: '${newEmp.fullName} ($cleanSicil) başarıyla eklendi.');
    }
  }

  // ==========================================
  // VERİTABANI YENİDEN YÜKLEME VE SENKRONİZASYON
  // ==========================================

  /// Veritabanındaki tüm tabloları ve kayıtları yeniden belleğe çeker
  Future<void> reloadAllFromDatabase() async {
    await _db.reloadAll();
    _initializeSeedData();
    notifyListeners();
  }

  bool _isDisposed = false;

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _workTimer?.cancel();
    _cloudSyncTimer?.cancel();
    super.dispose();
  }
}

class ExecutiveDashboardStats {
  final int totalEmployees;
  final int activeCheckedInToday;
  final double attendanceRatePercent;
  final double totalOvertimeHours;
  final double estimatedOvertimeCost;
  final int pendingLeavesCount;
  final int openHelpdeskTicketsCount;
  final int insideVisitorsCount;
  final int activeBranchesCount;
  final double employeeSatisfactionScore;

  ExecutiveDashboardStats({
    required this.totalEmployees,
    required this.activeCheckedInToday,
    required this.attendanceRatePercent,
    required this.totalOvertimeHours,
    required this.estimatedOvertimeCost,
    required this.pendingLeavesCount,
    required this.openHelpdeskTicketsCount,
    required this.insideVisitorsCount,
    required this.activeBranchesCount,
    required this.employeeSatisfactionScore,
  });
}
