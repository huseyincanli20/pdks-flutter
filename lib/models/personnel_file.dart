class EmployeeDocument {
  final String id;
  final String companyId;
  final int employeeId;
  final String title;
  final String documentType; // 'contract', 'id_card', 'certificate', 'health_report', 'diploma', 'criminal_record'
  final String fileName;
  final String? storageFileId;
  final String? mimeType;
  final int? fileSize;
  final DateTime uploadDate;
  final DateTime? expiryDate; // Belge bitiş tarihi
  final String status; // 'valid', 'expiring_soon', 'expired'
  final String? notes;

  EmployeeDocument({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.title,
    required this.documentType,
    required this.fileName,
    this.storageFileId,
    this.mimeType,
    this.fileSize,
    DateTime? uploadDate,
    this.expiryDate,
    this.status = 'valid',
    this.notes,
  }) : uploadDate = uploadDate ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'employeeId': employeeId,
        'title': title,
        'documentType': documentType,
        'fileName': fileName,
        'storageFileId': storageFileId,
        'mimeType': mimeType,
        'fileSize': fileSize,
        'uploadDate': uploadDate.toIso8601String(),
        'expiryDate': expiryDate?.toIso8601String(),
        'status': status,
        'notes': notes,
      };

  factory EmployeeDocument.fromJson(Map<String, dynamic> json) => EmployeeDocument(
        id: json['id'] ?? '',
        companyId: json['companyId'] ?? 'cmp_acme',
        employeeId: json['employeeId'] ?? 0,
        title: json['title'] ?? '',
        documentType: json['documentType'] ?? 'certificate',
        fileName: json['fileName'] ?? 'belge.pdf',
        storageFileId: json['storageFileId'],
        mimeType: json['mimeType'],
        fileSize: json['fileSize'],
        uploadDate: json['uploadDate'] != null ? DateTime.parse(json['uploadDate']) : DateTime.now(),
        expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : null,
        status: json['status'] ?? 'valid',
        notes: json['notes'],
      );
}

class OnboardingTask {
  final String id;
  final String companyId;
  final int employeeId;
  final String processType; // 'onboarding' (İşe Giriş), 'offboarding' (İşten Ayrılış)
  final String title;
  final String category; // 'evrak', 'it_donanim', 'oryantasyon', 'yetki_hesap', 'cikis_teslim'
  final bool isCompleted;
  final DateTime? completedAt;
  final String assignedRole; // 'hr', 'it', 'admin', 'manager'

  OnboardingTask({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.processType,
    required this.title,
    required this.category,
    this.isCompleted = false,
    this.completedAt,
    this.assignedRole = 'hr',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'employeeId': employeeId,
        'processType': processType,
        'title': title,
        'category': category,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
        'assignedRole': assignedRole,
      };

  factory OnboardingTask.fromJson(Map<String, dynamic> json) => OnboardingTask(
        id: json['id'] ?? '',
        companyId: json['companyId'] ?? 'cmp_acme',
        employeeId: json['employeeId'] ?? 0,
        processType: json['processType'] ?? 'onboarding',
        title: json['title'] ?? '',
        category: json['category'] ?? 'evrak',
        isCompleted: json['isCompleted'] ?? false,
        completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
        assignedRole: json['assignedRole'] ?? 'hr',
      );

  OnboardingTask copyWith({bool? isCompleted, DateTime? completedAt}) => OnboardingTask(
        id: id,
        companyId: companyId,
        employeeId: employeeId,
        processType: processType,
        title: title,
        category: category,
        isCompleted: isCompleted ?? this.isCompleted,
        completedAt: completedAt ?? this.completedAt,
        assignedRole: assignedRole,
      );
}
