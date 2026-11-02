/// Yüz Tanıma & Canlılık (Face Liveness & Biometric Enrollment)
class FaceEnrollment {
  final int employeeId;
  final String employeeName;
  final String faceVectorHash; // 128/512 boyutlu yüz embedding özet hash'i
  final DateTime enrolledAt;
  final bool isLivenessVerified; // Göz kırpma / Canlılık doğrulaması
  final double confidenceScore;

  FaceEnrollment({
    required this.employeeId,
    required this.employeeName,
    required this.faceVectorHash,
    required this.enrolledAt,
    this.isLivenessVerified = true,
    this.confidenceScore = 0.985,
  });

  Map<String, dynamic> toJson() => {
        'employeeId': employeeId,
        'employeeName': employeeName,
        'faceVectorHash': faceVectorHash,
        'enrolledAt': enrolledAt.toIso8601String(),
        'isLivenessVerified': isLivenessVerified,
        'confidenceScore': confidenceScore,
      };

  factory FaceEnrollment.fromJson(Map<String, dynamic> json) => FaceEnrollment(
        employeeId: json['employeeId'] ?? 0,
        employeeName: json['employeeName'] ?? '',
        faceVectorHash: json['faceVectorHash'] ?? '',
        enrolledAt: DateTime.tryParse(json['enrolledAt'] ?? '') ?? DateTime.now(),
        isLivenessVerified: json['isLivenessVerified'] ?? true,
        confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.985,
      );
}

/// Turnike / Kiosk Donanım Terminali (TCP/IP & Duvar Tableti)
class KioskTerminal {
  final String terminalId;
  final String companyId;
  final String terminalName;
  final String location;
  final String ipAddress;
  final int tcpPort;
  final String mode; // 'facial', 'rfid_card', 'qr_barcode', 'hybrid'
  final bool isOnline;
  final DateTime lastHeartbeat;
  final int totalScansToday;

  KioskTerminal({
    required this.terminalId,
    required this.companyId,
    required this.terminalName,
    required this.location,
    required this.ipAddress,
    this.tcpPort = 4370, // ZKTeco default port
    this.mode = 'hybrid',
    this.isOnline = true,
    required this.lastHeartbeat,
    this.totalScansToday = 142,
  });

  Map<String, dynamic> toJson() => {
        'terminalId': terminalId,
        'companyId': companyId,
        'terminalName': terminalName,
        'location': location,
        'ipAddress': ipAddress,
        'tcpPort': tcpPort,
        'mode': mode,
        'isOnline': isOnline,
        'lastHeartbeat': lastHeartbeat.toIso8601String(),
        'totalScansToday': totalScansToday,
      };

  factory KioskTerminal.fromJson(Map<String, dynamic> json) => KioskTerminal(
        terminalId: json['terminalId'] ?? '',
        companyId: json['companyId'] ?? '',
        terminalName: json['terminalName'] ?? '',
        location: json['location'] ?? '',
        ipAddress: json['ipAddress'] ?? '',
        tcpPort: json['tcpPort'] ?? 4370,
        mode: json['mode'] ?? 'hybrid',
        isOnline: json['isOnline'] ?? true,
        lastHeartbeat: DateTime.tryParse(json['lastHeartbeat'] ?? '') ?? DateTime.now(),
        totalScansToday: json['totalScansToday'] ?? 0,
      );
}

/// Turnike Kapı Geçiş Olay Telemetrisi
class TurnstileTelemetry {
  final String eventId;
  final String terminalId;
  final int employeeId;
  final String employeeName;
  final String scanMethod; // 'face_liveness', 'rfid', 'qr_code', 'pin'
  final bool accessGranted;
  final String direction; // 'in', 'out'
  final DateTime timestamp;
  final String? denialReason;

  TurnstileTelemetry({
    required this.eventId,
    required this.terminalId,
    required this.employeeId,
    required this.employeeName,
    required this.scanMethod,
    required this.accessGranted,
    required this.direction,
    required this.timestamp,
    this.denialReason,
  });
}
