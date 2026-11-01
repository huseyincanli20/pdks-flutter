class PerformanceGoal {
  final String id;
  final String companyId;
  final int employeeId;
  final String employeeName;
  final String period; // '2026 Q1', '2026 Q2', '2026 Q3', '2026 Q4', '2026 Yıllık'
  final String title;
  final String description;
  final double weightPercentage; // % ağırlık (örn 30%)
  final double currentProgress; // % tamamlanma (0 - 100)
  final double? selfRating; // 1.0 - 5.0
  final double? managerRating; // 1.0 - 5.0
  final String? managerFeedback;
  final String status; // 'active', 'submitted', 'reviewed'

  PerformanceGoal({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.employeeName,
    required this.period,
    required this.title,
    required this.description,
    this.weightPercentage = 25.0,
    this.currentProgress = 0.0,
    this.selfRating,
    this.managerRating,
    this.managerFeedback,
    this.status = 'active',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'period': period,
        'title': title,
        'description': description,
        'weightPercentage': weightPercentage,
        'currentProgress': currentProgress,
        'selfRating': selfRating,
        'managerRating': managerRating,
        'managerFeedback': managerFeedback,
        'status': status,
      };

  factory PerformanceGoal.fromJson(Map<String, dynamic> json) => PerformanceGoal(
        id: json['id'] ?? '',
        companyId: json['companyId'] ?? 'cmp_acme',
        employeeId: json['employeeId'] ?? 0,
        employeeName: json['employeeName'] ?? '',
        period: json['period'] ?? '2026 Q1',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        weightPercentage: (json['weightPercentage'] as num?)?.toDouble() ?? 25.0,
        currentProgress: (json['currentProgress'] as num?)?.toDouble() ?? 0.0,
        selfRating: (json['selfRating'] as num?)?.toDouble(),
        managerRating: (json['managerRating'] as num?)?.toDouble(),
        managerFeedback: json['managerFeedback'],
        status: json['status'] ?? 'active',
      );

  PerformanceGoal copyWith({
    double? currentProgress,
    double? selfRating,
    double? managerRating,
    String? managerFeedback,
    String? status,
  }) =>
      PerformanceGoal(
        id: id,
        companyId: companyId,
        employeeId: employeeId,
        employeeName: employeeName,
        period: period,
        title: title,
        description: description,
        weightPercentage: weightPercentage,
        currentProgress: currentProgress ?? this.currentProgress,
        selfRating: selfRating ?? this.selfRating,
        managerRating: managerRating ?? this.managerRating,
        managerFeedback: managerFeedback ?? this.managerFeedback,
        status: status ?? this.status,
      );
}
