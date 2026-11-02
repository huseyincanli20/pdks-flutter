import 'package:flutter/material.dart';

/// Varsayılan saat dilimi sabiti
const String kDefaultTimezone = 'Europe/Istanbul';

/// Hareket Türleri (6 temel tür)
enum MovementType {
  checkIn,
  checkOut,
  breakStart,
  breakEnd,
  dutyOut,
  dutyIn,
}

extension MovementTypeExtension on MovementType {
  String get label {
    switch (this) {
      case MovementType.checkIn:
        return 'Giriş';
      case MovementType.checkOut:
        return 'Çıkış';
      case MovementType.breakStart:
        return 'Mola başlangıcı';
      case MovementType.breakEnd:
        return 'Mola bitişi';
      case MovementType.dutyOut:
        return 'Görev çıkışı';
      case MovementType.dutyIn:
        return 'Görev dönüşü';
    }
  }

  Color get color {
    switch (this) {
      case MovementType.checkIn:
        return const Color(0xFF0D9488); // Turkuaz / Yeşil
      case MovementType.checkOut:
        return const Color(0xFF475569); // Koyu Gri / Lacivert
      case MovementType.breakStart:
        return const Color(0xFFD97706); // Kehribar / Turuncu
      case MovementType.breakEnd:
        return const Color(0xFF0284C7); // Açık Mavi
      case MovementType.dutyOut:
        return const Color(0xFF7C3AED); // Mor
      case MovementType.dutyIn:
        return const Color(0xFF2563EB); // Mavi
    }
  }

  IconData get icon {
    switch (this) {
      case MovementType.checkIn:
        return Icons.login_rounded;
      case MovementType.checkOut:
        return Icons.logout_rounded;
      case MovementType.breakStart:
        return Icons.free_breakfast_rounded;
      case MovementType.breakEnd:
        return Icons.play_circle_outline_rounded;
      case MovementType.dutyOut:
        return Icons.directions_walk_rounded;
      case MovementType.dutyIn:
        return Icons.assignment_return_rounded;
    }
  }

  static MovementType fromString(String? raw) {
    switch (raw) {
      case 'checkIn':
      case 'Giriş':
        return MovementType.checkIn;
      case 'checkOut':
      case 'Çıkış':
        return MovementType.checkOut;
      case 'breakStart':
      case 'Mola başlangıcı':
        return MovementType.breakStart;
      case 'breakEnd':
      case 'Mola bitişi':
        return MovementType.breakEnd;
      case 'dutyOut':
      case 'Görev çıkışı':
        return MovementType.dutyOut;
      case 'dutyIn':
      case 'Görev dönüşü':
        return MovementType.dutyIn;
      default:
        return MovementType.checkIn;
    }
  }
}

/// Hareket Kaynağı: Cihaz, Manuel veya İçe Aktarma
enum MovementSource {
  device,
  manual,
  imported,
}

extension MovementSourceExtension on MovementSource {
  String get label {
    switch (this) {
      case MovementSource.device:
        return 'Cihaz';
      case MovementSource.manual:
        return 'Manuel';
      case MovementSource.imported:
        return 'İçe aktarma';
    }
  }

  Color get color {
    switch (this) {
      case MovementSource.device:
        return const Color(0xFF0D9488);
      case MovementSource.manual:
        return const Color(0xFFD97706);
      case MovementSource.imported:
        return const Color(0xFF6366F1);
    }
  }

  IconData get icon {
    switch (this) {
      case MovementSource.device:
        return Icons.sensors_rounded;
      case MovementSource.manual:
        return Icons.edit_note_rounded;
      case MovementSource.imported:
        return Icons.upload_file_rounded;
    }
  }

  static MovementSource fromString(String? raw) {
    switch (raw) {
      case 'manual':
      case 'Manuel':
        return MovementSource.manual;
      case 'imported':
      case 'İçe aktarma':
        return MovementSource.imported;
      default:
        return MovementSource.device;
    }
  }
}

/// Düzeltme & Anomali Onay Durumu
enum CorrectionApprovalStatus {
  pending,
  approved,
  rejected,
}

extension CorrectionApprovalStatusExtension on CorrectionApprovalStatus {
  String get label {
    switch (this) {
      case CorrectionApprovalStatus.pending:
        return 'Onay Bekliyor';
      case CorrectionApprovalStatus.approved:
        return 'Onaylandı';
      case CorrectionApprovalStatus.rejected:
        return 'Reddedildi';
    }
  }

