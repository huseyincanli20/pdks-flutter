import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/employee.dart';
import '../../models/company.dart';
import '../../models/attendance_record.dart';
import '../../models/leave_request.dart';
import '../../models/shift_schedule.dart';
import '../../models/chat_message.dart';
import '../../models/app_notification.dart';
import '../../models/cafeteria_menu.dart';
import '../../models/quick_menu_item.dart';
import '../../models/page_customization.dart';
import '../../models/vehicle_request.dart';
import '../../models/payroll_slip.dart';
import '../../models/shift_swap_request.dart';
import '../../models/helpdesk_ticket.dart';
import '../../models/company_announcement.dart';
import '../../models/personnel_file.dart';
import '../../models/training_and_skill.dart';
import '../../models/performance_goal.dart';
import '../../models/visitor_record.dart';
import '../../models/hybrid_booking.dart';
import '../../models/organization_branch.dart';
import '../../models/integration_and_sync.dart';
import '../../models/employee_feedback.dart';
import '../../models/equipment_and_cmms.dart';
import '../../models/audit_log.dart';
import '../../models/ai_anomaly_and_insights.dart';
import '../../models/face_kiosk_and_turnstile.dart';
import '../../models/digital_signature_and_export.dart';
import '../../models/occupational_safety_and_nearmiss.dart';
import '../../models/push_to_talk_and_media.dart';

