class ChecklistItem {
  final String id;
  final String title;
  final bool isDone;

  ChecklistItem({
    required this.id,
    required this.title,
    this.isDone = false,
  });

  ChecklistItem copyWith({bool? isDone}) => ChecklistItem(
        id: id,
        title: title,
        isDone: isDone ?? this.isDone,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isDone': isDone,
      };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        isDone: json['isDone'] ?? false,
      );
}

class SparePartItem {
  final String partName;
  final int quantity;
  final double unitCost;

  SparePartItem({
    required this.partName,
    required this.quantity,
    required this.unitCost,
  });

  double get total => quantity * unitCost;

  Map<String, dynamic> toJson() => {
        'partName': partName,
        'quantity': quantity,
        'unitCost': unitCost,
      };

  factory SparePartItem.fromJson(Map<String, dynamic> json) => SparePartItem(
        partName: json['partName'] ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        unitCost: (json['unitCost'] as num?)?.toDouble() ?? 0.0,
      );
}

/// Kalibrasyon ve Ekipman Sicil Kart (ISO 9001 / ISO 17025 Uyumu)
class EquipmentRecord {
  final String id;
  final String companyId;
  final String equipmentCode; // rn. CNC-01, TURN-02, MIC-05
  final String serialNumber;
  final String name;
  final String brandModel;
  final String department;
  final String location;
  final DateTime? warrantyExpiryDate;
  final String qrBarcode;

  // Kalibrasyon & Sertifika Alanlar (ISO 9001 / ISO 17025)
  final int calibrationPeriodMonths; // rn. 6, 12 ay
  final DateTime lastCalibrationDate;
  final DateTime nextCalibrationDate;
  final String referenceStandard; // rn. 'ISO 17025 / TRKAK', 'ISO 9001:2015'
  final String toleranceLimit; // rn. ' 0.05 mm', ' 0.1 C'
  final String certificatePdfUrl;
  final String status; // 'active', 'warning_30d', 'warning_15d', 'warning_3d', 'quarantine'
  final String? quarantineReason;

  EquipmentRecord({
    required this.id,
    required this.companyId,
    required this.equipmentCode,
    required this.serialNumber,
    required this.name,
    required this.brandModel,
    required this.department,
    required this.location,
    this.warrantyExpiryDate,
    required this.qrBarcode,
    this.calibrationPeriodMonths = 12,
    DateTime? lastCalibrationDate,
    DateTime? nextCalibrationDate,
    this.referenceStandard = 'ISO 17025 / TRKAK Akredite',
    this.toleranceLimit = '0.02 mm / 0.5 %',
    this.certificatePdfUrl = 'sertifika_kalibrasyon_2026.pdf',
    this.status = 'active',
    this.quarantineReason,
  })  : lastCalibrationDate = lastCalibrationDate ?? DateTime.now().subtract(const Duration(days: 300)),
        nextCalibrationDate = nextCalibrationDate ?? DateTime.now().add(const Duration(days: 65));

  bool get isQuarantined =>
      status == 'quarantine' || DateTime.now().isAfter(nextCalibrationDate);

  int get daysUntilCalibration =>
      nextCalibrationDate.difference(DateTime.now()).inDays;

  String get computedStatus {
    if (status == 'quarantine' || DateTime.now().isAfter(nextCalibrationDate)) {
      return 'quarantine';
    }
    final days = daysUntilCalibration;
    if (days <= 3) return 'warning_3d';
    if (days <= 15) return 'warning_15d';
    if (days <= 30) return 'warning_30d';
    return 'active';
  }

