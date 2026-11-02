import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Deitirilemez Denetim Kayd (Immutable Audit Log)
/// SRS Blm 3 - Veri Gvenlii ve KVKK Uyumluluu gereksinimi
class AuditLogRecord {
  final String id;
  final String companyId;
  final int userId;
  final String userName;
  final String userRole;
  final String ipAddress;
  final DateTime timestamp;
  final String actionType; // 'Giri-k', 'zin Onay', 'Mesai Onay', 'Dnem Kilidi', 'Karantina', ' Gruptan karma', 'Mesaj Silme', ' Kalibrasyon Gncellendi'
  final String targetEntity; // 'AttendanceRecord', 'LeaveRequest', 'EquipmentRecord', 'ChatMessage', 'Payroll'
  final String? entityId;
  final String? oldValue;
  final String? newValue;
  final String hashSignature; // SHA-256 blok btnlk imzas

  AuditLogRecord({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.userName,
    required this.userRole,
    this.ipAddress = '192.168.1.105',
    DateTime? timestamp,
    required this.actionType,
    required this.targetEntity,
    this.entityId,
    this.oldValue,
    this.newValue,
    String? hashSignature,
  })  : timestamp = timestamp ?? DateTime.now(),
        hashSignature = hashSignature ??
            _generateSignature(
              id,
              userId,
              actionType,
              targetEntity,
              oldValue,
              newValue,
              timestamp ?? DateTime.now(),
            );

  static String _generateSignature(
    String id,
    int userId,
    String action,
    String entity,
    String? oldVal,
    String? newVal,
    DateTime time,
  ) {
    final payload = '$id|$userId|$action|$entity|${oldVal ?? ''}|${newVal ?? ''}|${time.toIso8601String()}|SECURE_SALT_KVKK_4857';
    return sha256.convert(utf8.encode(payload)).toString();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'userId': userId,
        'userName': userName,
        'userRole': userRole,
        'ipAddress': ipAddress,
        'timestamp': timestamp.toIso8601String(),
        'actionType': actionType,
        'targetEntity': targetEntity,
        'entityId': entityId,
        'oldValue': oldValue,
        'newValue': newValue,
        'hashSignature': hashSignature,
      };

  factory AuditLogRecord.fromJson(Map<String, dynamic> json) => AuditLogRecord(
        id: json['id'] ?? '',
        companyId: json['companyId'] ?? 'cmp_acme',
        userId: (json['userId'] as num?)?.toInt() ?? 0,
        userName: json['userName'] ?? '',
        userRole: json['userRole'] ?? '',
        ipAddress: json['ipAddress'] ?? '127.0.0.1',
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'])
            : null,
        actionType: json['actionType'] ?? 'LEM',
        targetEntity: json['targetEntity'] ?? '',
        entityId: json['entityId'],
        oldValue: json['oldValue'],
        newValue: json['newValue'],
        hashSignature: json['hashSignature'],
      );
}
