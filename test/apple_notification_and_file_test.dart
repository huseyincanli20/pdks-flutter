import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pdks_flutter/state/pdks_state.dart';
import 'package:pdks_flutter/views/notifications/notifications_screen.dart';
import 'package:pdks_flutter/core/services/ios_notification_service.dart';
import 'package:pdks_flutter/core/utils/platform_file_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Apple Kilit Ekranı & Bildirim Merkezi Testleri', () {
    test('IosNotificationService bildirim çağrısı hatasız çalışmalı', () {
      expect(() {
        IosNotificationService.showIosNotification(
          title: 'Test Bildirimi',
          body: 'Mesaj detayı',
          icon: Icons.apple_rounded,
        );
      }, returnsNormally);
    });

    test('PlatformFileHelper pickDocumentFile çağrılabilir olmalı', () async {
      // Test ortamında stub veya null döner ama exception fırlatmamalıdır
      final file = await PlatformFileHelper.pickDocumentFile();
      expect(file, isNull);
    });

    testWidgets('NotificationsScreen varsayılan olarak Apple Kilit Ekranı modunda açılmalı', (tester) async {
      final pdksState = PdksState();

      try {
        await tester.pumpWidget(
          ChangeNotifierProvider<PdksState>.value(
            value: pdksState,
            child: const MaterialApp(
              home: NotificationsScreen(),
            ),
          ),
        );

        await tester.pump();

        // Apple Kilit Ekranı bileşenleri ekranda olmalı
        expect(find.text('🍎 Apple Kilit Ekranı'), findsOneWidget);
        expect(find.text('Turkcell'), findsOneWidget);
        expect(find.text('PDKS'), findsWidgets);
        expect(find.text('100'), findsOneWidget);
        expect(find.byIcon(Icons.flashlight_on_rounded), findsOneWidget);
        expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);

        // Liste görünümüne geçiş yapılabilmeli
        final listButton = find.text('Liste');
        expect(listButton, findsOneWidget);
        await tester.tap(listButton);
        await tester.pump();

        // Liste görünümünde test butonu ve filtreler görünmeli
        expect(find.text('Apple Push Bildirimini Test Et'), findsOneWidget);
        expect(find.textContaining('Mesaj & Onaylar'), findsOneWidget);
      } finally {
        pdksState.dispose();
      }
    });

    test('Sadece mesaj ve onay bildirimlerine izin verilmeli, diğerleri filtrelenmeli', () {
      // Mesaj bildirimleri -> İzin verilir
      expect(IosNotificationService.isAllowedNotification('💬 Zeynep Kaya', 'Merhaba nasılsınız?'), isTrue);
      expect(IosNotificationService.isAllowedNotification('Yeni Mesaj', 'Yeni mesajınız var'), isTrue);

      // Onay bildirimleri -> İzin verilir
      expect(IosNotificationService.isAllowedNotification('✅ İzin Talebiniz Onaylandı', 'Yıllık izin talebiniz onaylandı.'), isTrue);
      expect(IosNotificationService.isAllowedNotification('🎉 Kayıt Onaylandı: Mehmet Kaya', 'Personel kaydı onaylanmıştır.'), isTrue);

      // Giriş, mesai, duyuru vb. rutin bildirimler -> ENGELLENİR
      expect(IosNotificationService.isAllowedNotification('PDKS • Hoş Geldiniz', 'Giriş başarılı.'), isFalse);
      expect(IosNotificationService.isAllowedNotification('⏰ Mesai Girişi Başarılı', '08:30 giriş yapıldı.'), isFalse);
      expect(IosNotificationService.isAllowedNotification('Günün Menüsü', 'Mercimek çorbası'), isFalse);
    });

    test('Uygulama içi bildirim balonu (enableInAppBanner) varsayılan olarak kapalı/gizli olmalı', () {
      expect(IosNotificationService.enableInAppBanner, isFalse);
    });
  });
}
