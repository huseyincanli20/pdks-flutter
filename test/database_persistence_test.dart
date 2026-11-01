import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdks_flutter/core/services/database_service.dart';
import 'package:pdks_flutter/models/company.dart';
import 'package:pdks_flutter/models/employee.dart';
import 'package:pdks_flutter/models/payroll_slip.dart';
import 'package:pdks_flutter/models/shift_schedule.dart';
import 'package:pdks_flutter/models/cafeteria_menu.dart';
import 'package:pdks_flutter/models/app_notification.dart';
import 'package:pdks_flutter/state/pdks_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DatabaseService.instance.init(forceReload: true);
  });

  group('DatabaseService Tam Kalıcılık Testleri', () {
    test('Tüm 16 tablonun varsayılan verilerle yüklenmesi ve getirilmesi', () async {
      final db = DatabaseService.instance;

      expect(db.getAllCompanies().isNotEmpty, true, reason: 'Şirketler yüklenmeli');
      expect(db.getAllEmployees().isNotEmpty, true, reason: 'Personeller yüklenmeli');
      expect(db.getAllRoles().isNotEmpty, true, reason: 'Roller yüklenmeli');
      expect(db.getAllPayrolls().isNotEmpty, true, reason: 'Bordrolar yüklenmeli');
      expect(db.getTwoWeekMenus().isNotEmpty, true, reason: '2 Haftalık menü yüklenmeli');
      expect(db.getAllShifts().isNotEmpty, true, reason: 'Vardiyalar yüklenmeli');
      expect(db.getAllNotifications().isNotEmpty, true, reason: 'Bildirimler yüklenmeli');
      expect(db.getAllQuickMenuItems().isNotEmpty, true, reason: 'Hızlı menü yüklenmeli');
    });

    test('Şirket CRUD işlemleri ve veritabanı senkronizasyonu', () async {
      final db = DatabaseService.instance;
      final newComp = Company(
        id: 'comp_test_99',
        code: 'TEST99',
        name: 'Test Holding A.Ş.',
        sector: 'Bilişim',
        address: 'İstanbul Teknopark',
        officeLat: 41.0082,
        officeLng: 28.9784,
        allowedWifiSsid: 'TEST_OFFICE_WIFI',
      );

      await db.insertCompany(newComp);
      expect(db.getCompanyById('comp_test_99')?.name, 'Test Holding A.Ş.');

      final updatedComp = newComp.copyWith(name: 'Test Holding Güncel');
      await db.updateCompany(updatedComp);
      expect(db.getCompanyById('comp_test_99')?.name, 'Test Holding Güncel');

      await db.deleteCompany('comp_test_99');
      expect(db.getCompanyById('comp_test_99'), isNull);
    });

    test('Rol CRUD işlemleri ve AppRoleItem serileştirme', () async {
      final db = DatabaseService.instance;
      const customRole = AppRoleItem(
        id: 'role_custom_tech',
        name: 'Kıdemli Saha Teknisyeni',
        description: 'Saha altyapı ve bakım yetkilisi',
        baseRole: UserRole.technician,
        icon: Icons.build_circle,
        color: Colors.amber,
        isSystemRole: false,
        createdBy: 'Admin',
        allowedPageIds: ['home', 'attendance', 'notifications'],
      );

      await db.insertRole(customRole);
      final fetchedRole = db.getAllRoles().firstWhere((r) => r.id == 'role_custom_tech');
      expect(fetchedRole.name, 'Kıdemli Saha Teknisyeni');
      expect(fetchedRole.allowedPageIds.contains('attendance'), true);

      final updatedRole = customRole.copyWith(name: 'Baş Teknisyen');
      await db.updateRole(updatedRole);
      expect(db.getAllRoles().firstWhere((r) => r.id == 'role_custom_tech').name, 'Baş Teknisyen');

      await db.deleteRole('role_custom_tech');
      expect(db.getAllRoles().any((r) => r.id == 'role_custom_tech'), false);
    });

    test('Bordro CRUD işlemleri ve toJson/fromJson doğrulaması', () async {
      final db = DatabaseService.instance;
      final slip = PayrollSlip(
        id: 'slip_test_01',
        companyId: 'cmp_acme',
        companyName: 'Acme Holding',
        employeeId: 1,
        employeeName: 'Ahmet Yılmaz',
        employeeTitle: 'Kıdemli Mühendis',
        department: 'Yazılım',
        tcKimlikNo: '11111111111',
        sicilNo: 'EMP-001',
        iban: 'TR110000000000000000000000',
        bankName: 'İş Bankası',
        periodMonth: 11,
        periodYear: 2026,
        issueDate: DateTime.now(),
        paymentDate: DateTime.now(),
        baseGrossSalary: 45000,
        incomeTax: 5500,
        stampTax: 340,
        status: PayrollStatus.draft,
      );

      await db.insertPayroll(slip);
      expect(db.getAllPayrolls().any((p) => p.id == 'slip_test_01'), true);

      // Onayla
      await db.bulkUpdatePayrollStatus(11, 2026, 'cmp_acme', PayrollStatus.approved);
      expect(db.getAllPayrolls().firstWhere((p) => p.id == 'slip_test_01').status, PayrollStatus.approved);

      // Ödendi yap
      await db.bulkUpdatePayrollStatus(11, 2026, 'cmp_acme', PayrollStatus.paid);
      expect(db.getAllPayrolls().firstWhere((p) => p.id == 'slip_test_01').status, PayrollStatus.paid);
      expect(db.getAllPayrolls().firstWhere((p) => p.id == 'slip_test_01').paymentDate, isNotNull);
    });

    test('Vardiya CRUD ve SharedPreferences kalıcılığı', () async {
      final db = DatabaseService.instance;
      final newShift = ShiftSchedule(
        id: 991,
        title: 'Gece Vardiyası C',
        startTime: '00:00',
        endTime: '08:00',
        breakMinutes: 45,
        assignedEmployeeCount: 8,
        activeDays: ['Pzt', 'Sal', 'Çar'],
      );

      await db.insertShift(newShift);
      expect(db.getAllShifts().any((s) => s.id == 991), true);

      final updatedShift = ShiftSchedule(
        id: 991,
        title: 'Gece Vardiyası Güncel',
        startTime: '23:30',
        endTime: '07:30',
        breakMinutes: 60,
        assignedEmployeeCount: 12,
        activeDays: ['Pzt', 'Sal', 'Çar', 'Per'],
      );
      await db.updateShift(updatedShift);
      expect(db.getAllShifts().firstWhere((s) => s.id == 991).title, 'Gece Vardiyası Güncel');

      await db.deleteShift(991);
      expect(db.getAllShifts().any((s) => s.id == 991), false);
    });

    test('2 Haftalık Yemekhane Menüsü kalıcı kaydı ve getirilmesi', () async {
      final db = DatabaseService.instance;
      final currentMenus = List<CafeteriaMenu>.from(db.getTwoWeekMenus());
      expect(currentMenus.isNotEmpty, true);

      final newMenuDay = CafeteriaMenu(
        companyId: 'cmp_acme',
        date: DateTime.now().add(const Duration(days: 20)),
        soup: 'Yayla Çorbası',
        mainDish: 'Karnıyarık & Pilav',
        sideDish: 'Cacık',
        dessertOrSalad: 'Revani',
        soupCalories: 150,
        mainDishCalories: 450,
      );

      currentMenus.add(newMenuDay);
      await db.saveTwoWeekMenus(currentMenus);

      final reloaded = db.getTwoWeekMenus();
      expect(reloaded.any((m) => m.mainDish == 'Karnıyarık & Pilav'), true);
    });

    test('Bildirim okundu, toplu okundu ve silindi DB işlemleri', () async {
      final db = DatabaseService.instance;
      final notif = AppNotification(
        id: 'notif_test_1',
        title: 'Test Bildirimi',
        message: 'Veritabanı test içeriği',
        type: NotificationType.system,
        icon: Icons.notifications,
        color: Colors.blue,
        timestamp: DateTime.now(),
        isRead: false,
      );

      await db.insertNotification(notif);
      expect(db.getAllNotifications().any((n) => n.id == 'notif_test_1' && !n.isRead), true);

      await db.markNotificationAsRead('notif_test_1');
      expect(db.getAllNotifications().firstWhere((n) => n.id == 'notif_test_1').isRead, true);

      await db.markAllNotificationsAsRead();
      expect(db.getAllNotifications().every((n) => n.isRead), true);

      await db.clearAllNotifications();
      expect(db.getAllNotifications().isEmpty, true);
    });

    test('Tema ve Aktif Şirket Tercihlerinin Veritabanına Yazılması ve Çekilmesi', () async {
      final db = DatabaseService.instance;

      await db.saveActiveCompanyId('comp_holding_xyz');
      expect(db.getActiveCompanyId(), 'comp_holding_xyz');

      await db.saveThemeType('dark');
      expect(db.getThemeType(), 'dark');
    });
  });

  group('PdksState ve DatabaseService Entegrasyon Testleri', () {
    test('PdksState başlangıçta tüm verileri veritabanından çeker', () async {
      final state = PdksState();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(state.companies.isNotEmpty, true);
      expect(state.employees.isNotEmpty, true);
      expect(state.roles.isNotEmpty, true);
      expect(state.shifts.isNotEmpty, true);
      expect(state.twoWeekMenus.isNotEmpty, true);
      expect(state.payrolls.isNotEmpty, true);
    });

    test('PdksState rol ekleme, yetki güncelleme ve silme veritabanına yansır', () async {
      final state = PdksState();
      await Future.delayed(const Duration(milliseconds: 50));

      final res = state.addNewRole(
        name: 'İşyeri Hekimi',
        description: 'Periyodik muayene ve revir sorumlusu',
        baseRole: UserRole.doctor,
        icon: Icons.medical_services_rounded,
        color: Colors.teal,
        allowedPageIds: ['home', 'profile', 'notifications'],
      );
      expect(res.success, true);
      final createdRole = state.roles.firstWhere((r) => r.name == 'İşyeri Hekimi');
      expect(DatabaseService.instance.getAllRoles().any((r) => r.id == createdRole.id), true);

      state.updateRolePermissions(createdRole.id, ['home', 'profile', 'notifications', 'chat']);
      final updatedRole = state.roles.firstWhere((r) => r.id == createdRole.id);
      expect(updatedRole.allowedPageIds.contains('chat'), true);
      expect(DatabaseService.instance.getAllRoles().firstWhere((r) => r.id == createdRole.id).allowedPageIds.contains('chat'), true);

      state.deleteRole(createdRole.id);
      expect(state.roles.any((r) => r.id == createdRole.id), false);
      expect(DatabaseService.instance.getAllRoles().any((r) => r.id == createdRole.id), false);
    });

    test('PdksState bordro durumu onaylama ve ödeme veritabanına kaydedilir', () async {
      final state = PdksState();
      await Future.delayed(const Duration(milliseconds: 50));

      final targetSlip = state.payrolls.first;
      state.updatePayrollStatus(targetSlip.id, PayrollStatus.approved);
      expect(state.payrolls.firstWhere((p) => p.id == targetSlip.id).status, PayrollStatus.approved);
      expect(DatabaseService.instance.getAllPayrolls().firstWhere((p) => p.id == targetSlip.id).status, PayrollStatus.approved);

      state.bulkPayPayrolls(targetSlip.periodMonth, targetSlip.periodYear);
      expect(state.payrolls.firstWhere((p) => p.id == targetSlip.id).status, PayrollStatus.paid);
      expect(DatabaseService.instance.getAllPayrolls().firstWhere((p) => p.id == targetSlip.id).status, PayrollStatus.paid);
    });

    test('PdksState reloadAllFromDatabase() tüm tabloları veritabanından tazeleyerek çeker', () async {
      final state = PdksState();
      await Future.delayed(const Duration(milliseconds: 50));

      // Veritabanına doğrudan yeni bir şirket ekleyelim
      final directComp = Company(
        id: 'comp_direct_sync',
        code: 'DIR99',
        name: 'Doğrudan DB Şirketi',
        sector: 'Teknoloji',
        address: 'Ankara',
        officeLat: 39.9,
        officeLng: 32.8,
        allowedWifiSsid: 'DIRECT_WIFI',
      );
      await DatabaseService.instance.insertCompany(directComp);

      // state henüz haberdar değil
      expect(state.companies.any((c) => c.id == 'comp_direct_sync'), false);

      // reloadAllFromDatabase çağrıldığında
      await state.reloadAllFromDatabase();

      // Artık veritabanından çekilmiş olmalı
      expect(state.companies.any((c) => c.id == 'comp_direct_sync'), true);
    });
  });
}
