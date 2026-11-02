import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdks_flutter/core/services/database_service.dart';
import 'package:pdks_flutter/core/services/location_service.dart';
import 'package:pdks_flutter/core/theme/app_theme.dart';
import 'package:pdks_flutter/core/utils/movement_calculation_engine.dart';
import 'package:pdks_flutter/models/attendance_record.dart';
import 'package:pdks_flutter/models/employee.dart';
import 'package:pdks_flutter/models/employee_movement.dart';
import 'package:pdks_flutter/models/leave_request.dart';
import 'package:pdks_flutter/state/pdks_state.dart';
import 'package:pdks_flutter/views/movement_management/employee_movement_management_screen.dart';

EmployeeMovementRecord _makeMovement({
  required String id,
  required int employeeId,
  required int shiftId,
  required String shiftName,
  required MovementType type,
  required DateTime timestamp,
  String deviceDoor = 'Ana Bina Turnike 1',
  MovementSource source = MovementSource.device,
  String note = '',
}) {
  return EmployeeMovementRecord(
    id: id,
    employeeId: employeeId,
    sicilNo: 'SIC-0101',
    employeeName: 'Çağrı Öztürk',
    department: 'Yazılım & Ar-Ge',
    shiftId: shiftId,
    shiftName: shiftName,
    type: type,
    timestamp: timestamp,
    deviceDoor: deviceDoor,
    source: source,
    note: note,
    rawDeviceSnapshot: RawDeviceMovementSnapshot(
      type: type,
      timestamp: timestamp,
      deviceDoor: deviceDoor,
      source: source,
      note: note,
    ),
  );
}

