
/// PDKS Sahte Geçiş & Anomali Kaydı (Anti-Buddy Punching & Fraud Detection)
class PdkAnomalyRecord {
  final String id;
  final String companyId;
  final int employeeId;
  final String employeeName;
  final String anomalyType; // 'buddy_punching_suspected', 'abnormal_overtime_surge', 'frequent_tardiness', 'impossible_travel_gps', 'ghost_shift'
  final String severity; // 'critical', 'warning', 'info'
  final String title;
  final String description;
  final DateTime detectedAt;
  String status; // 'pending', 'investigating', 'resolved', 'dismissed'
  String? resolutionNote;
  final Map<String, dynamic> evidenceData;

  PdkAnomalyRecord({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.employeeName,
    required this.anomalyType,
    required this.severity,
    required this.title,
    required this.description,
    required this.detectedAt,
    this.status = 'pending',
    this.resolutionNote,
    this.evidenceData = const {},
  });

  String get severityLabel {
    switch (severity) {
      case 'critical':
        return 'Kritik Risk 🚨';
      case 'warning':
        return 'Şüpheli Hareket ⚠️';
      default:
        return 'Bilgi / İnceleme ℹ️';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'anomalyType': anomalyType,
        'severity': severity,
        'title': title,
        'description': description,
        'detectedAt': detectedAt.toIso8601String(),
        'status': status,
        'resolutionNote': resolutionNote,
        'evidenceData': evidenceData,
      };

  factory PdkAnomalyRecord.fromJson(Map<String, dynamic> json) => PdkAnomalyRecord(
        id: json['id'] ?? '',
        companyId: json['companyId'] ?? '',
        employeeId: json['employeeId'] ?? 0,
        employeeName: json['employeeName'] ?? '',
        anomalyType: json['anomalyType'] ?? '',
        severity: json['severity'] ?? 'warning',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        detectedAt: DateTime.tryParse(json['detectedAt'] ?? '') ?? DateTime.now(),
        status: json['status'] ?? 'pending',
        resolutionNote: json['resolutionNote'],
        evidenceData: json['evidenceData'] != null ? Map<String, dynamic>.from(json['evidenceData']) : {},
      );
}

/// Akıllı Vardiya Optimizasyon Önerisi (AI Shift Recommendation)
class SmartShiftOptimization {
  final String id;
  final String companyId;
  final String department;
  final String weekLabel;
  final double coverageScorePercent; // e.g. 98.5%
  final double estimatedLaborCostTL;
  final int totalAssignedShifts;
  final List<String> optimizationNotes;
  final bool adheresToLaborLaw4857;

  SmartShiftOptimization({
    required this.id,
    required this.companyId,
    required this.department,
    required this.weekLabel,
    required this.coverageScorePercent,
    required this.estimatedLaborCostTL,
    required this.totalAssignedShifts,
    required this.optimizationNotes,
    this.adheresToLaborLaw4857 = true,
  });
}

/// AI Chat Bot Mesajı (4857 Kanun & PDKS İK Asistanı)
class AiAssistantMessage {
  final String id;
  final bool isUser;
  final String message;
  final DateTime timestamp;
  final String? actionTag; // e.g. 'open_leave', 'view_overtime', 'law_citation'
  final String? actionButtonText;

  AiAssistantMessage({
    required this.id,
    required this.isUser,
    required this.message,
    required this.timestamp,
    this.actionTag,
    this.actionButtonText,
  });
}
