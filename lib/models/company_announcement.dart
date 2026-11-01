class CompanyAnnouncement {
  final String id;
  final String companyId;
  final String title;
  final String content;
  final String category; // 'genel', 'ik', 'isg', 'etkinlik', 'acil'
  final bool isMandatory; // Okundu onayı zorunlu mu?
  final DateTime publishedAt;
  final String publisherName;
  final List<int> readEmployeeIds;
  final List<int> confirmedEmployeeIds; // Zorunlu okudum onayladım diyenler

  CompanyAnnouncement({
    required this.id,
    required this.companyId,
    required this.title,
    required this.content,
    this.category = 'genel',
    this.isMandatory = false,
    DateTime? publishedAt,
    this.publisherName = 'İnsan Kaynakları',
    this.readEmployeeIds = const [],
    this.confirmedEmployeeIds = const [],
  }) : publishedAt = publishedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'title': title,
        'content': content,
        'category': category,
        'isMandatory': isMandatory,
        'publishedAt': publishedAt.toIso8601String(),
        'publisherName': publisherName,
        'readEmployeeIds': readEmployeeIds,
        'confirmedEmployeeIds': confirmedEmployeeIds,
      };

  factory CompanyAnnouncement.fromJson(Map<String, dynamic> json) => CompanyAnnouncement(
        id: json['id'] ?? '',
        companyId: json['companyId'] ?? 'cmp_acme',
        title: json['title'] ?? '',
        content: json['content'] ?? '',
        category: json['category'] ?? 'genel',
        isMandatory: json['isMandatory'] ?? false,
        publishedAt: json['publishedAt'] != null ? DateTime.parse(json['publishedAt']) : DateTime.now(),
        publisherName: json['publisherName'] ?? 'İnsan Kaynakları',
        readEmployeeIds: (json['readEmployeeIds'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [],
        confirmedEmployeeIds: (json['confirmedEmployeeIds'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [],
      );

  CompanyAnnouncement copyWith({
    List<int>? readEmployeeIds,
    List<int>? confirmedEmployeeIds,
  }) =>
      CompanyAnnouncement(
        id: id,
        companyId: companyId,
        title: title,
        content: content,
        category: category,
        isMandatory: isMandatory,
        publishedAt: publishedAt,
        publisherName: publisherName,
        readEmployeeIds: readEmployeeIds ?? this.readEmployeeIds,
        confirmedEmployeeIds: confirmedEmployeeIds ?? this.confirmedEmployeeIds,
      );
}
