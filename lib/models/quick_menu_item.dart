import 'package:flutter/material.dart';

class QuickMenuItem {
  final String id;
  final String title;
  final String subtitle;
  final int iconCode;
  final int colorValue;
  final bool isVisible;
  final String actionType; // 'profile', 'payroll', 'chat', 'contacts', 'notifications', 'cafeteria', 'business_card', 'favorites', 'settings', 'about', 'leave', 'records', 'field_work', 'overtime', 'cloud_db', 'info_dialog'
  final String? customContent;

  const QuickMenuItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconCode,
    required this.colorValue,
    this.isVisible = true,
    this.actionType = 'info_dialog',
    this.customContent,
  });

  IconData get icon => _resolveIcon(iconCode);
  Color get color => Color(colorValue);

  static IconData _resolveIcon(int code) {
    if (code == Icons.directions_car_rounded.codePoint ||
        code == Icons.car_rental_rounded.codePoint ||
        code == Icons.airport_shuttle_rounded.codePoint ||
        code == 0xe1d7 ||
        code == 0xe1d5 ||
        code == 0xf689) {
      return Icons.directions_car_rounded;
    }
    switch (code) {
      case 0xe156:
        return Icons.beach_access_rounded;
      case 0xe314:
        return Icons.history_rounded;
      case 0xe40f:
        return Icons.more_time_rounded;
      case 0xe506:
        return Icons.restaurant_rounded;
      case 0xe425:
        return Icons.near_me_rounded;
      case 0xe3ab:
        return Icons.location_on_rounded;
      case 0xe153:
      case 0xe19a:
        return Icons.chat_bubble_rounded;
      case 0xe44f:
      case 0xe450:
        return Icons.notifications_rounded;
      case 0xe491:
      case 0xe492:
        return Icons.person_rounded;
      case 0xf00ee:
      case 0xe84f:
        return Icons.receipt_long_rounded;
      case 0xe49b:
      case 0xe2eb:
        return Icons.people_alt_rounded;
      case 0xf04ee:
      case 0xe0d6:
        return Icons.badge_rounded;
      case 0xe5f9:
      case 0xe838:
        return Icons.star_rounded;
      case 0xe57f:
      case 0xe8b8:
        return Icons.settings_rounded;
      case 0xe33d:
      case 0xe88e:
        return Icons.info_rounded;
      case 0xe87a:
        return Icons.local_fire_department_rounded;
      case 0xe17f:
        return Icons.cloud_rounded;
      case 0xe3e6:
        return Icons.login_rounded;
      case 0xe88a:
        return Icons.home_work_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  QuickMenuItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    int? iconCode,
    int? colorValue,
    bool? isVisible,
    String? actionType,
    String? customContent,
  }) {
    return QuickMenuItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
      isVisible: isVisible ?? this.isVisible,
      actionType: actionType ?? this.actionType,
      customContent: customContent ?? this.customContent,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'iconCode': iconCode,
    'colorValue': colorValue,
    'isVisible': isVisible,
    'actionType': actionType,
    'customContent': customContent,
  };

  factory QuickMenuItem.fromJson(Map<String, dynamic> json) => QuickMenuItem(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    subtitle: json['subtitle'] ?? '',
    iconCode: json['iconCode'] ?? 0xe156,
    colorValue: json['colorValue'] ?? 0xFF2563EB,
    isVisible: json['isVisible'] ?? true,
    actionType: json['actionType'] ?? 'info_dialog',
    customContent: json['customContent'],
  );
}
