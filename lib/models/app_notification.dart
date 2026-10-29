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
    );
  }
}
