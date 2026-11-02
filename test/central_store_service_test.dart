import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdks_flutter/core/services/central_store_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const key = 'pdks_db_employee_movements_v1';
  const url = 'http://127.0.0.1:5001/api/central';
  setUp(() => SharedPreferences.setMockInitialValues({key: '[{"id":"m1"}]', 'pdks_db_is_session_active_v1': true}));

  test('Business records are imported; device sessions and credentials stay local', () async {
    Map? payload;
    final service = CentralStoreService(client: MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer test-owner-key');
      if (request.method == 'GET') return http.Response('{"collections":{}}', 200);
      payload = jsonDecode(request.body) as Map;
      return http.Response(jsonEncode({'versions': {key: 1}}), 200);
    }));
    await service.initialize();
    await service.connect(url, 'test-owner-key', importLocal: true);
    expect((payload!['changes'] as List).length, 1);
    expect((payload!['changes'] as List).first['key'], key);
    expect(service.pendingCount, 0);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('pdks_db_is_session_active_v1'), true);
    expect(prefs.getBool('pdks_firebase_enabled'), false);
    service.dispose();
  });

  test('Offline changes survive restart and retry with the original version', () async {
    var offline = false;
    var remoteVersion = 0;
    final client = MockClient((request) async {
      if (offline) throw http.ClientException('offline');
      if (request.method == 'GET') return http.Response('{"collections":{}}', 200);
      final change = ((jsonDecode(request.body) as Map)['changes'] as List).single as Map;
      expect(change['expectedVersion'], remoteVersion);
      remoteVersion++;
      return http.Response(jsonEncode({'versions': {key: remoteVersion}}), 200);
    });
    final service = CentralStoreService(client: client);
    await service.initialize(); await service.connect(url, 'test-owner-key', importLocal: true);
    final prefs = await SharedPreferences.getInstance();
    await service.beforeWrite(key); await prefs.setString(key, '[{"id":"m2"}]'); service.afterWrite();
    offline = true; await service.syncNow();
    expect(service.pendingCount, 1);
    service.dispose();
    final restored = CentralStoreService(client: MockClient((request) async {
      if (request.method == 'GET') return http.Response('{"collections":{}}', 200);
      final change = ((jsonDecode(request.body) as Map)['changes'] as List).single as Map;
      expect(change['value'], '[{"id":"m2"}]'); expect(change['expectedVersion'], 1);
      return http.Response(jsonEncode({'versions': {key: 2}}), 200);
    }));
    await restored.initialize();
    expect(restored.pendingCount, 0);
    restored.dispose();
  });

  test('Conflict preserves pending changes and blocks silent replacement', () async {
    var conflict = false;
    final service = CentralStoreService(client: MockClient((request) async {
      if (request.method == 'GET') return http.Response('{"collections":{}}', 200);
      return conflict ? http.Response('{"message":"conflict"}', 409) : http.Response(jsonEncode({'versions': {key: 1}}), 200);
    }));
    await service.initialize(); await service.connect(url, 'test-owner-key', importLocal: true);
    final prefs = await SharedPreferences.getInstance();
    await service.beforeWrite(key); await prefs.setString(key, 'local-change'); service.afterWrite();
    conflict = true; await service.syncNow();
    expect(service.conflict, true); expect(service.pendingCount, 1);
    expect(prefs.getString(key), 'local-change');
    await expectLater(service.pull(), throwsStateError);
    expect(prefs.getString(key), 'local-change');
    service.dispose();
  });

  test('Existing server cannot be overwritten during initial import', () async {
    final service = CentralStoreService(client: MockClient((_) async => http.Response(jsonEncode({'collections': {key: {'value': 'server', 'version': 4}}}), 200)));
    await service.initialize();
    await expectLater(service.connect(url, 'test-owner-key', importLocal: true), throwsStateError);
    expect(service.configured, false);
    final prefs = await SharedPreferences.getInstance(); expect(prefs.getString(key), '[{"id":"m1"}]');
    service.dispose();
  });

  test('Authoritative pull preserves backup and local session, replaces business values', () async {
    final service = CentralStoreService(client: MockClient((_) async => http.Response(jsonEncode({'collections': {key: {'value': 'server', 'version': 4}}}), 200)));
    await service.initialize(); await service.connect(url, 'test-owner-key', importLocal: false);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(key), 'server'); expect(prefs.getBool('pdks_db_is_session_active_v1'), true);
    expect(prefs.getKeys().any((k) => k.startsWith('central_backup_')), true);
    service.dispose();
  });

  test('Failed authentication never activates a connection or changes records', () async {
    final service = CentralStoreService(client: MockClient((_) async => http.Response('', 401)));
    await service.initialize();
    await expectLater(service.connect(url, 'wrong', importLocal: true), throwsStateError);
    expect(service.configured, false);
    final prefs = await SharedPreferences.getInstance(); expect(prefs.getString(key), '[{"id":"m1"}]');
    service.dispose();
  });

  test('Remote HTTP endpoints and invalid server data are rejected', () async {
    final service = CentralStoreService(client: MockClient((_) async => http.Response(jsonEncode({'collections': {key: {'value': {'bad': 'shape'}, 'version': 1}}}), 200)));
    await service.initialize();
    await expectLater(service.connect('http://example.com/api/central', 'key', importLocal: false), throwsStateError);
    await expectLater(service.connect(url, 'key', importLocal: false), throwsStateError);
    final prefs = await SharedPreferences.getInstance(); expect(prefs.getString(key), '[{"id":"m1"}]');
    service.dispose();
  });
}
