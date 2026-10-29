import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdks_flutter/models/employee.dart';
import 'package:pdks_flutter/state/pdks_state.dart';
import 'package:pdks_flutter/views/auth/auth_screen.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDKS Kurumsal Lisans & Satın Alma Testleri', () {
    test('purchaseCorporateSubscription başarıyla şirket ve lisans oluşturmalı', () {
      final state = PdksState();

      final result = state.purchaseCorporateSubscription(
        companyName: 'Akın Bilişim Teknolojileri',
        companyCode: 'AKINBI',
        sector: 'Bilişim & Yazılım',
        adminFullName: 'Akın Can',
        adminEmail: 'akin@akinbilisim.com',
        adminPhone: '05551112233',
        adminPin: '9876',
        planName: 'Pro Enterprise Paketi ⭐',
        price: 9480.0,
        billingCycle: 'Yıllık Peşin',
        paymentMethod: 'Kredi Kartı (3D Secure)',
        cardLastFour: '4321',
      );

      expect(result.success, isTrue);
      expect(result.company, isNotNull);
      expect(result.company!.code, equals('AKINBI'));
      expect(result.licenseKey, startsWith('PDKS-2026-AKINBI-'));
      expect(result.adminUser, isNotNull);
      expect(result.adminUser!.email, equals('akin@akinbilisim.com'));
      expect(result.adminUser!.pinCode, equals('9876'));
      expect(result.adminUser!.role, equals(UserRole.admin));

      // Lisans onay bildirimi eklenmiş olmalı
      final notif = state.notifications.first;
      expect(notif.title, contains('Lisansı Aktif Edildi'));
      expect(notif.message, contains(result.licenseKey!));
      state.dispose();
    });

    test('Mükerrer şirket kodu reddedilmeli', () {
      final state = PdksState();

      // ACME zaten mevcut demo şirketi
      final result = state.purchaseCorporateSubscription(
        companyName: 'Sahte ACME',
        companyCode: 'ACME',
        sector: 'Test',
        adminFullName: 'Test Kişi',
        adminEmail: 'test@acme.com',
        adminPhone: '05550001122',
        adminPin: '1111',
        planName: 'Başlangıç',
        price: 490.0,
        billingCycle: 'Aylık',
        paymentMethod: 'Kredi Kartı',
      );

      expect(result.success, isFalse);
      expect(result.message, contains('zaten kayıtlıdır'));
      state.dispose();
    });

    testWidgets('AuthScreen üzerinde Satın Al sekmesi gözükmeli ve geçiş yapılabilmeli', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => PdksState(),
          child: MaterialApp(
            home: const AuthScreen(),
            theme: ThemeData.light(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(Tab, 'Giriş Yap'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Kayıt Ol'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Satın Al 💎'), findsOneWidget);

      // Satın Al sekmesine tıkla
      await tester.tap(find.widgetWithText(Tab, 'Satın Al 💎'));
      await tester.pumpAndSettle();

      expect(find.text('PDKS Enterprise SaaS Kurumsal Lisans'), findsOneWidget);
      expect(find.text('Aylık Ödeme'), findsOneWidget);
      expect(find.text('Yıllık Ödeme'), findsOneWidget);
      expect(find.text('Başlangıç'), findsOneWidget);
      expect(find.text('Pro Enterprise ⭐'), findsOneWidget);
      expect(find.text('Kurumsal Sınırsız'), findsOneWidget);
    });
  });
}
