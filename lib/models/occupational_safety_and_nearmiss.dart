/// Ramak Kala (Near-Miss) & Olay Bildirimi (İSG 6331 Sayılı Kanun Uyumlu)
class NearMissReport {
  final String id;
  final String companyId;
  final int reporterId;
  final String reporterName;
  final String title;
  final String description;
  final String department;
  final String locationDetail;
  final String riskLevel; // 'critical', 'high', 'medium', 'low'
  final DateTime reportedAt;
  String status; // 'open', 'investigating', 'action_taken', 'closed'
  String? correctiveAction;
  String? resolvedBy;
  DateTime? resolvedAt;
  final List<String> photoUrls;

  NearMissReport({
    required this.id,
    required this.companyId,
    required this.reporterId,
    required this.reporterName,
    required this.title,
    required this.description,
    required this.department,
    required this.locationDetail,
    this.riskLevel = 'high',
    required this.reportedAt,
    this.status = 'open',
    this.correctiveAction,
    this.resolvedBy,
    this.resolvedAt,
    this.photoUrls = const [],
  });

  String get riskLabel {
    switch (riskLevel) {
      case 'critical':
        return 'Hayati Tehlike 🚨';
      case 'high':
        return 'Yüksek Risk ⚠️';
      case 'medium':
        return 'Orta Risk ⚡';
      default:
        return 'Düşük Risk ℹ️';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'reporterId': reporterId,
        'reporterName': reporterName,
        'title': title,
        'description': description,
        'department': department,
        'locationDetail': locationDetail,
        'riskLevel': riskLevel,
        'reportedAt': reportedAt.toIso8601String(),
        'status': status,
        'correctiveAction': correctiveAction,
        'resolvedBy': resolvedBy,
        'resolvedAt': resolvedAt?.toIso8601String(),
        'photoUrls': photoUrls,
      };

  factory NearMissReport.fromJson(Map<String, dynamic> json) => NearMissReport(
        id: json['id'] ?? '',
        companyId: json['companyId'] ?? '',
        reporterId: json['reporterId'] ?? 0,
        reporterName: json['reporterName'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        department: json['department'] ?? '',
        locationDetail: json['locationDetail'] ?? '',
        riskLevel: json['riskLevel'] ?? 'high',
        reportedAt: DateTime.tryParse(json['reportedAt'] ?? '') ?? DateTime.now(),
        status: json['status'] ?? 'open',
        correctiveAction: json['correctiveAction'],
        resolvedBy: json['resolvedBy'],
        resolvedAt: json['resolvedAt'] != null ? DateTime.tryParse(json['resolvedAt']) : null,
        photoUrls: json['photoUrls'] != null ? List<String>.from(json['photoUrls']) : [],
      );
}

/// Personel İSG Sertifikası ve Periyodik Sağlık Muayenesi
class SafetyCertificate {
  final String id;
  final int employeeId;
  final String employeeName;
  final String certificateType; // 'high_altitude', 'welding', 'forklift', 'first_aid', 'fire_safety', 'health_exam'
  final String title;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String issuingOrganization;

  SafetyCertificate({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.certificateType,
    required this.title,
    required this.issueDate,
    required this.expiryDate,
    required this.issuingOrganization,
  });

  bool get isExpired => DateTime.now().isAfter(expiryDate);
  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;

  String get statusBadge {
    if (isExpired) return 'SÜRESİ DOLDU (ENGELLENDİ) 🛑';
    if (daysUntilExpiry <= 30) return '$daysUntilExpiry Gün Kaldı ⚠️';
    return 'Geçerli ✅';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'certificateType': certificateType,
        'title': title,
        'issueDate': issueDate.toIso8601String(),
        'expiryDate': expiryDate.toIso8601String(),
        'issuingOrganization': issuingOrganization,
      };

  factory SafetyCertificate.fromJson(Map<String, dynamic> json) => SafetyCertificate(
        id: json['id'] ?? '',
        employeeId: json['employeeId'] ?? 0,
        employeeName: json['employeeName'] ?? '',
        certificateType: json['certificateType'] ?? '',
        title: json['title'] ?? '',
        issueDate: DateTime.tryParse(json['issueDate'] ?? '') ?? DateTime.now(),
        expiryDate: DateTime.tryParse(json['expiryDate'] ?? '') ?? DateTime.now(),
        issuingOrganization: json['issuingOrganization'] ?? '',
      );
}

/// Tehlikeli Bölge ve Zorunlu KKD Alanı (Geofenced Hazard Zone)
class HazardZone {
  final String id;
  final String companyId;
  final String zoneName;
  final List<String> requiredPPE; // 'Baret', 'Çelik Burunlu Ayakkabı', 'Koruyucu Gözlük', 'Kulaklık', 'Emniyet Kemeri'
  final double centerLat;
  final double centerLng;
  final double radiusMeters;
  final String warningMessage;

  HazardZone({
    required this.id,
    required this.companyId,
    required this.zoneName,
    required this.requiredPPE,
    required this.centerLat,
    required this.centerLng,
    this.radiusMeters = 80.0,
    required this.warningMessage,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'zoneName': zoneName,
        'requiredPPE': requiredPPE,
        'centerLat': centerLat,
        'centerLng': centerLng,
        'radiusMeters': radiusMeters,
        'warningMessage': warningMessage,
      };

  factory HazardZone.fromJson(Map<String, dynamic> json) => HazardZone(
        id: json['id'] ?? '',
        companyId: json['companyId'] ?? '',
        zoneName: json['zoneName'] ?? '',
        requiredPPE: json['requiredPPE'] != null ? List<String>.from(json['requiredPPE']) : [],
        centerLat: (json['centerLat'] as num?)?.toDouble() ?? 0.0,
        centerLng: (json['centerLng'] as num?)?.toDouble() ?? 0.0,
        radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 80.0,
        warningMessage: json['warningMessage'] ?? '',
      );
}
