class ShiftSchedule {
  final int id;
  final String companyId;
  final String title; // örn: Sabah Vardiyası (08:30 - 17:30)
  final String startTime; // "08:30"
  final String endTime;   // "17:30"
  final int breakMinutes; // 60
  final List<String> activeDays; // ["Pazartesi", "Salı", ...]
  final int assignedEmployeeCount;

  ShiftSchedule({
    required this.id,
    this.companyId = 'cmp_acme',
    required this.title,
    required this.startTime,
    required this.endTime,
    this.breakMinutes = 60,
    this.activeDays = const [],
    this.assignedEmployeeCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'title': title,
      'startTime': startTime,
      'endTime': endTime,
      'breakMinutes': breakMinutes,
      'activeDays': activeDays,
      'assignedEmployeeCount': assignedEmployeeCount,
    };
  }

  factory ShiftSchedule.fromJson(Map<String, dynamic> json) {
    return ShiftSchedule(
      id: json['id'] ?? 0,
      companyId: json['companyId'] ?? 'cmp_acme',
      title: json['title'] ?? '',
      startTime: json['startTime'] ?? '08:30',
      endTime: json['endTime'] ?? '17:30',
      breakMinutes: json['breakMinutes'] ?? 60,
      activeDays: (json['activeDays'] as List?)?.map((e) => e.toString()).toList() ?? [],
      assignedEmployeeCount: json['assignedEmployeeCount'] ?? 0,
    );
  }
}
