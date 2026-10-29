import 'package:flutter/material.dart';

enum NotificationType {
  announcement,
  attendance,
  leave,
  cafeteria,
  system,
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType type;
  final IconData icon;
  final Color color;
  final String? targetPhone;
  final String? targetEmail;
  final bool isPushSent;
  final bool isSmsSent;
  final bool isEmailSent;
  final String? emailSubject;
  final String? emailBody;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    required this.type,
    required this.icon,
    required this.color,
    this.targetPhone,
    this.targetEmail,
    this.isPushSent = false,
    this.isSmsSent = false,
    this.isEmailSent = false,
    this.emailSubject,
    this.emailBody,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    NotificationType? type,
    IconData? icon,
    Color? color,
    String? targetPhone,
    String? targetEmail,
    bool? isPushSent,
    bool? isSmsSent,
    bool? isEmailSent,
    String? emailSubject,
    String? emailBody,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      targetPhone: targetPhone ?? this.targetPhone,
      targetEmail: targetEmail ?? this.targetEmail,
      isPushSent: isPushSent ?? this.isPushSent,
      isSmsSent: isSmsSent ?? this.isSmsSent,
      isEmailSent: isEmailSent ?? this.isEmailSent,
      emailSubject: emailSubject ?? this.emailSubject,
      emailBody: emailBody ?? this.emailBody,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type.name,
      'iconCode': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'colorValue': color.value,
      'targetPhone': targetPhone,
      'targetEmail': targetEmail,
      'isPushSent': isPushSent,
      'isSmsSent': isSmsSent,
      'isEmailSent': isEmailSent,
      'emailSubject': emailSubject,
      'emailBody': emailBody,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    NotificationType parsedType = NotificationType.system;
    try {
      parsedType = NotificationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => NotificationType.system,
      );
    } catch (_) {}

    IconData parsedIcon = Icons.notifications_rounded;
    if (json['iconCode'] != null) {
      parsedIcon = IconData(
        json['iconCode'] as int,
        fontFamily: json['iconFontFamily'] as String? ?? 'MaterialIcons',
        fontPackage: json['iconFontPackage'] as String?,
      );
    }

    Color parsedColor = const Color(0xFF2563EB);
    if (json['colorValue'] != null) {
      parsedColor = Color(json['colorValue'] as int);
    }

    return AppNotification(
      id: json['id']?.toString() ?? 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      isRead: json['isRead'] ?? false,
      type: parsedType,
      icon: parsedIcon,
      color: parsedColor,
      targetPhone: json['targetPhone'],
      targetEmail: json['targetEmail'],
      isPushSent: json['isPushSent'] ?? false,
      isSmsSent: json['isSmsSent'] ?? false,
      isEmailSent: json['isEmailSent'] ?? false,
      emailSubject: json['emailSubject'],
      emailBody: json['emailBody'],
    );
  }
}
