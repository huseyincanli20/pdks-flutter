class ShiftSwapRequest {
  final String id;
  final String companyId;
  final int requesterEmployeeId;
  final String requesterName;
  final int targetEmployeeId;
  final String targetName;
  final int shiftId;
  final String shiftTitle;
  final DateTime targetDate;
  final String reason;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  final String? approvedBy;

  ShiftSwapRequest({
    required this.id,
    required this.companyId,
    required this.requesterEmployeeId,
    required this.requesterName,
    required this.targetEmployeeId,
    required this.targetName,
    required this.shiftId,
    required this.shiftTitle,
    required this.targetDate,
    required this.reason,
    this.status = 'pending',
    DateTime? createdAt,
    this.approvedBy,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'requesterEmployeeId': requesterEmployeeId,
        'requesterName': requesterName,
        'targetEmployeeId': targetEmployeeId,
        'targetName': targetName,
        'shiftId': shiftId,
        'shiftTitle': shiftTitle,
        'targetDate': targetDate.toIso8601String(),
        'reason': reason,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'approvedBy': approvedBy,
      };

  factory ShiftSwapRequest.fromJson(Map<String, dynamic> json) => ShiftSwapRequest(
        id: json['id'] ?? '',
        companyId: json['companyId'] ?? 'cmp_acme',
        requesterEmployeeId: json['requesterEmployeeId'] ?? 0,
        requesterName: json['requesterName'] ?? '',
        targetEmployeeId: json['targetEmployeeId'] ?? 0,
        targetName: json['targetName'] ?? '',
        shiftId: json['shiftId'] ?? 0,
        shiftTitle: json['shiftTitle'] ?? '',
        targetDate: json['targetDate'] != null ? DateTime.parse(json['targetDate']) : DateTime.now(),
        reason: json['reason'] ?? '',
        status: json['status'] ?? 'pending',
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
        approvedBy: json['approvedBy'],
      );

  ShiftSwapRequest copyWith({String? status, String? approvedBy}) => ShiftSwapRequest(
        id: id,
        companyId: companyId,
        requesterEmployeeId: requesterEmployeeId,
        requesterName: requesterName,
        targetEmployeeId: targetEmployeeId,
        targetName: targetName,
        shiftId: shiftId,
        shiftTitle: shiftTitle,
        targetDate: targetDate,
        reason: reason,
        status: status ?? this.status,
        createdAt: createdAt,
        approvedBy: approvedBy ?? this.approvedBy,
      );
}

class OpenShiftSlot {
  final String id;
  final String companyId;
  final int shiftId;
  final String shiftTitle;
  final DateTime date;
  final int requiredHeadcount;
  final List<int> appliedEmployeeIds;
  final List<int> assignedEmployeeIds;

  OpenShiftSlot({
    required this.id,
    required this.companyId,
    required this.shiftId,
    required this.shiftTitle,
    required this.date,
    this.requiredHeadcount = 1,
    this.appliedEmployeeIds = const [],
    this.assignedEmployeeIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'shiftId': shiftId,
        'shiftTitle': shiftTitle,
        'date': date.toIso8601String(),
        'requiredHeadcount': requiredHeadcount,
        'appliedEmployeeIds': appliedEmployeeIds,
        'assignedEmployeeIds': assignedEmployeeIds,
      };

  factory OpenShiftSlot.fromJson(Map<String, dynamic> json) => OpenShiftSlot(
        id: json['id'] ?? '',
        companyId: json['companyId'] ?? 'cmp_acme',
        shiftId: json['shiftId'] ?? 0,
        shiftTitle: json['shiftTitle'] ?? '',
        date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
        requiredHeadcount: json['requiredHeadcount'] ?? 1,
        appliedEmployeeIds: (json['appliedEmployeeIds'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [],
        assignedEmployeeIds: (json['assignedEmployeeIds'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [],
      );
}
