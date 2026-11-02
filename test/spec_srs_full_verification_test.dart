import 'package:flutter_test/flutter_test.dart';
import 'package:pdks_flutter/core/utils/labor_law_rule_engine.dart';
import 'package:pdks_flutter/models/equipment_and_cmms.dart';
import 'package:pdks_flutter/models/audit_log.dart';
import 'package:pdks_flutter/state/pdks_state.dart';
import 'package:pdks_flutter/core/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDKS Teknik artname (SRS) & 4857 Mevzuat Kural Motoru Testleri', () {
    test('1. 4857 Madde 68 - Kademeli Ara Dinlenme Mola Kesintisi Testi', () {
      // 3.5 saat alma -> 15 dakika mola
      final mola3h = LaborLawRuleEngine.calculateMandatoryBreak(const Duration(hours: 3, minutes: 30));
      expect(mola3h.inMinutes, equals(15));

      // 6 saat alma -> 30 dakika mola
      final mola6h = LaborLawRuleEngine.calculateMandatoryBreak(const Duration(hours: 6));
      expect(mola6h.inMinutes, equals(30));

      // 9 saat alma -> 60 dakika (1 saat) mola
      final mola9h = LaborLawRuleEngine.calculateMandatoryBreak(const Duration(hours: 9));
      expect(mola9h.inMinutes, equals(60));

      // Net alma: 9 saat brt - 1 saat mola = 8 saat net
      final netWork = LaborLawRuleEngine.calculateNetWorkDuration(const Duration(hours: 9));
      expect(netWork.inHours, equals(8));
    });

    test('2. 4857 Madde 69 - Gece almas (20:00 - 06:00) ve 7.5 Saat Yasal Snr Testi', () {
      // 22:00 giri, 06:00 k -> 8 saat alma, hepsi gece
      final entry = DateTime(2026, 11, 2, 22, 0);
      final exit = DateTime(2026, 11, 3, 6, 0);

      final nightDuration = LaborLawRuleEngine.calculateNightShiftHours(entry, exit);
      expect(nightDuration.inHours, equals(8));

      final nightCheck = LaborLawRuleEngine.checkNightWorkLimit(entry, exit);
      expect(nightCheck.isExceeded, isTrue); // 8 saat > 7.5 saat yasal snr ald!
      expect(nightCheck.warningMessage, contains('7.5 saati aamaz'));
    });

    test('3. 4857 Madde 63 - Gnlk Azami 11 Saat alma Snr Testi', () {
      final normalWork = LaborLawRuleEngine.checkDailyLimit(const Duration(hours: 8));
      expect(normalWork.isExceeded, isFalse);

      final excessWork = LaborLawRuleEngine.checkDailyLimit(const Duration(hours: 12));
      expect(excessWork.isExceeded, isTrue);
      expect(excessWork.warningMessage, contains('11 saati aamaz'));
    });

    test('4. 4857 Madde 41 - Yllk 270 Saat Fazla Mesai Snr ve Uyars Testi', () {
      final normalOT = LaborLawRuleEngine.checkAnnualOvertimeLimit(150.0);
      expect(normalOT.isExceeded, isFalse);
      expect(normalOT.isApproaching, isFalse);

      final approachOT = LaborLawRuleEngine.checkAnnualOvertimeLimit(245.0);
      expect(approachOT.isApproaching, isTrue);
      expect(approachOT.isExceeded, isFalse);
      expect(approachOT.warningMessage, contains('KRTTK UYARI'));

      final exceededOT = LaborLawRuleEngine.checkAnnualOvertimeLimit(275.0);
      expect(exceededOT.isExceeded, isTrue);
      expect(exceededOT.warningMessage, contains('YASAL SINIR AILDI'));
    });

    test('5. 4857 Madde 41 - Fazla Mesai Karl Zaml Serbest Zaman (1.5x) Testi', () {
      // 2 saat fazla mesai -> 3 saat zaml serbest zaman hakk
      final freeTime = LaborLawRuleEngine.calculateCompensatoryFreeTime(const Duration(hours: 2));
      expect(freeTime.inMinutes, equals(180)); // 3 saat = 180 dk
    });

    test('6. 4857 Madde 53 - Kdem ve Ya Kriterine Gre Yllk zin Hesab Testi', () {
      // 2 yl kdem, 30 ya -> 14 gn
      expect(LaborLawRuleEngine.calculateAnnualLeaveAllowance(yearsOfService: 2, age: 30), equals(14));

      // 8 yl kdem, 35 ya -> 20 gn
      expect(LaborLawRuleEngine.calculateAnnualLeaveAllowance(yearsOfService: 8, age: 35), equals(20));

      // 16 yl kdem, 40 ya -> 26 gn
      expect(LaborLawRuleEngine.calculateAnnualLeaveAllowance(yearsOfService: 16, age: 40), equals(26));

      // KRTTK KURAL: 2 yl kdem ama 52 ya -> En az 20 gn (14 gn yerine 20 gn taban)
      expect(LaborLawRuleEngine.calculateAnnualLeaveAllowance(yearsOfService: 2, age: 52), equals(20));

      // KRTTK KURAL: 1 yl kdem ama 17 ya (Gen i) -> En az 20 gn
      expect(LaborLawRuleEngine.calculateAnnualLeaveAllowance(yearsOfService: 1, age: 17), equals(20));
    });

    test('7. 4857 Dinlenme Hakk - Mesai D Sessiz Mod ve Acil Durum Muafiyeti Testi', () {
      // eride olmayan (vardiya d) personele normal mesaj gnderildi -> Bastrlr (true)
      final quietNormal = LaborLawRuleEngine.shouldSuppressNotificationForRestHours(
        isCurrentlyCheckedIn: false,
        isCurrentlyOnLeave: false,
        isEmergencyOrIsg: false,
      );
      expect(quietNormal, isTrue);

      // eride olmayan personele ACIL / SG mesaj gnderildi -> Muaf tutulur (false)
      final quietUrgent = LaborLawRuleEngine.shouldSuppressNotificationForRestHours(
        isCurrentlyCheckedIn: false,
        isCurrentlyOnLeave: false,
        isEmergencyOrIsg: true,
      );
      expect(quietUrgent, isFalse);

      // eride alan personele normal mesaj -> Bastrlmaz, iletilir (false)
      final insideNormal = LaborLawRuleEngine.shouldSuppressNotificationForRestHours(
        isCurrentlyCheckedIn: true,
        isCurrentlyOnLeave: false,
        isEmergencyOrIsg: false,
      );
      expect(insideNormal, isFalse);
    });

    test('8. KVKK Uyumluluu - TC Kimlik ve cret Maskeleme Testi', () {
      final maskedTc = LaborLawRuleEngine.maskTcKimlik('12345678901');
      expect(maskedTc, equals('123*****01'));

      final maskedSalary = LaborLawRuleEngine.maskSalary(45000.0);
      expect(maskedSalary, equals('******  TL'));
    });
  });

  group('CMMS & Kalibrasyon Ynetim Sistemi (ISO 9001 / ISO 17025) Testleri', () {
    test('9. Ekipman Kalibrasyon Geri Saym ve Karantina Stat Belirleme Testi', () {
      // 100 gn sonrasna kalibrasyonu olan cihaz -> active
      final activeEq = EquipmentRecord(
        id: 'test_eq_1',
        companyId: 'cmp_acme',
        equipmentCode: 'CNC-TEST',
        serialNumber: 'SN-01',
        name: 'CNC Torna',
        brandModel: 'Mazak',
        department: 'retim',
        location: 'Hol 1',
        qrBarcode: 'EQ-01',
        lastCalibrationDate: DateTime.now().subtract(const Duration(days: 200)),
        nextCalibrationDate: DateTime.now().add(const Duration(days: 100)),
      );
      expect(activeEq.isQuarantined, isFalse);
      expect(activeEq.computedStatus, equals('active'));

      // Kalibrasyonuna 2 gn kalm cihaz -> warning_3d
      final warnEq = EquipmentRecord(
        id: 'test_eq_2',
        companyId: 'cmp_acme',
        equipmentCode: 'MIC-TEST',
        serialNumber: 'SN-02',
        name: 'Mikrometre',
        brandModel: 'Mitutoyo',
        department: 'Kalite',
        location: 'Lab',
        qrBarcode: 'EQ-02',
        lastCalibrationDate: DateTime.now().subtract(const Duration(days: 180)),
        nextCalibrationDate: DateTime.now().add(const Duration(days: 2)),
      );
      expect(warnEq.computedStatus, equals('warning_3d'));

      // Kalibrasyonu 10 gn gemi cihaz -> Otomatik Karantina
      final expEq = EquipmentRecord(
        id: 'test_eq_3',
        companyId: 'cmp_acme',
        equipmentCode: 'TRN-TEST',
        serialNumber: 'SN-03',
        name: 'Turnike Terminali',
        brandModel: 'ZKTeco',
        department: 'Gvenlik',
        location: 'Kap 1',
        qrBarcode: 'EQ-03',
        lastCalibrationDate: DateTime.now().subtract(const Duration(days: 375)),
        nextCalibrationDate: DateTime.now().subtract(const Duration(days: 10)),
      );
      expect(expEq.isQuarantined, isTrue);
      expect(expEq.computedStatus, equals('quarantine'));
    });

    test('10. CMMS  Emri Paralar ve Toplam Maliyet Hesab Testi', () {
      final part1 = SparePartItem(partName: 'Filtre Kartuu', quantity: 3, unitCost: 150.0);
      final part2 = SparePartItem(partName: 'Kzak Ya (1L)', quantity: 2, unitCost: 200.0);

      expect(part1.total, equals(450.0));
      expect(part2.total, equals(400.0));

      final wo = MaintenanceWorkOrder(
        id: 'wo_test_01',
        companyId: 'cmp_acme',
        equipmentId: 'eq_01',
        equipmentCode: 'CNC-01',
        equipmentName: 'CNC Freze',
        title: 'Periyodik Bakm',
        description: 'Test bakm',
        reportedBy: 'Ahmet Ylmaz',
        partsUsed: [part1, part2],
        totalCost: part1.total + part2.total,
        mttrMinutes: 90,
      );

      expect(wo.totalCost, equals(850.0));
      expect(wo.mttrMinutes, equals(90));
    });
  });

  group('Deitirilemez Denetim Kayd (Audit Log) & Dnem Kilitleme Testleri', () {
    test('11. AuditLogRecord SHA-256 Blok Btnlk mzalamas Testi', () {
      final log = AuditLogRecord(
        id: 'audit_test_01',
        companyId: 'cmp_acme',
        userId: 1,
        userName: 'Ahmet Ylmaz',
        userRole: 'Sistem Yneticisi',
        actionType: 'Mesai Onay',
        targetEntity: 'AttendanceRecord',
        entityId: 'rec_101',
        oldValue: 'approved: false',
        newValue: 'approved: true',
      );

      expect(log.hashSignature, isNotEmpty);
      expect(log.hashSignature.length, equals(64)); // SHA-256 hex string = 64 karakter
    });

    test('12. Puantaj Dnem Kilitleme Kalcl Testi', () async {
      await DatabaseService.instance.init();
      final db = DatabaseService.instance;

      const testPeriod = '2026-10';
      if (db.isPeriodLocked(testPeriod)) {
        await db.togglePeriodLock(testPeriod);
      }
      expect(db.isPeriodLocked(testPeriod), isFalse);

      await db.togglePeriodLock(testPeriod);
      expect(db.isPeriodLocked(testPeriod), isTrue);

      // Tekrar aldnda ak olmal
      await db.togglePeriodLock(testPeriod);
      expect(db.isPeriodLocked(testPeriod), isFalse);
    });
  });

  group('PDKSState Entegrasyon ve apraz Kontrol Testleri', () {
    test('13. PdksState api/apraz Entegrasyon Kontrolleri', () async {
      final db = DatabaseService.instance;
      await db.insertEquipmentRecord(
        EquipmentRecord(
          id: 'eq_quarantine_test',
          companyId: 'cmp_acme',
          equipmentCode: 'TRN-02',
          serialNumber: 'SN-Q',
          name: 'Turnike Terminali',
          brandModel: 'ZKTeco',
          department: 'Gvenlik',
          location: 'Kap 1',
          qrBarcode: 'EQ-Q',
          status: 'quarantine',
          quarantineReason: 'Yllk dorulama periyodu ald',
        ),
      );

      final state = PdksState();
      await state.reloadAllFromDatabase();

      // Karantinadaki cihaza standart i emri ama engeli
      final res = await state.createMaintenanceWorkOrder(
        equipmentId: 'eq_quarantine_test',
        title: 'Standart Ya Deimi',
        description: 'Deneme',
        priority: 'normal',
      );

      expect(res.success, isFalse);
      expect(res.message, contains('KARANTİNADA'));
    });
  });
}
