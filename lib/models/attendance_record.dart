enum AttendanceType { checkIn, checkOut, breakStart, breakEnd }

enum VerificationMethod { qrCode, geofenceGps, wifiIp, biometricKiosk }

class AttendanceRecord {
  final int id;
  final int employeeId;
  final String employeeName;
  final AttendanceType type;
  final DateTime timestamp;
  final double? userLatitude;
  final double? userLongitude;
  final double calculatedDistanceMeters;
  final bool isLocationVerified;
  final VerificationMethod verificationMethod;
  final String? deviceInfo;
  final String? note;

  AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.type,
    required this.timestamp,
    this.userLatitude,
    this.userLongitude,
    required this.calculatedDistanceMeters,
    required this.isLocationVerified,
    required this.verificationMethod,
    this.deviceInfo,
    this.note,
  });

  String get typeLabel {
    switch (type) {
      case AttendanceType.checkIn:
        return 'Giriş';
      case AttendanceType.checkOut:
        return 'Çıkış';
      case AttendanceType.breakStart:
        return 'Mola Başlangıcı';
      case AttendanceType.breakEnd:
        return 'Mola Bitişi';
    }
  }

  String get methodLabel {
    switch (verificationMethod) {
      case VerificationMethod.qrCode:
        return 'Dinamik QR Kod';
      case VerificationMethod.geofenceGps:
        return 'GPS / Geofencing';
      case VerificationMethod.wifiIp:
        return 'Ofis Wi-Fi / IP';
      case VerificationMethod.biometricKiosk:
        return 'Kiosk / Biyometrik';
    }
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? 0,
      employeeId: json['employeeId'] ?? 0,
      employeeName: json['employeeName'] ?? 'Personel',
      type: json['type'] == 'checkIn' || json['type'] == 0
          ? AttendanceType.checkIn
          : AttendanceType.checkOut,
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      userLatitude: (json['userLatitude'] as num?)?.toDouble(),
      userLongitude: (json['userLongitude'] as num?)?.toDouble(),
      calculatedDistanceMeters: (json['calculatedDistanceMeters'] as num?)?.toDouble() ?? 0.0,
      isLocationVerified: json['isLocationVerified'] ?? true,
      verificationMethod: VerificationMethod.values.firstWhere(
        (e) => e.name == json['verificationMethod'],
        orElse: () => VerificationMethod.geofenceGps,
      ),
      deviceInfo: json['deviceInfo'],
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'userLatitude': userLatitude,
      'userLongitude': userLongitude,
      'calculatedDistanceMeters': calculatedDistanceMeters,
      'isLocationVerified': isLocationVerified,
      'verificationMethod': verificationMethod.name,
      'deviceInfo': deviceInfo,
      'note': note,
    };
  }
}