void main() {
  final sampleEmployee = Employee(
    id: 101,
    sicilNo: 'SIC-0101',
    fullName: 'Çağrı Öztürk',
    title: 'Kıdemli Yazılım Mühendisi',
    department: 'Yazılım & Ar-Ge',
    role: UserRole.employee,
    email: 'cagri@sirket.com',
    phone: '05320000101',
    pinCode: '1234',
  );

  const dayShift = PdksShiftDefinition(
    id: 1,
    name: 'Gündüz Vardiyası',
    startTime: '08:30',
    endTime: '17:30',
    plannedBreakMinutes: 60,
    lateToleranceMinutes: 10,
    workDays: [1, 2, 3, 4, 5],
  );

  const nightShift = PdksShiftDefinition(
    id: 3,
    name: 'Gece Vardiyası',
    startTime: '22:00',
    endTime: '06:00',
    plannedBreakMinutes: 45,
    lateToleranceMinutes: 10,
    workDays: [1, 2, 3, 4, 5, 6],
  );

  group('Hesaplama Kuralları (MovementCalculationEngine) Testleri', () {
    test('1. Normal çalışma, birden fazla giriş-çıkış ve eşleşmiş mola hesabı', () {
      final date = DateTime(2026, 11, 2); // Pazartesi
      final now = DateTime(2026, 11, 2, 19, 0);

      final movements = [
        _makeMovement(
          id: 'm1',
          employeeId: 101,
          shiftId: dayShift.id,
          shiftName: dayShift.name,
          type: MovementType.checkIn,
          timestamp: DateTime(2026, 11, 2, 8, 30),
        ),
        _makeMovement(
          id: 'm2',
          employeeId: 101,
          shiftId: dayShift.id,
          shiftName: dayShift.name,
          type: MovementType.breakStart,
          timestamp: DateTime(2026, 11, 2, 12, 30),
          deviceDoor: 'Kafeterya Turnike',
        ),
        _makeMovement(
          id: 'm3',
          employeeId: 101,
          shiftId: dayShift.id,
          shiftName: dayShift.name,
          type: MovementType.breakEnd,
          timestamp: DateTime(2026, 11, 2, 13, 15), // 45 dk mola
          deviceDoor: 'Kafeterya Turnike',
        ),
        _makeMovement(
          id: 'm4',
          employeeId: 101,
          shiftId: dayShift.id,
          shiftName: dayShift.name,
          type: MovementType.checkOut,
          timestamp: DateTime(2026, 11, 2, 15, 0),
        ),
        // İkinci giriş-çıkış aralığı
        _makeMovement(
          id: 'm5',
          employeeId: 101,
          shiftId: dayShift.id,
          shiftName: dayShift.name,
          type: MovementType.checkIn,
          timestamp: DateTime(2026, 11, 2, 15, 30),
        ),
        _makeMovement(
          id: 'm6',
          employeeId: 101,
          shiftId: dayShift.id,
          shiftName: dayShift.name,
          type: MovementType.checkOut,
          timestamp: DateTime(2026, 11, 2, 17, 30),
        ),
      ];

      final summary = MovementCalculationEngine.calculateDailySummary(
        employee: sampleEmployee,
        date: date,
        shift: dayShift,
        allMovements: movements,
        leaves: const [],
        includeFieldDutyInNetWork: true,
        referenceNow: now,
      );

      // Toplam brüt: (08:30-15:00 = 6s 30dk) + (15:30-17:30 = 2s) = 8s 30dk (510 dk)
      // Mola: 45 dk -> Net çalışma: 510 - 45 = 465 dk (7s 45dk)
      expect(summary.status, DailyAttendanceStatus.completed);
      expect(summary.totalBreakDuration, const Duration(minutes: 45));
      expect(summary.netWorkDuration, const Duration(minutes: 465));
      expect(summary.lateDuration, Duration.zero);
      expect(summary.anomalies, isEmpty);
    });

    test('2. Gece vardiyasında ertesi güne geçen çıkış ve mola doğru eşleşir', () {
      final shiftDate = DateTime(2026, 11, 1); // 01.11.2026 22:00 -> 02.11.2026 06:00
      final now = DateTime(2026, 11, 2, 12, 0);

      expect(nightShift.crossesMidnight, isTrue);

      final movements = [
        _makeMovement(
          id: 'n1',
          employeeId: 101,
          shiftId: nightShift.id,
          shiftName: nightShift.name,
          type: MovementType.checkIn,
          timestamp: DateTime(2026, 11, 1, 21, 55),
          deviceDoor: 'Üretim Turnike',
        ),
        _makeMovement(
          id: 'n2',
          employeeId: 101,
          shiftId: nightShift.id,
          shiftName: nightShift.name,
          type: MovementType.breakStart,
          timestamp: DateTime(2026, 11, 2, 1, 30),
          deviceDoor: 'Üretim Dinlenme',
        ),
        _makeMovement(
          id: 'n3',
          employeeId: 101,
          shiftId: nightShift.id,
          shiftName: nightShift.name,
          type: MovementType.breakEnd,
          timestamp: DateTime(2026, 11, 2, 2, 15), // 45 dk mola
          deviceDoor: 'Üretim Dinlenme',
        ),
        _makeMovement(
          id: 'n4',
          employeeId: 101,
          shiftId: nightShift.id,
          shiftName: nightShift.name,
          type: MovementType.checkOut,
          timestamp: DateTime(2026, 11, 2, 6, 40), // 40 dk vardiya sonrası çıkış
          deviceDoor: 'Üretim Turnike',
        ),
      ];

      final summary = MovementCalculationEngine.calculateDailySummary(
        employee: sampleEmployee,
        date: shiftDate,
        shift: nightShift,
        allMovements: movements,
        leaves: const [],
        includeFieldDutyInNetWork: true,
        referenceNow: now,
      );

      expect(summary.status, DailyAttendanceStatus.completed);
      expect(summary.firstCheckIn, DateTime(2026, 11, 1, 21, 55));
      expect(summary.lastCheckOut, DateTime(2026, 11, 2, 6, 40));
      expect(summary.totalBreakDuration, const Duration(minutes: 45));
      // 21:55 -> 06:40 = 8s 45dk (525 dk) brüt, 45 dk mola -> 480 dk (8s) net
      expect(summary.netWorkDuration, const Duration(minutes: 480));
      expect(summary.pendingExtraDuration.inMinutes, greaterThan(0));
    });

    test('3. Eksik çıkışta kesin çalışma süresi üretilmez (null döner) ve incelemeye işaretlenir', () {
      final date = DateTime(2026, 11, 1);
      final now = DateTime(2026, 11, 2, 10, 0); // Vardiya bitmiş

      final movements = [
        _makeMovement(
          id: 'e1',
          employeeId: 101,
          shiftId: dayShift.id,
          shiftName: dayShift.name,
          type: MovementType.checkIn,
          timestamp: DateTime(2026, 11, 1, 8, 32),
        ),
      ];

      final summary = MovementCalculationEngine.calculateDailySummary(
        employee: sampleEmployee,
        date: date,
        shift: dayShift,
        allMovements: movements,
        leaves: const [],
        includeFieldDutyInNetWork: true,
        referenceNow: now,
      );

      expect(summary.status, DailyAttendanceStatus.missingMovement);
      expect(summary.hasMissingOrOpenInterval, isTrue);
      expect(summary.netWorkDuration, isNull);
      expect(
        summary.anomalies.any((a) => a.category == AnomalyCategory.missingCheckInOrOut),
        isTrue,
      );
    });

    test('4. Devam eden vardiyada personel eksik çıkış veya devamsız sayılmaz (Çalışıyor / Molada)', () {
      final date = DateTime(2026, 11, 2);
      final duringShiftNow = DateTime(2026, 11, 2, 11, 0); // Vardiya 08:30 - 17:30 devam ediyor

      final movementsWorking = [
        _makeMovement(
          id: 'w1',
          employeeId: 101,
          shiftId: dayShift.id,
          shiftName: dayShift.name,
          type: MovementType.checkIn,
          timestamp: DateTime(2026, 11, 2, 8, 50), // 10 dk toleransı aştı -> 20 dk geç kalma
        ),
      ];

      final workingSummary = MovementCalculationEngine.calculateDailySummary(
        employee: sampleEmployee,
        date: date,
        shift: dayShift,
        allMovements: movementsWorking,
        leaves: const [],
        includeFieldDutyInNetWork: true,
        referenceNow: duringShiftNow,
      );

      expect(workingSummary.status, DailyAttendanceStatus.working);
      expect(workingSummary.lateDuration, const Duration(minutes: 20));
      expect(workingSummary.anomalies, isEmpty);
    });

    test('5. İzinli, raporlu ve hafta tatilindeki personel devamsız sayılmaz', () {
      final monday = DateTime(2026, 11, 2);
      final sunday = DateTime(2026, 11, 1); // Pazar (hafta tatili)
      final now = DateTime(2026, 11, 2, 20, 0);

      final annualLeave = LeaveRequest(
        id: 1,
        employeeId: 101,
        employeeName: 'Çağrı Öztürk',
        type: LeaveType.annual,
        startDate: monday,
        endDate: monday,
        totalDays: 1,
        reason: 'Yıllık izin',
        status: LeaveStatus.approved,
        createdAt: sunday,
      );

      final leaveSummary = MovementCalculationEngine.calculateDailySummary(
        employee: sampleEmployee,
        date: monday,
        shift: dayShift,
        allMovements: const [],
        leaves: [annualLeave],
        includeFieldDutyInNetWork: true,
        referenceNow: now,
      );
      expect(leaveSummary.status, DailyAttendanceStatus.onLeave);

      final weekendSummary = MovementCalculationEngine.calculateDailySummary(
        employee: sampleEmployee,
        date: sunday,
        shift: dayShift,
        allMovements: const [],
        leaves: const [],
        includeFieldDutyInNetWork: true,
        referenceNow: now,
      );
      expect(weekendSummary.status, DailyAttendanceStatus.weekend);
    });

    test('6. Görevde geçen sürenin net çalışmaya dahil edilmesi ayarlanabilir', () {
      final date = DateTime(2026, 11, 2);
      final now = DateTime(2026, 11, 2, 19, 0);

      final movements = [
        _makeMovement(
          id: 'd1',
          employeeId: 101,
          shiftId: dayShift.id,
          shiftName: dayShift.name,
          type: MovementType.checkIn,
          timestamp: DateTime(2026, 11, 2, 8, 30),
        ),
        _makeMovement(
          id: 'd2',
          employeeId: 101,
          shiftId: dayShift.id,
          shiftName: dayShift.name,
          type: MovementType.dutyOut,
          timestamp: DateTime(2026, 11, 2, 10, 0),
        ),
        _makeMovement(
          id: 'd3',
          employeeId: 101,
          shiftId: dayShift.id,
          shiftName: dayShift.name,
          type: MovementType.dutyIn,
          timestamp: DateTime(2026, 11, 2, 12, 0), // 2 saat dış görev
        ),
        _makeMovement(
          id: 'd4',
          employeeId: 101,
          shiftId: dayShift.id,
          shiftName: dayShift.name,
          type: MovementType.checkOut,
          timestamp: DateTime(2026, 11, 2, 17, 30),
        ),
      ];

      final included = MovementCalculationEngine.calculateDailySummary(
        employee: sampleEmployee,
        date: date,
        shift: dayShift,
        allMovements: movements,
        leaves: const [],
        includeFieldDutyInNetWork: true,
        referenceNow: now,
      );
      final excluded = MovementCalculationEngine.calculateDailySummary(
        employee: sampleEmployee,
        date: date,
        shift: dayShift,
        allMovements: movements,
        leaves: const [],
        includeFieldDutyInNetWork: false,
        referenceNow: now,
      );

      expect(included.netWorkDuration, const Duration(hours: 9));
      expect(excluded.netWorkDuration, const Duration(hours: 7));
    });

    test('7. CSV çıktısı UTF-8 BOM ve Türkçe karakterleri korur', () {
      final record = _makeMovement(
        id: 'csv1',
        employeeId: 101,
        shiftId: dayShift.id,
        shiftName: 'Gündüz Vardiyası',
        type: MovementType.checkIn,
        timestamp: DateTime(2026, 11, 2, 8, 30),
        deviceDoor: 'Bina Giriş Kapısı',
        note: 'Normal geçiş kaydı (ğüşiöç)',
      );

      final csv = MovementCalculationEngine.generateMovementsCsv([record]);
      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(csv.contains('Çağrı Öztürk'), isTrue);
      expect(csv.contains('Yazılım & Ar-Ge'), isTrue);
      expect(csv.contains('02.11.2026 08:30'), isTrue);
    });
  });

  group('Veri İzlenebilirliği ve Arayüz Kabul Testleri', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await DatabaseService.instance.init();
    });

    test('8. Manuel düzeltmede ham cihaz kaydı korunur ve düzeltme geçmişi saklanır', () async {
      final state = PdksState();
      addTearDown(state.dispose);
      final existing = state.employeeMovements.firstWhere(
        (m) => m.source == MovementSource.device,
      );
      final originalRawTime = existing.rawDeviceSnapshot.timestamp;
      final newTime = originalRawTime.add(const Duration(minutes: 15));

      final res = await state.correctEmployeeMovement(
        movementId: existing.id,
        newType: existing.type,
        newTimestamp: newTime,
        newDeviceDoor: existing.deviceDoor,
        newNote: 'Kart okuyucu gecikmesi düzeltildi',
        reason: 'Turnike saat senkronizasyonu farkı',
      );

      expect(res.success, isTrue);

      final updated = state.employeeMovements.firstWhere((m) => m.id == existing.id);
      // Ham cihaz hareketi kaybolmamalı
      expect(updated.rawDeviceSnapshot.timestamp, originalRawTime);
      // Yeni değer ve düzeltme kaydı saklanmalı
      expect(updated.timestamp, newTime);
      expect(updated.correctionHistory, isNotEmpty);
      expect(updated.correctionHistory.last.reason, 'Turnike saat senkronizasyonu farkı');
      expect(updated.correctionHistory.last.approvalStatus, CorrectionApprovalStatus.pending);
    });

    testWidgets('9. Çalışan Hareket Yönetimi ekranı 6 sekmeyi ve KPI kartlarını doğru render eder', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ChangeNotifierProvider<PdksState>(
          create: (_) => PdksState(),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const EmployeeMovementManagementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Başlık ve Ana Sayfaya Dön butonu görünmeli (Demo Modu kaldırılmış olmalı)
      expect(find.textContaining('Demo Modu'), findsNothing);
      expect(find.text('Ana Sayfaya Dön'), findsWidgets);
      expect(find.text('Genel Bakış'), findsWidgets);
      expect(find.text('Toplam Personel'), findsOneWidget);

      // Çalışan Hareketleri sekmesine geçiş ve koyu temada bile tablo metinlerinin koyu renk (#0F172A) olduğunun doğrulanması
      await tester.tap(find.text('Çalışan Hareketleri').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Yeni Hareket Ekle'), findsWidgets);
      expect(find.textContaining('CSV İndir'), findsOneWidget);
      final headerText = tester.widget<Text>(find.text('Sicil Numarası').first);
      expect(headerText.style?.color, const Color(0xFF0F172A));

      // Günlük Devam Özeti sekmesine geçiş
      await tester.tap(find.text('Günlük Devam Özeti').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Görev'), findsWidgets);

      // Vardiyalar sekmesine geçiş
      await tester.tap(find.text('Vardiyalar').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Vardiya'), findsWidgets);

      // Kontrol Bekleyenler sekmesine geçiş
      await tester.tap(find.text('Kontrol Bekleyenler').first);
      await tester.pumpAndSettle();
      expect(find.text('Onayla'), findsWidgets);
    });

    test('10. Mesaiye Gir ve Mesaiden Çık işlemleri Çalışan Hareket Yönetimi listesine ve günlük özete anında işlenir', () async {
      final state = PdksState();
      addTearDown(state.dispose);

      final geofence = GeofenceResult(
        isInside: true,
        distanceMeters: 12.0,
        allowedRadiusMeters: 150.0,
        latitude: 41.0082,
        longitude: 28.9784,
      );

      // 1) Mesaiye Gir
      await state.performCheckInOut(
        type: AttendanceType.checkIn,
        method: VerificationMethod.geofenceGps,
        geofence: geofence,
        note: 'Canlı mesai girişi testi',
      );

      final today = DateTime.now();
      final userMovementsAfterIn = state.employeeMovements
          .where((m) =>
              m.employeeId == state.currentUser.id &&
              m.timestamp.year == today.year &&
              m.timestamp.month == today.month &&
              m.timestamp.day == today.day)
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      expect(userMovementsAfterIn, isNotEmpty);
      expect(userMovementsAfterIn.last.type, MovementType.checkIn);
      expect(userMovementsAfterIn.last.note, contains('Canlı mesai girişi testi'));

      final summariesAfterIn = state.getDailySummariesForDate(today);
      final userSummaryIn = summariesAfterIn.firstWhere((s) => s.employeeId == state.currentUser.id);
      expect(userSummaryIn.status, DailyAttendanceStatus.working);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      // 2) Mesaiden Çık
      await state.performCheckInOut(
        type: AttendanceType.checkOut,
        method: VerificationMethod.geofenceGps,
        geofence: geofence,
        note: 'Canlı mesai çıkışı testi',
      );

      final userMovementsAfterOut = state.employeeMovements
          .where((m) =>
              m.employeeId == state.currentUser.id &&
              m.timestamp.year == today.year &&
              m.timestamp.month == today.month &&
              m.timestamp.day == today.day)
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      expect(userMovementsAfterOut.any((m) => m.type == MovementType.checkIn), isTrue);
      expect(userMovementsAfterOut.any((m) => m.type == MovementType.checkOut), isTrue);
      expect(
        userMovementsAfterOut.any((m) => m.note.contains('Canlı mesai çıkışı testi')),
        isTrue,
      );

      final summariesAfterOut = state.getDailySummariesForDate(today);
      final userSummaryOut = summariesAfterOut.firstWhere((s) => s.employeeId == state.currentUser.id);
      expect(userSummaryOut.status, DailyAttendanceStatus.completed);
    });
  });
}
