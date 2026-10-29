import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdks_flutter/core/services/firebase_service.dart';
import 'package:pdks_flutter/core/services/database_service.dart';
import 'package:pdks_flutter/models/employee.dart';
import 'package:pdks_flutter/models/chat_message.dart';
import 'package:pdks_flutter/models/app_notification.dart';
import 'package:flutter/material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirebaseService Bulut Entegrasyonu Testleri', () {
    late FirebaseService firebase;
    late DatabaseService db;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      firebase = FirebaseService();
      db = DatabaseService();
      await db.init();
      await firebase.init();
    });

    test('Firebase Service varsayılan ayarları ve URL yapılandırması doğru olmalı', () {
      expect(firebase.projectId, isNotEmpty);
      expect(firebase.realtimeDbUrl, contains('firebaseio.com'));
      expect(firebase.firestoreUrl, contains('firestore.googleapis.com'));
      expect(firebase.isEnabled, isTrue);
    });

    test('Firebase yapılandırması güncellenebilmeli', () async {
      await firebase.updateConfig(
        projectId: 'test-custom-project',
        apiKey: 'test-api-key-12345',
        isEnabled: true,
      );

      expect(firebase.projectId, equals('test-custom-project'));
      expect(firebase.apiKey, equals('test-api-key-12345'));
      expect(firebase.realtimeDbUrl, equals('https://test-custom-project-default-rtdb.firebaseio.com'));
    });

    test('Personel, Mesaj ve Bildirim nesneleri Firebase JSON formatına hatasız dönüştürülmeli', () {
      final emp = Employee(
        id: 99,
        fullName: 'Bulut Personel',
        email: 'bulut@sirket.com',
        phone: '05551234567',
        department: 'Ar-Ge',
        title: 'Mühendis',
        pinCode: '9999',
        role: UserRole.employee,
        annualLeaveAllowance: 14,
        usedLeaveDays: 2,
        isApproved: true,
      );

      final empJson = emp.toJson();
      expect(empJson['fullName'], equals('Bulut Personel'));
      expect(empJson['email'], equals('bulut@sirket.com'));
      expect(empJson['isApproved'], isTrue);

      final rehydratedEmp = Employee.fromJson(empJson);
      expect(rehydratedEmp.fullName, equals('Bulut Personel'));
      expect(rehydratedEmp.email, equals('bulut@sirket.com'));
      expect(rehydratedEmp.isApproved, isTrue);

      final msg = ChatMessage(
        id: 'msg_test_1',
        senderId: 99,
        senderName: 'Bulut Personel',
        senderRole: UserRole.employee,
        channelId: 'company_general',
        text: 'Firebase mesaj testi',
        timestamp: DateTime(2026, 10, 29, 12, 0),
        isRead: true,
      );

      final msgJson = msg.toJson();
      expect(msgJson['text'], equals('Firebase mesaj testi'));
      final rehydratedMsg = ChatMessage.fromJson(msgJson);
      expect(rehydratedMsg.text, equals('Firebase mesaj testi'));

      final notif = AppNotification(
        id: 'notif_test_1',
        title: 'Bulut Bildirim',
        message: 'Firebase bildirimi',
        timestamp: DateTime(2026, 10, 29, 12, 0),
        type: NotificationType.system,
        icon: Icons.notifications,
        color: Colors.blue,
      );

      final notifJson = notif.toJson();
      expect(notifJson['title'], equals('Bulut Bildirim'));
      final rehydratedNotif = AppNotification.fromJson(notifJson);
      expect(rehydratedNotif.title, equals('Bulut Bildirim'));
    });
  });
}
