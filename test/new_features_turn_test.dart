import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdks_flutter/models/employee.dart';
import 'package:pdks_flutter/models/leave_request.dart';
import 'package:pdks_flutter/state/pdks_state.dart';
import 'package:pdks_flutter/core/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Yeni Özellikler Test Paketi', () {
    test('1. Saatlik İzin Talebi ve Toplam Saat Hesabı', () async {
      final pdks = PdksState();
      addTearDown(() {
        pdks.logout();
        pdks.dispose();
      });

      final emp = pdks.employees.firstWhere((e) => e.role == UserRole.employee);
      pdks.login(emp.email, emp.pinCode);

      final now = DateTime.now();
      final startTime = DateTime(now.year, now.month, now.day, 10, 0);
      final endTime = DateTime(now.year, now.month, now.day, 13, 30);

      final success = await pdks.submitLeaveRequest(
        type: LeaveType.hourly,
        startDate: startTime,
        endDate: endTime,
        reason: 'Diş hekimi randevusu',
        totalHours: 3.5,
      );

      expect(success, isTrue);
      expect(pdks.leaves.first.type, equals(LeaveType.hourly));
      expect(pdks.leaves.first.typeLabel, equals('Saatlik İzin'));
      expect(pdks.leaves.first.totalHours, equals(3.5));
      expect(pdks.leaves.first.totalDays, equals(0));
    });

    test('2. Sağlık / Rapor İzni Belge ve Rapor Yükleme', () async {
      final pdks = PdksState();
      addTearDown(() {
        pdks.logout();
        pdks.dispose();
      });

      final emp = pdks.employees.firstWhere((e) => e.role == UserRole.employee);
      pdks.login(emp.email, emp.pinCode);

      final fakeBytes = utf8.encode('PDF_DOCUMENT_CONTENT');
      final base64Doc = base64Encode(fakeBytes);

      final success = await pdks.submitLeaveRequest(
        type: LeaveType.medical,
        startDate: DateTime.now().add(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 3)),
        reason: 'Grip ve yüksek ateş raporu',
        documentName: 'dr_raporu_kasim_2026.pdf',
        documentPath: '/mock/path/dr_raporu.pdf',
        documentBase64: base64Doc,
      );

      expect(success, isTrue);
      final req = pdks.leaves.first;
      expect(req.type, equals(LeaveType.medical));
      expect(req.documentName, equals('dr_raporu_kasim_2026.pdf'));
      expect(req.documentBase64, equals(base64Doc));

      // JSON serializasyon testi
      final json = req.toJson();
      final deserialized = LeaveRequest.fromJson(json);
      expect(deserialized.documentName, equals('dr_raporu_kasim_2026.pdf'));
      expect(deserialized.documentBase64, equals(base64Doc));
    });

    test('3. Profil Fotoğrafı Base64 Data URI AvatarImageProvider', () {
      final fakePngBytes = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
      final base64String = 'data:image/png;base64,${base64Encode(fakePngBytes)}';

      final emp = Employee(
        id: 1,
        fullName: 'Ahmet Yılmaz',
        email: 'ahmet@sirket.com',
        department: 'Yazılım',
        title: 'Geliştirici',
        pinCode: '1234',
        avatarUrl: base64String,
      );

      final provider = emp.avatarImageProvider;
      expect(provider, isNotNull);
      expect(provider, isA<MemoryImage>());
      final memoryImage = provider as MemoryImage;
      expect(memoryImage.bytes, equals(fakePngBytes));
    });

    test('4. Hızlı Menüye Taşınan Kurumsal ve Servis Modülleri', () {
      final items = DatabaseService.defaultQuickMenuItems();
      final actionTypes = items.map((i) => i.actionType).toSet();

      expect(actionTypes.contains('shift_swap'), isTrue);
      expect(actionTypes.contains('helpdesk'), isTrue);
      expect(actionTypes.contains('near_miss'), isTrue);
      expect(actionTypes.contains('digital_docs'), isTrue);
      expect(actionTypes.contains('ptt_radio'), isTrue);
      expect(actionTypes.contains('shuttle'), isTrue);
      expect(actionTypes.contains('holidays'), isTrue);
      expect(actionTypes.contains('doctor'), isTrue);
      expect(actionTypes.contains('hybrid_desk'), isTrue);
      expect(actionTypes.contains('training'), isTrue);
      expect(actionTypes.contains('okr'), isTrue);
    });

    test('5. Çalışan Rolleri Taşınan Kurumsal Modüllere canAccessPage ile Erişebilmeli', () {
      final role = DatabaseService.defaultRoles().firstWhere((r) => r.id == 'role_employee');

      expect(role.canAccessPage('shift_swap'), isTrue);
      expect(role.canAccessPage('helpdesk'), isTrue);
      expect(role.canAccessPage('near_miss'), isTrue);
      expect(role.canAccessPage('digital_docs'), isTrue);
      expect(role.canAccessPage('shuttle'), isTrue);
      expect(role.canAccessPage('holidays'), isTrue);
      expect(role.canAccessPage('doctor'), isTrue);
    });
  });
}
