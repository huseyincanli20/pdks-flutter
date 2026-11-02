import '../../models/employee.dart';
import '../../models/leave_request.dart';
import '../../models/employee_movement.dart';

/// Eşleşmiş Zaman Aralığı (Giriş-Çıkış, Mola Başlangıç-Bitiş veya Görev Çıkış-Dönüş)
class PairedTimeInterval {
  final DateTime start;
  final DateTime end;
  final EmployeeMovementRecord startRecord;
  final EmployeeMovementRecord endRecord;

  const PairedTimeInterval({
    required this.start,
    required this.end,
    required this.startRecord,
    required this.endRecord,
  });

  Duration get duration => end.isAfter(start) ? end.difference(start) : Duration.zero;
}

/// PDKS Çalışan Hareket Yönetimi Hesaplama Motoru
/// Arayüz bileşenlerinden tamamen bağımsız, saf (pure) ve birim test edilebilir fonksiyonlar içerir.
class MovementCalculationEngine {
  const MovementCalculationEngine._();

  /// Tarihi gg.aa.yyyy biçiminde formatlar
  static String formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d.$m.$y';
  }

  /// Saati 24 saat (SS:dd) biçiminde formatlar
  static String formatTime(DateTime dateTime) {
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  /// Tarih ve saati gg.aa.yyyy SS:dd biçiminde formatlar
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${formatTime(dateTime)}';
  }

  /// Süreyi "X sa Y dk" veya "Y dk" biçiminde Türkçe formatlar
  static String formatDuration(Duration? duration, {String nullPlaceholder = 'İnceleme Bekliyor'}) {
    if (duration == null) return nullPlaceholder;
    final totalMinutes = duration.inMinutes;
    if (totalMinutes <= 0) return '0 dk';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '$hours sa $minutes dk';
    } else if (hours > 0) {
      return '$hours sa';
    } else {
      return '$minutes dk';
    }
  }

  /// Seçili tarih ve vardiya için vardiya başlangıç ve bitiş tam DateTime değerlerini üretir.
  /// Gece yarısını aşan vardiyalarda bitiş zamanı ertesi güne (date + 1 gün) taşınır.
  static ({DateTime shiftStart, DateTime shiftEnd}) getShiftBounds(
    DateTime date,
    PdksShiftDefinition shift,
  ) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final shiftStart = DateTime(
      dayStart.year,
      dayStart.month,
      dayStart.day,
      shift.startHour,
      shift.startMinute,
    );

    DateTime shiftEnd = DateTime(
      dayStart.year,
      dayStart.month,
      dayStart.day,
      shift.endHour,
      shift.endMinute,
    );

    if (shift.crossesMidnight) {
      shiftEnd = shiftEnd.add(const Duration(days: 1));
    }

    return (shiftStart: shiftStart, shiftEnd: shiftEnd);
  }

  /// Bir personelin belirli bir vardiya gününe (date) ait hareketlerini filtreler ve sıralar.
  /// Gece vardiyasında ertesi güne sarkan çıkış ve mola hareketlerini doğru vardiya günüyle eşleştirir.
  static List<EmployeeMovementRecord> getMovementsForShiftDay({
    required int employeeId,
    required DateTime date,
    required PdksShiftDefinition shift,
    required List<EmployeeMovementRecord> allMovements,
  }) {
    final dayOnly = DateTime(date.year, date.month, date.day);
    final bounds = getShiftBounds(dayOnly, shift);

    late final DateTime windowStart;
    late final DateTime windowEnd;

    if (shift.crossesMidnight) {
      // Gece vardiyası (örn. 22:00 - 06:00):
      // Vardiya başlangıcından 6 saat öncesi (16:00) ile ertesi gün vardiya bitişinden 8 saat sonrası (14:00)
      windowStart = bounds.shiftStart.subtract(const Duration(hours: 6));
      windowEnd = bounds.shiftEnd.add(const Duration(hours: 8));
    } else {
      // Gündüz vardiyası: Günün başlangıcı (00:00) ile günün sonu (23:59:59)
      windowStart = DateTime(dayOnly.year, dayOnly.month, dayOnly.day, 0, 0, 0);
      windowEnd = DateTime(dayOnly.year, dayOnly.month, dayOnly.day, 23, 59, 59, 999);
    }

    final matched = allMovements.where((m) {
      if (m.employeeId != employeeId) return false;
      return !m.timestamp.isBefore(windowStart) && !m.timestamp.isAfter(windowEnd);
    }).toList();

    matched.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return matched;
  }

  /// İki zaman aralığının kesişim (overlap) süresini tam DateTime üzerinden hesaplar.
  static Duration calculateIntervalOverlap(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    final overlapStart = aStart.isAfter(bStart) ? aStart : bStart;
    final overlapEnd = aEnd.isBefore(bEnd) ? aEnd : bEnd;
    if (overlapEnd.isAfter(overlapStart)) {
      return overlapEnd.difference(overlapStart);
    }
    return Duration.zero;
  }

  /// Personelin seçili tarihte onaylı izni veya sağlık raporu olup olmadığını kontrol eder.
  static DailyAttendanceStatus? checkLeaveOrHolidayStatus({
    required int employeeId,
    required DateTime date,
    required PdksShiftDefinition shift,
    required List<LeaveRequest> leaves,
    required bool hasMovementsOnDay,
  }) {
    final targetDay = DateTime(date.year, date.month, date.day);

    for (final leave in leaves) {
      if (leave.employeeId != employeeId) continue;
      if (leave.status != LeaveStatus.approved) continue;

      final startDay = DateTime(leave.startDate.year, leave.startDate.month, leave.startDate.day);
      final endDay = DateTime(leave.endDate.year, leave.endDate.month, leave.endDate.day);

      if (!targetDay.isBefore(startDay) && !targetDay.isAfter(endDay)) {
        if (leave.type == LeaveType.medical) {
          return DailyAttendanceStatus.medicalLeave;
        }
        return DailyAttendanceStatus.onLeave;
      }
    }

    // Hafta tatili kontrolü (vardiyanın çalışma günlerinde değilse ve o gün hareket yoksa)
    if (!shift.workDays.contains(targetDay.weekday) && !hasMovementsOnDay) {
      return DailyAttendanceStatus.weekend;
    }

    return null;
  }

  /// Tek bir personel ve gün için tüm devam özetini, çalışma/mola/görev sürelerini ve anomalileri hesaplar.
  static DailyAttendanceSummary calculateDailySummary({
    required Employee employee,
    required DateTime date,
    required PdksShiftDefinition shift,
    required List<EmployeeMovementRecord> allMovements,
    required List<LeaveRequest> leaves,
    bool includeFieldDutyInNetWork = true,
    DateTime? referenceNow,
  }) {
    final now = referenceNow ?? DateTime.now();
    final targetDay = DateTime(date.year, date.month, date.day);
    final bounds = getShiftBounds(targetDay, shift);
    final dayMovements = getMovementsForShiftDay(
      employeeId: employee.id,
      date: targetDay,
      shift: shift,
      allMovements: allMovements,
    );

    final anomalies = <MovementAnomalyItem>[];

    // 1. Manuel düzeltme onayı bekleyen hareketleri kontrol bekleyenlere ekle
    for (final mov in dayMovements) {
      for (final corr in mov.correctionHistory) {
        if (corr.approvalStatus == CorrectionApprovalStatus.pending) {
          anomalies.add(
            MovementAnomalyItem(
              id: 'anom_corr_${corr.id}',
              category: AnomalyCategory.pendingManualCorrection,
              employeeId: employee.id,
              sicilNo: employee.displaySicilNo,
              employeeName: employee.fullName,
              department: employee.department,
              shiftName: shift.name,
              date: targetDay,
              title: 'Onay Bekleyen Manuel Düzeltme',
              description:
                  'Önceki: ${corr.previousValueSummary} → Yeni: ${corr.newValueSummary} (Gerekçe: ${corr.reason})',
              relatedMovementId: mov.id,
              correctionId: corr.id,
              approvalStatus: corr.approvalStatus,
            ),
          );
        }
      }
    }

    // 2. Art arda aynı türde hareket kontrolü
    for (int i = 1; i < dayMovements.length; i++) {
      final prev = dayMovements[i - 1];
      final curr = dayMovements[i];
      if (prev.type == curr.type) {
        anomalies.add(
          MovementAnomalyItem(
            id: 'anom_consec_${prev.id}_${curr.id}',
            category: AnomalyCategory.consecutiveSameType,
            employeeId: employee.id,
            sicilNo: employee.displaySicilNo,
            employeeName: employee.fullName,
            department: employee.department,
            shiftName: shift.name,
            date: targetDay,
            title: 'Art Arda Aynı Türde Hareket (${curr.type.label})',
            description:
                '${formatTime(prev.timestamp)} ve ${formatTime(curr.timestamp)} saatlerinde art arda iki "${curr.type.label}" kaydı tespit edildi.',
            relatedMovementId: curr.id,
          ),
        );
      }
    }

    // 3. Giriş-Çıkış, Mola ve Görev aralıklarını eşleştir
    final workIntervals = <PairedTimeInterval>[];
    final breakIntervals = <PairedTimeInterval>[];
    final dutyIntervals = <PairedTimeInterval>[];

    EmployeeMovementRecord? openCheckIn;
    EmployeeMovementRecord? openBreakStart;
    EmployeeMovementRecord? openDutyOut;

    bool hasOrphanCheckOut = false;
    bool hasUnmatchedBreak = false;
    bool hasConsecutiveCheckInError = false;

    DateTime? firstCheckIn;
    DateTime? lastCheckOut;

    for (final mov in dayMovements) {
      switch (mov.type) {
        case MovementType.checkIn:
          firstCheckIn ??= mov.timestamp;
          if (openCheckIn != null) {
            // Açık giriş varken tekrar giriş yapıldı
            hasConsecutiveCheckInError = true;
          }
          openCheckIn = mov;
          break;

        case MovementType.checkOut:
          lastCheckOut = mov.timestamp;
          if (openBreakStart != null) {
            // Mola bitişi yapılmadan çıkış yapıldı
            hasUnmatchedBreak = true;
            anomalies.add(
              MovementAnomalyItem(
                id: 'anom_break_unclosed_${openBreakStart.id}',
                category: AnomalyCategory.unmatchedBreak,
                employeeId: employee.id,
                sicilNo: employee.displaySicilNo,
                employeeName: employee.fullName,
                department: employee.department,
                shiftName: shift.name,
                date: targetDay,
                title: 'Mola Bitişi Olmadan Çıkış Yapıldı',
                description:
                    '${formatTime(openBreakStart.timestamp)} saatinde başlayan mola sonlandırılmadan ${formatTime(mov.timestamp)} saatinde çıkış yapıldı.',
                relatedMovementId: openBreakStart.id,
              ),
            );
            openBreakStart = null;
          }
          if (openCheckIn == null) {
            hasOrphanCheckOut = true;
            anomalies.add(
              MovementAnomalyItem(
                id: 'anom_missing_in_${mov.id}',
                category: AnomalyCategory.missingCheckInOrOut,
                employeeId: employee.id,
                sicilNo: employee.displaySicilNo,
                employeeName: employee.fullName,
                department: employee.department,
                shiftName: shift.name,
                date: targetDay,
                title: 'Eksik Giriş Hareketi',
                description:
                    '${formatTime(mov.timestamp)} saatinde çıkış kaydı var ancak öncesinde eşleşen bir giriş kaydı bulunmuyor.',
                relatedMovementId: mov.id,
              ),
            );
          } else {
            workIntervals.add(
              PairedTimeInterval(
                start: openCheckIn.timestamp,
                end: mov.timestamp,
                startRecord: openCheckIn,
                endRecord: mov,
              ),
            );
            openCheckIn = null;
          }
          break;

        case MovementType.breakStart:
          if (openCheckIn == null) {
            // Çalışma aralığı dışında mola başlangıcı
            hasUnmatchedBreak = true;
            anomalies.add(
              MovementAnomalyItem(
                id: 'anom_break_outside_${mov.id}',
                category: AnomalyCategory.unmatchedBreak,
                employeeId: employee.id,
                sicilNo: employee.displaySicilNo,
                employeeName: employee.fullName,
                department: employee.department,
                shiftName: shift.name,
                date: targetDay,
                title: 'Giriş Kaydı Olmadan Mola Başlangıcı',
                description:
                    '${formatTime(mov.timestamp)} saatinde aktif bir çalışma girişi olmadan mola başlangıcı kaydedildi.',
                relatedMovementId: mov.id,
              ),
            );
          } else if (openBreakStart != null) {
            hasUnmatchedBreak = true;
          } else {
            openBreakStart = mov;
          }
          break;

        case MovementType.breakEnd:
          if (openBreakStart == null) {
            hasUnmatchedBreak = true;
            anomalies.add(
              MovementAnomalyItem(
                id: 'anom_break_no_start_${mov.id}',
                category: AnomalyCategory.unmatchedBreak,
                employeeId: employee.id,
                sicilNo: employee.displaySicilNo,
                employeeName: employee.fullName,
                department: employee.department,
                shiftName: shift.name,
                date: targetDay,
                title: 'Başlangıcı Olmayan Mola Bitişi',
                description:
                    '${formatTime(mov.timestamp)} saatinde mola bitişi kaydedildi ancak öncesinde mola başlangıcı bulunmuyor.',
                relatedMovementId: mov.id,
              ),
            );
          } else {
            breakIntervals.add(
              PairedTimeInterval(
                start: openBreakStart.timestamp,
                end: mov.timestamp,
                startRecord: openBreakStart,
                endRecord: mov,
              ),
            );
            openBreakStart = null;
          }
          break;

        case MovementType.dutyOut:
          openDutyOut = mov;
          break;

        case MovementType.dutyIn:
          if (openDutyOut != null) {
            dutyIntervals.add(
              PairedTimeInterval(
                start: openDutyOut.timestamp,
                end: mov.timestamp,
                startRecord: openDutyOut,
                endRecord: mov,
              ),
            );
            openDutyOut = null;
          }
          break;
      }
    }

    // 4. Vardiya devam ediyor mu yoksa tamamlandı mı?
    final isTodayOrActiveShift = _isShiftStillOngoing(
      targetDay: targetDay,
      shiftStart: bounds.shiftStart,
      shiftEnd: bounds.shiftEnd,
      now: now,
      openCheckIn: openCheckIn,
    );

    // Eğer vardiya süresi bittiyse ve hala açık giriş varsa -> Eksik Çıkış!
    bool hasMissingCheckOutAfterShift = false;
    if (openCheckIn != null && !isTodayOrActiveShift) {
      hasMissingCheckOutAfterShift = true;
      anomalies.add(
        MovementAnomalyItem(
          id: 'anom_missing_out_${openCheckIn.id}',
          category: AnomalyCategory.missingCheckInOrOut,
          employeeId: employee.id,
          sicilNo: employee.displaySicilNo,
          employeeName: employee.fullName,
          department: employee.department,
          shiftName: shift.name,
          date: targetDay,
          title: 'Eksik Çıkış Hareketi',
          description:
              '${formatDateTime(openCheckIn.timestamp)} tarihinde giriş yapıldı ancak vardiya sonunda çıkış kaydı bulunamadı.',
          relatedMovementId: openCheckIn.id,
        ),
      );
    }

    if (openBreakStart != null && !isTodayOrActiveShift) {
      hasUnmatchedBreak = true;
      anomalies.add(
        MovementAnomalyItem(
          id: 'anom_break_open_${openBreakStart.id}',
          category: AnomalyCategory.unmatchedBreak,
          employeeId: employee.id,
          sicilNo: employee.displaySicilNo,
          employeeName: employee.fullName,
          department: employee.department,
          shiftName: shift.name,
          date: targetDay,
          title: 'Eşleşmeyen Mola Hareketi (Açık Mola)',
          description:
              '${formatTime(openBreakStart.timestamp)} saatinde başlayan mola için bitiş kaydı bulunamadı.',
          relatedMovementId: openBreakStart.id,
        ),
      );
    }

    // 5. Eşleşmiş molalardan yalnızca çalışma aralıkları içinde kalanları hesapla
    Duration matchedBreaksInsideWork = Duration.zero;
    for (final b in breakIntervals) {
      Duration overlapForThisBreak = Duration.zero;
      for (final w in workIntervals) {
        overlapForThisBreak += calculateIntervalOverlap(b.start, b.end, w.start, w.end);
      }
      // Eğer vardiya şu an devam ediyorsa ve açık giriş varsa, o aralıktaki tamamlanmış molaları da dikkate al
      if (openCheckIn != null && isTodayOrActiveShift) {
        overlapForThisBreak += calculateIntervalOverlap(
          b.start,
          b.end,
          openCheckIn.timestamp,
          now.isAfter(b.end) ? now : b.end,
        );
      }
      if (overlapForThisBreak == Duration.zero) {
        hasUnmatchedBreak = true;
        anomalies.add(
          MovementAnomalyItem(
            id: 'anom_break_outside_work_${b.startRecord.id}',
            category: AnomalyCategory.unmatchedBreak,
            employeeId: employee.id,
            sicilNo: employee.displaySicilNo,
            employeeName: employee.fullName,
            department: employee.department,
            shiftName: shift.name,
            date: targetDay,
            title: 'Çalışma Aralığı Dışında Mola',
            description:
                '${formatTime(b.start)} - ${formatTime(b.end)} arasındaki mola, eşleşmiş bir çalışma aralığı içinde yer almıyor.',
            relatedMovementId: b.startRecord.id,
          ),
        );
      } else {
        matchedBreaksInsideWork += overlapForThisBreak;
      }
    }

    // Görevde geçen toplam süre
    Duration totalDutyDuration = Duration.zero;
    for (final d in dutyIntervals) {
      totalDutyDuration += d.duration;
    }

    // 6. Geç kalma ve erken çıkış hesaplamaları (Tam DateTime üzerinden)
    Duration lateDuration = Duration.zero;
    final latestAllowedIn = bounds.shiftStart.add(Duration(minutes: shift.lateToleranceMinutes));
    if (firstCheckIn != null && firstCheckIn.isAfter(latestAllowedIn)) {
      lateDuration = firstCheckIn.difference(bounds.shiftStart);
    }

    Duration earlyLeaveDuration = Duration.zero;
    if (lastCheckOut != null &&
        openCheckIn == null &&
        !hasOrphanCheckOut &&
        lastCheckOut.isBefore(bounds.shiftEnd)) {
      earlyLeaveDuration = bounds.shiftEnd.difference(lastCheckOut);
    }

    // 7. Günlük Durum (Status) ve Net Çalışma Süresi Belirleme
    final hasStructuralAnomaly = hasOrphanCheckOut ||
        hasMissingCheckOutAfterShift ||
        hasConsecutiveCheckInError ||
        hasUnmatchedBreak;

    late final DailyAttendanceStatus status;
    Duration? netWorkDuration;
    Duration pendingExtraDuration = Duration.zero;

    if (dayMovements.isEmpty) {
      final leaveOrHoliday = checkLeaveOrHolidayStatus(
        employeeId: employee.id,
        date: targetDay,
        shift: shift,
        leaves: leaves,
        hasMovementsOnDay: false,
      );
      if (leaveOrHoliday != null) {
        status = leaveOrHoliday;
        netWorkDuration = Duration.zero;
      } else if (now.isBefore(bounds.shiftStart)) {
        // Vardiya henüz başlamadıysa devamsız olarak işaretleme
        status = DailyAttendanceStatus.weekend;
        netWorkDuration = Duration.zero;
      } else {
        status = DailyAttendanceStatus.absent;
        netWorkDuration = Duration.zero;
      }
    } else if (hasStructuralAnomaly) {
      // KURAL: Açık veya eksik aralıklar için kesin çalışma süresi üretme; kaydı incelemeye işaretle.
      status = DailyAttendanceStatus.missingMovement;
      netWorkDuration = null;
    } else if (openCheckIn != null && isTodayOrActiveShift) {
      // Devam eden vardiyada personeli devamsız veya eksik çıkış olarak işaretleme!
      if (openBreakStart != null) {
        status = DailyAttendanceStatus.onBreak;
      } else {
        status = DailyAttendanceStatus.working;
      }
      // Açık (devam eden) vardiya için henüz kesinleşmiş net süre üretme (null)
      netWorkDuration = null;
    } else {
      // Tüm giriş-çıkış ve mola aralıkları eksiksiz kapandı -> Tamamlandı
      status = DailyAttendanceStatus.completed;

      Duration grossWork = Duration.zero;
      for (final w in workIntervals) {
        grossWork += w.duration;
      }

      Duration computedNet = grossWork - matchedBreaksInsideWork;
      if (computedNet.isNegative) {
        computedNet = Duration.zero;
      }

      if (includeFieldDutyInNetWork) {
        // Çalışma aralığı dışında kalan görev sürelerini ekle (çalışma aralığı içindekiler zaten grossWork içinde)
        for (final d in dutyIntervals) {
          Duration overlapWithWork = Duration.zero;
          for (final w in workIntervals) {
            overlapWithWork += calculateIntervalOverlap(d.start, d.end, w.start, w.end);
          }
          if (d.duration > overlapWithWork) {
            computedNet += (d.duration - overlapWithWork);
          }
        }
      } else {
        // Görev süresi çalışma aralığı içindeyse ve dahil edilmeyecekse çıkar
        for (final d in dutyIntervals) {
          for (final w in workIntervals) {
            final overlap = calculateIntervalOverlap(d.start, d.end, w.start, w.end);
            if (computedNet > overlap) {
              computedNet -= overlap;
            } else {
              computedNet = Duration.zero;
            }
          }
        }
      }

      netWorkDuration = computedNet;

      // KURAL: Vardiya dışındaki süreyi otomatik olarak onaylı fazla mesai sayma -> İnceleme bekleyen fazla süre
      final plannedNet = Duration(minutes: shift.plannedNetWorkMinutes);
      if (computedNet > plannedNet) {
        pendingExtraDuration = computedNet - plannedNet;
      } else {
        // Vardiya saatleri dışında (erken giriş veya geç çıkış) geçen süreyi de kontrol et
        Duration outOfShiftWork = Duration.zero;
        for (final w in workIntervals) {
          if (w.start.isBefore(bounds.shiftStart)) {
            final earlyEnd = w.end.isBefore(bounds.shiftStart) ? w.end : bounds.shiftStart;
            outOfShiftWork += earlyEnd.difference(w.start);
          }
          if (w.end.isAfter(bounds.shiftEnd)) {
            final lateStart = w.start.isAfter(bounds.shiftEnd) ? w.start : bounds.shiftEnd;
            outOfShiftWork += w.end.difference(lateStart);
          }
        }
        if (outOfShiftWork.inMinutes >= 15) {
          pendingExtraDuration = outOfShiftWork;
        }
      }
    }

    return DailyAttendanceSummary(
      employeeId: employee.id,
      sicilNo: employee.displaySicilNo,
      employeeName: employee.fullName,
      department: employee.department,
      title: employee.title,
      isEmployeeActive: employee.isActive,
      date: targetDay,
      plannedShift: shift,
      firstCheckIn: firstCheckIn,
      lastCheckOut: lastCheckOut,
      totalBreakDuration: matchedBreaksInsideWork,
      dutyDuration: totalDutyDuration,
      netWorkDuration: netWorkDuration,
      lateDuration: lateDuration,
      earlyLeaveDuration: earlyLeaveDuration,
      pendingExtraDuration: pendingExtraDuration,
      status: status,
      anomalies: anomalies,
      dayMovements: dayMovements,
    );
  }

  /// Vardiyanın halen devam edip etmediğini belirler.
  /// Eğer seçili gün bugünse ve personelin açık girişinde "eksik çıkış simülasyonu" yoksa
  /// veya şu anki saat vardiya bitişinden önceyse vardiya devam ediyor kabul edilir.
  static bool _isShiftStillOngoing({
    required DateTime targetDay,
    required DateTime shiftStart,
    required DateTime shiftEnd,
    required DateTime now,
    required EmployeeMovementRecord? openCheckIn,
  }) {
    if (openCheckIn == null) return false;
    // Eğer açık hareketin açıklamasında açıkça vardiya sonu unutulan çıkış / geçmiş vardiya belirtilmişse
    // veya hareket zamanı şu andan 11 saatten daha eskiyse vardiya kapanmış kabul edilir.
    if (now.difference(openCheckIn.timestamp).inHours >= 11) {
      return false;
    }
    if (openCheckIn.note.toLowerCase().contains('çıkış unutuldu') ||
        openCheckIn.note.toLowerCase().contains('eksik çıkış')) {
      return false;
    }
    final todayDay = DateTime(now.year, now.month, now.day);
    if (targetDay == todayDay) {
      return true;
    }
    return now.isBefore(shiftEnd.add(const Duration(hours: 2)));
  }

  /// Filtrelenmiş çalışan hareketlerini Türkçe karakterleri koruyarak (UTF-8 BOM ile) CSV metnine dönüştürür.
  static String generateMovementsCsv(List<EmployeeMovementRecord> records) {
    final buffer = StringBuffer('\uFEFF'); // UTF-8 BOM (Excel ve tüm editörlerde Türkçe karakterleri korur)
    buffer.writeln(
      'Tarih ve Saat;Sicil Numarası;Ad Soyad;Departman;Vardiya;Hareket Türü;Cihaz / Kapı;Kaynak;Açıklama',
    );

    for (final r in records) {
      final row = [
        formatDateTime(r.timestamp),
        _escapeCsvField(r.sicilNo),
        _escapeCsvField(r.employeeName),
        _escapeCsvField(r.department),
        _escapeCsvField(r.shiftName),
        _escapeCsvField(r.type.label),
        _escapeCsvField(r.deviceDoor),
        _escapeCsvField(r.source.label),
        _escapeCsvField(r.note),
      ].join(';');
      buffer.writeln(row);
    }

    return buffer.toString();
  }

  static String _escapeCsvField(String value) {
    final cleaned = value.replaceAll('\r', ' ').replaceAll('\n', ' ');
    if (cleaned.contains(';') || cleaned.contains('"')) {
      return '"${cleaned.replaceAll('"', '""')}"';
    }
    return cleaned;
  }
}
