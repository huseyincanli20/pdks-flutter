enum LeaveType { annual, medical, excused, unpaid }

enum LeaveStatus { pending, approved, rejected }

class LeaveRequest {
  final int id;
  final String companyId;
  final int employeeId;
  final String employeeName;
  final LeaveType type;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final String reason;
  final LeaveStatus status;
  final String? managerComment;
  final DateTime createdAt;

  LeaveRequest({
    required this.id,
    this.companyId = 'cmp_acme',
    required this.employeeId,
    required this.employeeName,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    this.status = LeaveStatus.pending,
    this.managerComment,
    required this.createdAt,
  });

  String get typeLabel {
    switch (type) {
      case LeaveType.annual:
        return 'Yıllık İzin';
      case LeaveType.medical:
        return 'Hastalık / Rapor';
      case LeaveType.excused:
        return 'Mazeret İzni';
      case LeaveType.unpaid:
        return 'Ücretsiz İzin';
    }
  }

  String get statusLabel {
    switch (status) {
      case LeaveStatus.pending:
        return 'Onay Bekliyor';
      case LeaveStatus.approved:
        return 'Onaylandı';
      case LeaveStatus.rejected:
        return 'Reddedildi';
    }
  }

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] ?? 0,
      companyId: json['companyId'] ?? 'cmp_acme',
      employeeId: json['employeeId'] ?? 0,
      employeeName: json['employeeName'] ?? 'Personel',
      type: LeaveType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LeaveType.annual,
      ),
      startDate: DateTime.tryParse(json['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate'] ?? '') ?? DateTime.now(),
      totalDays: json['totalDays'] ?? 1,
      reason: json['reason'] ?? '',
      status: LeaveStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => LeaveStatus.pending,
      ),
      managerComment: json['managerComment'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'type': type.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalDays': totalDays,
      'reason': reason,
      'status': status.name,
      'managerComment': managerComment,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
