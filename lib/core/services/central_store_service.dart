import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Installation-owner connection. This is not an employee authorization system.
class CentralStoreService extends ChangeNotifier {
  CentralStoreService({http.Client? client}) : _client = client ?? http.Client();
  static final instance = CentralStoreService();
  final http.Client _client;
  SharedPreferences? _prefs;
  String baseUrl = '';
  String _token = '';
  String status = 'Merkezi sunucu bağlı değil';
  bool busy = false;
  bool conflict = false;
  DateTime? lastSync;
  Timer? _timer;
  final Map<String, int> _pending = {};
  final Map<String, int> _versions = {};
  int _generation = 0;
  int _writesInFlight = 0;
  bool get configured => baseUrl.isNotEmpty && _token.isNotEmpty;
  int get pendingCount => _pending.length;
  Map<String, String> get headers => {'Authorization': 'Bearer $_token'};
  String fileUrl(String id) => '$baseUrl/files/${Uri.encodeComponent(id)}';
  static bool businessKey(String key) => key.startsWith('pdks_db_') &&
      !['session', 'logged_in', 'last_user', 'saved_company_code', 'failed_pin',
        'pin_lockout', 'theme_mode', 'active_company_id', 'offline_queue'].any(key.contains);

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    baseUrl = _prefs!.getString('central_url') ?? '';
    _token = _prefs!.getString('central_token') ?? '';
    _readMap('central_pending', _pending);
    _readMap('central_versions', _versions);
    _generation = _pending.values.fold(0, (a, b) => a > b ? a : b);
    if (configured) {
      // An existing Firebase writer must not compete with the central store.
      await _prefs!.setBool('pdks_firebase_enabled', false);
      await syncNow();
      if (_pending.isEmpty && !conflict) {
        try { await pull(); } catch (_) { /* Offline cache remains usable. */ }
      }
      _startTimer();
    }
  }
  void _readMap(String key, Map<String, int> target) {
    try {
      final data = jsonDecode(_prefs!.getString(key) ?? '{}') as Map;
      target.addAll(data.map((k, v) => MapEntry(k as String, (v as num).toInt())));
    } catch (_) { status = 'Eşitleme bilgisi okunamadı; yerel kayıtlar korundu'; }
  }
  Map<String, Object?> localSnapshot() => {
    for (final key in _prefs!.getKeys().where(businessKey)) key: _prefs!.get(key),
  };
  Future<void> beforeWrite(String key) async {
    _writesInFlight++;
    if (!configured || !businessKey(key)) return;
    _pending[key] = ++_generation;
    await _prefs!.setString('central_pending', jsonEncode(_pending));
  }
  void afterWrite() {
    _writesInFlight--;
    if (configured) {
      status = conflict ? 'Çakışma var; yerel kayıtlar korundu' : '${_pending.length} koleksiyon gönderilmeyi bekliyor';
      notifyListeners();
    }
  }
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) { if (_pending.isNotEmpty && !conflict) unawaited(syncNow()); });
  }
  Future<void> connect(String url, String token, {required bool importLocal}) async {
    if (busy) throw StateError('Devam eden işlem var');
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasAuthority || uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment ||
        !(uri.scheme == 'https' || (uri.scheme == 'http' && ['localhost', '127.0.0.1', '[::1]'].contains(uri.host)))) {
      throw StateError('HTTPS sunucu adresi girin. Yerel bilgisayarda HTTP kullanılabilir.');
    }
    final nextUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    final response = await _client.get(Uri.parse('$nextUrl/snapshot'), headers: {'Authorization': 'Bearer ${token.trim()}'}).timeout(const Duration(seconds: 8));
    _check(response);
    final remote = (jsonDecode(response.body) as Map)['collections'] as Map;
    _validate(remote);
    if (importLocal && remote.isNotEmpty) throw StateError('Sunucu dolu. Üzerine aktarmak yerine sunucudan yükleyin.');
    if (!importLocal && remote.isEmpty) throw StateError('Sunucu boş. İlk kurulumda yerel kayıtları aktar seçeneğini açın.');
    await backupLocal();
    _prefs ??= await SharedPreferences.getInstance();
    baseUrl = nextUrl; _token = token.trim(); _pending.clear(); _versions.clear(); conflict = false;
    await _prefs!.setString('central_url', baseUrl);
    await _prefs!.setString('central_token', _token);
    await _prefs!.setBool('pdks_firebase_enabled', false);
    await _prefs!.setString('central_pending', '{}');
    await _prefs!.setString('central_versions', '{}');
    if (importLocal) {
      for (final key in localSnapshot().keys) { _pending[key] = ++_generation; }
      await _prefs!.setString('central_pending', jsonEncode(_pending));
      await syncNow();
    } else {
      await _apply(remote);
    }
    _startTimer(); notifyListeners();
  }
  Future<void> backupLocal() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString('central_backup_${DateTime.now().microsecondsSinceEpoch}', jsonEncode(localSnapshot()));
  }
  Future<void> syncNow() async {
    if (!configured || busy || conflict || _writesInFlight > 0) return;
    busy = true; notifyListeners();
    try {
      final sent = Map<String, int>.from(_pending);
      if (sent.isNotEmpty) {
        final changes = sent.keys.map((key) => {'key': key, 'value': _prefs!.get(key), 'expectedVersion': _versions[key] ?? 0}).toList();
        final response = await _client.post(Uri.parse('$baseUrl/sync'), headers: {...headers, 'Content-Type': 'application/json'}, body: jsonEncode({'changes': changes})).timeout(const Duration(seconds: 15));
        if (response.statusCode == 409) { conflict = true; throw StateError('Başka bir cihaz aynı veriyi değiştirdi. Bekleyen kayıtlar korundu.'); }
        _check(response);
        final versions = (jsonDecode(response.body) as Map)['versions'] as Map;
        versions.forEach((k, v) => _versions[k as String] = (v as num).toInt());
        for (final entry in sent.entries) { if (_pending[entry.key] == entry.value) _pending.remove(entry.key); }
        await _prefs!.setString('central_versions', jsonEncode(_versions));
        await _prefs!.setString('central_pending', jsonEncode(_pending));
      }
      lastSync = DateTime.now(); status = _pending.isEmpty ? 'Tüm yerel değişiklikler sunucuya kaydedildi' : 'Yeni değişiklikler gönderilmeyi bekliyor';
    } catch (e) { status = 'Gönderilemedi; yerel kayıtlar korundu. ${_message(e)}'; }
    finally { busy = false; notifyListeners(); }
  }
  Future<void> pull({bool resolveConflict = false}) async {
    if (!configured || busy) return;
    if (_writesInFlight > 0) throw StateError('Yerel kayıt işlemi devam ediyor.');
    if (_pending.isNotEmpty && !resolveConflict) throw StateError('Önce bekleyen kayıtları gönderin.');
    busy = true; notifyListeners();
    try {
      final generation = _generation;
      final response = await _client.get(Uri.parse('$baseUrl/snapshot'), headers: headers).timeout(const Duration(seconds: 8));
      _check(response);
      if (generation != _generation) throw StateError('İndirme sırasında yerel veri değişti; tekrar deneyin.');
      final remote = (jsonDecode(response.body) as Map)['collections'] as Map;
      _validate(remote);
      if (remote.isEmpty && localSnapshot().isNotEmpty) throw StateError('Sunucu boş görünüyor; yerel kayıtlar silinmedi.');
      if (resolveConflict) { await backupLocal(); _pending.clear(); await _prefs!.setString('central_pending', '{}'); }
      await _apply(remote);
    } catch (e) { status = _message(e); rethrow; }
    finally { busy = false; notifyListeners(); }
  }
  void _validate(Map remote) {
    for (final entry in remote.entries) {
      if (entry.key is! String || !businessKey(entry.key as String) || entry.value is! Map) throw StateError('Sunucudan geçersiz koleksiyon geldi.');
      final row = entry.value as Map;
      final value = row['value'];
      if (row['version'] is! num || !(value == null || value is String || value is bool || value is int || (value is List && value.every((x) => x is String)))) {
        throw StateError('Sunucu kayıt biçimi desteklenmiyor; yerel kayıtlar korundu.');
      }
    }
  }
  Future<void> _apply(Map remote) async {
    _validate(remote);
    // Keep a local recovery snapshot before any authoritative replacement.
    await backupLocal();
    for (final key in localSnapshot().keys) { if (!remote.containsKey(key)) await _prefs!.remove(key); }
    _versions.clear();
    for (final entry in remote.entries) {
      final key = entry.key as String;
      if (!businessKey(key)) continue;
      final row = entry.value as Map;
      await _setRaw(key, row['value']); _versions[key] = (row['version'] as num).toInt();
    }
    await _prefs!.setString('central_versions', jsonEncode(_versions));
    conflict = false; lastSync = DateTime.now(); status = 'Sunucu kayıtları yüklendi';
  }
  Future<void> _setRaw(String key, dynamic value) async {
    if (value == null) { await _prefs!.remove(key); }
    else if (value is String) { await _prefs!.setString(key, value); }
    else if (value is bool) { await _prefs!.setBool(key, value); }
    else if (value is int) { await _prefs!.setInt(key, value); }
    else if (value is List) { await _prefs!.setStringList(key, value.cast<String>()); }
    else { throw StateError('Desteklenmeyen kayıt türü'); }
  }
  Future<List<Map<String, dynamic>>> files(String companyId) async {
    _requireConnection();
    final r = await _client.get(Uri.parse('$baseUrl/files').replace(queryParameters: {'companyId': companyId}), headers: headers).timeout(const Duration(seconds: 10));
    _check(r); return (jsonDecode(r.body) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  Future<Map<String, dynamic>> upload(Uint8List bytes, String name, String companyId, {String employeeId = '', String category = 'belge'}) async {
    _requireConnection();
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) throw StateError('Dosya 1 bayt–10 MB arasında olmalı.');
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/files'))..headers.addAll(headers)
      ..fields.addAll({'companyId': companyId, 'employeeId': employeeId, 'category': category})
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: name));
    final response = await http.Response.fromStream(await _client.send(request).timeout(const Duration(seconds: 30)));
    _check(response); return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }
  Future<Uint8List> download(String id) async {
    _requireConnection(); final response = await _client.get(Uri.parse(fileUrl(id)), headers: headers).timeout(const Duration(seconds: 30));
    _check(response); return response.bodyBytes;
  }
  Future<void> deleteFile(String id) async {
    _requireConnection(); final response = await _client.delete(Uri.parse(fileUrl(id)), headers: headers).timeout(const Duration(seconds: 10)); _check(response);
  }
  void _requireConnection() { if (!configured) throw StateError('Önce merkezi sunucu bağlantısını kurun.'); }
  static String _message(Object e) => e.toString().replaceFirst('Bad state: ', '');
  static void _check(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    if (r.statusCode == 401) throw StateError('Sunucu bağlantı anahtarı geçersiz.');
    try { final body = jsonDecode(r.body) as Map; throw StateError(body['message']?.toString() ?? 'Sunucu hatası (${r.statusCode})'); }
    on FormatException { throw StateError('Sunucu hatası (${r.statusCode})'); }
  }
  @override
  void dispose() { _timer?.cancel(); _client.close(); super.dispose(); }
}

/// Captures every business-table write, including modules added later.
class CentralPreferences {
  CentralPreferences(this.raw);
  final SharedPreferences raw;
  bool containsKey(String key) => raw.containsKey(key);
  String? getString(String key) => raw.getString(key);
  bool? getBool(String key) => raw.getBool(key);
  int? getInt(String key) => raw.getInt(key);
  List<String>? getStringList(String key) => raw.getStringList(key);
  Future<bool> _write(String key, Future<bool> Function() write) async {
    try {
      await CentralStoreService.instance.beforeWrite(key);
      return await write();
    } finally { CentralStoreService.instance.afterWrite(); }
  }
  Future<bool> setString(String key, String value) => _write(key, () => raw.setString(key, value));
  Future<bool> setBool(String key, bool value) => _write(key, () => raw.setBool(key, value));
  Future<bool> setInt(String key, int value) => _write(key, () => raw.setInt(key, value));
  Future<bool> setStringList(String key, List<String> value) => _write(key, () => raw.setStringList(key, value));
  Future<bool> remove(String key) => _write(key, () => raw.remove(key));
}