  Color get color {
    switch (this) {
      case CorrectionApprovalStatus.pending:
        return const Color(0xFFD97706);
      case CorrectionApprovalStatus.approved:
        return const Color(0xFF10B981);
      case CorrectionApprovalStatus.rejected:
        return const Color(0xFFEF4444);
    }
  }

  static CorrectionApprovalStatus fromString(String? raw) {
    switch (raw) {
      case 'approved':
      case 'Onaylandı':
        return CorrectionApprovalStatus.approved;
      case 'rejected':
      case 'Reddedildi':
        return CorrectionApprovalStatus.rejected;
      default:
        return CorrectionApprovalStatus.pending;
    }
  }
}

/// Günlük Devam Özeti Durumları (8 Temel Durum)
enum DailyAttendanceStatus {
  completed,
  working,
  onBreak,
  missingMovement,
  onLeave,
  medicalLeave,
  absent,
  weekend,
}

extension DailyAttendanceStatusExtension on DailyAttendanceStatus {
  String get label {
    switch (this) {
      case DailyAttendanceStatus.completed:
        return 'Tamamlandı';
      case DailyAttendanceStatus.working:
        return 'Çalışıyor';
      case DailyAttendanceStatus.onBreak:
        return 'Molada';
      case DailyAttendanceStatus.missingMovement:
        return 'Eksik hareket';
      case DailyAttendanceStatus.onLeave:
        return 'İzinli';
      case DailyAttendanceStatus.medicalLeave:
        return 'Raporlu';
      case DailyAttendanceStatus.absent:
        return 'Devamsız';
      case DailyAttendanceStatus.weekend:
        return 'Hafta tatili';
    }
  }

  Color get color {
    switch (this) {
      case DailyAttendanceStatus.completed:
        return const Color(0xFF10B981); // Yeşil
      case DailyAttendanceStatus.working:
        return const Color(0xFF0D9488); // Turkuaz
      case DailyAttendanceStatus.onBreak:
        return const Color(0xFFD97706); // Kehribar
      case DailyAttendanceStatus.missingMovement:
        return const Color(0xFFEA580C); // Turuncu / Uyarı
      case DailyAttendanceStatus.onLeave:
        return const Color(0xFF0284C7); // Mavi
      case DailyAttendanceStatus.medicalLeave:
        return const Color(0xFF7C3AED); // Mor
      case DailyAttendanceStatus.absent:
        return const Color(0xFFEF4444); // Kırmızı
      case DailyAttendanceStatus.weekend:
        return const Color(0xFF64748B); // Gri
    }
  }

  IconData get icon {
    switch (this) {
      case DailyAttendanceStatus.completed:
        return Icons.check_circle_rounded;
      case DailyAttendanceStatus.working:
        return Icons.work_history_rounded;
      case DailyAttendanceStatus.onBreak:
        return Icons.coffee_rounded;
      case DailyAttendanceStatus.missingMovement:
        return Icons.warning_amber_rounded;
      case DailyAttendanceStatus.onLeave:
        return Icons.beach_access_rounded;
      case DailyAttendanceStatus.medicalLeave:
        return Icons.medical_services_rounded;
      case DailyAttendanceStatus.absent:
        return Icons.cancel_rounded;
      case DailyAttendanceStatus.weekend:
        return Icons.weekend_rounded;
    }
  }
}

/// Ham Cihaz Hareketi Özeti (Düzeltmeler sırasında asla silinmez)
class RawDeviceMovementSnapshot {
  final MovementType type;
  final DateTime timestamp;
  final String deviceDoor;
  final MovementSource source;
  final String note;

