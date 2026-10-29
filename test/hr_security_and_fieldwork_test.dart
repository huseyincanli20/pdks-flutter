import 'package:flutter_test/flutter_test.dart';
import 'package:pdks_flutter/models/employee.dart';
import 'package:pdks_flutter/state/pdks_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('İK Güvenlik Kısıtlamaları (Admin Yetkisi Verilememe)', () {
    test('İK yetkilisi başka bir personele Admin rolü veya unvanı veremez', () {
      final state = PdksState();

      // İK kullanıcısı olarak oturum aç (ik@sirket.com / 2345)
      final loginRes = state.login('ik@sirket.com', '2345');
      expect(loginRes.success, isTrue);
      expect(state.currentUser.role, equals(UserRole.hr));

      // Standart bir personeli bul
      final target = state.employees.firstWhere((e) => e.role == UserRole.employee);

      // 1. İK, personelin rolünü Admin yapmayı denediğinde REDDEDİLMELİ
      final updateRoleRes = state.changeEmployeeRoleByActor(
        employeeId: target.id,
        newBaseRole: UserRole.admin,
      );
      expect(updateRoleRes.success, isFalse);
      expect(updateRoleRes.message, contains('Admin'));

      // 2. İK, unvanı Admin yapmayı denediğinde REDDEDİLMELİ
      final updateInfoRes = state.updateEmployeeByHr(
        employeeId: target.id,
        fullName: target.fullName,
        phone: target.phone,
        department: target.department,
        title: 'Sistem Yöneticisi (Admin)',
        role: UserRole.employee,
      );
      expect(updateInfoRes.success, isFalse);
      expect(updateInfoRes.message, contains('Admin'));

      // 3. İK, onaylama sırasında Admin rolü vermeyi denerse REDDEDİLMELİ
      final approveRes = state.approveEmployeeRegistration(
        employeeId: target.id,
        department: 'Bilişim',
        title: 'Genel Admin',
        role: UserRole.admin,
      );
      expect(approveRes.success, isFalse);
      expect(approveRes.message, contains('Admin'));

      state.dispose();
    });
  });

  group('CEO ve Admin Hızlı Menü Yönetimi', () {
    test('Yalnızca CEO ve Admin hızlı menüleri gizleyebilir ve yeni menü ekleyebilir', () {
      final state = PdksState();

      // Standart personel ile giriş
      state.login('personel@sirket.com', '1234');
      expect(state.currentUser.role, equals(UserRole.employee));

      // Standart personel menü gizlemeyi dener -> Reddedilir
      final empToggleRes = state.toggleQuickMenuItemVisibility('qm_leave');
      expect(empToggleRes.success, isFalse);

      // Standart personel menü eklemeyi dener -> Reddedilir
      final empAddRes = state.addQuickMenuItem(
        title: 'Yetkisiz Menü',
        subtitle: 'Deneme',
        iconCode: 0xe156,
        colorValue: 0xFF2563EB,
        actionType: 'info_dialog',
      );
      expect(empAddRes.success, isFalse);

      // Şimdi Admin olarak giriş yap
      state.login('admin@sirket.com', '4567');
      expect(state.currentUser.role, equals(UserRole.admin));

      // Admin 'qm_leave' menüsünü gizleyebilir
      final adminToggleRes = state.toggleQuickMenuItemVisibility('qm_leave');
      expect(adminToggleRes.success, isTrue);

      final toggledItem = state.quickMenuItems.firstWhere((m) => m.id == 'qm_leave');
      expect(toggledItem.isVisible, isFalse);

      // Admin yeni menü ekleyebilir
      final adminAddRes = state.addQuickMenuItem(
        title: 'Şirket Aracı Talep',
        subtitle: 'Saha aracı rezervasyonu',
        iconCode: 0xe425,
        colorValue: 0xFF10B981,
        actionType: 'field_work',
      );
      expect(adminAddRes.success, isTrue);
      expect(state.quickMenuItems.any((m) => m.title == 'Şirket Aracı Talep'), isTrue);

      state.dispose();
    });
  });

  group('Dışarıda Çalışma (Saha Görevi) Sistemi', () {
    test('Dışarıda çalışma başlatıldığında GPS konumu ve görev İK bildirimine düşmeli', () {
      final state = PdksState();

      // Personel ile giriş yap
      state.login('personel@sirket.com', '1234');

      final startRes = state.startFieldWork(
        missionTitle: 'Müşteri Ziyareti - Maslak',
        missionNote: 'Yeni sözleşme toplantısı için yerinde ziyaret.',
        latitude: 41.1105,
        longitude: 29.0224,
        addressName: 'Maslak No:1 Plaza, Sarıyer / İstanbul',
      );

      expect(startRes.success, isTrue);
      expect(state.isCheckedIn, isTrue);
      expect(state.isFieldWorkActive, isTrue);
      expect(state.activeFieldWorkTitle, equals('Müşteri Ziyareti - Maslak'));
      expect(state.activeFieldWorkAddress, equals('Maslak No:1 Plaza, Sarıyer / İstanbul'));

      // İK'ya anlık bildirim oluşturulmuş olmalı
      final notif = state.notifications.first;
      expect(notif.title, contains('Dışarıda Çalışma'));
      expect(notif.message, contains('Maslak No:1 Plaza'));
      expect(notif.message, contains('41.1105'));

      // Dışarıda çalışmayı sonlandır
      final endRes = state.endFieldWork(exitNote: 'Toplantı başarılı bitti.');
      expect(endRes.success, isTrue);
      expect(state.isFieldWorkActive, isFalse);
      expect(state.isCheckedIn, isFalse);

      state.dispose();
    });
  });
}
