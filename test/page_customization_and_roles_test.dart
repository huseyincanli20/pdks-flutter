import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pdks_flutter/models/employee.dart';
import 'package:pdks_flutter/state/pdks_state.dart';
import 'package:pdks_flutter/core/services/database_service.dart';
import 'package:pdks_flutter/views/common/app_drawer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Yönetici ve Admin Sayfa Düzenleme Yetki & Güvenlik Testleri', () {
    late PdksState pdks;

    setUp(() {
      pdks = PdksState();
    });

    tearDown(() {
      pdks.logout();
      pdks.dispose();
    });

    test('Normal çalışan veya İK kullanıcısı sayfa düzenleme modunu açamaz', () {
      // 1. Çalışan ile giriş yap
      pdks.login('personel@sirket.com', '1234');
      expect(pdks.currentUser.role, equals(UserRole.employee));

      // Düzenleme modunu açmayı dene
      pdks.setAdminEditMode(true);
      expect(pdks.isAdminEditMode, isFalse);

      // 2. İK kullanıcısı ile giriş yap
      pdks.login('ik@sirket.com', '2345');
      expect(pdks.currentUser.role, equals(UserRole.hr));

      pdks.setAdminEditMode(true);
      expect(pdks.isAdminEditMode, isFalse);
    });

    test('Yalnızca Yönetici (Patron/CEO) ve Admin düzenleme modunu açabilir', () {
      // 1. Şirket Yöneticisi (Patron / CEO) ile giriş yap
      pdks.login('patron@sirket.com', '3456');
      expect(pdks.currentUser.role, equals(UserRole.boss));

      pdks.setAdminEditMode(true);
      expect(pdks.isAdminEditMode, isTrue);

      pdks.setAdminEditMode(false);
      expect(pdks.isAdminEditMode, isFalse);

      // 2. Sistem Yöneticisi (Admin) ile giriş yap
      pdks.login('admin@sirket.com', '4567');
      expect(pdks.currentUser.role, equals(UserRole.admin));

      pdks.setAdminEditMode(true);
      expect(pdks.isAdminEditMode, isTrue);
    });

    test('Bölüm gizleme ve sayfa özelleştirmesi veritabanına kalıcı kaydedilir', () {
      // Yönetici ile giriş yap
      pdks.login('patron@sirket.com', '3456');
      pdks.setAdminEditMode(true);

      // Profil sayfasında beden ölçüleri bölümünü gizle
      pdks.togglePageSection('profile', 'clothing_sizes');
      expect(pdks.getPageCustomization('profile').isSectionHidden('clothing_sizes'), isTrue);

      // Veritabanından kontrol et
      final dbCust = DatabaseService().getPageCustomization('profile');
      expect(dbCust, isNotNull);
      expect(dbCust!.isSectionHidden('clothing_sizes'), isTrue);

      // Sayfaya duyuru ekle
      final current = pdks.getPageCustomization('profile');
      pdks.updatePageCustomization(current.copyWith(
        showAnnouncement: true,
        announcementText: 'İK Bildirimi: Beden ölçülerinizi lütfen güncelleyiniz.',
      ));

      final updatedCust = DatabaseService().getPageCustomization('profile');
      expect(updatedCust!.showAnnouncement, isTrue);
      expect(updatedCust.announcementText, contains('İK Bildirimi'));
    });

    testWidgets('AppDrawer menüsünde Düzenleme Modu şalteri sadece Yönetici ve Admine görünür', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Çalışan rolü
      pdks.login('personel@sirket.com', '1234');

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: pdks,
          child: const MaterialApp(
            home: Scaffold(
              drawer: AppDrawer(),
              body: Text('Test'),
            ),
          ),
        ),
      );

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Düzenleme şalteri ve menü yönetimi butonunun çalışan için olmaması gerekir
      expect(find.text('Sayfa Düzenleme Modu'), findsNothing);
      expect(find.text('Menüyü Yönet'), findsNothing);

      // Timer'ı temizlemek için çıkış yap
      pdks.logout();
    });

    testWidgets('Yönetici (Boss) giriş yaptığında AppDrawer üzerinde Düzenleme şalteri ve Menüyü Yönet görünür', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Yönetici (Patron/CEO) rolü
      pdks.login('patron@sirket.com', '3456');

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: pdks,
          child: const MaterialApp(
            home: Scaffold(
              drawer: AppDrawer(),
              body: Text('Test'),
            ),
          ),
        ),
      );

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Sayfa Düzenleme Modu'), findsOneWidget);
      expect(find.text('Menüyü Yönet'), findsOneWidget);

      pdks.logout();
    });
  });
}