  EquipmentRecord copyWith({
    String? status,
    String? quarantineReason,
    DateTime? lastCalibrationDate,
    DateTime? nextCalibrationDate,
    String? certificatePdfUrl,
    String? toleranceLimit,
  }) =>
      EquipmentRecord(
        id: id,
        companyId: companyId,
        equipmentCode: equipmentCode,
        serialNumber: serialNumber,
        name: name,
        brandModel: brandModel,
        department: department,
        location: location,
        warrantyExpiryDate: warrantyExpiryDate,
        qrBarcode: qrBarcode,
        calibrationPeriodMonths: calibrationPeriodMonths,
        lastCalibrationDate: lastCalibrationDate ?? this.lastCalibrationDate,
        nextCalibrationDate: nextCalibrationDate ?? this.nextCalibrationDate,
        referenceStandard: referenceStandard,
        toleranceLimit: toleranceLimit ?? this.toleranceLimit,
        certificatePdfUrl: certificatePdfUrl ?? this.certificatePdfUrl,
        status: status ?? this.status,
        quarantineReason: quarantineReason ?? this.quarantineReason,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'equipmentCode': equipmentCode,
        'serialNumber': serialNumber,
        'name': name,
        'brandModel': brandModel,
        'department': department,
        'location': location,
        'warrantyExpiryDate': warrantyExpiryDate?.toIso8601String(),
        'qrBarcode': qrBarcode,
        'calibrationPeriodMonths': calibrationPeriodMonths,
        'lastCalibrationDate': lastCalibrationDate.toIso8601String(),
        'nextCalibrationDate': nextCalibrationDate.toIso8601String(),
        'referenceStandard': referenceStandard,
        'toleranceLimit': toleranceLimit,
        'certificatePdfUrl': certificatePdfUrl,
        'status': status,
        'quarantineReason': quarantineReason,
      };

  factory EquipmentRecord.fromJson(Map<String, dynamic> json) => EquipmentRecord(
        id: json['id'] ?? '',
        companyId: json['companyId'] ?? 'cmp_acme',
        equipmentCode: json['equipmentCode'] ?? '',
        serialNumber: json['serialNumber'] ?? '',
        name: json['name'] ?? '',
        brandModel: json['brandModel'] ?? '',
        department: json['department'] ?? '',
        location: json['location'] ?? '',
        warrantyExpiryDate: json['warrantyExpiryDate'] != null
            ? DateTime.tryParse(json['warrantyExpiryDate'])
            : null,
        qrBarcode: json['qrBarcode'] ?? '',
        calibrationPeriodMonths: (json['calibrationPeriodMonths'] as num?)?.toInt() ?? 12,
        lastCalibrationDate: json['lastCalibrationDate'] != null
            ? DateTime.tryParse(json['lastCalibrationDate'])
            : null,
        nextCalibrationDate: json['nextCalibrationDate'] != null
            ? DateTime.tryParse(json['nextCalibrationDate'])
            : null,
        referenceStandard: json['referenceStandard'] ?? 'ISO 17025',
        toleranceLimit: json['toleranceLimit'] ?? '0.02 mm',
        certificatePdfUrl: json['certificatePdfUrl'] ?? '',
        status: json['status'] ?? 'active',
        quarantineReason: json['quarantineReason'],
      );
}

/// Periyodik Bakm ve Arza  Emri (CMMS Work Order)
class MaintenanceWorkOrder {
  final String id;
  final String companyId;
  final String equipmentId;
  final String equipmentCode;
  final String equipmentName;
  final String title;
  final String description;
  final String? photoUrl;
  final String priority; // 'normal', 'high', 'urgent' (Acil arza)
  final String status; // 'open', 'in_progress', 'completed', 'cancelled'
  final String reportedBy;
  final DateTime reportedAt;
  final int? assignedTechnicianId;
  final String? assignedTechnicianName;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<ChecklistItem> checklist;
  final List<SparePartItem> partsUsed;
  final double totalCost;
  final int? mttrMinutes; // Mean Time To Repair (Mdahale/Tamir sresi dk)
  final int? downtimeMinutes; // Duru sresi dk

