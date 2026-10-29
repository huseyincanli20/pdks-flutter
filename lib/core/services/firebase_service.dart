import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/employee.dart';
import '../../models/chat_message.dart';
import '../../models/app_notification.dart';
import '../../models/attendance_record.dart';
import '../../models/leave_request.dart';
import 'database_service.dart';

/// Firebase Bulut Veritabanı ve Senkronizasyon Servisi
/// Google Firebase Firestore ve Realtime Database REST API üzerinden tüm cihazlarla canlı eşitlenir.
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  static const String _prefKeyFirebaseProject = 'pdks_firebase_project_id';
  static const String _prefKeyFirebaseApiKey = 'pdks_firebase_api_key';
  static const String _prefKeyFirebaseEnabled = 'pdks_firebase_enabled';

  // Varsayılan / Yapılandırılabilir Firebase Proje Bilgileri
  String _projectId = 'pdks-kurumsal-cloud';
  String _apiKey = '';
  bool _isEnabled = true;
  bool _isConnected = false;

  final http.Client _client = http.Client();

  // Getters
  String get projectId => _projectId;
  String get apiKey => _apiKey;
  bool get isEnabled => _isEnabled;
  bool get isConnected => _isConnected;

  String get realtimeDbUrl => 'https://$_projectId-default-rtdb.firebaseio.com';
  String get firestoreUrl => 'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  /// Firebase Yapılandırmasını Yükle
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _projectId = prefs.getString(_prefKeyFirebaseProject) ?? 'pdks-kurumsal-cloud';
      _apiKey = prefs.getString(_prefKeyFirebaseApiKey) ?? '';
      _isEnabled = prefs.getBool(_prefKeyFirebaseEnabled) ?? true;

      // Bağlantıyı Canlı Test Et
      await testConnection();
    } catch (e) {
      debugPrint('⚠️ Firebase Init Hatası: $e');
    }
  }

  /// Firebase Ayarlarını Güncelle ve Kaydet
  Future<bool> updateConfig({
    required String projectId,
    String? apiKey,
    required bool isEnabled,
  }) async {
    _projectId = projectId.trim();
    _apiKey = (apiKey ?? '').trim();
    _isEnabled = isEnabled;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyFirebaseProject, _projectId);
      await prefs.setString(_prefKeyFirebaseApiKey, _apiKey);
      await prefs.setBool(_prefKeyFirebaseEnabled, _isEnabled);
    } catch (e) {
      debugPrint('⚠️ Firebase updateConfig Hatası: $e');
    }

    return await testConnection();
  }

  /// Firebase Canlı Bağlantı Testi (Ping)
  Future<bool> testConnection() async {
    if (!_isEnabled || _projectId.isEmpty) {
      _isConnected = false;
      return false;
    }

    try {
      // Firebase Realtime DB .json ping
      final uri = Uri.parse('$realtimeDbUrl/status.json');
      final response = await _client.get(uri).timeout(const Duration(seconds: 3));

      // 200 veya 401/403 (proje var ancak auth kuralları aktif) proje varlığını kanıtlar
      if (response.statusCode >= 200 && response.statusCode < 500) {
        _isConnected = true;
        return true;
      }
    } catch (_) {
      // Çevrimdışı veya DNS çözülemediğinde
    }

    _isConnected = false;
    return false;
  }

  // ==========================================
  // PERSONEL / MÜKERRER KAYIT BULUT İŞLEMLERİ
  // ==========================================

  /// Firebase Bulutunda Bu E-Posta veya Telefon ile Kayıt Var mı?
  Future<bool> checkUserExistsOnCloud(String email, String phone) async {
    if (!_isEnabled) return false;

    try {
      final uri = Uri.parse('$realtimeDbUrl/employees.json');
      final response = await _client.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 && response.body != 'null') {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final cleanEmail = email.trim().toLowerCase();
        final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');

        for (final item in data.values) {
          if (item is Map) {
            final eEmail = (item['email'] ?? '').toString().trim().toLowerCase();
            final ePhone = (item['phone'] ?? '').toString().replaceAll(RegExp(r'\D'), '');

            if (eEmail == cleanEmail || (cleanPhone.isNotEmpty && ePhone.contains(cleanPhone))) {
              return true; // Mükerrer kayıt bulundu!
            }
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Firebase checkUserExists Hatası: $e');
    }

    return false;
  }

  /// Yeni Personeli Firebase Bulut Veritabanına Yaz
  Future<bool> saveEmployeeToCloud(Employee emp) async {
    if (!_isEnabled) return false;

    try {
      final uri = Uri.parse('$realtimeDbUrl/employees/${emp.id}.json');
      final response = await _client.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(emp.toJson()),
      ).timeout(const Duration(seconds: 4));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('⚠️ Firebase saveEmployee Hatası: $e');
      return false;
    }
  }

  /// Personeli E-Posta ile Firebase'den Getir
  Future<Employee?> getEmployeeFromCloudByEmail(String email) async {
    if (!_isEnabled) return null;

    try {
      final uri = Uri.parse('$realtimeDbUrl/employees.json');
      final response = await _client.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 && response.body != 'null') {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final cleanEmail = email.trim().toLowerCase();

        for (final item in data.values) {
          if (item is Map) {
            final eEmail = (item['email'] ?? '').toString().trim().toLowerCase();
            if (eEmail == cleanEmail) {
              return Employee.fromJson(Map<String, dynamic>.from(item));
            }
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Firebase getEmployee Hatası: $e');
    }

    return null;
  }

  // ==========================================
  // BULUT CANLI MESAJLAŞMA İŞLEMLERİ
  // ==========================================

  /// Mesajı Firebase Bulutuna İlet
  Future<bool> pushMessageToCloud(ChatMessage msg) async {
    if (!_isEnabled) return false;

    try {
      final uri = Uri.parse('$realtimeDbUrl/messages/${msg.id}.json');
      final response = await _client.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(msg.toJson()),
      ).timeout(const Duration(seconds: 3));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('⚠️ Firebase pushMessage Hatası: $e');
      return false;
    }
  }

  /// Buluttaki En Yeni Mesajları Çek
  Future<List<ChatMessage>> fetchNewMessagesFromCloud() async {
    if (!_isEnabled) return [];

    try {
      final uri = Uri.parse('$realtimeDbUrl/messages.json');
      final response = await _client.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 && response.body != 'null') {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<ChatMessage> list = [];
        data.forEach((key, val) {
          if (val is Map) {
            try {
              list.add(ChatMessage.fromJson(Map<String, dynamic>.from(val)));
            } catch (_) {}
          }
        });
        return list;
      }
    } catch (_) {}

    return [];
  }

  // ==========================================
  // BULUT BİLDİRİM & DEVAM İŞLEMLERİ
  // ==========================================

  /// Bildirimi Firebase Bulutuna Gönder
  Future<bool> pushNotificationToCloud(AppNotification notif) async {
    if (!_isEnabled) return false;

    try {
      final uri = Uri.parse('$realtimeDbUrl/notifications/${notif.id}.json');
      final response = await _client.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(notif.toJson()),
      ).timeout(const Duration(seconds: 3));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Devam / Giriş-Çıkış Kaydını Buluta Yaz
  Future<bool> pushAttendanceToCloud(AttendanceRecord rec) async {
    if (!_isEnabled) return false;

    try {
      final uri = Uri.parse('$realtimeDbUrl/attendance/${rec.id}.json');
      final response = await _client.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(rec.toJson()),
      ).timeout(const Duration(seconds: 3));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// İzin Talebini Buluta Yaz
  Future<bool> pushLeaveToCloud(LeaveRequest leave) async {
    if (!_isEnabled) return false;

    try {
      final uri = Uri.parse('$realtimeDbUrl/leaves/${leave.id}.json');
      final response = await _client.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(leave.toJson()),
      ).timeout(const Duration(seconds: 3));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Tüm Yerel Veritabanını Firebase'e Yükle (Toplu Eşitleme)
  Future<({int employees, int messages, int records, bool success})> syncLocalDbToFirebase(DatabaseService db) async {
    if (!_isEnabled) {
      return (employees: 0, messages: 0, records: 0, success: false);
    }

    int empCount = 0;
    int msgCount = 0;
    int recCount = 0;

    try {
      // 1. Personeller
      for (final e in db.getAllEmployees()) {
        final ok = await saveEmployeeToCloud(e);
        if (ok) empCount++;
      }

      // 2. Mesajlar
      for (final m in db.getAllMessages()) {
        final ok = await pushMessageToCloud(m);
        if (ok) msgCount++;
      }

      // 3. Devam Kayıtları
      for (final r in db.getAllRecords()) {
        final ok = await pushAttendanceToCloud(r);
        if (ok) recCount++;
      }

      _isConnected = true;
      return (employees: empCount, messages: msgCount, records: recCount, success: true);
    } catch (e) {
      debugPrint('⚠️ Firebase Toplu Senkronizasyon Hatası: $e');
      return (employees: empCount, messages: msgCount, records: recCount, success: false);
    }
  }
}