  const RawDeviceMovementSnapshot({
    required this.type,
    required this.timestamp,
    required this.deviceDoor,
    required this.source,
    required this.note,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'deviceDoor': deviceDoor,
        'source': source.name,
        'note': note,
      };

  factory RawDeviceMovementSnapshot.fromJson(Map<String, dynamic> json) {
    return RawDeviceMovementSnapshot(
      type: MovementTypeExtension.fromString(json['type']?.toString()),
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      deviceDoor: json['deviceDoor']?.toString() ?? 'Ana Giriş Turnike 1',
      source: MovementSourceExtension.fromString(json['source']?.toString()),
      note: json['note']?.toString() ?? '',
    );
  }
}

/// Hareket Düzeltme Kaydı (İzlenebilirlik / Audit Trail)
class MovementCorrectionRecord {
  final String id;
  final String movementId;
  final MovementType previousType;
  final DateTime previousTimestamp;
  final String previousDeviceDoor;
  final String previousNote;
  final MovementType newType;
  final DateTime newTimestamp;
  final String newDeviceDoor;
  final String newNote;
  final String reason;
  final String actorName;
  final String actorRole;
  final DateTime correctedAt;
  final CorrectionApprovalStatus approvalStatus;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  const MovementCorrectionRecord({
    required this.id,
    required this.movementId,
    required this.previousType,
    required this.previousTimestamp,
    required this.previousDeviceDoor,
    required this.previousNote,
    required this.newType,
    required this.newTimestamp,
    required this.newDeviceDoor,
    required this.newNote,
    required this.reason,
    required this.actorName,
    this.actorRole = 'İK / Yönetici',
    required this.correctedAt,
    this.approvalStatus = CorrectionApprovalStatus.pending,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
  });

  String get previousValueSummary =>
      '${previousType.label} • ${_fmtDateTime(previousTimestamp)} • $previousDeviceDoor';

  String get newValueSummary =>
      '${newType.label} • ${_fmtDateTime(newTimestamp)} • $newDeviceDoor';

  static String _fmtDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d.$m.$y $hh:$mm';
  }

  MovementCorrectionRecord copyWith({
    CorrectionApprovalStatus? approvalStatus,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? rejectionReason,
  }) {
    return MovementCorrectionRecord(
      id: id,
      movementId: movementId,
      previousType: previousType,
      previousTimestamp: previousTimestamp,
      previousDeviceDoor: previousDeviceDoor,
      previousNote: previousNote,
      newType: newType,
      newTimestamp: newTimestamp,
      newDeviceDoor: newDeviceDoor,
      newNote: newNote,
      reason: reason,
      actorName: actorName,
      actorRole: actorRole,
      correctedAt: correctedAt,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'movementId': movementId,
        'previousType': previousType.name,
        'previousTimestamp': previousTimestamp.toIso8601String(),
        'previousDeviceDoor': previousDeviceDoor,
        'previousNote': previousNote,
        'newType': newType.name,
        'newTimestamp': newTimestamp.toIso8601String(),
        'newDeviceDoor': newDeviceDoor,
        'newNote': newNote,
        'reason': reason,
        'actorName': actorName,
        'actorRole': actorRole,
        'correctedAt': correctedAt.toIso8601String(),
        'approvalStatus': approvalStatus.name,
        'reviewedBy': reviewedBy,
        'reviewedAt': reviewedAt?.toIso8601String(),
        'rejectionReason': rejectionReason,
      };

  factory MovementCorrectionRecord.fromJson(Map<String, dynamic> json) {
    return MovementCorrectionRecord(
      id: json['id']?.toString() ?? '',
      movementId: json['movementId']?.toString() ?? '',
      previousType: MovementTypeExtension.fromString(json['previousType']?.toString()),
      previousTimestamp: DateTime.tryParse(json['previousTimestamp']?.toString() ?? '') ?? DateTime.now(),
      previousDeviceDoor: json['previousDeviceDoor']?.toString() ?? '',
      previousNote: json['previousNote']?.toString() ?? '',
      newType: MovementTypeExtension.fromString(json['newType']?.toString()),
      newTimestamp: DateTime.tryParse(json['newTimestamp']?.toString() ?? '') ?? DateTime.now(),
      newDeviceDoor: json['newDeviceDoor']?.toString() ?? '',
      newNote: json['newNote']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      actorName: json['actorName']?.toString() ?? 'Sistem',
      actorRole: json['actorRole']?.toString() ?? 'Yönetici',
      correctedAt: DateTime.tryParse(json['correctedAt']?.toString() ?? '') ?? DateTime.now(),
      approvalStatus: CorrectionApprovalStatusExtension.fromString(json['approvalStatus']?.toString()),
      reviewedBy: json['reviewedBy']?.toString(),
      reviewedAt: json['reviewedAt'] != null ? DateTime.tryParse(json['reviewedAt'].toString()) : null,
      rejectionReason: json['rejectionReason']?.toString(),
    );
  }
}

/// Çalışan Hareket Kaydı (Giriş, Çıkış, Mola, Görev)
class EmployeeMovementRecord {
  final String id;
  final String companyId;
  final int employeeId;
  final String sicilNo;
  final String employeeName;
  final String department;
  final int shiftId;
  final String shiftName;
  final MovementType type;
  final DateTime timestamp;
  final String deviceDoor;
  final MovementSource source;
  final String note;
  final RawDeviceMovementSnapshot rawDeviceSnapshot;
  final List<MovementCorrectionRecord> correctionHistory;