/// PDKS Kurumsal Veritabanı Servisi (Persistent Database Engine)
/// SharedPreferences / IndexedDB / Web LocalStorage üzerinde kalıcı veri yönetimi
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  static DatabaseService get instance => _instance;
  DatabaseService._internal() {
    _seedEnterpriseDefaultDataSync();
  }

  // Veritabanı Depolama Anahtarları
  static const String _keyEmployees = 'pdks_db_employees_v1';
  static const String _keyCompanies = 'pdks_db_companies_v1';
  static const String _keyRecords = 'pdks_db_records_v1';
  static const String _keyLeaves = 'pdks_db_leaves_v1';
  static const String _keyShifts = 'pdks_db_shifts_v1';
  static const String _keyMessages = 'pdks_db_messages_v1';
  static const String _keyChannels = 'pdks_db_channels_v1';
  static const String _keyNotifications = 'pdks_db_notifications_v1';
  static const String _keyMenu = 'pdks_db_menu_v1';
  static const String _keyTwoWeekMenus = 'pdks_db_twoweek_menus_v1';
  static const String _keyQuickMenu = 'pdks_db_quick_menu_v1';
  static const String _keyPageCustomizations = 'pdks_db_page_customizations_v1';
  static const String _keyVehicleRequests = 'pdks_db_vehicle_requests_v1';
  static const String _keyPayrolls = 'pdks_db_payrolls_v1';
  static const String _keyRoles = 'pdks_db_roles_v1';
  static const String _keyActiveCompanyId = 'pdks_db_active_company_id_v1';
  static const String _keyThemeMode = 'pdks_db_theme_mode_v1';

  // Kurumsal Ek Modüller (Enterprise Extended Keys)
  static const String _keyShiftSwaps = 'pdks_db_shift_swaps_v1';
  static const String _keyOpenShiftSlots = 'pdks_db_open_shifts_v1';
  static const String _keyHelpdeskTickets = 'pdks_db_helpdesk_v1';
  static const String _keyAnnouncements = 'pdks_db_announcements_v1';
  static const String _keyDocuments = 'pdks_db_documents_v1';
  static const String _keyOnboardingTasks = 'pdks_db_onboarding_v1';
  static const String _keyTrainingCourses = 'pdks_db_training_courses_v1';
  static const String _keyTrainingRecords = 'pdks_db_training_records_v1';
  static const String _keyPerformanceGoals = 'pdks_db_performance_goals_v1';
  static const String _keyVisitorRecords = 'pdks_db_visitors_v1';
  static const String _keyHybridBookings = 'pdks_db_hybrid_bookings_v1';
  static const String _keyCompanyBranches = 'pdks_db_branches_v1';
  static const String _keyApprovalDelegations = 'pdks_db_delegations_v1';
  static const String _keyIntegrations = 'pdks_db_integrations_v1';
  static const String _keyOfflineQueue = 'pdks_db_offline_queue_v1';
  static const String _keyFeedbacks = 'pdks_db_feedbacks_v1';
  static const String _keyEquipmentRecords = 'pdks_db_equipment_records_v1';
  static const String _keyWorkOrders = 'pdks_db_work_orders_v1';
  static const String _keyAuditLogs = 'pdks_db_audit_logs_v1';
  static const String _keyLockedPeriods = 'pdks_db_locked_periods_v1';
  static const String _keySavedCompanyCode = 'pdks_db_saved_company_code_v1';
  static const String _keyLastUserEmail = 'pdks_db_last_user_email_v1';
  static const String _keyFailedPinAttempts = 'pdks_db_failed_pin_attempts_v1';
  static const String _keyPinLockoutUntil = 'pdks_db_pin_lockout_until_v1';

  // İleri Düzey 5 Kurumsal Modül Anahtarları (Advanced Enterprise Keys)
  static const String _keyAnomalies = 'pdks_db_anomalies_v1';
  static const String _keyFaceEnrollments = 'pdks_db_face_enrollments_v1';
  static const String _keyKioskTerminals = 'pdks_db_kiosk_terminals_v1';
  static const String _keySignedDocuments = 'pdks_db_signed_docs_v1';
  static const String _keyNearMissReports = 'pdks_db_near_miss_v1';
  static const String _keySafetyCertificates = 'pdks_db_safety_certs_v1';
  static const String _keyHazardZones = 'pdks_db_hazard_zones_v1';
  static const String _keyPttChannels = 'pdks_db_ptt_channels_v1';
  static const String _keyPttBursts = 'pdks_db_ptt_bursts_v1';

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  // Bellek İçi Hızlı Veri Deposu (In-Memory Database Cache)
  final List<Employee> _employees = [];
  final List<Company> _companies = [];
  final List<AttendanceRecord> _records = [];
  final List<LeaveRequest> _leaves = [];
  final List<ShiftSchedule> _shifts = [];
  final List<ChatMessage> _messages = [];
  final List<ChatChannel> _customChannels = [];
  final List<AppNotification> _notifications = [];
  final List<QuickMenuItem> _quickMenuItems = [];
  final List<VehicleRequest> _vehicleRequests = [];
  final List<PayrollSlip> _payrolls = [];
  final List<AppRoleItem> _roles = [];
  final List<CafeteriaMenu> _twoWeekMenus = [];
  final Map<String, PageCustomization> _pageCustomizations = {};
  CafeteriaMenu? _todayMenu;
  String? _activeCompanyId;
  String? _themeType;

  // Kurumsal Ek Modüller Önbellek Listeleri
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

  // İleri Düzey 5 Modül Önbellek Listeleri
  final List<PdkAnomalyRecord> _anomalies = [];
  final List<FaceEnrollment> _faceEnrollments = [];
  final List<KioskTerminal> _kioskTerminals = [];
  final List<SignedDocumentRecord> _signedDocuments = [];
  final List<NearMissReport> _nearMissReports = [];
  final List<SafetyCertificate> _safetyCertificates = [];
  final List<HazardZone> _hazardZones = [];
  final List<PttChannel> _pttChannels = [];
  final List<PttVoiceBurst> _pttBursts = [];

  bool get isInitialized => _isInitialized;

  /// Veritabanını Başlat ve Kalıcı Depodan Verileri Yükle
  Future<void> init({bool forceReload = false}) async {
    if (_isInitialized && !forceReload) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _employees.clear();
      _companies.clear();
      _records.clear();
      _leaves.clear();
      _shifts.clear();
      _messages.clear();
      _customChannels.clear();
      _notifications.clear();
      _quickMenuItems.clear();
      _vehicleRequests.clear();
      _payrolls.clear();
      _roles.clear();
      _twoWeekMenus.clear();
      _pageCustomizations.clear();
      _shiftSwaps.clear();
      _openShiftSlots.clear();
      _helpdeskTickets.clear();
      _announcements.clear();
      _documents.clear();
      _onboardingTasks.clear();
      _trainingCourses.clear();
      _trainingRecords.clear();
      _performanceGoals.clear();
      _visitorRecords.clear();
      _hybridBookings.clear();
      _branches.clear();
      _delegations.clear();
      _integrations.clear();
      _offlineQueue.clear();
      _feedbacks.clear();
      _equipmentRecords.clear();
      _workOrders.clear();
      _auditLogs.clear();
      _lockedPeriods.clear();
      _todayMenu = null;
      _activeCompanyId = null;
      _themeType = null;
      await _loadAllDataFromDb();
      _isInitialized = true;
    } catch (e) {
      debugPrint('⚠️ [DatabaseService] Init Hatası: $e');
      _isInitialized = true; // Fallback to memory
    }
  }

  /// Tüm tabloları veritabanından oku; boşsa varsayılan kurumsal verileri yükle
  Future<void> _loadAllDataFromDb() async {
    final prefs = _prefs;
    if (prefs == null) return;

    // 1. Şirketler
    final companiesRaw = prefs.getString(_keyCompanies);
    if (companiesRaw != null && companiesRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(companiesRaw);
        _companies.clear();
        _companies.addAll(list.map((item) => Company.fromJson(Map<String, dynamic>.from(item))));
      } catch (e) {
        debugPrint('⚠️ Şirketler yüklenirken hata: $e');
      }
    }

    // 2. Personeller / Kullanıcılar
    final employeesRaw = prefs.getString(_keyEmployees);
    if (employeesRaw != null && employeesRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(employeesRaw);
        _employees.clear();
        _employees.addAll(list.map((item) => Employee.fromJson(Map<String, dynamic>.from(item))));
      } catch (e) {
        debugPrint('⚠️ Personeller yüklenirken hata: $e');
      }
    }

    // Eğer veritabanı tamamen boşsa (ilk kurulum), varsayılan şirket ve çalışanları tohumla
    if (_companies.isEmpty || _employees.isEmpty) {
      await _seedDefaultDatabase();
    }

    // 3. Giriş / Çıkış Devam Kayıtları
    final recordsRaw = prefs.getString(_keyRecords);
    if (recordsRaw != null && recordsRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(recordsRaw);
        _records.clear();
        _records.addAll(list.map((item) => AttendanceRecord.fromJson(Map<String, dynamic>.from(item))));
      } catch (e) {
        debugPrint('⚠️ Devam kayıtları yüklenirken hata: $e');
      }
    }

    // 4. İzin Talepleri
    final leavesRaw = prefs.getString(_keyLeaves);
    if (leavesRaw != null && leavesRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(leavesRaw);
        _leaves.clear();
        _leaves.addAll(list.map((item) => LeaveRequest.fromJson(Map<String, dynamic>.from(item))));
      } catch (e) {
        debugPrint('⚠️ İzinler yüklenirken hata: $e');
      }
    }

    // 5. Vardiyalar
    final shiftsRaw = prefs.getString(_keyShifts);
    if (shiftsRaw != null && shiftsRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(shiftsRaw);
        _shifts.clear();
        _shifts.addAll(list.map((item) => ShiftSchedule.fromJson(Map<String, dynamic>.from(item))));
      } catch (e) {
        debugPrint('⚠️ Vardiyalar yüklenirken hata: $e');
      }
    }
    if (_shifts.isEmpty) {
      await _seedDefaultShifts();
    }

    // 6. Mesajlar
    final messagesRaw = prefs.getString(_keyMessages);
    if (messagesRaw != null && messagesRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(messagesRaw);
        _messages.clear();
        _messages.addAll(list.map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item))));
      } catch (e) {
        debugPrint('⚠️ Mesajlar yüklenirken hata: $e');
      }
    }

    // 7. Özel Grup Kanalları
    final channelsRaw = prefs.getString(_keyChannels);
    if (channelsRaw != null && channelsRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(channelsRaw);
        _customChannels.clear();
        _customChannels.addAll(list.map((item) => ChatChannel.fromJson(Map<String, dynamic>.from(item))));
      } catch (e) {
        debugPrint('⚠️ Kanallar yüklenirken hata: $e');
      }
    }

    // 8. Bildirimler
    final notifsRaw = prefs.getString(_keyNotifications);
    if (notifsRaw != null && notifsRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(notifsRaw);
        _notifications.clear();
        _notifications.addAll(list.map((item) => AppNotification.fromJson(Map<String, dynamic>.from(item))));
      } catch (e) {
        debugPrint('⚠️ Bildirimler yüklenirken hata: $e');
      }
    }
    if (_notifications.isEmpty) {
      await _seedDefaultNotifications();
    }

    // 9. Yemekhane Menüsü
    final menuRaw = prefs.getString(_keyMenu);
    if (menuRaw != null && menuRaw.isNotEmpty) {
      try {
        _todayMenu = CafeteriaMenu.fromJson(jsonDecode(menuRaw));
      } catch (e) {
        debugPrint('⚠️ Menü yüklenirken hata: $e');
      }
    }

    // 10. Hızlı Menü Öğeleri
    final quickMenuRaw = prefs.getString(_keyQuickMenu);
    if (quickMenuRaw != null && quickMenuRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(quickMenuRaw);
        _quickMenuItems.clear();
        _quickMenuItems.addAll(list.map((item) => QuickMenuItem.fromJson(Map<String, dynamic>.from(item))));
      } catch (e) {
        debugPrint('⚠️ Hızlı menü yüklenirken hata: $e');
      }
    }

    // 11. Sayfa Özelleştirmeleri (Yönetici & Admin Düzenleme Modu)
    final pageCustRaw = prefs.getString(_keyPageCustomizations);
    if (pageCustRaw != null && pageCustRaw.isNotEmpty) {
      try {
        final Map<String, dynamic> map = jsonDecode(pageCustRaw);
        _pageCustomizations.clear();
        map.forEach((k, v) {
          if (v is Map<String, dynamic>) {
            _pageCustomizations[k] = PageCustomization.fromJson(v);
          } else if (v is Map) {
            _pageCustomizations[k] = PageCustomization.fromJson(Map<String, dynamic>.from(v));
          }
        });
      } catch (e) {
        debugPrint('⚠️ Sayfa özelleştirmeleri yüklenirken hata: $e');
      }
    }

    // 12. Araç Talepleri (Vehicle Requests)
    final vehicleRaw = prefs.getString(_keyVehicleRequests);
    if (vehicleRaw != null && vehicleRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(vehicleRaw);
        _vehicleRequests.clear();
        _vehicleRequests.addAll(list.map((item) => VehicleRequest.fromJson(Map<String, dynamic>.from(item))));
      } catch (e) {
        debugPrint('⚠️ Araç talepleri yüklenirken hata: $e');
      }
    }
    if (_vehicleRequests.isEmpty) {
      await _seedDefaultVehicleRequests();
    }

    // 13. Roller & Yetkiler (Roles)
    final rolesRaw = prefs.getString(_keyRoles);
    if (rolesRaw != null && rolesRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(rolesRaw);
        _roles.clear();
        _roles.addAll(list.map((item) => AppRoleItem.fromJson(Map<String, dynamic>.from(item))));
      } catch (e) {
        debugPrint('⚠️ Roller yüklenirken hata: $e');
      }
    }
    if (_roles.isEmpty) {
      _roles.addAll(defaultRoles());
      await _persistRoles();
    } else {
      final existingIds = _roles.map((r) => r.id).toSet();
      bool addedRole = false;
      for (final sysRole in defaultRoles()) {
        if (!existingIds.contains(sysRole.id)) {
          _roles.add(sysRole);
          addedRole = true;
        }
      }
      if (addedRole) {
        await _persistRoles();
      }
    }

    // 14. Bordrolar & Maaş Belgeleri (Payrolls)
    final payrollsRaw = prefs.getString(_keyPayrolls);
    if (payrollsRaw != null && payrollsRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(payrollsRaw);
        _payrolls.clear();
        _payrolls.addAll(list.map((item) => PayrollSlip.fromJson(Map<String, dynamic>.from(item))));
      } catch (e) {
        debugPrint('⚠️ Bordrolar yüklenirken hata: $e');
      }
    }
    if (_payrolls.isEmpty) {
      await _seedDefaultPayrolls();
    }

    // 15. 2 Haftalık Yemekhane Menüsü (Two Week Menus)
    final twoWeekRaw = prefs.getString(_keyTwoWeekMenus);
    if (twoWeekRaw != null && twoWeekRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(twoWeekRaw);
        _twoWeekMenus.clear();
        _twoWeekMenus.addAll(list.map((item) => CafeteriaMenu.fromJson(Map<String, dynamic>.from(item))));
      } catch (e) {
        debugPrint('⚠️ 2 Haftalık menü yüklenirken hata: $e');
      }
    }
    if (_twoWeekMenus.isEmpty) {
      await _seedDefaultTwoWeekMenu();
    }

    // 16. Kullanıcı Tercihleri (Active Company & Theme)
    _activeCompanyId = prefs.getString(_keyActiveCompanyId);
    _themeType = prefs.getString(_keyThemeMode);

    // 17. Vardiya Takas & Açık Vardiyalar
    final shiftSwapsRaw = prefs.getString(_keyShiftSwaps);
    if (shiftSwapsRaw != null && shiftSwapsRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(shiftSwapsRaw);
        _shiftSwaps.clear();
        _shiftSwaps.addAll(list.map((i) => ShiftSwapRequest.fromJson(Map<String, dynamic>.from(i))));
      } catch (e) {
        debugPrint('⚠️ Vardiya takasları yüklenirken hata: $e');
      }
    }
    final openShiftsRaw = prefs.getString(_keyOpenShiftSlots);
    if (openShiftsRaw != null && openShiftsRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(openShiftsRaw);
        _openShiftSlots.clear();
        _openShiftSlots.addAll(list.map((i) => OpenShiftSlot.fromJson(Map<String, dynamic>.from(i))));
      } catch (e) {
        debugPrint('⚠️ Açık vardiyalar yüklenirken hata: $e');
      }
    }

    // 18. Teknik Destek & Arıza Talepleri (Helpdesk)
    final helpdeskRaw = prefs.getString(_keyHelpdeskTickets);
    if (helpdeskRaw != null && helpdeskRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(helpdeskRaw);
        _helpdeskTickets.clear();
        _helpdeskTickets.addAll(list.map((i) => HelpdeskTicket.fromJson(Map<String, dynamic>.from(i))));
      } catch (e) {
        debugPrint('⚠️ Destek talepleri yüklenirken hata: $e');
      }
    }

    // 19. Duyurular & Okundu Onayları
    final announcementsRaw = prefs.getString(_keyAnnouncements);
    if (announcementsRaw != null && announcementsRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(announcementsRaw);
        _announcements.clear();
        _announcements.addAll(list.map((i) => CompanyAnnouncement.fromJson(Map<String, dynamic>.from(i))));
      } catch (e) {
        debugPrint('⚠️ Duyurular yüklenirken hata: $e');
      }
    }

    // 20. Özlük Dosyası Evrakları & İşe Giriş/Çıkış
    final docsRaw = prefs.getString(_keyDocuments);
    if (docsRaw != null && docsRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(docsRaw);
        _documents.clear();
        _documents.addAll(list.map((i) => EmployeeDocument.fromJson(Map<String, dynamic>.from(i))));
      } catch (e) {
        debugPrint('⚠️ Özlük belgeleri yüklenirken hata: $e');
      }
    }
    final onboardingRaw = prefs.getString(_keyOnboardingTasks);
    if (onboardingRaw != null && onboardingRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(onboardingRaw);
        _onboardingTasks.clear();
        _onboardingTasks.addAll(list.map((i) => OnboardingTask.fromJson(Map<String, dynamic>.from(i))));
      } catch (e) {
        debugPrint('⚠️ İşe giriş/çıkış görevleri yüklenirken hata: $e');
      }
    }

    // 21. Eğitim & Yetkinlikler
    final coursesRaw = prefs.getString(_keyTrainingCourses);
    if (coursesRaw != null && coursesRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(coursesRaw);
        _trainingCourses.clear();
        _trainingCourses.addAll(list.map((i) => TrainingCourse.fromJson(Map<String, dynamic>.from(i))));
      } catch (e) {
        debugPrint('⚠️ Eğitim kursları yüklenirken hata: $e');
      }
    }
    final recordsTrainingRaw = prefs.getString(_keyTrainingRecords);
    if (recordsTrainingRaw != null && recordsTrainingRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(recordsTrainingRaw);
        _trainingRecords.clear();
        _trainingRecords.addAll(list.map((i) => EmployeeTrainingRecord.fromJson(Map<String, dynamic>.from(i))));
      } catch (e) {
        debugPrint('⚠️ Eğitim kayıtları yüklenirken hata: $e');
      }
    }

    // 22. Performans & Hedefler (OKRs)
    final goalsRaw = prefs.getString(_keyPerformanceGoals);
    if (goalsRaw != null && goalsRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(goalsRaw);
        _performanceGoals.clear();
        _performanceGoals.addAll(list.map((i) => PerformanceGoal.fromJson(Map<String, dynamic>.from(i))));
      } catch (e) {
        debugPrint('⚠️ Performans hedefleri yüklenirken hata: $e');
      }
    }

    // 23. Ziyaretçi & Taşeron Kayıtları
    final visitorsRaw = prefs.getString(_keyVisitorRecords);
    if (visitorsRaw != null && visitorsRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(visitorsRaw);
        _visitorRecords.clear();
        _visitorRecords.addAll(list.map((i) => VisitorRecord.fromJson(Map<String, dynamic>.from(i))));
      } catch (e) {
        debugPrint('⚠️ Ziyaretçi kayıtları yüklenirken hata: $e');
      }
    }

    // 24. Hibrit Rezervasyonlar (Masa, Oda, Otopark)
    final bookingsRaw = prefs.getString(_keyHybridBookings);
    if (bookingsRaw != null && bookingsRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(bookingsRaw);
        _hybridBookings.clear();
        _hybridBookings.addAll(list.map((i) => HybridBooking.fromJson(Map<String, dynamic>.from(i))));
      } catch (e) {
        debugPrint('⚠️ Rezervasyonlar yüklenirken hata: $e');
      }
    }

    // 25. Şubeler & Onay Vekaletleri
    final branchesRaw = prefs.getString(_keyCompanyBranches);
    if (branchesRaw != null && branchesRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(branchesRaw);
        _branches.clear();
        _branches.addAll(list.map((i) => CompanyBranch.fromJson(Map<String, dynamic>.from(i))));
      } catch (e) {
        debugPrint('⚠️ Şubeler yüklenirken hata: $e');
      }
    }
    final delegationsRaw = prefs.getString(_keyApprovalDelegations);
    if (delegationsRaw != null && delegationsRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(delegationsRaw);
        _delegations.clear();
        _delegations.addAll(list.map((i) => ApprovalDelegation.fromJson(Map<String, dynamic>.from(i))));
      } catch (e) {
        debugPrint('⚠️ Vekaletler yüklenirken hata: $e');
      }
    }

    // 26. Entegrasyonlar & Çevrimdışı Kuyruk
    final integrationsRaw = prefs.getString(_keyIntegrations);
    if (integrationsRaw != null && integrationsRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(integrationsRaw);
        _integrations.clear();
        _integrations.addAll(list.map((i) => IntegrationEndpoint.fromJson(Map<String, dynamic>.from(i))));
      } catch (e) {
        debugPrint('⚠️ Entegrasyonlar yüklenirken hata: $e');
      }
    }
    final offlineRaw = prefs.getString(_keyOfflineQueue);
    if (offlineRaw != null && offlineRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(offlineRaw);
        _offlineQueue.clear();
        _offlineQueue.addAll(list.map((i) => OfflineSyncItem.fromJson(Map<String, dynamic>.from(i))));
      } catch (e) {
        debugPrint('⚠️ Çevrimdışı kuyruk yüklenirken hata: $e');
      }
    }

    // 27. Çalışan Geri Bildirimleri & Anketler
    final feedbacksRaw = prefs.getString(_keyFeedbacks);
    if (feedbacksRaw != null && feedbacksRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(feedbacksRaw);
        _feedbacks.clear();
        _feedbacks.addAll(list.map((i) => EmployeeFeedback.fromJson(Map<String, dynamic>.from(i))));
      } catch (e) {
        debugPrint('⚠️ Geri bildirimler yüklenirken hata: $e');
      }
    }

    // 28. Kalibrasyon & CMMS Ekipman Sicil Kartları (ISO 9001 / ISO 17025)
    final eqRaw = prefs.getString(_keyEquipmentRecords);
    if (eqRaw != null && eqRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(eqRaw);
        _equipmentRecords.clear();
        _equipmentRecords.addAll(list.map((i) => EquipmentRecord.fromJson(Map<String, dynamic>.from(i))));
      } catch (e) {
        debugPrint('⚠️ Ekipman kayıtları yüklenirken hata: $e');
      }
    }

    // 29. Periyodik Bakım & Arıza İş Emirleri (CMMS Work Orders)
    final woRaw = prefs.getString(_keyWorkOrders);
    if (woRaw != null && woRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(woRaw);
        _workOrders.clear();
        _workOrders.addAll(list.map((i) => MaintenanceWorkOrder.fromJson(Map<String, dynamic>.from(i))));
      } catch (e) {
        debugPrint('⚠️ Bakım iş emirleri yüklenirken hata: $e');
      }
    }

    // 30. Değiştirilemez Denetim Kayıtları (Immutable Audit Log)
    final auditRaw = prefs.getString(_keyAuditLogs);
    if (auditRaw != null && auditRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(auditRaw);
        _auditLogs.clear();
        _auditLogs.addAll(list.map((i) => AuditLogRecord.fromJson(Map<String, dynamic>.from(i))));
      } catch (e) {
        debugPrint('⚠️ Denetim kayıtları yüklenirken hata: $e');
      }
    }

    // 31. Bordro Kilitli Puantaj Dönemleri
    final lockedRaw = prefs.getStringList(_keyLockedPeriods);
    if (lockedRaw != null) {
      _lockedPeriods.clear();
      _lockedPeriods.addAll(lockedRaw);
    }

    // 32. Yapay Zeka Anomali & Sahte Geçiş Kayıtları
    final anomaliesRaw = prefs.getString(_keyAnomalies);
    if (anomaliesRaw != null && anomaliesRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(anomaliesRaw);
        _anomalies.clear();
        _anomalies.addAll(list.map((i) => PdkAnomalyRecord.fromJson(Map<String, dynamic>.from(i))));
      } catch (e) {
        debugPrint('⚠️ Anomaliler yüklenirken hata: $e');
      }
    }

    // 33. Yüz Tanıma & Canlılık Biyometrik Kayıtları
    final faceRaw = prefs.getString(_keyFaceEnrollments);
    if (faceRaw != null && faceRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(faceRaw);
        _faceEnrollments.clear();
        _faceEnrollments.addAll(list.map((i) => FaceEnrollment.fromJson(Map<String, dynamic>.from(i))));
      } catch (e) {
        debugPrint('⚠️ Yüz kayıtları yüklenirken hata: $e');
      }
    }

    // 34. Kiosk & Turnike Terminalleri
    final kioskRaw = prefs.getString(_keyKioskTerminals);
    if (kioskRaw != null && kioskRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(kioskRaw);
        _kioskTerminals.clear();
        _kioskTerminals.addAll(list.map((i) => KioskTerminal.fromJson(Map<String, dynamic>.from(i))));
      } catch (e) {
        debugPrint('⚠️ Kiosk terminalleri yüklenirken hata: $e');
      }
    }

    // 35. 5070 Sayılı Kanun Uyumlu İmzalı Belgeler
    final signedRaw = prefs.getString(_keySignedDocuments);
    if (signedRaw != null && signedRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(signedRaw);
        _signedDocuments.clear();
        _signedDocuments.addAll(list.map((i) => SignedDocumentRecord.fromJson(Map<String, dynamic>.from(i))));
      } catch (e) {
        debugPrint('⚠️ İmzalı belgeler yüklenirken hata: $e');
      }
    }

    // 36. Ramak Kala (Near-Miss) İSG Olay Bildirimleri
    final nearMissRaw = prefs.getString(_keyNearMissReports);
    if (nearMissRaw != null && nearMissRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(nearMissRaw);
        _nearMissReports.clear();
        _nearMissReports.addAll(list.map((i) => NearMissReport.fromJson(Map<String, dynamic>.from(i))));
      } catch (e) {
        debugPrint('⚠️ Ramak kala bildirimleri yüklenirken hata: $e');
      }
    }

    // 37. Personel İSG Sertifikaları & Sağlık Muayeneleri
    final certsRaw = prefs.getString(_keySafetyCertificates);
    if (certsRaw != null && certsRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(certsRaw);
        _safetyCertificates.clear();
        _safetyCertificates.addAll(list.map((i) => SafetyCertificate.fromJson(Map<String, dynamic>.from(i))));
      } catch (e) {
        debugPrint('⚠️ İSG sertifikaları yüklenirken hata: $e');
      }
    }

    // 38. Tehlikeli Bölge ve Zorunlu KKD Alanları
    final hazardRaw = prefs.getString(_keyHazardZones);
    if (hazardRaw != null && hazardRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(hazardRaw);
        _hazardZones.clear();
        _hazardZones.addAll(list.map((i) => HazardZone.fromJson(Map<String, dynamic>.from(i))));
      } catch (e) {
        debugPrint('⚠️ Tehlikeli bölgeler yüklenirken hata: $e');
      }
    }

    // 39. Saha Telsizi (PTT) Kanalları
    final pttRaw = prefs.getString(_keyPttChannels);
    if (pttRaw != null && pttRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(pttRaw);
        _pttChannels.clear();
        _pttChannels.addAll(list.map((i) => PttChannel.fromJson(Map<String, dynamic>.from(i))));
      } catch (e) {
        debugPrint('⚠️ PTT kanalları yüklenirken hata: $e');
      }
    }

    // 40. PTT Ses İletimleri
    final burstsRaw = prefs.getString(_keyPttBursts);
    if (burstsRaw != null && burstsRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(burstsRaw);
        _pttBursts.clear();
        _pttBursts.addAll(list.map((i) => PttVoiceBurst.fromJson(Map<String, dynamic>.from(i))));
      } catch (e) {
        debugPrint('⚠️ PTT ses iletimleri yüklenirken hata: $e');
      }
    }

    if (_helpdeskTickets.isEmpty || _announcements.isEmpty || _trainingCourses.isEmpty) {
      await _seedDefaultEnterpriseModules();
    }

    // Mevcut veritabanında yeni demo roller (Teknisyen, Doktor, Servis, Araç Kiralama) eksikse ekle
    await _ensureNewDemoEmployees();
  }

  /// Varsayılan Veritabanı Tohumlama (Seed Data)
  static List<Company> defaultCompanies() => [
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
        Company(
          id: 'cmp_fabrika01',
          code: 'FABRIKA01',
          name: 'Fabrika 01 Endüstriyel Üretim ve Otomotiv A.Ş.',
          sector: 'Otomotiv & Ağır Sanayi',
          address: 'Organize Sanayi Bölgesi 4. Cadde No: 12, Kocaeli',
          officeLat: 40.76540,
          officeLng: 29.94080,
          allowedRadiusMeters: 300.0,
          allowedWifiSsid: 'Fabrika01_Uretim_WiFi',
          taxNumber: '1122334455',
          phone: '+90 262 600 01 01',
          email: 'ik@fabrika01.com.tr',
          primaryColor: const Color(0xFF0284C7),
        ),
      ];

  Future<void> _seedDefaultDatabase() async {
    if (_companies.isEmpty) {
      _companies.addAll(defaultCompanies());
      await _persistCompanies();
    } else if (!_companies.any((c) => c.code == 'FABRIKA01')) {
      _companies.add(Company(
        id: 'cmp_fabrika01',
        code: 'FABRIKA01',
        name: 'Fabrika 01 Endüstriyel Üretim ve Otomotiv A.Ş.',
        sector: 'Otomotiv & Ağır Sanayi',
        address: 'Organize Sanayi Bölgesi 4. Cadde No: 12, Kocaeli',
        officeLat: 40.76540,
        officeLng: 29.94080,
        allowedRadiusMeters: 300.0,
        allowedWifiSsid: 'Fabrika01_Uretim_WiFi',
        taxNumber: '1122334455',
        phone: '+90 262 600 01 01',
        email: 'ik@fabrika01.com.tr',
        primaryColor: const Color(0xFF0284C7),
      ));
      await _persistCompanies();
    }

    if (_employees.isEmpty) {
      _employees.addAll([
        Employee(
          id: 1,
          companyId: 'cmp_acme',
          fullName: 'Ahmet Yılmaz',
          email: 'personel@sirket.com',
          phone: '05321112233',
          department: 'Yazılım & Ar-Ge',
          title: 'Kıdemli Mobil Geliştirici',
          pinCode: '1234',
          role: UserRole.employee,
          annualLeaveAllowance: 14,
          usedLeaveDays: 0,
          isApproved: true,
          hireDate: DateTime(2022, 3, 15),
          heightCm: 178,
          weightKg: 75,
          shirtSize: 'L',
          pantSize: '32/32',
          shoeSize: 42,
          outerwearSize: 'L',
        ),
        Employee(
          id: 2,
          companyId: 'cmp_acme',
          fullName: 'Zeynep Kaya',
          email: 'ik@sirket.com',
          phone: '05332223344',
          department: 'İnsan Kaynakları',
          title: 'İK Direktörü',
          pinCode: '2345',
          role: UserRole.hr,
          annualLeaveAllowance: 20,
          usedLeaveDays: 0,
          isApproved: true,
          hireDate: DateTime(2021, 6, 1),
          heightCm: 168,
          weightKg: 58,
          shirtSize: 'M',
          pantSize: '38',
          shoeSize: 38,
          outerwearSize: 'M',
        ),
        Employee(
          id: 3,
          companyId: 'cmp_acme',
          fullName: 'Kemal Özdemir',
          email: 'patron@sirket.com',
          phone: '05309998877',
          department: 'Yönetim Kurulu',
          title: 'Genel Müdür / CEO',
          pinCode: '3456',
          role: UserRole.boss,
          annualLeaveAllowance: 30,
          usedLeaveDays: 0,
          isApproved: true,
          hireDate: DateTime(2018, 1, 1),
          heightCm: 182,
          weightKg: 84,
          shirtSize: 'XL',
          pantSize: '34/32',
          shoeSize: 43,
          outerwearSize: 'XL',
        ),
        Employee(
          id: 4,
          companyId: 'cmp_acme',
          fullName: 'Serkan Arslan',
          email: 'admin@sirket.com',
          phone: '05408887766',
          department: 'Bilgi İşlem & IT',
          title: 'Sistem Yöneticisi',
          pinCode: '4567',
          role: UserRole.admin,
          annualLeaveAllowance: 20,
          usedLeaveDays: 0,
          isApproved: true,
          hireDate: DateTime(2020, 9, 10),
          heightCm: 175,
          weightKg: 72,
          shirtSize: 'M',
          pantSize: '31/32',
          shoeSize: 41,
          outerwearSize: 'M',
        ),
        Employee(
          id: 5,
          companyId: 'cmp_acme',
          fullName: 'Mehmet Demir',
          email: 'mehmet.demir@sirket.com',
          phone: '05353334455',
          department: 'Satış & Pazarlama',
          title: 'Bölge Satış Müdürü',
          pinCode: '9988',
          role: UserRole.employee,
          annualLeaveAllowance: 14,
          usedLeaveDays: 0,
          isApproved: true,
          hireDate: DateTime(2023, 2, 1),
        ),
        Employee(
          id: 6,
          companyId: 'cmp_acme',
          fullName: 'Elif Şahin',
          email: 'elif.sahin@sirket.com',
          phone: '05424445566',
          department: 'Mali İşler',
          title: 'Muhasebe Uzmanı',
          pinCode: '1122',
          role: UserRole.employee,
          annualLeaveAllowance: 14,
          usedLeaveDays: 0,
          isApproved: true,
          hireDate: DateTime(2023, 4, 15),
        ),
        Employee(
          id: 7,
          companyId: 'cmp_acme',
          fullName: 'Hasan Usta',
          email: 'yemekhane@sirket.com',
          phone: '05445556677',
          department: 'İdari İşler & Mutfak',
          title: 'Mutfak Şefi',
          pinCode: '5678',
          role: UserRole.cafeteria,
          annualLeaveAllowance: 14,
          usedLeaveDays: 0,
          isApproved: true,
          hireDate: DateTime(2021, 1, 10),
        ),
        Employee(
          id: 8,
          companyId: 'cmp_acme',
          fullName: 'Serkan Usta',
          email: 'teknisyen@sirket.com',
          phone: '05341234567',
          department: 'Teknik Hizmetler & Bakım',
          title: 'Kıdemli Saha Teknisyeni',
          pinCode: '1234',
          role: UserRole.technician,
          annualLeaveAllowance: 14,
          usedLeaveDays: 0,
          isApproved: true,
          hireDate: DateTime(2022, 5, 10),
        ),
        Employee(
          id: 9,
          companyId: 'cmp_acme',
          fullName: 'Dr. Elif Çetin',
          email: 'doktor@sirket.com',
          phone: '05359876543',
          department: 'İş Sağlığı ve Güvenliği',
          title: 'İşyeri Hekimi',
          pinCode: '1234',
          role: UserRole.doctor,
          annualLeaveAllowance: 20,
          usedLeaveDays: 0,
          isApproved: true,
          hireDate: DateTime(2021, 8, 15),
        ),
        Employee(
          id: 10,
          companyId: 'cmp_acme',
          fullName: 'Murat Şen',
          email: 'servis@sirket.com',
          phone: '05364567890',
          department: 'Ulaşım & Lojistik',
          title: 'Servis ve Ulaşım Sorumlusu',
          pinCode: '1234',
          role: UserRole.serviceManager,
          annualLeaveAllowance: 14,
          usedLeaveDays: 0,
          isApproved: true,
          hireDate: DateTime(2020, 11, 1),
        ),
        Employee(
          id: 11,
          companyId: 'cmp_acme',
          fullName: 'Cenk Vural',
          email: 'arackiralama@sirket.com',
          phone: '05373216549',
          department: 'Filo & Araç Kiralama',
          title: 'Filo & Araç Kiralama Sorumlusu',
          pinCode: '1234',
          role: UserRole.vehicleRentalManager,
          annualLeaveAllowance: 16,
          usedLeaveDays: 0,
          isApproved: true,
          hireDate: DateTime(2022, 1, 20),
        ),
      ]);
      await _persistEmployees();
    }
  }

  /// Mevcut veritabanında yeni rollerin demo hesapları eksikse ekle
  Future<void> _ensureNewDemoEmployees() async {
    final newDemoUsers = [
      Employee(
        id: 8,
        companyId: 'cmp_acme',
        fullName: 'Serkan Usta',
        email: 'teknisyen@sirket.com',
        phone: '05341234567',
        department: 'Teknik Hizmetler & Bakım',
        title: 'Kıdemli Saha Teknisyeni',
        pinCode: '1234',
        role: UserRole.technician,
        annualLeaveAllowance: 14,
        usedLeaveDays: 0,
        isApproved: true,
        hireDate: DateTime(2022, 5, 10),
      ),
      Employee(
        id: 9,
        companyId: 'cmp_acme',
        fullName: 'Dr. Elif Çetin',
        email: 'doktor@sirket.com',
        phone: '05359876543',
        department: 'İş Sağlığı ve Güvenliği',
        title: 'İşyeri Hekimi',
        pinCode: '1234',
        role: UserRole.doctor,
        annualLeaveAllowance: 20,
        usedLeaveDays: 0,
        isApproved: true,
        hireDate: DateTime(2021, 8, 15),
      ),
      Employee(
        id: 10,
        companyId: 'cmp_acme',
        fullName: 'Murat Şen',
        email: 'servis@sirket.com',
        phone: '05364567890',
        department: 'Ulaşım & Lojistik',
        title: 'Servis ve Ulaşım Sorumlusu',
        pinCode: '1234',
        role: UserRole.serviceManager,
        annualLeaveAllowance: 14,
        usedLeaveDays: 0,
        isApproved: true,
        hireDate: DateTime(2020, 11, 1),
      ),
      Employee(
        id: 11,
        companyId: 'cmp_acme',
        fullName: 'Cenk Vural',
        email: 'arackiralama@sirket.com',
        phone: '05373216549',
        department: 'Filo & Araç Kiralama',
        title: 'Filo & Araç Kiralama Sorumlusu',
        pinCode: '1234',
        role: UserRole.vehicleRentalManager,
        annualLeaveAllowance: 16,
        usedLeaveDays: 0,
        isApproved: true,
        hireDate: DateTime(2022, 1, 20),
      ),
    ];

    bool added = false;
    for (final demo in newDemoUsers) {
      if (!_employees.any((e) => e.email.toLowerCase() == demo.email.toLowerCase() || e.id == demo.id)) {
        _employees.add(demo);
        added = true;
      }
    }
    if (added) {
      await _persistEmployees();
    }
  }

  // ==========================================
  // PERSONEL / KULLANICI İŞLEMLERİ (DATABASE)
  // ==========================================

  List<Employee> getAllEmployees() => List.unmodifiable(_employees);

  Employee? getEmployeeById(int id) {
    try {
      return _employees.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Employee? getEmployeeByEmail(String email) {
    final clean = email.trim().toLowerCase();
    try {
      return _employees.firstWhere((e) => e.email.trim().toLowerCase() == clean);
    } catch (_) {
      return null;
    }
  }

  Employee? getEmployeeByPhone(String phone) {
    final clean = _normalizePhone(phone);
    if (clean.isEmpty) return null;
    try {
      return _employees.firstWhere((e) => _normalizePhone(e.phone) == clean);
    } catch (_) {
      return null;
    }
  }

  /// Telefon numarası normalizasyonu (05321112233 -> 5321112233)
  String _normalizePhone(String raw) {
    String digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('90')) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return digits;
  }

  /// E-posta veya Telefon Numarasının Veritabanında Zaten Kayıtlı Olup Olmadığını Kontrol Eder
  bool isEmailOrPhoneRegistered(String email, String phone) {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = _normalizePhone(phone);

    // E-posta kontrolü
    final emailExists = _employees.any((e) => e.email.trim().toLowerCase() == cleanEmail);
    if (emailExists) return true;

    // Telefon kontrolü (eğer telefon girildiyse)
    if (cleanPhone.isNotEmpty) {
      final phoneExists = _employees.any((e) => _normalizePhone(e.phone) == cleanPhone);
      if (phoneExists) return true;
    }

    return false;
  }

  /// Yeni Personeli Veritabanına Ekle ve Kalıcı Olarak Kaydet
  Future<void> insertEmployee(Employee employee) async {
    final index = _employees.indexWhere((e) => e.id == employee.id);
    if (index != -1) {
      _employees[index] = employee;
    } else {
      _employees.add(employee);
    }
    await _persistEmployees();
  }

  /// Personel Bilgilerini Veritabanında Güncelle
  Future<void> updateEmployee(Employee employee) async {
    final index = _employees.indexWhere((e) => e.id == employee.id);
    if (index != -1) {
      _employees[index] = employee;
      await _persistEmployees();
    }
  }

  /// Personeli Sil
  Future<void> deleteEmployee(int id) async {
    _employees.removeWhere((e) => e.id == id);
    await _persistEmployees();
  }

  Future<void> _persistEmployees() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      final list = _employees.map((e) => e.toJson()).toList();
      await prefs.setString(_keyEmployees, jsonEncode(list));
    } catch (e) {
      debugPrint('⚠️ Personeller diske kaydedilemedi: $e');
    }
  }

  // ==========================================
  // ŞİRKET İŞLEMLERİ (DATABASE)
  // ==========================================

  List<Company> getAllCompanies() {
    if (_companies.isEmpty) {
      _companies.addAll(defaultCompanies());
    }
    return List.unmodifiable(_companies);
  }

  Company? getCompanyById(String id) {
    try {
      return _companies.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Company? getCompanyByCode(String code) {
    final clean = code.trim().toUpperCase();
    try {
      return _companies.firstWhere((c) => c.code.toUpperCase() == clean);
    } catch (_) {
      return null;
    }
  }

  Future<void> insertCompany(Company company) async {
    final idx = _companies.indexWhere((c) => c.id == company.id);
    if (idx != -1) {
      _companies[idx] = company;
    } else {
      _companies.add(company);
    }
    await _persistCompanies();
  }

  Future<void> updateCompany(Company company) async {
    final idx = _companies.indexWhere((c) => c.id == company.id);
    if (idx != -1) {
      _companies[idx] = company;
      await _persistCompanies();
    }
  }

  Future<void> deleteCompany(String id) async {
    _companies.removeWhere((c) => c.id == id);
    await _persistCompanies();
  }

  Future<void> _persistCompanies() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      final list = _companies.map((c) => c.toJson()).toList();
      await prefs.setString(_keyCompanies, jsonEncode(list));
    } catch (e) {
      debugPrint('⚠️ Şirketler diske kaydedilemedi: $e');
    }
  }

  // ==========================================
  // DEVAM KAYITLARI (GİRİŞ/ÇIKIŞ) (DATABASE)
  // ==========================================

  List<AttendanceRecord> getAllRecords() => List.unmodifiable(_records);

  Future<void> insertAttendanceRecord(AttendanceRecord record) async {
    _records.insert(0, record);
    await _persistRecords();
  }

  Future<void> clearAllRecords() async {
    _records.clear();
    await _persistRecords();
  }

  Future<void> _persistRecords() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      final list = _records.map((r) => r.toJson()).toList();
      await prefs.setString(_keyRecords, jsonEncode(list));
    } catch (e) {
      debugPrint('⚠️ Devam kayıtları diske kaydedilemedi: $e');
    }
  }

  // ==========================================
  // İZİN TALEPLERİ (DATABASE)
  // ==========================================

  List<LeaveRequest> getAllLeaves() => List.unmodifiable(_leaves);

  Future<void> insertLeaveRequest(LeaveRequest leave) async {
    _leaves.insert(0, leave);
    await _persistLeaves();
  }

  Future<void> updateLeaveRequest(LeaveRequest leave) async {
    final idx = _leaves.indexWhere((l) => l.id == leave.id);
    if (idx != -1) {
      _leaves[idx] = leave;
      await _persistLeaves();
    }
  }

  Future<void> deleteLeaveRequest(int id) async {
    _leaves.removeWhere((l) => l.id == id);
    await _persistLeaves();
  }

  Future<void> _persistLeaves() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      final list = _leaves.map((l) => l.toJson()).toList();
      await prefs.setString(_keyLeaves, jsonEncode(list));
    } catch (e) {
      debugPrint('⚠️ İzinler diske kaydedilemedi: $e');
    }
  }

  // ==========================================
  // MESAJLAŞMA VE SOHBETLER (DATABASE)
  // ==========================================

  List<ChatMessage> getAllMessages() => List.unmodifiable(_messages);

  Future<void> insertChatMessage(ChatMessage msg) async {
    _messages.add(msg);
    await _persistMessages();
  }

  Future<void> markChannelMessagesAsRead(String channelId, int currentUserId) async {
    bool changed = false;
    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i].channelId == channelId && !_messages[i].isRead && _messages[i].senderId != currentUserId) {
        _messages[i] = _messages[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) {
      await _persistMessages();
    }
  }

  /// Mesajı kalıcı silmez, veritabanında denetim kaydı olarak soft-delete işaretler.
  Future<void> softDeleteChatMessage(String messageId, {required String deletedBy}) async {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx != -1) {
      _messages[idx] = _messages[idx].copyWith(
        isDeleted: true,
        deletedAt: DateTime.now(),
        deletedBy: deletedBy,
      );
      await _persistMessages();
    }
  }

  List<ChatChannel> getCustomChannels() => List.unmodifiable(_customChannels);

  Future<void> insertCustomChannel(ChatChannel channel) async {
    _customChannels.add(channel);
    await _persistChannels();
  }

  Future<void> updateCustomChannel(ChatChannel channel) async {
    final idx = _customChannels.indexWhere((c) => c.id == channel.id);
    if (idx != -1) {
      _customChannels[idx] = channel;
    } else {
      _customChannels.add(channel);
    }
    await _persistChannels();
  }

  Future<void> _persistMessages() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      final list = _messages.map((m) => m.toJson()).toList();
      await prefs.setString(_keyMessages, jsonEncode(list));
    } catch (e) {
      debugPrint('⚠️ Mesajlar diske kaydedilemedi: $e');
    }
  }

  Future<void> _persistChannels() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      final list = _customChannels.map((c) => c.toJson()).toList();
      await prefs.setString(_keyChannels, jsonEncode(list));
    } catch (e) {
      debugPrint('⚠️ Kanallar diske kaydedilemedi: $e');
    }
  }

  // ==========================================
  // BİLDİRİMLER (DATABASE)
  // ==========================================

  List<AppNotification> getAllNotifications() => List.unmodifiable(_notifications);

  Future<void> insertNotification(AppNotification notif) async {
    _notifications.insert(0, notif);
    await _persistNotifications();
  }

  Future<void> updateNotification(AppNotification notif) async {
    final idx = _notifications.indexWhere((n) => n.id == notif.id);
    if (idx != -1) {
      _notifications[idx] = notif;
      await _persistNotifications();
    }
  }

  Future<void> markNotificationAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_notifications[idx].isRead) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      await _persistNotifications();
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    bool changed = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) {
      await _persistNotifications();
    }
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    await _persistNotifications();
  }

  Future<void> clearAllNotifications() async {
    _notifications.clear();
    await _persistNotifications();
  }

  Future<void> _persistNotifications() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      final list = _notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_keyNotifications, jsonEncode(list));
    } catch (e) {
      debugPrint('⚠️ Bildirimler diske kaydedilemedi: $e');
    }
  }

  Future<void> _seedDefaultNotifications() async {
    _notifications.clear();
    _notifications.addAll([
      AppNotification(
        id: 'seed_notif_1',
        title: '🎉 Sisteme Hoş Geldiniz!',
        message: 'Kurumsal PDKS hesabınız aktif edildi. Günlük mesai ve izinlerinizi buradan takip edebilirsiniz.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: NotificationType.system,
        icon: Icons.verified_user_rounded,
        color: const Color(0xFF10B981),
        isRead: false,
      ),
      AppNotification(
        id: 'seed_notif_2',
        title: '🍽️ Yemekhane Menüsü Yayında',
        message: 'Bugünün ve 2 haftalık yemekhane menüsünü Hızlı Menüden inceleyebilirsiniz.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        type: NotificationType.cafeteria,
        icon: Icons.restaurant_rounded,
        color: const Color(0xFFEA580C),
        isRead: false,
      ),
    ]);
    await _persistNotifications();
  }

  // ==========================================
  // VARDİYALAR & YEMEKHANE MENÜSÜ (DATABASE)
  // ==========================================

  List<ShiftSchedule> getAllShifts() => List.unmodifiable(_shifts);

  Future<void> insertShift(ShiftSchedule shift) async {
    final idx = _shifts.indexWhere((s) => s.id == shift.id);
    if (idx != -1) {
      _shifts[idx] = shift;
    } else {
      _shifts.add(shift);
    }
    await _persistShifts();
  }

  Future<void> updateShift(ShiftSchedule shift) async {
    final idx = _shifts.indexWhere((s) => s.id == shift.id);
    if (idx != -1) {
      _shifts[idx] = shift;
      await _persistShifts();
    }
  }

  Future<void> deleteShift(int id) async {
    _shifts.removeWhere((s) => s.id == id);
    await _persistShifts();
  }

  Future<void> _persistShifts() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      final list = _shifts.map((s) => s.toJson()).toList();
      await prefs.setString(_keyShifts, jsonEncode(list));
    } catch (e) {
      debugPrint('⚠️ Vardiyalar diske kaydedilemedi: $e');
    }
  }

  Future<void> _seedDefaultShifts() async {
    _shifts.clear();
    _shifts.addAll([
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
    ]);
    await _persistShifts();
  }

  CafeteriaMenu? getTodayMenu() => _todayMenu;

  Future<void> saveMenu(CafeteriaMenu menu) async {
    _todayMenu = menu;
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_keyMenu, jsonEncode(menu.toJson()));
    } catch (e) {
      debugPrint('⚠️ Menü diske kaydedilemedi: $e');
    }
  }

  List<CafeteriaMenu> getTwoWeekMenus() => List.unmodifiable(_twoWeekMenus);

  Future<void> saveTwoWeekMenus(List<CafeteriaMenu> menus) async {
    _twoWeekMenus.clear();
    _twoWeekMenus.addAll(menus);
    await _persistTwoWeekMenus();
  }

  // ==========================================
  // HIZLI MENÜ (QUICK MENU MANAGEMENT)
  // ==========================================

  static List<QuickMenuItem> defaultQuickMenuItems() => const [
    QuickMenuItem(
      id: 'qm_profile',
      title: 'Profil',
      subtitle: 'Kişisel bilgiler & izin bakiyesi',
      iconCode: 0xe491,
      colorValue: 0xFF2563EB,
      isVisible: true,
      actionType: 'profile',
    ),
    QuickMenuItem(
      id: 'qm_payroll',
      title: 'Bordro & Maaş',
      subtitle: 'Aylık maaş hesaplama, icmal & ödemeler',
      iconCode: 0xf00ee,
      colorValue: 0xFF10B981,
      isVisible: true,
      actionType: 'payroll',
    ),
    QuickMenuItem(
      id: 'qm_chat',
      title: 'Mesajlaşma',
      subtitle: 'Şirket içi kanallar & 1-e-1 sohbet',
      iconCode: 0xe153,
      colorValue: 0xFF0284C7,
      isVisible: true,
      actionType: 'chat',
    ),
    QuickMenuItem(
      id: 'qm_contacts',
      title: 'Kişiler',
      subtitle: 'Şirket rehberi & mesai arkadaşları',
      iconCode: 0xe49b,
      colorValue: 0xFF4F46E5,
      isVisible: true,
      actionType: 'contacts',
    ),
    QuickMenuItem(
      id: 'qm_notifications',
      title: 'Bildirimler',
      subtitle: 'Duyurular & onay bildirimleri',
      iconCode: 0xe44f,
      colorValue: 0xFF8B5CF6,
      isVisible: true,
      actionType: 'notifications',
    ),
    QuickMenuItem(
      id: 'qm_cafeteria',
      title: 'Yemekhane Menüsü',
      subtitle: 'Günün menüsü & 2 haftalık çizelge',
      iconCode: 0xe506,
      colorValue: 0xFFEA580C,
      isVisible: true,
      actionType: 'cafeteria',
    ),
    QuickMenuItem(
      id: 'qm_business_card',
      title: 'Kartvizit',
      subtitle: 'Dijital QR kodlu şirket kartı',
      iconCode: 0xf04ee,
      colorValue: 0xFF0D9488,
      isVisible: true,
      actionType: 'business_card',
    ),
    QuickMenuItem(
      id: 'qm_favorites',
      title: 'Sık Kullanılanlar',
      subtitle: 'Hızlı kısayollar, yemek & servis',
      iconCode: 0xe5f9,
      colorValue: 0xFFD97706,
      isVisible: true,
      actionType: 'favorites',
    ),
    QuickMenuItem(
      id: 'qm_leave',
      title: 'İzin Talebi',
      subtitle: 'Yıllık izin veya mazeret talebi oluşturun',
      iconCode: 0xe156,
      colorValue: 0xFFF59E0B,
      isVisible: true,
      actionType: 'leave',
    ),
    QuickMenuItem(
      id: 'qm_records',
      title: 'Giriş / Çıkışlar',
      subtitle: 'Geçmiş devam ve yoklama kayıtları',
      iconCode: 0xe314,
      colorValue: 0xFF2563EB,
      isVisible: true,
      actionType: 'records',
    ),
    QuickMenuItem(
      id: 'qm_field_work',
      title: 'Dışarıda Çalışma 📍',
      subtitle: 'Saha görevi ve anlık konum bildirimi',
      iconCode: 0xe425,
      colorValue: 0xFF10B981,
      isVisible: true,
      actionType: 'field_work',
    ),
    QuickMenuItem(
      id: 'qm_overtime',
      title: 'Fazla Mesai',
      subtitle: 'Ek mesai saat talebi bildirin',
      iconCode: 0xe40f,
      colorValue: 0xFF9333EA,
      isVisible: true,
      actionType: 'overtime',
    ),
    QuickMenuItem(
      id: 'qm_vehicle_request',
      title: 'Araç Talebi & Filo',
      subtitle: 'Şirket havuz araçları ve filo kiralama',
      iconCode: 0xe1d7,
      colorValue: 0xFF059669,
      isVisible: true,
      actionType: 'vehicle_request',
    ),
    QuickMenuItem(
      id: 'qm_enterprise_hub',
      title: 'Kurumsal Modüller (15 Modül)',
      subtitle: 'Vardiya takası, hibrit masa, helpdesk, onay & hedefler',
      iconCode: 0xf05a1,
      colorValue: 0xFF6366F1,
      isVisible: true,
      actionType: 'enterprise_hub',
    ),
    QuickMenuItem(
      id: 'qm_settings',
      title: 'Ayarlar',
      subtitle: 'Tema, bildirim ve sistem tercihleri',
      iconCode: 0xe57f,
      colorValue: 0xFF475569,
      isVisible: true,
      actionType: 'settings',
    ),
    QuickMenuItem(
      id: 'qm_about',
      title: 'Hakkımda',
      subtitle: 'Sürüm 1.0.0 & sistem güvenliği',
      iconCode: 0xe33d,
      colorValue: 0xFF0284C7,
      isVisible: true,
      actionType: 'about',
    ),
    QuickMenuItem(
      id: 'qm_cloud_db',
      title: 'Firebase Bulut DB',
      subtitle: 'Merkezi bulut senkronizasyonu',
      iconCode: 0xe87a,
      colorValue: 0xFFFF5722,
      isVisible: true,
      actionType: 'cloud_db',
    ),
  ];

  List<QuickMenuItem> getAllQuickMenuItems() {
    if (_quickMenuItems.isEmpty) {
      return defaultQuickMenuItems();
    }
    final existingIds = _quickMenuItems.map((e) => e.id).toSet();
    final missing = defaultQuickMenuItems().where((d) => !existingIds.contains(d.id));
    if (missing.isNotEmpty) {
      _quickMenuItems.addAll(missing);
    }
    return List.unmodifiable(_quickMenuItems);
  }

  Future<void> saveQuickMenuItems(List<QuickMenuItem> items) async {
    _quickMenuItems.clear();
    _quickMenuItems.addAll(items);
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      final list = _quickMenuItems.map((q) => q.toJson()).toList();
      await prefs.setString(_keyQuickMenu, jsonEncode(list));
    } catch (e) {
      debugPrint('⚠️ Hızlı menü diske kaydedilemedi: $e');
    }
  }

  // ==========================================
  // SAYFA ÖZELLEŞTİRMELERİ (YÖNETİCİ & ADMİN)
  // ==========================================

  Map<String, PageCustomization> getAllPageCustomizations() {
    return Map.unmodifiable(_pageCustomizations);
  }

  PageCustomization? getPageCustomization(String pageId) {
    return _pageCustomizations[pageId];
  }

  Future<void> savePageCustomization(PageCustomization customization) async {
    _pageCustomizations[customization.pageId] = customization;
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      final map = _pageCustomizations.map((k, v) => MapEntry(k, v.toJson()));
      await prefs.setString(_keyPageCustomizations, jsonEncode(map));
    } catch (e) {
      debugPrint('⚠️ Sayfa özelleştirmesi kaydedilemedi: $e');
    }
  }

  Future<void> deletePageCustomization(String pageId) async {
    _pageCustomizations.remove(pageId);
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      final map = _pageCustomizations.map((k, v) => MapEntry(k, v.toJson()));
      await prefs.setString(_keyPageCustomizations, jsonEncode(map));
    } catch (e) {
      debugPrint('⚠️ Sayfa özelleştirmesi silinemedi: $e');
    }
  }

  // ==========================================
  // ARAÇ TALEP İŞLEMLERİ (VEHICLE REQUESTS)
  // ==========================================

  List<VehicleRequest> getAllVehicleRequests() => List.unmodifiable(_vehicleRequests);

  Future<void> insertVehicleRequest(VehicleRequest req) async {
    _vehicleRequests.removeWhere((r) => r.id == req.id);
    _vehicleRequests.insert(0, req);
    await _persistVehicleRequests();
  }

  Future<void> updateVehicleRequest(VehicleRequest req) async {
    final idx = _vehicleRequests.indexWhere((r) => r.id == req.id);
    if (idx != -1) {
      _vehicleRequests[idx] = req;
      await _persistVehicleRequests();
    }
  }

  Future<void> deleteVehicleRequest(String reqId) async {
    _vehicleRequests.removeWhere((r) => r.id == reqId);
    await _persistVehicleRequests();
  }

  Future<void> _persistVehicleRequests() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      final list = _vehicleRequests.map((r) => r.toJson()).toList();
      await prefs.setString(_keyVehicleRequests, jsonEncode(list));
    } catch (e) {
      debugPrint('⚠️ Araç talepleri diske kaydedilemedi: $e');
    }
  }

  Future<void> _seedDefaultVehicleRequests() async {
    final now = DateTime.now();
    _vehicleRequests.clear();
    _vehicleRequests.addAll([
      VehicleRequest(
        id: 'vr_demo_1',
        companyId: 'cmp_acme',
        employeeId: 8,
        employeeName: 'Serkan Usta',
        employeeDepartment: 'Teknik Hizmetler & Bakım',
        employeeTitle: 'Kıdemli Saha Teknisyeni',
        vehicleType: 'Hafif Ticari / Kamyonet',
        startDate: now.add(const Duration(hours: 2)),
        endDate: now.add(const Duration(hours: 8)),
        destination: 'Sincan OSB Fabrika Arıza Bakımı',
        purpose: 'Arızalanan üretim hattı motorlarının teknik bakımı ve test ekipmanı sevki',
        passengerCount: 2,
        needsDriver: false,
        notes: 'Arkada 3 adet ağır kalibrasyon çantası taşınacaktır.',
        status: VehicleRequestStatus.pending,
      ),
      VehicleRequest(
        id: 'vr_demo_2',
        companyId: 'cmp_acme',
        employeeId: 9,
        employeeName: 'Dr. Elif Çetin',
        employeeDepartment: 'İş Sağlığı ve Güvenliği',
        employeeTitle: 'İşyeri Hekimi',
        vehicleType: 'Binek Otomobil (Sedan/HB)',
        startDate: now.subtract(const Duration(days: 1, hours: 2)),
        endDate: now.subtract(const Duration(days: 1)),
        destination: 'Bölge Hastanesi Vizite & Sağlık Denetimi',
        purpose: 'İşe giriş periyodik sağlık raporu onayları ve heyet görüşmesi',
        passengerCount: 1,
        needsDriver: false,
        status: VehicleRequestStatus.approved,
        assignedVehicle: '06 ACME 101 - Fiat Egea 1.6 Multijet',
        assignedDriver: 'Personel Kendisi',
        approvalNote: 'Güzergah uygun görüldü, araç anahtarı güvenlikten teslim alınabilir.',
        approvedBy: 'Cenk Vural (Araç Kiralama Sorumlusu)',
      ),
      VehicleRequest(
        id: 'vr_demo_3',
        companyId: 'cmp_acme',
        employeeId: 10,
        employeeName: 'Murat Şen',
        employeeDepartment: 'Ulaşım & Lojistik',
        employeeTitle: 'Servis ve Ulaşım Sorumlusu',
        vehicleType: 'Minibüs / Servis',
        startDate: now.subtract(const Duration(days: 3)),
        endDate: now.subtract(const Duration(days: 3, hours: -6)),
        destination: 'Eryaman - Batıkent Vardiya Servis Ringi',
        purpose: 'Mesaiye kalan yazılım ve teknik ekibin akşam transferi',
        passengerCount: 12,
        needsDriver: true,
        status: VehicleRequestStatus.completed,
        assignedVehicle: '06 PDKS 007 - Mercedes Sprinter 16+1',
        assignedDriver: 'Murat Şen (Servis Sorumlusu)',
        approvalNote: 'Servis planlaması tamamlandı.',
        approvedBy: 'Cenk Vural (Araç Kiralama Sorumlusu)',
      ),
    ]);
    await _persistVehicleRequests();
  }

  // ==========================================
  // BORDRO VE MAAŞ İŞLEMLERİ (PAYROLLS)
  // ==========================================

  List<PayrollSlip> getAllPayrolls() => List.unmodifiable(_payrolls);

  Future<void> insertPayroll(PayrollSlip slip) async {
    final idx = _payrolls.indexWhere((p) => p.id == slip.id);
    if (idx != -1) {
      _payrolls[idx] = slip;
    } else {
      _payrolls.insert(0, slip);
    }
    await _persistPayrolls();
  }

  Future<void> updatePayroll(PayrollSlip slip) async {
    final idx = _payrolls.indexWhere((p) => p.id == slip.id);
    if (idx != -1) {
      _payrolls[idx] = slip;
      await _persistPayrolls();
    }
  }

  Future<void> saveAllPayrolls(List<PayrollSlip> slips) async {
    _payrolls.clear();
    _payrolls.addAll(slips);
    await _persistPayrolls();
  }

  Future<void> bulkUpdatePayrollStatus(int month, int year, String companyId, PayrollStatus status) async {
    bool changed = false;
    for (int i = 0; i < _payrolls.length; i++) {
      if (_payrolls[i].companyId == companyId &&
          _payrolls[i].periodMonth == month &&
          _payrolls[i].periodYear == year) {
        _payrolls[i].status = status;
        changed = true;
      }
    }
    if (changed) {
      await _persistPayrolls();
    }
  }

  Future<void> _persistPayrolls() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      final list = _payrolls.map((p) => p.toJson()).toList();
      await prefs.setString(_keyPayrolls, jsonEncode(list));
    } catch (e) {
      debugPrint('⚠️ Bordrolar diske kaydedilemedi: $e');
    }
  }

  Future<void> _seedDefaultPayrolls() async {
    _payrolls.clear();
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    final prevMonth = currentMonth == 1 ? 12 : currentMonth - 1;
    final prevYear = currentMonth == 1 ? currentYear - 1 : currentYear;

    for (final emp in _employees) {
      if (!emp.isApproved) continue;
      final company = _companies.firstWhere((c) => c.id == emp.companyId, orElse: () => _companies.first);
      final otHours = (emp.id % 2 == 0) ? (emp.id * 2.5) : 0.0;
      final bonus = (emp.role == UserRole.boss || emp.role == UserRole.hr) ? 5000.0 : 0.0;

      // Önceki ay bordrosu (Ödendi)
      _payrolls.add(_buildSeedSlip(
        employee: emp,
        company: company,
        month: prevMonth,
        year: prevYear,
        overtimeHours: otHours,
        bonus: bonus,
        status: PayrollStatus.paid,
      ));

      // Bu ay bordrosu (Onaylandı)
      _payrolls.add(_buildSeedSlip(
        employee: emp,
        company: company,
        month: currentMonth,
        year: currentYear,
        overtimeHours: otHours,
        bonus: bonus,
        status: PayrollStatus.approved,
      ));
    }
    await _persistPayrolls();
  }

  PayrollSlip _buildSeedSlip({
    required Employee employee,
    required Company company,
    required int month,
    required int year,
    double overtimeHours = 0.0,
    double bonus = 0.0,
    PayrollStatus status = PayrollStatus.approved,
  }) {
    final hourlyRate = employee.baseGrossSalary / 225.0;
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
      status: status,
      isSigned: true,
      signatureTimestamp: DateTime(year, month, 28, 17, 30),
    );
  }

  // ==========================================
  // KURUMSAL ROL VE YETKİLER (ROLES)
  // ==========================================

  List<AppRoleItem> getAllRoles() => List.unmodifiable(_roles);

  Future<void> insertRole(AppRoleItem role) async {
    final idx = _roles.indexWhere((r) => r.id == role.id);
    if (idx != -1) {
      _roles[idx] = role;
    } else {
      _roles.add(role);
    }
    await _persistRoles();
  }

  Future<void> updateRole(AppRoleItem role) async {
    final idx = _roles.indexWhere((r) => r.id == role.id);
    if (idx != -1) {
      _roles[idx] = role;
      await _persistRoles();
    }
  }

  Future<void> deleteRole(String roleId) async {
    _roles.removeWhere((r) => r.id == roleId);
    await _persistRoles();
  }

  Future<void> saveAllRoles(List<AppRoleItem> roles) async {
    _roles.clear();
    _roles.addAll(roles);
    await _persistRoles();
  }

  Future<void> _persistRoles() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      final list = _roles.map((r) => r.toJson()).toList();
      await prefs.setString(_keyRoles, jsonEncode(list));
    } catch (e) {
      debugPrint('⚠️ Roller diske kaydedilemedi: $e');
    }
  }

  static List<AppRoleItem> defaultRoles() => const [
    AppRoleItem(
      id: 'role_employee',
      name: 'Personel',
      description: 'Standart mobil devam takip ve QR okuma yetkisi',
      baseRole: UserRole.employee,
      color: Color(0xFF2563EB),
      icon: Icons.badge_outlined,
      isSystemRole: true,
      createdBy: 'Sistem',
      allowedPageIds: [
        'profile', 'payroll', 'chat', 'contacts', 'notifications',
        'cafeteria', 'business_card', 'favorites', 'leave',
        'records', 'field_work', 'overtime', 'vehicle_request',
        'enterprise_hub', 'settings', 'about',
      ],
    ),
    AppRoleItem(
      id: 'role_hr',
      name: 'İnsan Kaynakları (İK)',
      description: 'Personel, puantaj, vardiya ve izin yönetimi yetkileri',
      baseRole: UserRole.hr,
      color: Color(0xFF0284C7),
      icon: Icons.people_alt_outlined,
      isSystemRole: true,
      createdBy: 'Sistem',
      allowedPageIds: [
        'profile', 'payroll', 'chat', 'contacts', 'notifications',
        'cafeteria', 'business_card', 'favorites', 'leave',
        'records', 'field_work', 'overtime', 'vehicle_request',
        'enterprise_hub', 'settings', 'about',
      ],
    ),
    AppRoleItem(
      id: 'role_boss',
      name: 'Patron (Yönetim)',
      description: 'Şirket maliyetleri, devam istatistikleri ve rol ekleme yetkisi',
      baseRole: UserRole.boss,
      color: Color(0xFFD97706),
      icon: Icons.workspace_premium_outlined,
      isSystemRole: true,
      createdBy: 'Sistem',
      allowedPageIds: [
        'profile', 'payroll', 'chat', 'contacts', 'notifications',
        'cafeteria', 'business_card', 'favorites', 'leave',
        'records', 'field_work', 'overtime', 'vehicle_request',
        'enterprise_hub', 'settings', 'about', 'cloud_db',
      ],
    ),
    AppRoleItem(
      id: 'role_admin',
      name: 'Sistem Yöneticisi (Admin)',
      description: 'En yüksek güvenlikli teknik sistem yapılandırma yetkisi',
      baseRole: UserRole.admin,
      color: Color(0xFF9333EA),
      icon: Icons.admin_panel_settings_outlined,
      isSystemRole: true,
      createdBy: 'Sistem',
      allowedPageIds: [
        'profile', 'payroll', 'chat', 'contacts', 'notifications',
        'cafeteria', 'business_card', 'favorites', 'leave',
        'records', 'field_work', 'overtime', 'vehicle_request',
        'enterprise_hub', 'settings', 'about', 'cloud_db',
      ],
    ),
    AppRoleItem(
      id: 'role_cafeteria',
      name: 'Yemekhane Personeli',
      description: 'Yemekhane menüsü düzenleme, yayınlama ve porsiyon takibi yetkileri',
      baseRole: UserRole.cafeteria,
      color: Color(0xFFEA580C),
      icon: Icons.restaurant_menu_rounded,
      isSystemRole: true,
      createdBy: 'Sistem',
      allowedPageIds: [
        'cafeteria', 'profile', 'settings', 'about',
      ],
    ),
    AppRoleItem(
      id: 'role_technician',
      name: 'Teknisyen',
      description: 'Saha teknik bakım, arıza müdahalesi, cihaz kalibrasyonu ve araç talep yetkisi',
      baseRole: UserRole.technician,
      color: Color(0xFF0D9488),
      icon: Icons.build_rounded,
      isSystemRole: true,
      createdBy: 'Sistem',
      allowedPageIds: [
        'profile', 'payroll', 'chat', 'contacts', 'notifications',
        'cafeteria', 'business_card', 'favorites', 'leave',
        'records', 'field_work', 'overtime', 'vehicle_request',
        'enterprise_hub', 'settings', 'about',
      ],
    ),
    AppRoleItem(
      id: 'role_doctor',
      name: 'İşyeri Hekimi (Doktor)',
      description: 'İş sağlığı ve güvenliği, periyodik muayene, vizite kontrolleri ve araç talep yetkisi',
      baseRole: UserRole.doctor,
      color: Color(0xFFE11D48),
      icon: Icons.medical_services_rounded,
      isSystemRole: true,
      createdBy: 'Sistem',
      allowedPageIds: [
        'profile', 'payroll', 'chat', 'contacts', 'notifications',
        'cafeteria', 'business_card', 'favorites', 'leave',
        'records', 'vehicle_request', 'enterprise_hub', 'settings', 'about',
      ],
    ),
    AppRoleItem(
      id: 'role_service_manager',
      name: 'Servis Sorumlusu',
      description: 'Personel servis güzergahları, vardiya servis çizelgesi ve ulaşım koordinasyonu',
      baseRole: UserRole.serviceManager,
      color: Color(0xFF4F46E5),
      icon: Icons.airport_shuttle_rounded,
      isSystemRole: true,
      createdBy: 'Sistem',
      allowedPageIds: [
        'profile', 'payroll', 'chat', 'contacts', 'notifications',
        'cafeteria', 'business_card', 'favorites', 'leave',
        'records', 'vehicle_request', 'enterprise_hub', 'settings', 'about',
      ],
    ),
    AppRoleItem(
      id: 'role_vehicle_rental_manager',
      name: 'Araç Kiralama Sorumlusu',
      description: 'Şirket araç filosu, filo kiralama sözleşmeleri ve araç talep onay & tahsis yönetimi',
      baseRole: UserRole.vehicleRentalManager,
      color: Color(0xFF059669),
      icon: Icons.car_rental_rounded,
      isSystemRole: true,
      createdBy: 'Sistem',
      allowedPageIds: [
        'profile', 'payroll', 'chat', 'contacts', 'notifications',
        'cafeteria', 'business_card', 'favorites', 'leave',
        'records', 'vehicle_request', 'enterprise_hub', 'settings', 'about',
      ],
    ),
  ];

  // ==========================================
  // 2 HAFTALIK YEMEK MENÜSÜ TOHUMLAMA (SEED)
  // ==========================================

  Future<void> _seedDefaultTwoWeekMenu() async {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    _twoWeekMenus.clear();
    final items = [
      {'soup': 'Süzme Mercimek Çorbası', 'soupCal': 160, 'main': 'Hasanpaşa Köfte', 'mainCal': 380, 'side': 'Tereyağlı Pirinç Pilavı', 'sideCal': 210, 'dessert': 'Mevsim Salata & Kazandibi', 'dessertCal': 190, 'veg': 'Zeytinyağlı Enginar & Fırın Sebze', 'vegCal': 260},
      {'soup': 'Yayla Çorbası', 'soupCal': 140, 'main': 'Orman Kebabı', 'mainCal': 390, 'side': 'Şehriyeli Bulgur Pilavı', 'sideCal': 190, 'dessert': 'Kemalpaşa Tatlısı', 'dessertCal': 210, 'veg': 'Mantar Sote & Yoğurtlu Kabak', 'vegCal': 230},
      {'soup': 'Ezogelin Çorbası', 'soupCal': 150, 'main': 'Geleneksel Kuru Fasulye', 'mainCal': 410, 'side': 'Tereyağlı Pirinç Pilavı', 'sideCal': 210, 'dessert': 'Karışık Turşu & Cacık', 'dessertCal': 120, 'veg': 'Zeytinyağlı Barbunya Pilaki', 'vegCal': 280},
      {'soup': 'Tarhana Çorbası', 'soupCal': 150, 'main': 'Fırında Soslu Tavuk Baget', 'mainCal': 360, 'side': 'Elma Dilim Baharatlı Patates', 'sideCal': 200, 'dessert': 'Mozaik Pasta', 'dessertCal': 210, 'veg': 'Fırın Sebze Dizmesi & Humus', 'vegCal': 240},
      {'soup': 'Domates Çorbası (Kaşarlı)', 'soupCal': 150, 'main': 'İzmir Köfte', 'mainCal': 380, 'side': 'Fesleğenli Burgu Makarna', 'sideCal': 220, 'dessert': 'Fırın Sütlaç', 'dessertCal': 210, 'veg': 'Ispanak Graten & Fırın Mantar', 'vegCal': 250},
      {'soup': 'Kremalı Mantar Çorbası', 'soupCal': 160, 'main': 'Çıtır Piliç Şinitzel', 'mainCal': 380, 'side': 'Kremalı Patates Püresi', 'sideCal': 190, 'dessert': 'Supangle & Muz', 'dessertCal': 220, 'veg': 'Falafel Dürüm & Tahin Sos', 'vegCal': 310},
      {'soup': 'Tavuk Suyu Şehriye Çorbası', 'soupCal': 130, 'main': 'Kıymalı Biber Dolması', 'mainCal': 340, 'side': 'Süzme Yoğurt', 'sideCal': 120, 'dessert': 'Haşhaşlı Revani Tatlısı', 'dessertCal': 240, 'veg': 'Zeytinyağlı Taze Fasulye', 'vegCal': 210},
      {'soup': 'Kelle Paça Çorbası', 'soupCal': 180, 'main': 'Tas Kebabı', 'mainCal': 420, 'side': 'Arpa Şehriyeli Pirinç Pilavı', 'sideCal': 210, 'dessert': 'Trileçe', 'dessertCal': 230, 'veg': 'Fırında Mücver & Yoğurt', 'vegCal': 220},
      {'soup': 'Mercimek Çorbası', 'soupCal': 160, 'main': 'Karnıyarık', 'mainCal': 360, 'side': 'Cacık & Salata', 'sideCal': 130, 'dessert': 'Kalburabastı', 'dessertCal': 220, 'veg': 'İmambayıldı & Pirinç Pilavı', 'vegCal': 260},
      {'soup': 'Brokoli Çorbası', 'soupCal': 120, 'main': 'Fırında Somon / Levrek', 'mainCal': 350, 'side': 'Roka Salatası & Fırın Patates', 'sideCal': 170, 'dessert': 'İncir Tatlısı', 'dessertCal': 180, 'veg': 'Kinoa Köftesi & Avokado Salata', 'vegCal': 270},
      {'soup': 'Düğün Çorbası', 'soupCal': 170, 'main': 'Et Sote', 'mainCal': 400, 'side': 'Meyhane Pilavı', 'sideCal': 200, 'dessert': 'Profiterol', 'dessertCal': 240, 'veg': 'Zeytinyağlı Kereviz & Portakal', 'vegCal': 210},
      {'soup': 'Şehriye Çorbası', 'soupCal': 140, 'main': 'Fırında Köfte Patates', 'mainCal': 390, 'side': 'Mevsim Salata', 'sideCal': 90, 'dessert': 'Künefe', 'dessertCal': 280, 'veg': 'Fırında Kaşarlı Karnabahar', 'vegCal': 230},
      {'soup': 'Sebze Çorbası', 'soupCal': 130, 'main': 'Piliç Külbastı', 'mainCal': 350, 'side': 'Soslu Spagetti', 'sideCal': 230, 'dessert': 'Meyve Tabağı', 'dessertCal': 120, 'veg': 'Nohutlu Ispanak Yemeği', 'vegCal': 240},
      {'soup': 'Ezogelin Çorbası', 'soupCal': 150, 'main': 'Etli Nohut Yemeği', 'mainCal': 380, 'side': 'Pirinç Pilavı & Turşu', 'sideCal': 220, 'dessert': 'Ayva Tatlısı', 'dessertCal': 200, 'veg': 'Fırında Güveç Sebze', 'vegCal': 230},
    ];

    for (int i = 0; i < 14; i++) {
      final it = items[i % items.length];
      _twoWeekMenus.add(CafeteriaMenu(
        date: monday.add(Duration(days: i)),
        soup: it['soup'] as String,
        soupCalories: it['soupCal'] as int,
        mainDish: it['main'] as String,
        mainDishCalories: it['mainCal'] as int,
        sideDish: it['side'] as String,
        sideDishCalories: it['sideCal'] as int,
        dessertOrSalad: it['dessert'] as String,
        dessertCalories: it['dessertCal'] as int,
        drink: 'Ayran / Su',
        drinkCalories: 80,
        vegetarianAlternative: it['veg'] as String?,
        vegetarianCalories: it['vegCal'] as int? ?? 250,
      ));
    }
    await _persistTwoWeekMenus();
  }

  Future<void> _persistTwoWeekMenus() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      final list = _twoWeekMenus.map((m) => m.toJson()).toList();
      await prefs.setString(_keyTwoWeekMenus, jsonEncode(list));
    } catch (e) {
      debugPrint('⚠️ 2 Haftalık menü kaydedilemedi: $e');
    }
  }

  // ==========================================
  // KULLANICI TERCİHLERİ (SETTINGS & PREFERENCES)
  // ==========================================

  String? getActiveCompanyId() => _activeCompanyId;
  Future<void> saveActiveCompanyId(String id) async {
    _activeCompanyId = id;
    await _prefs?.setString(_keyActiveCompanyId, id);
  }

  String? getThemeType() => _themeType;
  Future<void> saveThemeType(String theme) async {
    _themeType = theme;
    await _prefs?.setString(_keyThemeMode, theme);
  }

  // ==========================================
  // KURUMSAL EK MODÜLLER (15 ENTERPRISE MODULES)
  // ==========================================

  // 1. Vardiya Takas & Açık Vardiya
  List<ShiftSwapRequest> getAllShiftSwaps() => List.unmodifiable(_shiftSwaps);
  Future<void> insertShiftSwap(ShiftSwapRequest req) async {
    _shiftSwaps.insert(0, req);
    await _persistShiftSwaps();
  }
  Future<void> updateShiftSwapStatus(String id, String status, String approvedBy) async {
    final idx = _shiftSwaps.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _shiftSwaps[idx] = _shiftSwaps[idx].copyWith(status: status, approvedBy: approvedBy);
      await _persistShiftSwaps();
    }
  }
  List<OpenShiftSlot> getAllOpenShiftSlots() => List.unmodifiable(_openShiftSlots);
  Future<void> insertOpenShiftSlot(OpenShiftSlot slot) async {
    _openShiftSlots.add(slot);
    await _persistOpenShifts();
  }
  Future<void> applyToOpenShiftSlot(String slotId, int employeeId) async {
    final idx = _openShiftSlots.indexWhere((s) => s.id == slotId);
    if (idx != -1) {
      final cur = _openShiftSlots[idx];
      if (!cur.appliedEmployeeIds.contains(employeeId)) {
        final updatedList = List<int>.from(cur.appliedEmployeeIds)..add(employeeId);
        _openShiftSlots[idx] = OpenShiftSlot(
          id: cur.id,
          companyId: cur.companyId,
          shiftId: cur.shiftId,
          shiftTitle: cur.shiftTitle,
          date: cur.date,
          requiredHeadcount: cur.requiredHeadcount,
          appliedEmployeeIds: updatedList,
          assignedEmployeeIds: cur.assignedEmployeeIds,
        );
        await _persistOpenShifts();
      }
    }
  }
  Future<void> _persistShiftSwaps() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_keyShiftSwaps, jsonEncode(_shiftSwaps.map((s) => s.toJson()).toList()));
    } catch (_) {}
  }
  Future<void> _persistOpenShifts() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_keyOpenShiftSlots, jsonEncode(_openShiftSlots.map((s) => s.toJson()).toList()));
    } catch (_) {}
  }

  // 2. Teknik Destek & Arıza Bakım (Helpdesk)
  List<HelpdeskTicket> getAllHelpdeskTickets() => List.unmodifiable(_helpdeskTickets);
  Future<void> insertHelpdeskTicket(HelpdeskTicket ticket) async {
    _helpdeskTickets.insert(0, ticket);
    await _persistHelpdeskTickets();
  }
  Future<void> updateHelpdeskTicket(HelpdeskTicket ticket) async {
    final idx = _helpdeskTickets.indexWhere((t) => t.id == ticket.id);
    if (idx != -1) {
      _helpdeskTickets[idx] = ticket;
      await _persistHelpdeskTickets();
    }
  }
  Future<void> assignTechnicianToTicket(String ticketId, int techId, String techName) async {
    final idx = _helpdeskTickets.indexWhere((t) => t.id == ticketId);
    if (idx != -1) {
      _helpdeskTickets[idx] = _helpdeskTickets[idx].copyWith(
        assignedTechnicianId: techId,
        assignedTechnicianName: techName,
        status: 'in_progress',
      );
      await _persistHelpdeskTickets();
    }
  }
  Future<void> resolveHelpdeskTicket(String ticketId, String solutionNotes) async {
    final idx = _helpdeskTickets.indexWhere((t) => t.id == ticketId);
    if (idx != -1) {
      _helpdeskTickets[idx] = _helpdeskTickets[idx].copyWith(
        solutionNotes: solutionNotes,
        status: 'resolved',
        resolvedAt: DateTime.now(),
      );
      await _persistHelpdeskTickets();
    }
  }
  Future<void> _persistHelpdeskTickets() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_keyHelpdeskTickets, jsonEncode(_helpdeskTickets.map((t) => t.toJson()).toList()));
    } catch (_) {}
  }

  // 3. Duyurular & Okundu Onayı
  List<CompanyAnnouncement> getAllAnnouncements() => List.unmodifiable(_announcements);
  Future<void> insertAnnouncement(CompanyAnnouncement announcement) async {
    _announcements.insert(0, announcement);
    await _persistAnnouncements();
  }
  Future<void> markAnnouncementRead(String id, int employeeId) async {
    final idx = _announcements.indexWhere((a) => a.id == id);
    if (idx != -1 && !_announcements[idx].readEmployeeIds.contains(employeeId)) {
      final updated = List<int>.from(_announcements[idx].readEmployeeIds)..add(employeeId);
      _announcements[idx] = _announcements[idx].copyWith(readEmployeeIds: updated);
      await _persistAnnouncements();
    }
  }
  Future<void> confirmAnnouncement(String id, int employeeId) async {
    final idx = _announcements.indexWhere((a) => a.id == id);
    if (idx != -1 && !_announcements[idx].confirmedEmployeeIds.contains(employeeId)) {
      final updatedReads = List<int>.from(_announcements[idx].readEmployeeIds);
      if (!updatedReads.contains(employeeId)) updatedReads.add(employeeId);
      final updatedConfs = List<int>.from(_announcements[idx].confirmedEmployeeIds)..add(employeeId);
      _announcements[idx] = _announcements[idx].copyWith(
        readEmployeeIds: updatedReads,
        confirmedEmployeeIds: updatedConfs,
      );
      await _persistAnnouncements();
    }
  }
  Future<void> deleteAnnouncement(String id) async {
    _announcements.removeWhere((a) => a.id == id);
    await _persistAnnouncements();
  }
  Future<void> _persistAnnouncements() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_keyAnnouncements, jsonEncode(_announcements.map((a) => a.toJson()).toList()));
    } catch (_) {}
  }

  // 4. Personel Özlük Dosyası & İşe Giriş / Çıkış
  List<EmployeeDocument> getAllDocuments() => List.unmodifiable(_documents);
  Future<void> insertDocument(EmployeeDocument doc) async {
    _documents.insert(0, doc);
    await _persistDocuments();
  }
  Future<void> deleteDocument(String id) async {
    _documents.removeWhere((d) => d.id == id);
    await _persistDocuments();
  }
  List<OnboardingTask> getAllOnboardingTasks() => List.unmodifiable(_onboardingTasks);
  Future<void> insertOnboardingTask(OnboardingTask task) async {
    _onboardingTasks.add(task);
    await _persistOnboardingTasks();
  }
  Future<void> toggleOnboardingTask(String id, bool isCompleted) async {
    final idx = _onboardingTasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _onboardingTasks[idx] = _onboardingTasks[idx].copyWith(
        isCompleted: isCompleted,
        completedAt: isCompleted ? DateTime.now() : null,
      );
      await _persistOnboardingTasks();
    }
  }
  Future<void> _persistDocuments() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_keyDocuments, jsonEncode(_documents.map((d) => d.toJson()).toList()));
    } catch (_) {}
  }
  Future<void> _persistOnboardingTasks() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_keyOnboardingTasks, jsonEncode(_onboardingTasks.map((t) => t.toJson()).toList()));
    } catch (_) {}
  }

  // 5. Eğitim & Yetkinlik Takibi
  List<TrainingCourse> getAllTrainingCourses() => List.unmodifiable(_trainingCourses);
  List<EmployeeTrainingRecord> getAllTrainingRecords() => List.unmodifiable(_trainingRecords);
  Future<void> insertTrainingCourse(TrainingCourse course) async {
    _trainingCourses.add(course);
    await _persistTrainingCourses();
  }
  Future<void> assignTrainingCourse(String courseId, String courseTitle, int employeeId, String companyId) async {
    final newRec = EmployeeTrainingRecord(
      id: 'tr_${DateTime.now().millisecondsSinceEpoch}_$employeeId',
      companyId: companyId,
      employeeId: employeeId,
      courseId: courseId,
      courseTitle: courseTitle,
      status: 'assigned',
      score: 0,
    );
    _trainingRecords.add(newRec);
    await _persistTrainingRecords();
  }
  Future<void> completeTrainingCourse(String recordId, int score) async {
    final idx = _trainingRecords.indexWhere((r) => r.id == recordId);
    if (idx != -1) {
      _trainingRecords[idx] = _trainingRecords[idx].copyWith(
        status: 'completed',
        score: score,
        completedDate: DateTime.now(),
        certificateExpiry: DateTime.now().add(const Duration(days: 365)),
      );
      await _persistTrainingRecords();
    }
  }
  Future<void> _persistTrainingCourses() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_keyTrainingCourses, jsonEncode(_trainingCourses.map((c) => c.toJson()).toList()));
    } catch (_) {}
  }
  Future<void> _persistTrainingRecords() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_keyTrainingRecords, jsonEncode(_trainingRecords.map((r) => r.toJson()).toList()));
    } catch (_) {}
  }

  // 6. Performans & Hedef Yönetimi (OKRs)
  List<PerformanceGoal> getAllPerformanceGoals() => List.unmodifiable(_performanceGoals);
  Future<void> insertPerformanceGoal(PerformanceGoal goal) async {
    _performanceGoals.insert(0, goal);
    await _persistPerformanceGoals();
  }
  Future<void> updatePerformanceGoal(PerformanceGoal goal) async {
    final idx = _performanceGoals.indexWhere((g) => g.id == goal.id);
    if (idx != -1) {
      _performanceGoals[idx] = goal;
      await _persistPerformanceGoals();
    }
  }
  Future<void> _persistPerformanceGoals() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_keyPerformanceGoals, jsonEncode(_performanceGoals.map((g) => g.toJson()).toList()));
    } catch (_) {}
  }

  // 7. Ziyaretçi & Taşeron Yönetimi
  List<VisitorRecord> getAllVisitorRecords() => List.unmodifiable(_visitorRecords);
  Future<void> insertVisitorRecord(VisitorRecord visitor) async {
    _visitorRecords.insert(0, visitor);
    await _persistVisitorRecords();
  }
  Future<void> checkInVisitor(String id) async {
    final idx = _visitorRecords.indexWhere((v) => v.id == id);
    if (idx != -1) {
      _visitorRecords[idx] = _visitorRecords[idx].copyWith(
        status: 'inside',
        checkInTime: DateTime.now(),
      );
      await _persistVisitorRecords();
    }
  }
  Future<void> checkOutVisitor(String id) async {
    final idx = _visitorRecords.indexWhere((v) => v.id == id);
    if (idx != -1) {
      _visitorRecords[idx] = _visitorRecords[idx].copyWith(
        status: 'completed',
        checkOutTime: DateTime.now(),
      );
      await _persistVisitorRecords();
    }
  }
  Future<void> _persistVisitorRecords() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_keyVisitorRecords, jsonEncode(_visitorRecords.map((v) => v.toJson()).toList()));
    } catch (_) {}
  }

  // 8. Hibrit Çalışma & Rezervasyon (Masa, Oda, Otopark)
  List<HybridBooking> getAllHybridBookings() => List.unmodifiable(_hybridBookings);
  Future<void> insertHybridBooking(HybridBooking booking) async {
    _hybridBookings.insert(0, booking);
    await _persistHybridBookings();
  }
  Future<void> cancelHybridBooking(String id) async {
    final idx = _hybridBookings.indexWhere((b) => b.id == id);
    if (idx != -1) {
      _hybridBookings[idx] = _hybridBookings[idx].copyWith(status: 'cancelled');
      await _persistHybridBookings();
    }
  }
  Future<void> _persistHybridBookings() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_keyHybridBookings, jsonEncode(_hybridBookings.map((b) => b.toJson()).toList()));
    } catch (_) {}
  }

  // 9. Şubeler & Onay Süreçleri / Vekalet
  List<CompanyBranch> getAllCompanyBranches() => List.unmodifiable(_branches);
  Future<void> insertCompanyBranch(CompanyBranch branch) async {
    _branches.add(branch);
    await _persistCompanyBranches();
  }
  List<ApprovalDelegation> getAllApprovalDelegations() => List.unmodifiable(_delegations);
  Future<void> insertApprovalDelegation(ApprovalDelegation delegation) async {
    _delegations.insert(0, delegation);
    await _persistApprovalDelegations();
  }
  Future<void> toggleApprovalDelegation(String id, bool isActive) async {
    final idx = _delegations.indexWhere((d) => d.id == id);
    if (idx != -1) {
      _delegations[idx] = _delegations[idx].copyWith(isActive: isActive);
      await _persistApprovalDelegations();
    }
  }
  Future<void> _persistCompanyBranches() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_keyCompanyBranches, jsonEncode(_branches.map((b) => b.toJson()).toList()));
    } catch (_) {}
  }
  Future<void> _persistApprovalDelegations() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_keyApprovalDelegations, jsonEncode(_delegations.map((d) => d.toJson()).toList()));
    } catch (_) {}
  }

  // 10. Entegrasyon Merkezi & Çevrimdışı Çalışma Kuyruğu
  List<IntegrationEndpoint> getAllIntegrationEndpoints() => List.unmodifiable(_integrations);
  Future<void> insertIntegrationEndpoint(IntegrationEndpoint ep) async {
    _integrations.add(ep);
    await _persistIntegrations();
  }
  Future<void> updateIntegrationEndpoint(IntegrationEndpoint ep) async {
    final idx = _integrations.indexWhere((e) => e.id == ep.id);
    if (idx != -1) {
      _integrations[idx] = ep;
      await _persistIntegrations();
    }
  }
  List<OfflineSyncItem> getAllOfflineSyncItems() => List.unmodifiable(_offlineQueue);
  Future<void> enqueueOfflineItem(OfflineSyncItem item) async {
    _offlineQueue.add(item);
    await _persistOfflineQueue();
  }
  Future<void> clearOfflineQueue() async {
    _offlineQueue.clear();
    await _persistOfflineQueue();
  }
  Future<void> _persistIntegrations() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_keyIntegrations, jsonEncode(_integrations.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }
  Future<void> _persistOfflineQueue() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_keyOfflineQueue, jsonEncode(_offlineQueue.map((i) => i.toJson()).toList()));
    } catch (_) {}
  }

  // 11. Çalışan Geri Bildirimleri & Anketler
  List<EmployeeFeedback> getAllEmployeeFeedbacks() => List.unmodifiable(_feedbacks);
  Future<void> insertEmployeeFeedback(EmployeeFeedback fb) async {
    _feedbacks.insert(0, fb);
    await _persistFeedbacks();
  }
  Future<void> respondToFeedback(String id, String response) async {
    final idx = _feedbacks.indexWhere((f) => f.id == id);
    if (idx != -1) {
      _feedbacks[idx] = _feedbacks[idx].copyWith(status: 'resolved', hrResponse: response);
      await _persistFeedbacks();
    }
  }
  Future<void> _persistFeedbacks() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_keyFeedbacks, jsonEncode(_feedbacks.map((f) => f.toJson()).toList()));
    } catch (_) {}
  }

  // 12. Kalibrasyon & CMMS Ekipman Sicil Kartları (ISO 9001 / ISO 17025)
  List<EquipmentRecord> getAllEquipmentRecords() => List.unmodifiable(_equipmentRecords);
  Future<void> insertEquipmentRecord(EquipmentRecord eq) async {
    _equipmentRecords.insert(0, eq);
    await _persistEquipmentRecords();
  }
  Future<void> updateEquipmentRecord(EquipmentRecord eq) async {
    final idx = _equipmentRecords.indexWhere((e) => e.id == eq.id);
    if (idx != -1) {
      _equipmentRecords[idx] = eq;
      await _persistEquipmentRecords();
    }
  }
  Future<void> deleteEquipmentRecord(String id) async {
    _equipmentRecords.removeWhere((e) => e.id == id);
    await _persistEquipmentRecords();
  }
  Future<void> _persistEquipmentRecords() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_keyEquipmentRecords, jsonEncode(_equipmentRecords.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  // 13. Periyodik Bakım ve Arıza İş Emirleri (CMMS Work Orders)
  List<MaintenanceWorkOrder> getAllWorkOrders() => List.unmodifiable(_workOrders);
  Future<void> insertWorkOrder(MaintenanceWorkOrder wo) async {
    _workOrders.insert(0, wo);
    await _persistWorkOrders();
  }
  Future<void> updateWorkOrder(MaintenanceWorkOrder wo) async {
    final idx = _workOrders.indexWhere((w) => w.id == wo.id);
    if (idx != -1) {
      _workOrders[idx] = wo;
      await _persistWorkOrders();
    }
  }
  Future<void> _persistWorkOrders() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_keyWorkOrders, jsonEncode(_workOrders.map((w) => w.toJson()).toList()));
    } catch (_) {}
  }

  // 14. Değiştirilemez Denetim Kayıtları (Immutable Audit Log - KVKK & 4857)
  List<AuditLogRecord> getAllAuditLogs() => List.unmodifiable(_auditLogs);
  Future<void> insertAuditLog(AuditLogRecord log) async {
    _auditLogs.insert(0, log);
    await _persistAuditLogs();
  }
  Future<void> _persistAuditLogs() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_keyAuditLogs, jsonEncode(_auditLogs.map((l) => l.toJson()).toList()));
    } catch (_) {}
  }

  // 15. Puantaj ve Dönem Kilitleme (Bordro Tahakkuk Güvenliği)
  List<String> getLockedPeriods() => List.unmodifiable(_lockedPeriods);
  bool isPeriodLocked(String period) => _lockedPeriods.contains(period);
  Future<void> togglePeriodLock(String period) async {
    if (_lockedPeriods.contains(period)) {
      _lockedPeriods.remove(period);
    } else {
      _lockedPeriods.add(period);
    }
    await _persistLockedPeriods();
  }
  Future<void> _persistLockedPeriods() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setStringList(_keyLockedPeriods, _lockedPeriods);
    } catch (_) {}
  }

  // 16. Multi-Tenant Şirket Kodu ve Güvenli PIN Oturum Yönetimi
  String? _inMemoryCompanyCode = 'FABRIKA01';
  int _inMemoryFailedPinAttempts = 0;
  DateTime? _inMemoryPinLockoutUntil;

  String? getSavedCompanyCode() {
    if (_prefs != null && _prefs!.containsKey(_keySavedCompanyCode)) {
      final code = _prefs!.getString(_keySavedCompanyCode);
      return (code != null && code.isNotEmpty) ? code : null;
    }
    return _inMemoryCompanyCode;
  }

  Future<void> saveCompanyCode(String code) async {
    _inMemoryCompanyCode = code;
    await _prefs?.setString(_keySavedCompanyCode, code);
  }

  Future<void> clearCompanyCode() async {
    _inMemoryCompanyCode = null;
    await _prefs?.setString(_keySavedCompanyCode, '');
  }

  String? getLastUserEmail() => _prefs?.getString(_keyLastUserEmail);
  Future<void> saveLastUserEmail(String email) async => await _prefs?.setString(_keyLastUserEmail, email);

  int getFailedPinAttempts() => _prefs?.getInt(_keyFailedPinAttempts) ?? _inMemoryFailedPinAttempts;
  Future<void> setFailedPinAttempts(int count) async {
    _inMemoryFailedPinAttempts = count;
    await _prefs?.setInt(_keyFailedPinAttempts, count);
  }

  DateTime? getPinLockoutUntil() {
    final s = _prefs?.getString(_keyPinLockoutUntil);
    if (s != null) return DateTime.tryParse(s);
    return _inMemoryPinLockoutUntil;
  }

  Future<void> setPinLockoutUntil(DateTime? time) async {
    _inMemoryPinLockoutUntil = time;
    if (time == null) {
      await _prefs?.remove(_keyPinLockoutUntil);
    } else {
      await _prefs?.setString(_keyPinLockoutUntil, time.toIso8601String());
    }
  }

  // 17. Yapay Zeka & Anomali Tespiti (Anti-Buddy Punching)
  List<PdkAnomalyRecord> getAllAnomalies() => List.unmodifiable(_anomalies);
  Future<void> insertAnomaly(PdkAnomalyRecord item) async {
    _anomalies.insert(0, item);
    await _persistAnomalies();
  }
  Future<void> updateAnomaly(PdkAnomalyRecord item) async {
    final idx = _anomalies.indexWhere((a) => a.id == item.id);
    if (idx != -1) {
      _anomalies[idx] = item;
      await _persistAnomalies();
    }
  }
  Future<void> _persistAnomalies() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_keyAnomalies, jsonEncode(_anomalies.map((a) => a.toJson()).toList()));
    } catch (_) {}
  }

  // 18. Yüz Tanıma & Kiosk Terminalleri
  List<FaceEnrollment> getAllFaceEnrollments() => List.unmodifiable(_faceEnrollments);
  Future<void> saveFaceEnrollment(FaceEnrollment item) async {
    _faceEnrollments.removeWhere((f) => f.employeeId == item.employeeId);
    _faceEnrollments.add(item);
    await _persistFaceEnrollments();
  }
  Future<void> _persistFaceEnrollments() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_keyFaceEnrollments, jsonEncode(_faceEnrollments.map((f) => f.toJson()).toList()));
    } catch (_) {}
  }

  List<KioskTerminal> getAllKioskTerminals() => List.unmodifiable(_kioskTerminals);
  Future<void> insertKioskTerminal(KioskTerminal item) async {
    _kioskTerminals.add(item);
    await _persistKioskTerminals();
  }
  Future<void> _persistKioskTerminals() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_keyKioskTerminals, jsonEncode(_kioskTerminals.map((k) => k.toJson()).toList()));
    } catch (_) {}
  }

  // 19. 5070 Sayılı Kanun Uyumlu E-İmza & Belge Arşivi
  List<SignedDocumentRecord> getAllSignedDocuments() => List.unmodifiable(_signedDocuments);
  Future<void> insertSignedDocument(SignedDocumentRecord item) async {
    _signedDocuments.insert(0, item);
    await _persistSignedDocuments();
  }
  Future<void> _persistSignedDocuments() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_keySignedDocuments, jsonEncode(_signedDocuments.map((s) => s.toJson()).toList()));
    } catch (_) {}
  }

  // 20. İSG, Ramak Kala & Tehlikeli Bölge Geofence
  List<NearMissReport> getAllNearMissReports() => List.unmodifiable(_nearMissReports);
  Future<void> insertNearMissReport(NearMissReport item) async {
    _nearMissReports.insert(0, item);
    await _persistNearMissReports();
  }
  Future<void> updateNearMissReport(NearMissReport item) async {
    final idx = _nearMissReports.indexWhere((n) => n.id == item.id);
    if (idx != -1) {
      _nearMissReports[idx] = item;
      await _persistNearMissReports();
    }
  }
  Future<void> _persistNearMissReports() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_keyNearMissReports, jsonEncode(_nearMissReports.map((n) => n.toJson()).toList()));
    } catch (_) {}
  }

  List<SafetyCertificate> getAllSafetyCertificates() => List.unmodifiable(_safetyCertificates);
  Future<void> insertSafetyCertificate(SafetyCertificate item) async {
    _safetyCertificates.add(item);
    await _persistSafetyCertificates();
  }
  Future<void> _persistSafetyCertificates() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_keySafetyCertificates, jsonEncode(_safetyCertificates.map((c) => c.toJson()).toList()));
    } catch (_) {}
  }

  List<HazardZone> getAllHazardZones() => List.unmodifiable(_hazardZones);
  Future<void> insertHazardZone(HazardZone item) async {
    _hazardZones.add(item);
    await _persistHazardZones();
  }
  Future<void> _persistHazardZones() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_keyHazardZones, jsonEncode(_hazardZones.map((h) => h.toJson()).toList()));
    } catch (_) {}
  }

  // 21. Saha Telsizi (PTT) & Ses İletimleri
  List<PttChannel> getAllPttChannels() => List.unmodifiable(_pttChannels);
  Future<void> updatePttChannel(PttChannel item) async {
    final idx = _pttChannels.indexWhere((p) => p.id == item.id);
    if (idx != -1) {
      _pttChannels[idx] = item;
      await _persistPttChannels();
    }
  }
  Future<void> _persistPttChannels() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_keyPttChannels, jsonEncode(_pttChannels.map((p) => p.toJson()).toList()));
    } catch (_) {}
  }

  List<PttVoiceBurst> getAllPttBursts() => List.unmodifiable(_pttBursts);
  Future<void> insertPttBurst(PttVoiceBurst item) async {
    _pttBursts.insert(0, item);
    await _persistPttBursts();
  }
  Future<void> _persistPttBursts() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_keyPttBursts, jsonEncode(_pttBursts.map((b) => b.toJson()).toList()));
    } catch (_) {}
  }

  // 12. Varsayılan Kurumsal Tohumlama (Seed Data for 15 Modules)
  Future<void> _seedDefaultEnterpriseModules() async {
    // Vardiya Takas & Açık Vardiya
    if (_shiftSwaps.isEmpty) {
      _shiftSwaps.add(ShiftSwapRequest(
        id: 'swap_01',
        companyId: 'cmp_acme',
        requesterEmployeeId: 1,
        requesterName: 'Ahmet Yılmaz',
        targetEmployeeId: 2,
        targetName: 'Zeynep Kaya',
        shiftId: 1,
        shiftTitle: 'Standart Ofis Vardiyası',
        targetDate: DateTime.now().add(const Duration(days: 3)),
        reason: 'Şahsi randevu nedeniyle cuma günü takas ricası.',
        status: 'pending',
      ));
      await _persistShiftSwaps();
    }
    if (_openShiftSlots.isEmpty) {
      _openShiftSlots.add(OpenShiftSlot(
        id: 'openshift_01',
        companyId: 'cmp_acme',
        shiftId: 3,
        shiftTitle: 'Hafta Sonu Nöbetçi Ekip',
        date: DateTime.now().add(const Duration(days: 5)),
        requiredHeadcount: 2,
        appliedEmployeeIds: [1],
      ));
      await _persistOpenShifts();
    }

    // Teknik Destek Talepleri
    if (_helpdeskTickets.isEmpty) {
      _helpdeskTickets.addAll([
        HelpdeskTicket(
          id: 'ticket_01',
          companyId: 'cmp_acme',
          requesterId: 1,
          requesterName: 'Ahmet Yılmaz',
          title: '3. Kat Toplantı Odası Projeksiyon Açılmıyor',
          description: 'HDMI kablosu ve güç adaptörü kontrol edildi, sinyal gelmiyor.',
          category: 'it',
          priority: 'high',
          status: 'in_progress',
          assignedTechnicianId: 8,
          assignedTechnicianName: 'Murat Usta (Teknisyen)',
        ),
        HelpdeskTicket(
          id: 'ticket_02',
          companyId: 'cmp_acme',
          requesterId: 2,
          requesterName: 'Zeynep Kaya',
          title: 'Ar-Ge Ofisi Klima Bakım İhtiyacı',
          description: 'Klima soğutma modunda yeterli üflemiyor, filtre temizliği gerekebilir.',
          category: 'facility',
          priority: 'medium',
          status: 'open',
        ),
      ]);
      await _persistHelpdeskTickets();
    }

    // Duyurular
    if (_announcements.isEmpty) {
      _announcements.addAll([
        CompanyAnnouncement(
          id: 'ann_01',
          companyId: 'cmp_acme',
          title: '📢 2026 Hibrit Çalışma ve Masa Rezervasyonu Başladı',
          content: 'Haftalık 2 gün ofis, 3 gün uzaktan çalışma politikamız devreye girmiştir. Ofise geleceğiniz günlerde Hızlı Menü > Hibrit Rezervasyon üzerinden masanızı ayırtmayı unutmayınız.',
          category: 'genel',
          isMandatory: true,
          readEmployeeIds: [1, 2],
          confirmedEmployeeIds: [1],
        ),
        CompanyAnnouncement(
          id: 'ann_02',
          companyId: 'cmp_acme',
          title: '🩺 Yıllık Periyodik Sağlık Muayeneleri Hakkında',
          content: 'İşyeri Hekimimiz Dr. Selin Erdem tarafından revirde yıllık sağlık taramaları başlatılmıştır. Randevu saatlerinizi e-posta üzerinden kontrol edebilirsiniz.',
          category: 'isg',
          isMandatory: false,
          readEmployeeIds: [1],
        ),
      ]);
      await _persistAnnouncements();
    }

    // Özlük Dosyası & İşe Giriş/Çıkış
    if (_documents.isEmpty) {
      _documents.addAll([
        EmployeeDocument(
          id: 'doc_01',
          companyId: 'cmp_acme',
          employeeId: 1,
          title: 'Belirsiz Süreli İş Sözleşmesi',
          documentType: 'contract',
          fileName: 'ahmet_yilmaz_sozlesme_2022.pdf',
          status: 'valid',
        ),
        EmployeeDocument(
          id: 'doc_02',
          companyId: 'cmp_acme',
          employeeId: 1,
          title: 'İleri Düzey Mobil Mimari Sertifikası',
          documentType: 'certificate',
          fileName: 'flutter_certified_eng.pdf',
          expiryDate: DateTime.now().add(const Duration(days: 400)),
          status: 'valid',
        ),
        EmployeeDocument(
          id: 'doc_03',
          companyId: 'cmp_acme',
          employeeId: 1,
          title: 'Ağır ve Tehlikeli İşler Sağlık Raporu',
          documentType: 'health_report',
          fileName: 'saglik_raporu_2025.pdf',
          expiryDate: DateTime.now().add(const Duration(days: 25)),
          status: 'expiring_soon',
        ),
      ]);
      await _persistDocuments();
    }
    if (_onboardingTasks.isEmpty) {
      _onboardingTasks.addAll([
        OnboardingTask(
          id: 'onb_01',
          companyId: 'cmp_acme',
          employeeId: 1,
          processType: 'onboarding',
          title: 'Nüfus Cüzdanı & Diploma Fotokopisi Teslimi',
          category: 'evrak',
          isCompleted: true,
          completedAt: DateTime(2022, 3, 15),
        ),
        OnboardingTask(
          id: 'onb_02',
          companyId: 'cmp_acme',
          employeeId: 1,
          processType: 'onboarding',
          title: 'Kurumsal E-posta & Slack / Teams Tanımlaması',
          category: 'yetki_hesap',
          isCompleted: true,
          completedAt: DateTime(2022, 3, 15),
        ),
        OnboardingTask(
          id: 'onb_03',
          companyId: 'cmp_acme',
          employeeId: 1,
          processType: 'onboarding',
          title: 'Dizüstü Bilgisayar & Güvenlik Kartı Teslimi',
          category: 'it_donanim',
          isCompleted: true,
          completedAt: DateTime(2022, 3, 16),
        ),
        OnboardingTask(
          id: 'onb_04',
          companyId: 'cmp_acme',
          employeeId: 1,
          processType: 'onboarding',
          title: 'Kurumsal Kültür & İK Oryantasyon Eğitimi',
          category: 'oryantasyon',
          isCompleted: true,
          completedAt: DateTime(2022, 3, 18),
        ),
      ]);
      await _persistOnboardingTasks();
    }

    // Eğitim & Yetkinlikler
    if (_trainingCourses.isEmpty) {
      _trainingCourses.addAll([
        TrainingCourse(
          id: 'course_isg',
          companyId: 'cmp_acme',
          title: 'Temel İş Sağlığı ve Güvenliği (İSG) Eğitimi',
          description: '6331 sayılı kanun gereği zorunlu genel iş sağlığı, ilk yardım ve tahliye eğitimi.',
          category: 'isg',
          durationMinutes: 120,
          passingScore: 70,
          validityMonths: 12,
        ),
        TrainingCourse(
          id: 'course_kvkk',
          companyId: 'cmp_acme',
          title: 'KVKK & Bilgi Güvenliği Farkındalık Eğitimi',
          description: 'Kişisel verilerin korunması, parola güvenliği ve phishing saldırılarına karşı önlemler.',
          category: 'kvkk',
          durationMinutes: 45,
          passingScore: 80,
          validityMonths: 24,
        ),
      ]);
      await _persistTrainingCourses();
    }
    if (_trainingRecords.isEmpty) {
      _trainingRecords.addAll([
        EmployeeTrainingRecord(
          id: 'tr_rec_01',
          companyId: 'cmp_acme',
          employeeId: 1,
          courseId: 'course_isg',
          courseTitle: 'Temel İş Sağlığı ve Güvenliği (İSG) Eğitimi',
          status: 'completed',
          score: 95,
          completedDate: DateTime.now().subtract(const Duration(days: 60)),
          certificateExpiry: DateTime.now().add(const Duration(days: 305)),
        ),
        EmployeeTrainingRecord(
          id: 'tr_rec_02',
          companyId: 'cmp_acme',
          employeeId: 1,
          courseId: 'course_kvkk',
          courseTitle: 'KVKK & Bilgi Güvenliği Farkındalık Eğitimi',
          status: 'assigned',
          score: 0,
        ),
      ]);
      await _persistTrainingRecords();
    }

    // Performans & Hedefler
    if (_performanceGoals.isEmpty) {
      _performanceGoals.addAll([
        PerformanceGoal(
          id: 'goal_01',
          companyId: 'cmp_acme',
          employeeId: 1,
          employeeName: 'Ahmet Yılmaz',
          period: '2026 Q1',
          title: 'Mobil PDKS Çevrimdışı ve Veritabanı Mimarisi',
          description: 'İnternet kesintilerinde veri kaybını önleyen yerel SQLite/IndexedDB kuyruk sistemini devreye alma.',
          weightPercentage: 50.0,
          currentProgress: 90.0,
          selfRating: 4.8,
          managerRating: 5.0,
          managerFeedback: 'Saha testlerinde mükemmel sonuç alındı, performansı tebrik ederim.',
          status: 'reviewed',
        ),
        PerformanceGoal(
          id: 'goal_02',
          companyId: 'cmp_acme',
          employeeId: 1,
          employeeName: 'Ahmet Yılmaz',
          period: '2026 Q1',
          title: 'Kiosk Biyometrik ve QR Doğrulama Entegrasyonu',
          description: 'Tablet kiosk üzerinde 1 saniyenin altında QR kod ve temassız okutma tepki süresi yakalama.',
          weightPercentage: 50.0,
          currentProgress: 75.0,
          status: 'active',
        ),
      ]);
      await _persistPerformanceGoals();
    }

    // Ziyaretçi & Taşeron Kayıtları
    if (_visitorRecords.isEmpty) {
      _visitorRecords.addAll([
        VisitorRecord(
          id: 'vis_01',
          companyId: 'cmp_acme',
          visitorFullName: 'Murat Arslan',
          visitorCompany: 'Nova Savunma Teknolojileri',
          visitorPhone: '0533 111 22 33',
          hostEmployeeId: 1,
          hostEmployeeName: 'Ahmet Yılmaz',
          purpose: 'Kurumsal Entegrasyon & API İnceleme Toplantısı',
          expectedDate: DateTime.now(),
          qrPassCode: 'PASS-ACME-4455',
          status: 'inside',
          checkInTime: DateTime.now().subtract(const Duration(minutes: 45)),
        ),
        VisitorRecord(
          id: 'vis_02',
          companyId: 'cmp_acme',
          visitorFullName: 'Kemal Güneş',
          visitorCompany: 'TeknoBakım Elektrik Ltd.',
          visitorPhone: '0542 999 88 77',
          hostEmployeeId: 8,
          hostEmployeeName: 'Murat Usta (Teknisyen)',
          purpose: 'Trafo ve Kesintisiz Güç Kaynağı Periyodik Bakımı',
          expectedDate: DateTime.now().add(const Duration(days: 1)),
          qrPassCode: 'PASS-ACME-8899',
          status: 'pre_registered',
          isContractor: true,
          hasSafetyBriefing: true,
        ),
      ]);
      await _persistVisitorRecords();
    }

    // Hibrit Rezervasyonlar
    if (_hybridBookings.isEmpty) {
      _hybridBookings.addAll([
        HybridBooking(
          id: 'res_01',
          companyId: 'cmp_acme',
          employeeId: 1,
          employeeName: 'Ahmet Yılmaz',
          resourceType: 'desk',
          resourceCode: 'Masa A-14 (Monitörlü Çalışma İstasyonu)',
          date: DateTime.now(),
          timeSlot: 'Tam Gün (08:30 - 18:00)',
          status: 'confirmed',
        ),
        HybridBooking(
          id: 'res_02',
          companyId: 'cmp_acme',
          employeeId: 2,
          employeeName: 'Zeynep Kaya',
          resourceType: 'meeting_room',
          resourceCode: 'Toplantı Odası Orion (10 Kişilik)',
          date: DateTime.now().add(const Duration(days: 1)),
          timeSlot: '14:00 - 15:30',
          status: 'confirmed',
        ),
      ]);
      await _persistHybridBookings();
    }

    // Şubeler & Onay Vekaleti
    if (_branches.isEmpty) {
      _branches.addAll([
        CompanyBranch(
          id: 'br_ank',
          companyId: 'cmp_acme',
          name: 'Ankara Ar-Ge & İnovasyon Kampüsü',
          code: 'ANK-01',
          city: 'Ankara',
          address: 'ODTÜ Teknokent Silikon Blok No: 4',
          managerId: 3,
          managerName: 'Mehmet Demir',
          departments: ['Yazılım & Ar-Ge', 'İnsan Kaynakları', 'Sistem Yönetimi'],
          employeeCount: 42,
        ),
        CompanyBranch(
          id: 'br_ist',
          companyId: 'cmp_acme',
          name: 'İstanbul Finans & Satış Ofisi',
          code: 'IST-02',
          city: 'İstanbul',
          address: 'Büyükdere Cd. Levent Plaza No: 18',
          managerId: 4,
          managerName: 'Canan Can',
          departments: ['Finans & Muhasebe', 'Kurumsal Satış', 'Müşteri Başarısı'],
          employeeCount: 28,
        ),
      ]);
      await _persistCompanyBranches();
    }
    if (_delegations.isEmpty) {
      _delegations.add(ApprovalDelegation(
        id: 'del_01',
        companyId: 'cmp_acme',
        managerId: 2,
        managerName: 'Zeynep Kaya (İK Direktörü)',
        delegateEmployeeId: 1,
        delegateEmployeeName: 'Ahmet Yılmaz',
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        scope: 'leave',
        isActive: false,
      ));
      await _persistApprovalDelegations();
    }

    // Entegrasyonlar & Çevrimdışı Kuyruk
    if (_integrations.isEmpty) {
      _integrations.addAll([
        IntegrationEndpoint(
          id: 'int_logo',
          companyId: 'cmp_acme',
          name: 'Logo Tiger ERP Muhasebe Aktarımı',
          systemType: 'erp',
          status: 'active',
          syncedRecordsCount: 2450,
          failedRecordsCount: 0,
          apiEndpoint: 'https://erp.acmeteknoloji.com/api/v2/pdks',
        ),
        IntegrationEndpoint(
          id: 'int_zk',
          companyId: 'cmp_acme',
          name: 'ZKTeco Turnike & Kart Okuyucu Gateway',
          systemType: 'turnstile',
          status: 'active',
          syncedRecordsCount: 4890,
          failedRecordsCount: 1,
          apiEndpoint: 'tcp://192.168.1.100:4370',
        ),
        IntegrationEndpoint(
          id: 'int_sap',
          companyId: 'cmp_acme',
          name: 'SAP SuccessFactors İK & Bordro Köprüsü',
          systemType: 'payroll',
          status: 'active',
          syncedRecordsCount: 1120,
          failedRecordsCount: 0,
          apiEndpoint: 'https://api.successfactors.eu/odata/v2',
        ),
      ]);
      await _persistIntegrations();
    }
    if (_offlineQueue.isEmpty) {
      _offlineQueue.add(OfflineSyncItem(
        id: 'off_01',
        companyId: 'cmp_acme',
        actionType: 'field_work',
        payload: {'employeeId': 1, 'note': 'Müşteri sahası kontrolü tamamlandı'},
        syncStatus: 'synced',
      ));
      await _persistOfflineQueue();
    }

    // Çalışan Geri Bildirimleri & Anketler
    if (_feedbacks.isEmpty) {
      _feedbacks.addAll([
        EmployeeFeedback(
          id: 'fb_01',
          companyId: 'cmp_acme',
          category: 'suggestion',
          title: 'Yemekhanede Sağlıklı Atıştırmalık & Meyve Günleri',
          content: 'Haftanın iki günü ara öğünlerde elma, muz ve kuruyemiş ikramı yapılabilirse çalışma enerjimiz artacaktır.',
          isAnonymous: false,
          submitterEmployeeId: 1,
          submitterName: 'Ahmet Yılmaz',
          rating: 5,
          status: 'resolved',
          hrResponse: 'Harika bir öneri! Önümüzdeki pazartesiden itibaren her salı ve perşembe taze meyve sepetleri ofis katlarına dağıtılacaktır.',
        ),
        EmployeeFeedback(
          id: 'fb_02',
          companyId: 'cmp_acme',
          category: 'survey',
          title: '2026 Çalışma Alanı & Esnek Mesai Memnuniyeti',
          content: 'Ofis içi sessiz odaklanma kabinleri ve ergonomik sandalyeler çalışmayı çok keyifli kılıyor.',
          isAnonymous: true,
          rating: 5,
          status: 'submitted',
        ),
      ]);
      await _persistFeedbacks();
    }

    // Kalibrasyon & CMMS Ekipman Sicil Kartları (ISO 9001 / ISO 17025)
    if (_equipmentRecords.isEmpty) {
      _equipmentRecords.addAll([
        EquipmentRecord(
          id: 'eq_01',
          companyId: 'cmp_acme',
          equipmentCode: 'CNC-01',
          serialNumber: 'DMG-2024-8841',
          name: '5 Eksen CNC Freze & İşleme Merkezi',
          brandModel: 'DMG MORI DMU 50',
          department: 'Üretim Departmanı',
          location: 'Talaşlı İmalat Holü - İstasyon 1',
          warrantyExpiryDate: DateTime.now().add(const Duration(days: 450)),
          qrBarcode: 'EQ-CNC-01-DMG-2024',
          calibrationPeriodMonths: 12,
          lastCalibrationDate: DateTime.now().subtract(const Duration(days: 200)),
          nextCalibrationDate: DateTime.now().add(const Duration(days: 165)),
          referenceStandard: 'ISO 17025 / TÜRKAK Akredite',
          toleranceLimit: '±0.005 mm',
          certificatePdfUrl: 'sertifika_cnc_01_2026.pdf',
          status: 'active',
        ),
        EquipmentRecord(
          id: 'eq_02',
          companyId: 'cmp_acme',
          equipmentCode: 'MIC-04',
          serialNumber: 'MIT-883921',
          name: 'Dijital Kumpas & Mikrometre Takımı',
          brandModel: 'Mitutoyo Digimatic 0-150mm',
          department: 'Kalite Kontrol',
          location: 'Ölçüm & Metroloji Odası',
          warrantyExpiryDate: DateTime.now().add(const Duration(days: 200)),
          qrBarcode: 'EQ-MIC-04-MIT-2024',
          calibrationPeriodMonths: 6,
          lastCalibrationDate: DateTime.now().subtract(const Duration(days: 178)),
          nextCalibrationDate: DateTime.now().add(const Duration(days: 2)),
          referenceStandard: 'ISO 17025 / DIN 862',
          toleranceLimit: '±0.001 mm',
          certificatePdfUrl: 'sertifika_mic_04_2026.pdf',
          status: 'warning_3d',
        ),
        EquipmentRecord(
          id: 'eq_03',
          companyId: 'cmp_acme',
          equipmentCode: 'TRN-02',
          serialNumber: 'ZK-PROX-9902',
          name: 'RFID & Biyometrik Turnike Geçiş Terminali 2',
          brandModel: 'ZKTeco ProCapture-X',
          department: 'Güvenlik & İdari İşler',
          location: 'Ana Bina Personel Girişi B Kapısı',
          warrantyExpiryDate: DateTime.now().subtract(const Duration(days: 30)),
          qrBarcode: 'EQ-TRN-02-ZK-2023',
          calibrationPeriodMonths: 12,
          lastCalibrationDate: DateTime.now().subtract(const Duration(days: 380)),
          nextCalibrationDate: DateTime.now().subtract(const Duration(days: 15)),
          referenceStandard: 'ISO 9001:2015 Madde 7.1.5',
          toleranceLimit: 'Optik Doğrulama %99.9',
          certificatePdfUrl: 'sertifika_trn_02_gecmis.pdf',
          status: 'quarantine',
          quarantineReason: 'Yıllık doğrulama periyodu aşıldı ve optik sensör tolerans dışı (ISO 9001 uyarınca kullanım dışı)',
        ),
        EquipmentRecord(
          id: 'eq_04',
          companyId: 'cmp_acme',
          equipmentCode: 'TERMO-01',
          serialNumber: 'FLUKE-802-99',
          name: 'Hassas Sıcaklık ve Bağıl Nem Kalibratörü',
          brandModel: 'Fluke 971 Metrology Grade',
          department: 'AR-GE Laboratuvarı',
          location: 'Temiz Oda (Cleanroom Class 1000)',
          warrantyExpiryDate: DateTime.now().add(const Duration(days: 600)),
          qrBarcode: 'EQ-TERMO-01-FLUKE',
          calibrationPeriodMonths: 12,
          lastCalibrationDate: DateTime.now().subtract(const Duration(days: 345)),
          nextCalibrationDate: DateTime.now().add(const Duration(days: 20)),
          referenceStandard: 'ISO 17025 / NIST Standard',
          toleranceLimit: '±0.1°C / ±1.5% RH',
          certificatePdfUrl: 'sertifika_termo_01_fluke.pdf',
          status: 'warning_30d',
        ),
      ]);
      await _persistEquipmentRecords();
    }

    // Periyodik Bakım & Arıza İş Emirleri (CMMS Work Orders)
    if (_workOrders.isEmpty) {
      _workOrders.addAll([
        MaintenanceWorkOrder(
          id: 'wo_01',
          companyId: 'cmp_acme',
          equipmentId: 'eq_01',
          equipmentCode: 'CNC-01',
          equipmentName: '5 Eksen CNC Freze & İşleme Merkezi',
          title: 'Haftalık Spindle Yağlama ve Kızak Boşluk Kontrolü',
          description: 'X/Y eksen cetvelleri temizlenecek, ISO VG 68 kızak yağı tamamlanacak.',
          priority: 'high',
          status: 'in_progress',
          reportedBy: 'Ahmet Yılmaz',
          reportedAt: DateTime.now().subtract(const Duration(hours: 4)),
          assignedTechnicianId: 8,
          assignedTechnicianName: 'Murat Usta (Teknisyen)',
          startedAt: DateTime.now().subtract(const Duration(hours: 2)),
          checklist: [
            ChecklistItem(id: 'c1', title: 'Hava basıncı 6 bar kontrolü', isDone: true),
            ChecklistItem(id: 'c2', title: 'Merkezi yağlama haznesi dolumu', isDone: true),
            ChecklistItem(id: 'c3', title: 'Spindle salgı komparatör ölçümü', isDone: false),
          ],
          partsUsed: [
            SparePartItem(partName: 'ISO VG 68 Hidrolik Kızak Yağı (1L)', quantity: 2, unitCost: 350.0),
          ],
          totalCost: 700.0,
          mttrMinutes: 120,
          downtimeMinutes: 45,
        ),
        MaintenanceWorkOrder(
          id: 'wo_02',
          companyId: 'cmp_acme',
          equipmentId: 'eq_03',
          equipmentCode: 'TRN-02',
          equipmentName: 'RFID & Biyometrik Turnike Geçiş Terminali 2',
          title: 'Turnike Kart Okuyucu Tepki Vermiyor (Karantinada)',
          description: 'Ağ kablosu ve PoE güç beslemesi test edilecek, firmware yeniden yüklenecek.',
          priority: 'urgent',
          status: 'open',
          reportedBy: 'Canan Can',
          reportedAt: DateTime.now().subtract(const Duration(minutes: 40)),
          assignedTechnicianId: 8,
          assignedTechnicianName: 'Murat Usta (Teknisyen)',
          checklist: [
            ChecklistItem(id: 'tc1', title: 'RJ45 Ağ soketi kontrolü', isDone: false),
            ChecklistItem(id: 'tc2', title: 'RFID okuyucu anten sinyal testi', isDone: false),
          ],
          totalCost: 0.0,
        ),
      ]);
      await _persistWorkOrders();
    }

    // Değiştirilemez Denetim Kayıtları (Immutable Audit Log)
    if (_auditLogs.isEmpty) {
      _auditLogs.addAll([
        AuditLogRecord(
          id: 'audit_01',
          companyId: 'cmp_acme',
          userId: 1,
          userName: 'Ahmet Yılmaz',
          userRole: 'Sistem Yöneticisi',
          ipAddress: '192.168.1.105',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          actionType: 'Kalibrasyon Karantina',
          targetEntity: 'EquipmentRecord',
          entityId: 'eq_03',
          oldValue: 'status: active',
          newValue: 'status: quarantine (ISO 9001 uyarınca kullanım dışı)',
        ),
        AuditLogRecord(
          id: 'audit_02',
          companyId: 'cmp_acme',
          userId: 2,
          userName: 'Zeynep Kaya',
          userRole: 'İK Yöneticisi',
          ipAddress: '192.168.1.112',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          actionType: 'Fazla Mesai Onayı',
          targetEntity: 'AttendanceRecord',
          entityId: 'rec_449',
          oldValue: 'approvedOvertime: 0.0',
          newValue: 'approvedOvertime: 2.5 (4857 Madde 41 onaylandı)',
        ),
      ]);
      await _persistAuditLogs();
    }

    // Kilitli Puantaj Dönemi (Örn. Geçen ayın bordrosu kapalı)
    if (_lockedPeriods.isEmpty) {
      final prevMonth = DateTime.now().subtract(const Duration(days: 35));
      final monthStr = '${prevMonth.year}-${prevMonth.month.toString().padLeft(2, '0')}';
      _lockedPeriods.add(monthStr);
      await _persistLockedPeriods();
    }

    _seedEnterpriseDefaultDataSync();
    await _persistAnomalies();
    await _persistFaceEnrollments();
    await _persistKioskTerminals();
    await _persistSignedDocuments();
    await _persistNearMissReports();
    await _persistSafetyCertificates();
    await _persistHazardZones();
    await _persistPttChannels();
    await _persistPttBursts();
  }

  void _seedEnterpriseDefaultDataSync() {
    // 32. Yapay Zeka Anomali & Sahte Geçiş (Anti-Buddy Punching) Tohumları
    if (_anomalies.isEmpty) {
      _anomalies.addAll([
        PdkAnomalyRecord(
          id: 'anom_01',
          companyId: 'cmp_acme',
          employeeId: 1,
          employeeName: 'Ahmet Yılmaz',
          anomalyType: 'buddy_punching_suspected',
          severity: 'critical',
          title: 'Şüpheli Başkası Yerine Kart Basma (Buddy Punching)',
          description: 'Aynı RFID turnikesinden 2.1 saniye arayla peş peşe 2 giriş tespit edildi. Kiosk kamera görüntüsünde tek kişi mevcuttu.',
          detectedAt: DateTime.now().subtract(const Duration(hours: 2)),
          status: 'pending',
          evidenceData: {'turnstileId': 'TRN-01', 'intervalSeconds': 2.1, 'cameraConfidence': 0.22},
        ),
        PdkAnomalyRecord(
          id: 'anom_02',
          companyId: 'cmp_acme',
          employeeId: 8,
          employeeName: 'Murat Usta (Teknisyen)',
          anomalyType: 'abnormal_overtime_surge',
          severity: 'warning',
          title: 'Haftalık Yasal Fazla Mesai Yoğunluğu (4857 Madde 41)',
          description: 'Haftalık toplam çalışma süresi 58 saati aştı. Son 3 günde günlük 11 saatlik dinlenme süresi sınırına yaklaşıldı.',
          detectedAt: DateTime.now().subtract(const Duration(hours: 5)),
          status: 'pending',
          evidenceData: {'weeklyHours': 58.5, 'consecutiveDays': 5},
        ),
      ]);
    }

    // 33. Yüz Tanıma Profilleri
    if (_faceEnrollments.isEmpty) {
      _faceEnrollments.addAll([
        FaceEnrollment(
          employeeId: 1,
          employeeName: 'Ahmet Yılmaz',
          faceVectorHash: 'e7b8c9d0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0',
          enrolledAt: DateTime.now().subtract(const Duration(days: 30)),
          isLivenessVerified: true,
          confidenceScore: 0.992,
        ),
        FaceEnrollment(
          employeeId: 2,
          employeeName: 'Zeynep Kaya',
          faceVectorHash: 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4',
          enrolledAt: DateTime.now().subtract(const Duration(days: 25)),
          isLivenessVerified: true,
          confidenceScore: 0.987,
        ),
      ]);
    }

    // 34. Kiosk & Turnike Donanım Terminalleri
    if (_kioskTerminals.isEmpty) {
      _kioskTerminals.addAll([
        KioskTerminal(
          terminalId: 'kiosk_01',
          companyId: 'cmp_acme',
          terminalName: 'Fabrika Ana Giriş Turnike A1',
          location: 'A Blok Güvenlik Nizamiyesi',
          ipAddress: '192.168.1.201',
          mode: 'hybrid',
          isOnline: true,
          lastHeartbeat: DateTime.now(),
          totalScansToday: 218,
        ),
        KioskTerminal(
          terminalId: 'kiosk_02',
          companyId: 'cmp_acme',
          terminalName: 'Atölye & İmalat Kiosk Duvar Tableti',
          location: 'B Blok CNC & Pres Atölyesi',
          ipAddress: '192.168.1.202',
          mode: 'facial',
          isOnline: true,
          lastHeartbeat: DateTime.now(),
          totalScansToday: 84,
        ),
      ]);
    }

    // 35. 5070 E-İmza & Bordro Belgeleri
    if (_signedDocuments.isEmpty) {
      _signedDocuments.add(
        SignedDocumentRecord(
          id: 'doc_01',
          companyId: 'cmp_acme',
          employeeId: 1,
          employeeName: 'Ahmet Yılmaz',
          documentType: 'payroll_slip',
          documentTitle: '2026 Ekim Ayı Maaş Bordro Pusulası',
          period: '2026-10',
          signatureSvgOrPoints: 'POINTS:M12,45 C20,30 40,60 70,25 S90,80 120,40',
          signedAt: DateTime.now().subtract(const Duration(days: 2)),
          signerIp: '192.168.1.105',
          isVerified5070: true,
        ),
      );
    }

    // 36. Ramak Kala (Near-Miss) İSG Olay Bildirimleri
    if (_nearMissReports.isEmpty) {
      _nearMissReports.addAll([
        NearMissReport(
          id: 'nm_01',
          companyId: 'cmp_acme',
          reporterId: 8,
          reporterName: 'Murat Usta (Teknisyen)',
          title: 'CNC-01 Tezgahı Çevresinde Hidrolik Yağ Sızıntısı',
          description: 'Kızak yağı tahliyesinde sızıntı var, zemin aşırı kaygan. Bir çalışan neredeyse kayıp düşüyordu.',
          department: 'Üretim & İmalat',
          locationDetail: 'CNC-01 ve Pres Hattı 3. Koridor',
          riskLevel: 'high',
          reportedAt: DateTime.now().subtract(const Duration(hours: 6)),
          status: 'action_taken',
          correctiveAction: 'Bölge emniyet şeridine alındı, keçeler serildi.',
        ),
        NearMissReport(
          id: 'nm_02',
          companyId: 'cmp_acme',
          reporterId: 1,
          reporterName: 'Ahmet Yılmaz',
          title: 'Trafo Odası Yan Panosunda Açık Klemens',
          description: 'Aydınlatma panosunun kapağı açık kalmış ve 380V açık baralar çıplak duruyor.',
          department: 'Enerji & Altyapı',
          locationDetail: 'Trafo Binası Zemin Kat',
          riskLevel: 'critical',
          reportedAt: DateTime.now().subtract(const Duration(hours: 1)),
          status: 'open',
        ),
      ]);
    }

    // 37. Personel İSG Sertifikaları & Sağlık Muayeneleri
    if (_safetyCertificates.isEmpty) {
      _safetyCertificates.addAll([
        SafetyCertificate(
          id: 'cert_01',
          employeeId: 8,
          employeeName: 'Murat Usta (Teknisyen)',
          certificateType: 'high_altitude',
          title: 'Yüksekte Çalışma & İskele Kurulum Yetki Belgesi (IRATA L1)',
          issueDate: DateTime.now().subtract(const Duration(days: 300)),
          expiryDate: DateTime.now().add(const Duration(days: 65)),
          issuingOrganization: 'TMMOB & Akredite İSG Enstitüsü',
        ),
        SafetyCertificate(
          id: 'cert_02',
          employeeId: 2,
          employeeName: 'Zeynep Kaya',
          certificateType: 'first_aid',
          title: 'Temel İlk Yardım ve Acil Durum Müdahale Sertifikası',
          issueDate: DateTime.now().subtract(const Duration(days: 400)),
          expiryDate: DateTime.now().subtract(const Duration(days: 10)),
          issuingOrganization: 'Kızılay & Sağlık Bakanlığı',
        ),
      ]);
    }

    // 38. Tehlikeli Bölge ve Zorunlu KKD Alanları
    if (_hazardZones.isEmpty) {
      _hazardZones.addAll([
        HazardZone(
          id: 'hz_01',
          companyId: 'cmp_acme',
          zoneName: 'Ağır Pres & CNC İmalat Alanı',
          requiredPPE: ['Baret (EN 397)', 'Çelik Burunlu Ayakkabı (S3)', 'Koruyucu Çapak Gözlüğü'],
          centerLat: 40.01461,
          centerLng: 32.51520,
          radiusMeters: 60.0,
          warningMessage: 'DİKKAT: Yüksek ses ve mekanik sıkışma tehlikesi! Baret ve S3 ayakkabı giyilmesi zorunludur.',
        ),
        HazardZone(
          id: 'hz_02',
          companyId: 'cmp_acme',
          zoneName: 'Yüksek Gerilim Trafo & Şalt Sahası',
          requiredPPE: ['Yalıtkan Baret', 'Ark Koruyucu Siperlik', '1000V Dielektrik Eldiven'],
          centerLat: 40.01490,
          centerLng: 32.51580,
          radiusMeters: 30.0,
          warningMessage: 'HAYATİ TEHLİKE: Yetkisiz giriş yasaktır! Yalnızca EKAT belgeli personel girebilir.',
        ),
      ]);
    }

    // 39. Saha Telsizi (PTT) Kanalları
    if (_pttChannels.isEmpty) {
      _pttChannels.addAll([
        PttChannel(
          id: 'ptt_01',
          companyId: 'cmp_acme',
          channelName: 'Kanal 1: Saha Güvenlik & Amirleri',
          description: 'Nizamiye, çevre güvenlik ve ziyaretçi geçiş telsiz kanalı.',
          activeParticipantsCount: 6,
        ),
        PttChannel(
          id: 'ptt_02',
          companyId: 'cmp_acme',
          channelName: 'Kanal 2: Bakım & Arıza Teknisyenleri',
          description: 'Mekanik, elektrik ve turnike arıza koordinasyon telsizi.',
          activeParticipantsCount: 8,
        ),
        PttChannel(
          id: 'ptt_03',
          companyId: 'cmp_acme',
          channelName: 'Kanal 3: İSG & Acil Müdahale',
          description: 'Yangın, ilk yardım ve acil durum tahliye frekansı.',
          activeParticipantsCount: 12,
        ),
      ]);
    }

    // 40. PTT Ses İletimleri
    if (_pttBursts.isEmpty) {
      _pttBursts.addAll([
        PttVoiceBurst(
          burstId: 'burst_01',
          channelId: 'ptt_02',
          speakerId: 8,
          speakerName: 'Murat Usta (Teknisyen)',
          speakerRole: 'Bakım Sorumlusu',
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
          durationSeconds: 4,
          transcriptText: 'Merkez, Turnike 2 kart okuyucusu firmware güncellemesi tamamlandı, turnike aktif.',
          waveformPoints: [0.2, 0.6, 0.9, 0.8, 0.4, 0.7, 0.9, 0.5, 0.2],
        ),
      ]);
    }
  }

  // ==========================================
  // VERİTABANI YENİDEN YÜKLEME (RELOAD ALL)
  // ==========================================

  Future<void> reloadAll() async {
    await init(forceReload: true);
  }
}
