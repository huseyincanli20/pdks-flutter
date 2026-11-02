import 'package:flutter/material.dart';

enum AppThemeType {
  light,
  dark,
}

extension AppThemeTypeExtension on AppThemeType {
  String get title {
    switch (this) {
      case AppThemeType.light:
        return 'Aydınlık Tema';
      case AppThemeType.dark:
        return 'Koyu Tema (AMOLED Gece)';
    }
  }

  String get subtitle {
    switch (this) {
      case AppThemeType.light:
        return 'Ferah, parlak ve yüksek kontrastlı klasik beyaz gündüz arayüzü';
      case AppThemeType.dark:
        return 'Derin siyah OLED zıt tonlar, göz konforu ve batarya tasarrufu';
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemeType.light:
        return Icons.light_mode_rounded;
      case AppThemeType.dark:
        return Icons.dark_mode_rounded;
    }
  }

  Color get primaryColor {
    switch (this) {
      case AppThemeType.light:
        return const Color(0xFF2563EB); // Royal Blue
      case AppThemeType.dark:
        return const Color(0xFF38BDF8); // Electric Sky Blue (Yüksek Zıtlık)
    }
  }

  Color get previewBg {
    switch (this) {
      case AppThemeType.light:
        return const Color(0xFFFFFFFF);
      case AppThemeType.dark:
        return const Color(0xFF090D16);
    }
  }

  bool get isDarkTheme {
    switch (this) {
      case AppThemeType.light:
        return false;
      case AppThemeType.dark:
        return true;
    }
  }
}

