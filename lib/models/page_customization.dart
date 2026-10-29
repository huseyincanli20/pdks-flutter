import 'package:flutter/material.dart';

class PageSectionItem {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  const PageSectionItem({
    required this.id,
    required this.title,
    this.description = '',
    this.icon = Icons.view_quilt_rounded,
  });
}

class PageCustomization {
  final String pageId;
  final String? customTitle;
  final String? customSubtitle;
  final String? announcementText;
  final bool showAnnouncement;
  final Color? accentColor;
  final Set<String> hiddenSectionIds;
  final Map<String, String> customSectionTitles;
  final bool isMaintenanceMode;
  final DateTime updatedAt;

  PageCustomization({
    required this.pageId,
    this.customTitle,
    this.customSubtitle,
    this.announcementText,
    this.showAnnouncement = false,
    this.accentColor,
    Set<String>? hiddenSectionIds,
    Map<String, String>? customSectionTitles,
    this.isMaintenanceMode = false,
    DateTime? updatedAt,
  })  : hiddenSectionIds = hiddenSectionIds ?? {},
        customSectionTitles = customSectionTitles ?? {},
        updatedAt = updatedAt ?? DateTime.now();

  bool isSectionHidden(String sectionId) => hiddenSectionIds.contains(sectionId);

  PageCustomization copyWith({
    String? pageId,
    String? customTitle,
    String? customSubtitle,
    String? announcementText,
    bool? showAnnouncement,
    Color? accentColor,
    Set<String>? hiddenSectionIds,
    Map<String, String>? customSectionTitles,
    bool? isMaintenanceMode,
    DateTime? updatedAt,
  }) {
    return PageCustomization(
      pageId: pageId ?? this.pageId,
      customTitle: customTitle ?? this.customTitle,
      customSubtitle: customSubtitle ?? this.customSubtitle,
      announcementText: announcementText ?? this.announcementText,
      showAnnouncement: showAnnouncement ?? this.showAnnouncement,
      accentColor: accentColor ?? this.accentColor,
      hiddenSectionIds: hiddenSectionIds ?? Set.from(this.hiddenSectionIds),
      customSectionTitles: customSectionTitles ?? Map.from(this.customSectionTitles),
      isMaintenanceMode: isMaintenanceMode ?? this.isMaintenanceMode,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'pageId': pageId,
    'customTitle': customTitle,
    'customSubtitle': customSubtitle,
    'announcementText': announcementText,
    'showAnnouncement': showAnnouncement,
    'accentColor': accentColor?.value,
    'hiddenSectionIds': hiddenSectionIds.toList(),
    'customSectionTitles': customSectionTitles,
    'isMaintenanceMode': isMaintenanceMode,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory PageCustomization.fromJson(Map<String, dynamic> json) => PageCustomization(
    pageId: json['pageId'] ?? '',
    customTitle: json['customTitle'],
    customSubtitle: json['customSubtitle'],
    announcementText: json['announcementText'],
    showAnnouncement: json['showAnnouncement'] ?? false,
    accentColor: json['accentColor'] != null ? Color(json['accentColor'] as int) : null,
    hiddenSectionIds: (json['hiddenSectionIds'] as List<dynamic>?)?.map((e) => e.toString()).toSet() ?? {},
    customSectionTitles: (json['customSectionTitles'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v.toString())) ?? {},
    isMaintenanceMode: json['isMaintenanceMode'] ?? false,
    updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now() : DateTime.now(),
  );
}
