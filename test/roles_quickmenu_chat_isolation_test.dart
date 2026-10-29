import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdks_flutter/core/services/database_service.dart';
import 'package:pdks_flutter/models/employee.dart';
import 'package:pdks_flutter/state/pdks_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. Hızlı Menü Yönetimine Tüm Menülerin Eklenmesi', () {
    test('defaultQuickMenuItems tüm uygulama sayfalarını (15 menü) içermeli', () {
      final items = DatabaseService.defaultQuickMenuItems();
      final actionTypes = items.map((m) => m.actionType).toSet();

      expect(items.length, greaterThanOrEqualTo(15));
      expect(actionTypes, containsAll([
        'profile',
        'payroll',
        'chat',
        'contacts',
        'notifications',
        'cafeteria',
        'business_card',
        'favorites',
        'leave',
        'records',
        'field_work',
        'overtime',
        'settings',
        'about',
        'cloud_db',
      ]));
    });

    test('CEO/Admin hızlı menü görünürlüğünü değiştirebilir ve varsayılana sıfırlayabilir', () {
      final pdks = PdksState();
      addTearDown(() {
        pdks.logout();
        pdks.dispose();
      });

      final boss = pdks.employees.firstWhere((e) => e.role == UserRole.boss);
      pdks.login(boss.email, boss.pinCode);

      // Varsayılan menüleri kontrol et
      expect(pdks.quickMenuItems.length, greaterThanOrEqualTo(15));

      // Menü gizleme testi
      final profileMenu = pdks.quickMenuItems.firstWhere((m) => m.actionType == 'profile');
      expect(profileMenu.isVisible, isTrue);

      final toggleRes = pdks.toggleQuickMenuItemVisibility(profileMenu.id);
      expect(toggleRes.success, isTrue);

      final updatedProfile = pdks.quickMenuItems.firstWhere((m) => m.id == profileMenu.id);
      expect(updatedProfile.isVisible, isFalse);

      // Sıfırlama testi
      final resetRes = pdks.resetQuickMenuItemsToDefault();
      expect(resetRes.success, isTrue);
      expect(pdks.quickMenuItems.firstWhere((m) => m.actionType == 'profile').isVisible, isTrue);
    });
  });

  group('2. Kurumsal Rol Tanımlama Sisteminde Sayfa Yetki Düzeyleri', () {
    test('Varsayılan roller sayfa yetkileriyle (allowedPageIds) tanımlı olmalı', () {
      final pdks = PdksState();
      addTearDown(() {
        pdks.logout();
        pdks.dispose();
      });

      final adminRole = pdks.roles.firstWhere((r) => r.baseRole == UserRole.admin);
      final employeeRole = pdks.roles.firstWhere((r) => r.baseRole == UserRole.employee);
      final cafeteriaRole = pdks.roles.firstWhere((r) => r.baseRole == UserRole.cafeteria);

      expect(adminRole.allowedPageIds, contains('cloud_db'));
      expect(employeeRole.allowedPageIds, isNot(contains('cloud_db')));
      expect(cafeteriaRole.allowedPageIds, contains('cafeteria'));
      expect(cafeteriaRole.allowedPageIds, isNot(contains('payroll')));
    });

    test('Patron yeni rol eklerken sayfa yetkilerini belirleyebilmeli', () {
      final pdks = PdksState();
      addTearDown(() {
        pdks.logout();
        pdks.dispose();
      });

      final boss = pdks.employees.firstWhere((e) => e.role == UserRole.boss);
      pdks.login(boss.email, boss.pinCode);

      final addRes = pdks.addNewRole(
        name: 'Saha Mühendisi',
        description: 'Saha operasyonları ve konum yetkilisi',
        baseRole: UserRole.employee,
        color: const Color(0xFF0D9488),
        icon: Icons.engineering_rounded,
        allowedPageIds: ['profile', 'field_work', 'chat', 'notifications'],
      );

      expect(addRes.success, isTrue);

      final newRole = pdks.roles.firstWhere((r) => r.name == 'Saha Mühendisi');
      expect(newRole.allowedPageIds, containsAll(['profile', 'field_work', 'chat', 'notifications']));
      expect(newRole.allowedPageIds, isNot(contains('payroll')));
    });

    test('Rol sayfa yetkileri updateRolePermissions ile güncellenebilmeli', () {
      final pdks = PdksState();
      addTearDown(() {
        pdks.logout();
        pdks.dispose();
      });

      final boss = pdks.employees.firstWhere((e) => e.role == UserRole.boss);
      pdks.login(boss.email, boss.pinCode);

      pdks.addNewRole(
        name: 'Stajyer',
        description: 'Sınırlı stajyer hesabı',
        baseRole: UserRole.employee,
        color: const Color(0xFF6366F1),
        icon: Icons.school_rounded,
        allowedPageIds: ['profile', 'chat'],
      );

      final internRole = pdks.roles.firstWhere((r) => r.name == 'Stajyer');
      expect(internRole.allowedPageIds.length, equals(2));

      // Yetkileri genişlet
      final updateRes = pdks.updateRolePermissions(internRole.id, ['profile', 'chat', 'cafeteria', 'favorites']);
      expect(updateRes.success, isTrue);

      final updatedRole = pdks.roles.firstWhere((r) => r.id == internRole.id);
      expect(updatedRole.allowedPageIds, contains('cafeteria'));
      expect(updatedRole.allowedPageIds.length, equals(4));
    });

    test('hasPagePermission yetki kontrolü doğru çalışmalı', () {
      final pdks = PdksState();
      addTearDown(() {
        pdks.logout();
        pdks.dispose();
      });

      final adminUser = pdks.employees.firstWhere((e) => e.role == UserRole.admin);
      final normalEmployee = pdks.employees.firstWhere((e) => e.role == UserRole.employee);

      // Admin her sayfaya erişebilir
      expect(pdks.hasPagePermission('cloud_db', adminUser), isTrue);

      // Normal çalışan korumalı cloud_db sayfasına erişemez
      expect(pdks.hasPagePermission('cloud_db', normalEmployee), isFalse);

      // Normal çalışan profil veya chat sayfasına erişebilir
      expect(pdks.hasPagePermission('profile', normalEmployee), isTrue);
      expect(pdks.hasPagePermission('chat', normalEmployee), isTrue);
    });
  });

  group('3. Mesaj Silme Özelliği (Database Silinmeden Soft-Delete)', () {
    test('softDeleteChatMessage mesajı veritabanından silmez, isDeleted olarak işaretler', () {
      final pdks = PdksState();
      addTearDown(() {
        pdks.logout();
        pdks.dispose();
      });

      final emp = pdks.employees.firstWhere((e) => e.role == UserRole.employee);
      pdks.login(emp.email, emp.pinCode);

      // Mesaj gönder
      pdks.sendMessage(
        channelId: 'company_general',
        text: 'Deneme kurumsal mesaj metni',
      );

      final myMsg = pdks.chatMessages.firstWhere((m) => m.senderId == emp.id && m.text == 'Deneme kurumsal mesaj metni');
      expect(myMsg.isDeleted, isFalse);

      // Mesajı sil
      final delRes = pdks.softDeleteChatMessage(myMsg.id);
      expect(delRes.success, isTrue);

      // Mesajın listede ve veritabanında HALA BULUNDUĞUNU, sadece isDeleted = true olduğunu doğrula
      final stillExistingMsg = pdks.chatMessages.firstWhere((m) => m.id == myMsg.id);
      expect(stillExistingMsg.isDeleted, isTrue);
      expect(stillExistingMsg.deletedBy, equals(emp.fullName));
      expect(stillExistingMsg.deletedAt, isNotNull);

      // Mesaj metninin veritabanı denetim kaydı için korunduğunu doğrula
      expect(stillExistingMsg.text, equals('Deneme kurumsal mesaj metni'));
    });

    test('Yetkisiz başka bir personel başkasının mesajını silemez', () {
      final pdks = PdksState();
      addTearDown(() {
        pdks.logout();
        pdks.dispose();
      });

      final emp1 = pdks.employees[0];
      final emp2 = pdks.employees[1];

      pdks.login(emp1.email, emp1.pinCode);
      pdks.sendMessage(channelId: 'company_general', text: 'Özel Mesaj');
      final msg = pdks.chatMessages.last;

      // Başka kullanıcı oturum açsın
      pdks.login(emp2.email, emp2.pinCode);
      final delRes = pdks.softDeleteChatMessage(msg.id);
      expect(delRes.success, isFalse);
      expect(delRes.message, contains('Yetki Sınırı'));
    });
  });

  group('4. Grup Kanalları İzolasyonu & Gizliliği', () {
    test('Gruba eklenmeyen çalışanlar kanalı channelsForCurrentUser içinde göremez', () {
      final pdks = PdksState();
      addTearDown(() {
        pdks.logout();
        pdks.dispose();
      });

      final boss = pdks.employees.firstWhere((e) => e.role == UserRole.boss);
      final emp1 = pdks.employees[0]; // Eklenecek üye
      final emp2 = pdks.employees[1]; // Eklenmeyecek üye

      pdks.login(boss.email, boss.pinCode);

      // Sadece boss ve emp1'in dahil olduğu özel bir grup kuralım
      final createRes = pdks.createGroupChannel(
        title: 'Ar-Ge Özel Ekip',
        subtitle: 'Gizli Proje Koordinasyonu',
        participantIds: [boss.id, emp1.id],
      );

      expect(createRes.success, isTrue);
      final groupChannel = createRes.channel!;

      // 1. Eklenen çalışan (emp1) oturum açtığında: Kanalı görür
      pdks.login(emp1.email, emp1.pinCode);
      final emp1Channels = pdks.channelsForCurrentUser;
      expect(emp1Channels.any((c) => c.id == groupChannel.id), isTrue);

      // 2. Eklenmeyen çalışan (emp2) oturum açtığında: Kanalı GÖREMEZ!
      pdks.login(emp2.email, emp2.pinCode);
      final emp2Channels = pdks.channelsForCurrentUser;
      expect(emp2Channels.any((c) => c.id == groupChannel.id), isFalse);
    });

    test('Eklenmeyen personele grup mesajları gitmez ve unreadChatCount artmaz', () {
      final pdks = PdksState();
      addTearDown(() {
        pdks.logout();
        pdks.dispose();
      });

      final boss = pdks.employees.firstWhere((e) => e.role == UserRole.boss);
      final empIn = pdks.employees[0];
      final empOut = pdks.employees[1];

      // Önce empOut'un başlangıç okunmamış sayısını alalım
      pdks.login(empOut.email, empOut.pinCode);
      final initialUnreadEmpOut = pdks.unreadChatCount;

      pdks.login(boss.email, boss.pinCode);
      final createRes = pdks.createGroupChannel(
        title: 'Finans Denetim Grubu',
        subtitle: 'Sadece yetkili üyeler',
        participantIds: [boss.id, empIn.id],
      );
      final channel = createRes.channel!;

      // Boss grupta mesaj göndersin
      pdks.sendMessage(
        channelId: channel.id,
        text: 'Gizli bilanço raporu yayınlandı.',
      );

      // 1. Eklenen üye (empIn) mesajı görmeli ve okunmamış sayılmalı
      pdks.login(empIn.email, empIn.pinCode);
      final empInMessages = pdks.getMessagesForChannel(channel.id);
      expect(empInMessages, isNotEmpty);
      expect(pdks.getUnreadCountForChannel(channel.id), greaterThan(0));

      // 2. Eklenmeyen kullanıcı (empOut) açısından kontrol:
      pdks.login(empOut.email, empOut.pinCode);

      // Mesajlar listesinde bu mesajlar gelmemeli (boş liste)
      final empOutMessages = pdks.getMessagesForChannel(channel.id);
      expect(empOutMessages, isEmpty);

      // Kanala ait okunmamış mesaj sayısı 0 olmalı
      expect(pdks.getUnreadCountForChannel(channel.id), equals(0));

      // Genel okunmamış mesaj sayısına da yansımamalı (başlangıç sayısıyla aynı kalmalı)
      expect(pdks.unreadChatCount, equals(initialUnreadEmpOut));

      // Eklenmeyen kullanıcı bu kanala mesaj da gönderememeli
      pdks.sendMessage(
        channelId: channel.id,
        text: 'Yetkisiz sızma denemesi',
      );
      final checkMessages = pdks.chatMessages.where((m) => m.channelId == channel.id && m.text == 'Yetkisiz sızma denemesi');
      expect(checkMessages, isEmpty);
    });
  });
}
