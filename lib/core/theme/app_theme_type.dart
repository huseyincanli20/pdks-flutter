import 'package:flutter/material.dart';

enum AppThemeType {
  system,
  light,
  dark,
  navy,
  emerald,
  purple,
  amber,
}

extension AppThemeTypeExtension on AppThemeType {
  String get title {
    switch (this) {
      case AppThemeType.system:
        return 'Sistem Varsayılanı';
      case AppThemeType.light:
        return 'Aydınlık (Klasik)';
      case AppThemeType.dark:
        return 'Koyu (AMOLED Gece)';
      case AppThemeType.navy:
        return 'Derin Lacivert (Okyanus)';
      case AppThemeType.emerald:
        return 'Zümrüt Yeşili (Finans)';
      case AppThemeType.purple:
        return 'Kraliyet Moru (Nebula)';
      case AppThemeType.amber:
        return 'Sıcak Kehribar (Altın)';
    }
  }

  String get subtitle {
    switch (this) {
      case AppThemeType.system:
        return 'Telefonun (iOS / Android) temasını otomatik takip eder';
      case AppThemeType.light:
        return 'Ferah, parlak ve klasik beyaz gündüz arayüzü';
      case AppThemeType.dark:
        return 'Derin siyah OLED tonları, göz konforu ve batarya tasarrufu';
      case AppThemeType.navy:
        return 'Prestijli kurumsal derin okyanus mavisi ve lacivert tonlar';
      case AppThemeType.emerald:
        return 'Zümrüt yeşili ve koyu çam vurgularıyla modern iş teması';
      case AppThemeType.purple:
        return 'Lila ve neon mor vurgularla fütüristik siber tema';
      case AppThemeType.amber:
        return 'Sıcak altın ve kehribar vurgularıyla lüks yönetici teması';
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemeType.system:
        return Icons.brightness_auto_rounded;
      case AppThemeType.light:
        return Icons.light_mode_rounded;
      case AppThemeType.dark:
        return Icons.dark_mode_rounded;
      case AppThemeType.navy:
        return Icons.water_drop_rounded;
      case AppThemeType.emerald:
        return Icons.eco_rounded;
      case AppThemeType.purple:
        return Icons.auto_awesome_rounded;
      case AppThemeType.amber:
        return Icons.workspace_premium_rounded;
    }
  }

  Color get primaryColor {
    switch (this) {
      case AppThemeType.system:
        return const Color(0xFF2563EB);
      case AppThemeType.light:
        return const Color(0xFF2563EB);
      case AppThemeType.dark:
        return const Color(0xFF3B82F6);
      case AppThemeType.navy:
        return const Color(0xFF0284C7); // Sky/Navy
      case AppThemeType.emerald:
        return const Color(0xFF10B981); // Emerald
      case AppThemeType.purple:
        return const Color(0xFF8B5CF6); // Purple
      case AppThemeType.amber:
        return const Color(0xFFF59E0B); // Amber
    }
  }

  Color get previewBg {
    switch (this) {
      case AppThemeType.system:
        return const Color(0xFFF1F5F9);
      case AppThemeType.light:
        return const Color(0xFFFFFFFF);
      case AppThemeType.dark:
        return const Color(0xFF0B0F19);
      case AppThemeType.navy:
        return const Color(0xFF0A192F);
      case AppThemeType.emerald:
        return const Color(0xFF06281E);
      case AppThemeType.purple:
        return const Color(0xFF1A102F);
      case AppThemeType.amber:
        return const Color(0xFF1C1917);
    }
  }

  bool get isDarkTheme {
    switch (this) {
      case AppThemeType.light:
        return false;
      case AppThemeType.dark:
      case AppThemeType.navy:
      case AppThemeType.emerald:
      case AppThemeType.purple:
      case AppThemeType.amber:
        return true;
      case AppThemeType.system:
        return false; // Dynamic
    }
  }
}