  const EmployeeMovementRecord({
    required this.id,
    this.companyId = 'cmp_acme',
    required this.employeeId,
    required this.sicilNo,
    required this.employeeName,
    required this.department,
    required this.shiftId,
    required this.shiftName,
    required this.type,
    required this.timestamp,
    required this.deviceDoor,
    required this.source,
    this.note = '',
    required this.rawDeviceSnapshot,
    this.correctionHistory = const [],
  });

  bool get isCorrected => correctionHistory.isNotEmpty;

  bool get hasPendingCorrection =>
      correctionHistory.any((c) => c.approvalStatus == CorrectionApprovalStatus.pending);

  MovementCorrectionRecord? get latestCorrection =>
      correctionHistory.isNotEmpty ? correctionHistory.last : null;

  EmployeeMovementRecord copyWith({
    String? id,
    String? companyId,
    int? employeeId,
    String? sicilNo,
    String? employeeName,
    String? department,
    int? shiftId,
    String? shiftName,
    MovementType? type,
    DateTime? timestamp,
    String? deviceDoor,
    MovementSource? source,
    String? note,
    RawDeviceMovementSnapshot? rawDeviceSnapshot,
    List<MovementCorrectionRecord>? correctionHistory,
  }) {
    return EmployeeMovementRecord(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      employeeId: employeeId ?? this.employeeId,
      sicilNo: sicilNo ?? this.sicilNo,
      employeeName: employeeName ?? this.employeeName,
      department: department ?? this.department,
      shiftId: shiftId ?? this.shiftId,
      shiftName: shiftName ?? this.shiftName,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      deviceDoor: deviceDoor ?? this.deviceDoor,
      source: source ?? this.source,
      note: note ?? this.note,
      rawDeviceSnapshot: rawDeviceSnapshot ?? this.rawDeviceSnapshot,
      correctionHistory: correctionHistory ?? this.correctionHistory,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'employeeId': employeeId,
        'sicilNo': sicilNo,
        'employeeName': employeeName,
        'department': department,
        'shiftId': shiftId,
        'shiftName': shiftName,
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'deviceDoor': deviceDoor,
        'source': source.name,
        'note': note,
        'rawDeviceSnapshot': rawDeviceSnapshot.toJson(),
        'correctionHistory': correctionHistory.map((c) => c.toJson()).toList(),
      };

  factory EmployeeMovementRecord.fromJson(Map<String, dynamic> json) {
    final parsedType = MovementTypeExtension.fromString(json['type']?.toString());
    final parsedTs = DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now();
    final parsedDoor = json['deviceDoor']?.toString() ?? 'Ana Giriş Turnike 1';
    final parsedSource = MovementSourceExtension.fromString(json['source']?.toString());
    final parsedNote = json['note']?.toString() ?? '';

    return EmployeeMovementRecord(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString() ?? 'cmp_acme',
      employeeId: (json['employeeId'] as num?)?.toInt() ?? 1,
      sicilNo: json['sicilNo']?.toString() ?? 'SICIL-1001',
      employeeName: json['employeeName']?.toString() ?? '',
      department: json['department']?.toString() ?? 'Genel',
      shiftId: (json['shiftId'] as num?)?.toInt() ?? 1,
      shiftName: json['shiftName']?.toString() ?? 'Gündüz Vardiyası',
      type: parsedType,
      timestamp: parsedTs,
      deviceDoor: parsedDoor,
      source: parsedSource,
      note: parsedNote,
      rawDeviceSnapshot: json['rawDeviceSnapshot'] is Map
          ? RawDeviceMovementSnapshot.fromJson(Map<String, dynamic>.from(json['rawDeviceSnapshot']))
          : RawDeviceMovementSnapshot(
              type: parsedType,
              timestamp: parsedTs,
              deviceDoor: parsedDoor,
              source: parsedSource,
              note: parsedNote,
            ),
      correctionHistory: (json['correctionHistory'] as List?)
              ?.map((item) => MovementCorrectionRecord.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          const [],
    );
  }
}

/// Vardiya Tanımı (Gece yarısını aşan vardiya, planlanan mola ve geç kalma toleransı destekli)
class PdksShiftDefinition {
  final int id;
  final String companyId;
  final String name;
  final String startTime; // "08:30" veya "22:00"
  final String endTime; // "17:30" veya "06:00"
  final int plannedBreakMinutes; // örn. 60
  final int lateToleranceMinutes; // örn. 15
  final List<int> workDays; // 1 = Pazartesi ... 7 = Pazar

  const PdksShiftDefinition({
    required this.id,
    this.companyId = 'cmp_acme',
    required this.name,
    required this.startTime,
    required this.endTime,
    this.plannedBreakMinutes = 60,
    this.lateToleranceMinutes = 15,
    this.workDays = const [1, 2, 3, 4, 5],
  });

  int get startHour => int.tryParse(startTime.split(':').first) ?? 8;
  int get startMinute =>
      startTime.split(':').length > 1 ? (int.tryParse(startTime.split(':')[1]) ?? 30) : 0;

  int get endHour => int.tryParse(endTime.split(':').first) ?? 17;
  int get endMinute =>
      endTime.split(':').length > 1 ? (int.tryParse(endTime.split(':')[1]) ?? 30) : 0;

  int get startTotalMinutes => startHour * 60 + startMinute;
  int get endTotalMinutes => endHour * 60 + endMinute;

  /// Gece yarısını aşan vardiya mı? (Örn. 22:00 - 06:00)
  bool get crossesMidnight => endTotalMinutes <= startTotalMinutes;

  /// Planlanan brüt vardiya süresi (dakika)
  int get plannedGrossMinutes {
    if (crossesMidnight) {
      return (24 * 60 - startTotalMinutes) + endTotalMinutes;
    }
    return endTotalMinutes - startTotalMinutes;
  }

  /// Planlanan net çalışma süresi (dakika)
  int get plannedNetWorkMinutes {
    final net = plannedGrossMinutes - plannedBreakMinutes;
    return net > 0 ? net : 0;
  }

  String get timeRangeLabel => '$startTime - $endTime';

  PdksShiftDefinition copyWith({
    int? id,
    String? companyId,
    String? name,
    String? startTime,
    String? endTime,
    int? plannedBreakMinutes,
    int? lateToleranceMinutes,
    List<int>? workDays,
  }) {
    return PdksShiftDefinition(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      plannedBreakMinutes: plannedBreakMinutes ?? this.plannedBreakMinutes,
      lateToleranceMinutes: lateToleranceMinutes ?? this.lateToleranceMinutes,
      workDays: workDays ?? this.workDays,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'name': name,
        'startTime': startTime,
        'endTime': endTime,
        'plannedBreakMinutes': plannedBreakMinutes,
        'lateToleranceMinutes': lateToleranceMinutes,
        'workDays': workDays,
      };

  factory PdksShiftDefinition.fromJson(Map<String, dynamic> json) {
    return PdksShiftDefinition(
      id: (json['id'] as num?)?.toInt() ?? 1,
      companyId: json['companyId']?.toString() ?? 'cmp_acme',
      name: json['name']?.toString() ?? 'Gündüz Vardiyası',
      startTime: json['startTime']?.toString() ?? '08:30',
      endTime: json['endTime']?.toString() ?? '17:30',
      plannedBreakMinutes: (json['plannedBreakMinutes'] as num?)?.toInt() ?? 60,
      lateToleranceMinutes: (json['lateToleranceMinutes'] as num?)?.toInt() ?? 15,
      workDays: (json['workDays'] as List?)?.map((e) => (e as num).toInt()).toList() ??
          const [1, 2, 3, 4, 5],
    );
  }
}

/// Kontrol Bekleyen Kayıt Türü
enum AnomalyCategory {
  missingCheckInOrOut,
  consecutiveSameType,
  unmatchedBreak,
  pendingManualCorrection,
}

extension AnomalyCategoryExtension on AnomalyCategory {
  String get label {
    switch (this) {
      case AnomalyCategory.missingCheckInOrOut:
        return 'Eksik Giriş / Çıkış';
      case AnomalyCategory.consecutiveSameType:
        return 'Art Arda Aynı Tür Hareket';
      case AnomalyCategory.unmatchedBreak:
        return 'Eşleşmeyen Mola Hareketi';
      case AnomalyCategory.pendingManualCorrection:
        return 'Onay Bekleyen Manuel Düzeltme';
    }
  }

  Color get color {
    switch (this) {
      case AnomalyCategory.missingCheckInOrOut:
        return const Color(0xFFEF4444);
      case AnomalyCategory.consecutiveSameType:
        return const Color(0xFFEA580C);
      case AnomalyCategory.unmatchedBreak:
        return const Color(0xFFD97706);
      case AnomalyCategory.pendingManualCorrection:
        return const Color(0xFF0284C7);
    }
  }

  IconData get icon {
    switch (this) {
      case AnomalyCategory.missingCheckInOrOut:
        return Icons.sync_problem_rounded;
      case AnomalyCategory.consecutiveSameType:
        return Icons.repeat_one_rounded;
      case AnomalyCategory.unmatchedBreak:
        return Icons.coffee_outlined;
      case AnomalyCategory.pendingManualCorrection:
        return Icons.fact_check_rounded;
    }
  }
}

/// Kontrol Bekleyen Anomali veya Manuel Düzeltme Kaydı
class MovementAnomalyItem {
  final String id;
  final AnomalyCategory category;
  final int employeeId;
  final String sicilNo;
  final String employeeName;
  final String department;
  final String shiftName;
  final DateTime date;
  final String title;
  final String description;
  final String? relatedMovementId;
  final String? correctionId;
  final CorrectionApprovalStatus approvalStatus;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  const MovementAnomalyItem({
    required this.id,
    required this.category,
    required this.employeeId,
    required this.sicilNo,
    required this.employeeName,
    required this.department,
    required this.shiftName,
    required this.date,
    required this.title,
    required this.description,
    this.relatedMovementId,
    this.correctionId,
    this.approvalStatus = CorrectionApprovalStatus.pending,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
  });
}

/// Anomali Yönetici Kararı Kaydı (Kalıcı saklama için)
class AnomalyResolutionRecord {
  final String anomalyId;
  final CorrectionApprovalStatus status;
  final String reviewedBy;
  final DateTime reviewedAt;
  final String? reason;

  const AnomalyResolutionRecord({
    required this.anomalyId,
    required this.status,
    required this.reviewedBy,
    required this.reviewedAt,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
        'anomalyId': anomalyId,
        'status': status.name,
        'reviewedBy': reviewedBy,
        'reviewedAt': reviewedAt.toIso8601String(),
        'reason': reason,
      };

  factory AnomalyResolutionRecord.fromJson(Map<String, dynamic> json) {
    return AnomalyResolutionRecord(
      anomalyId: json['anomalyId']?.toString() ?? '',
      status: CorrectionApprovalStatusExtension.fromString(json['status']?.toString()),
      reviewedBy: json['reviewedBy']?.toString() ?? 'Yönetici',
      reviewedAt: DateTime.tryParse(json['reviewedAt']?.toString() ?? '') ?? DateTime.now(),
      reason: json['reason']?.toString(),
    );
  }
}

/// Günlük Devam Özeti Satırı
class DailyAttendanceSummary {
  final int employeeId;
  final String sicilNo;
  final String employeeName;
  final String department;
  final String title;
  final bool isEmployeeActive;
  final DateTime date;
  final PdksShiftDefinition plannedShift;
  final DateTime? firstCheckIn;
  final DateTime? lastCheckOut;
  final Duration totalBreakDuration;
  final Duration dutyDuration;
  /// Kesin net çalışma süresi. Açık/eksik aralık varsa null döner ("İnceleme Bekliyor").
  final Duration? netWorkDuration;
  final Duration lateDuration;
  final Duration earlyLeaveDuration;
  final Duration pendingExtraDuration;
  final DailyAttendanceStatus status;
  final List<MovementAnomalyItem> anomalies;
  final List<EmployeeMovementRecord> dayMovements;

  const DailyAttendanceSummary({
    required this.employeeId,
    required this.sicilNo,
    required this.employeeName,
    required this.department,
    required this.title,
    this.isEmployeeActive = true,
    required this.date,
    required this.plannedShift,
    this.firstCheckIn,
    this.lastCheckOut,
    required this.totalBreakDuration,
    required this.dutyDuration,
    this.netWorkDuration,
    required this.lateDuration,
    required this.earlyLeaveDuration,
    required this.pendingExtraDuration,
    required this.status,
    this.anomalies = const [],
    this.dayMovements = const [],
  });

  bool get isLate => lateDuration.inMinutes > 0;
  bool get isEarlyLeave => earlyLeaveDuration.inMinutes > 0;
  bool get hasMissingOrOpenInterval => status == DailyAttendanceStatus.missingMovement;
}
