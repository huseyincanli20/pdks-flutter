class TrainingCourse {
  final String id;
  final String companyId;
  final String title;
  final String description;
  final String instructor;
  final int durationMinutes;
  final String category; // 'isg', 'yazilim', 'yonetim', 'kvkk', 'teknik'
  final bool hasQuiz;
  final int passingScore;
  final int validityMonths; // Sertifika geçerlilik süresi (ay)

  TrainingCourse({
    required this.id,
    required this.companyId,
    required this.title,
    required this.description,
    this.instructor = 'Kurumsal Akademi',
    this.durationMinutes = 60,
    this.category = 'isg',
    this.hasQuiz = true,
    this.passingScore = 70,
    this.validityMonths = 12,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'title': title,
        'description': description,
        'instructor': instructor,
        'durationMinutes': durationMinutes,
        'category': category,
        'hasQuiz': hasQuiz,
        'passingScore': passingScore,
        'validityMonths': validityMonths,
      };

  factory TrainingCourse.fromJson(Map<String, dynamic> json) => TrainingCourse(
        id: json['id'] ?? '',
        companyId: json['companyId'] ?? 'cmp_acme',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        instructor: json['instructor'] ?? 'Kurumsal Akademi',
        durationMinutes: json['durationMinutes'] ?? 60,
        category: json['category'] ?? 'isg',
        hasQuiz: json['hasQuiz'] ?? true,
        passingScore: json['passingScore'] ?? 70,
        validityMonths: json['validityMonths'] ?? 12,
      );
}

class EmployeeTrainingRecord {
  final String id;
  final String companyId;
  final int employeeId;
  final String courseId;
  final String courseTitle;
  final String status; // 'assigned', 'in_progress', 'completed', 'expired'
  final int score;
  final DateTime? completedDate;
  final DateTime? certificateExpiry;

  EmployeeTrainingRecord({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.courseId,
    required this.courseTitle,
    this.status = 'assigned',
    this.score = 0,
    this.completedDate,
    this.certificateExpiry,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'employeeId': employeeId,
        'courseId': courseId,
        'courseTitle': courseTitle,
        'status': status,
        'score': score,
        'completedDate': completedDate?.toIso8601String(),
        'certificateExpiry': certificateExpiry?.toIso8601String(),
      };

  factory EmployeeTrainingRecord.fromJson(Map<String, dynamic> json) => EmployeeTrainingRecord(
        id: json['id'] ?? '',
        companyId: json['companyId'] ?? 'cmp_acme',
        employeeId: json['employeeId'] ?? 0,
        courseId: json['courseId'] ?? '',
        courseTitle: json['courseTitle'] ?? '',
        status: json['status'] ?? 'assigned',
        score: json['score'] ?? 0,
        completedDate: json['completedDate'] != null ? DateTime.parse(json['completedDate']) : null,
        certificateExpiry: json['certificateExpiry'] != null ? DateTime.parse(json['certificateExpiry']) : null,
      );

  EmployeeTrainingRecord copyWith({String? status, int? score, DateTime? completedDate, DateTime? certificateExpiry}) =>
      EmployeeTrainingRecord(
        id: id,
        companyId: companyId,
        employeeId: employeeId,
        courseId: courseId,
        courseTitle: courseTitle,
        status: status ?? this.status,
        score: score ?? this.score,
        completedDate: completedDate ?? this.completedDate,
        certificateExpiry: certificateExpiry ?? this.certificateExpiry,
      );
}
