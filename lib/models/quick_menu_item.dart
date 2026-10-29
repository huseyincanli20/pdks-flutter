import 'package:flutter/material.dart';

class QuickMenuItem {
  final String id;
  final String title;
  final String subtitle;
  final int iconCode;
  final int colorValue;
  final bool isVisible;
  final String actionType; // 'leave', 'records', 'overtime', 'field_work', 'cafeteria', 'info_dialog'
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
        return Icons.campaign_rounded;
      case 0xe84f:
        return Icons.account_balance_wallet_rounded;
      case 0xe2eb:
        return Icons.groups_rounded;
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
