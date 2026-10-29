import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'app_theme_type.dart';

class AppTheme {
  static ThemeData getThemeData(AppThemeType type) {
    switch (type) {
      case AppThemeType.system:
      case AppThemeType.light:
        return lightTheme;
      case AppThemeType.dark:
        return darkTheme;
      case AppThemeType.navy:
        return navyTheme;
      case AppThemeType.emerald:
        return emeraldTheme;
      case AppThemeType.purple:
        return purpleTheme;
      case AppThemeType.amber:
        return amberTheme;
    }
  }

  // 1. AYDINLIK (LIGHT) TEMA
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary);
          }
          return const TextStyle(fontSize: 11, color: AppColors.textSecondary);
        }),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  // 2. KOYU (DARK / AMOLED MIDNIGHT) TEMA
  static ThemeData get darkTheme {
    return _buildCustomDarkTheme(
      scaffoldBg: const Color(0xFF0B0F19),
      surfaceColor: const Color(0xFF1E293B),
      borderColor: const Color(0xFF334155),
      primaryColor: const Color(0xFF3B82F6),
      accentColor: const Color(0xFF60A5FA),
    );
  }

  // 3. DERİN LACİVERT (NAVY OCEAN) TEMA
  static ThemeData get navyTheme {
    return _buildCustomDarkTheme(
      scaffoldBg: const Color(0xFF0A192F),
      surfaceColor: const Color(0xFF112240),
      borderColor: const Color(0xFF233554),
      primaryColor: const Color(0xFF38BDF8),
      accentColor: const Color(0xFF7DD3FC),
    );
  }

  // 4. ZÜMRÜT YEŞİLİ (EMERALD FINANS) TEMA
  static ThemeData get emeraldTheme {
    return _buildCustomDarkTheme(
      scaffoldBg: const Color(0xFF041E15),
      surfaceColor: const Color(0xFF0B382A),
      borderColor: const Color(0xFF165B43),
      primaryColor: const Color(0xFF10B981),
      accentColor: const Color(0xFF34D399),
    );
  }

  // 5. KRALİYET MORU (PURPLE NEBULA) TEMA
  static ThemeData get purpleTheme {
    return _buildCustomDarkTheme(
      scaffoldBg: const Color(0xFF0F0B1E),
      surfaceColor: const Color(0xFF1E1738),
      borderColor: const Color(0xFF332759),
      primaryColor: const Color(0xFFA855F7),
      accentColor: const Color(0xFFC084FC),
    );
  }

  // 6. SICAK KEHRİBAR (AMBER GOLD) TEMA
  static ThemeData get amberTheme {
    return _buildCustomDarkTheme(
      scaffoldBg: const Color(0xFF14120E),
      surfaceColor: const Color(0xFF262118),
      borderColor: const Color(0xFF3D3425),
      primaryColor: const Color(0xFFF59E0B),
      accentColor: const Color(0xFFFBBF24),
    );
  }

  static ThemeData _buildCustomDarkTheme({
    required Color scaffoldBg,
    required Color surfaceColor,
    required Color borderColor,
    required Color primaryColor,
    required Color accentColor,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: scaffoldBg,
      cardColor: surfaceColor,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        error: AppColors.danger,
        onSurface: AppColors.darkTextPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
      ),
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scaffoldBg,
        indicatorColor: primaryColor.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accentColor);
          }
          return const TextStyle(fontSize: 11, color: AppColors.darkTextSecondary);
        }),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }
}
