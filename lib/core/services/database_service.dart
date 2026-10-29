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

/// PDKS Kurumsal Veritabanı Servisi (Persistent Database Engine)
/// SharedPreferences / IndexedDB / Web LocalStorage üzerinde kalıcı veri yönetimi
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

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
  static const String _keyQuickMenu = 'pdks_db_quick_menu_v1';
  static const String _keyPageCustomizations = 'pdks_db_page_customizations_v1';

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
  final Map<String, PageCustomization> _pageCustomizations = {};
  CafeteriaMenu? _todayMenu;

  bool get isInitialized => _isInitialized;

  /// Veritabanını Başlat ve Kalıcı Depodan Verileri Yükle
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
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
  }

  /// Varsayılan Veritabanı Tohumlama (Seed Data)
  Future<void> _seedDefaultDatabase() async {
    if (_companies.isEmpty) {
      _companies.addAll([
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
      ]);
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
      ]);
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

  List<Company> getAllCompanies() => List.unmodifiable(_companies);

  Company? getCompanyByCode(String code) {
    final clean = code.trim().toUpperCase();
    try {
      return _companies.firstWhere((c) => c.code.toUpperCase() == clean);
    } catch (_) {
      return null;
    }
  }

  Future<void> insertCompany(Company company) async {
    _companies.add(company);
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

  // ==========================================
  // VARDİYALAR & YEMEKHANE MENÜSÜ (DATABASE)
  // ==========================================

  List<ShiftSchedule> getAllShifts() => List.unmodifiable(_shifts);

  Future<void> insertShift(ShiftSchedule shift) async {
    _shifts.add(shift);
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
}