  MaintenanceWorkOrder({
    required this.id,
    required this.companyId,
    required this.equipmentId,
    required this.equipmentCode,
    required this.equipmentName,
    required this.title,
    required this.description,
    this.photoUrl,
    this.priority = 'normal',
    this.status = 'open',
    required this.reportedBy,
    DateTime? reportedAt,
    this.assignedTechnicianId,
    this.assignedTechnicianName,
    this.startedAt,
    this.completedAt,
    this.checklist = const [],
    this.partsUsed = const [],
    this.totalCost = 0.0,
    this.mttrMinutes,
    this.downtimeMinutes,
  }) : reportedAt = reportedAt ?? DateTime.now();

  bool get isUrgent => priority == 'urgent';

  MaintenanceWorkOrder copyWith({
    String? status,
    int? assignedTechnicianId,
    String? assignedTechnicianName,
    DateTime? startedAt,
    DateTime? completedAt,
    List<ChecklistItem>? checklist,
    List<SparePartItem>? partsUsed,
    double? totalCost,
    int? mttrMinutes,
    int? downtimeMinutes,
  }) =>
      MaintenanceWorkOrder(
        id: id,
        companyId: companyId,
        equipmentId: equipmentId,
        equipmentCode: equipmentCode,
        equipmentName: equipmentName,
        title: title,
        description: description,
        photoUrl: photoUrl,
        priority: priority,
        status: status ?? this.status,
        reportedBy: reportedBy,
        reportedAt: reportedAt,
        assignedTechnicianId: assignedTechnicianId ?? this.assignedTechnicianId,
        assignedTechnicianName: assignedTechnicianName ?? this.assignedTechnicianName,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt ?? this.completedAt,
        checklist: checklist ?? this.checklist,
        partsUsed: partsUsed ?? this.partsUsed,
        totalCost: totalCost ?? this.totalCost,
        mttrMinutes: mttrMinutes ?? this.mttrMinutes,
        downtimeMinutes: downtimeMinutes ?? this.downtimeMinutes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'equipmentId': equipmentId,
        'equipmentCode': equipmentCode,
        'equipmentName': equipmentName,
        'title': title,
        'description': description,
        'photoUrl': photoUrl,
        'priority': priority,
        'status': status,
        'reportedBy': reportedBy,
        'reportedAt': reportedAt.toIso8601String(),
        'assignedTechnicianId': assignedTechnicianId,
        'assignedTechnicianName': assignedTechnicianName,
        'startedAt': startedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'checklist': checklist.map((c) => c.toJson()).toList(),
        'partsUsed': partsUsed.map((p) => p.toJson()).toList(),
        'totalCost': totalCost,
        'mttrMinutes': mttrMinutes,
        'downtimeMinutes': downtimeMinutes,
      };

  factory MaintenanceWorkOrder.fromJson(Map<String, dynamic> json) => MaintenanceWorkOrder(
        id: json['id'] ?? '',
        companyId: json['companyId'] ?? 'cmp_acme',
        equipmentId: json['equipmentId'] ?? '',
        equipmentCode: json['equipmentCode'] ?? '',
        equipmentName: json['equipmentName'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        photoUrl: json['photoUrl'],
        priority: json['priority'] ?? 'normal',
        status: json['status'] ?? 'open',
        reportedBy: json['reportedBy'] ?? 'Sistem',
        reportedAt: json['reportedAt'] != null
            ? DateTime.tryParse(json['reportedAt'])
            : null,
        assignedTechnicianId: json['assignedTechnicianId'],
        assignedTechnicianName: json['assignedTechnicianName'],
        startedAt: json['startedAt'] != null
            ? DateTime.tryParse(json['startedAt'])
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'])
            : null,
        checklist: (json['checklist'] as List?)
                ?.map((c) => ChecklistItem.fromJson(c))
                .toList() ??
            [],
        partsUsed: (json['partsUsed'] as List?)
                ?.map((p) => SparePartItem.fromJson(p))
                .toList() ??
            [],
        totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0.0,
        mttrMinutes: json['mttrMinutes'],
        downtimeMinutes: json['downtimeMinutes'],
      );
}
