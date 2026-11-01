class HelpdeskTicket {
  final String id;
  final String companyId;
  final int requesterId;
  final String requesterName;
  final String title;
  final String description;
  final String category; // 'it', 'hardware', 'facility', 'electrical', 'safety'
  final String priority; // 'low', 'medium', 'high', 'critical'
  final String status; // 'open', 'in_progress', 'resolved', 'closed'
  final int? assignedTechnicianId;
  final String? assignedTechnicianName;
  final String? solutionNotes;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  HelpdeskTicket({
    required this.id,
    required this.companyId,
    required this.requesterId,
    required this.requesterName,
    required this.title,
    required this.description,
    this.category = 'it',
    this.priority = 'medium',
    this.status = 'open',
    this.assignedTechnicianId,
    this.assignedTechnicianName,
    this.solutionNotes,
    DateTime? createdAt,
    this.resolvedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'requesterId': requesterId,
        'requesterName': requesterName,
        'title': title,
        'description': description,
        'category': category,
        'priority': priority,
        'status': status,
        'assignedTechnicianId': assignedTechnicianId,
        'assignedTechnicianName': assignedTechnicianName,
        'solutionNotes': solutionNotes,
        'createdAt': createdAt.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
      };

  factory HelpdeskTicket.fromJson(Map<String, dynamic> json) => HelpdeskTicket(
        id: json['id'] ?? '',
        companyId: json['companyId'] ?? 'cmp_acme',
        requesterId: json['requesterId'] ?? 0,
        requesterName: json['requesterName'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        category: json['category'] ?? 'it',
        priority: json['priority'] ?? 'medium',
        status: json['status'] ?? 'open',
        assignedTechnicianId: json['assignedTechnicianId'],
        assignedTechnicianName: json['assignedTechnicianName'],
        solutionNotes: json['solutionNotes'],
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
        resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
      );

  HelpdeskTicket copyWith({
    String? status,
    int? assignedTechnicianId,
    String? assignedTechnicianName,
    String? solutionNotes,
    DateTime? resolvedAt,
  }) =>
      HelpdeskTicket(
        id: id,
        companyId: companyId,
        requesterId: requesterId,
        requesterName: requesterName,
        title: title,
        description: description,
        category: category,
        priority: priority,
        status: status ?? this.status,
        assignedTechnicianId: assignedTechnicianId ?? this.assignedTechnicianId,
        assignedTechnicianName: assignedTechnicianName ?? this.assignedTechnicianName,
        solutionNotes: solutionNotes ?? this.solutionNotes,
        createdAt: createdAt,
        resolvedAt: resolvedAt ?? this.resolvedAt,
      );
}
