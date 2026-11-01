class EmployeeFeedback {
  final String id;
  final String companyId;
  final String category; // 'survey' (Memnuniyet Anketi), 'suggestion' (Öneri Kutusu), 'complaint' (Geri Bildirim)
  final String title;
  final String content;
  final bool isAnonymous;
  final int? submitterEmployeeId;
  final String? submitterName;
  final int rating; // 1 - 5 yıldız
  final String status; // 'submitted', 'under_review', 'resolved'
  final String? hrResponse;
  final DateTime createdAt;

  EmployeeFeedback({
    required this.id,
    required this.companyId,
    required this.category,
    required this.title,
    required this.content,
    this.isAnonymous = false,
    this.submitterEmployeeId,
    this.submitterName,
    this.rating = 5,
    this.status = 'submitted',
    this.hrResponse,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'category': category,
        'title': title,
        'content': content,
        'isAnonymous': isAnonymous,
        'submitterEmployeeId': submitterEmployeeId,
        'submitterName': submitterName,
        'rating': rating,
        'status': status,
        'hrResponse': hrResponse,
        'createdAt': createdAt.toIso8601String(),
      };

  factory EmployeeFeedback.fromJson(Map<String, dynamic> json) => EmployeeFeedback(
        id: json['id'] ?? '',
        companyId: json['companyId'] ?? 'cmp_acme',
        category: json['category'] ?? 'suggestion',
        title: json['title'] ?? '',
        content: json['content'] ?? '',
        isAnonymous: json['isAnonymous'] ?? false,
        submitterEmployeeId: json['submitterEmployeeId'],
        submitterName: json['submitterName'],
        rating: json['rating'] ?? 5,
        status: json['status'] ?? 'submitted',
        hrResponse: json['hrResponse'],
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      );

  EmployeeFeedback copyWith({String? status, String? hrResponse}) => EmployeeFeedback(
        id: id,
        companyId: companyId,
        category: category,
        title: title,
        content: content,
        isAnonymous: isAnonymous,
        submitterEmployeeId: submitterEmployeeId,
        submitterName: submitterName,
        rating: rating,
        status: status ?? this.status,
        hrResponse: hrResponse ?? this.hrResponse,
        createdAt: createdAt,
      );
}
