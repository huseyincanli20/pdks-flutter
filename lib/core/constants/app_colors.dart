import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF2563EB); // Royal Blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF60A5FA);

  static const Color secondary = Color(0xFF0F172A); // Dark Slate
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;

  // Dark Theme Colors (Yüksek Zıtlık / High Contrast)
  static const Color darkBackground = Color(0xFF090D16); // Deep AMOLED Midnight Obsidian
  static const Color darkSurface = Color(0xFF131B2A);    // Rich Dark Slate
  static const Color darkBorder = Color(0xFF28364A);     // High Contrast Dark Border
  static const Color darkDivider = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFFFFFFF); // Kristal Beyaz (Maksimum Zıtlık)
  static const Color darkTextSecondary = Color(0xFFCBD5E1); // Parlak Gümüş Slate (Net Okunabilir Zıt Renk)
  static const Color darkTextMuted = Color(0xFF94A3B8);

  // Status Colors
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color danger = Color(0xFFEF4444);  // Crimson Red
  static const Color info = Color(0xFF0EA5E9);    // Sky Blue

  // Grayscale & Borders (Light)
  static const Color textPrimary = Color(0xFF0F172A); // Derin Siyah Slate (Aydınlık Modda Net Zıtlık)
  static const Color textSecondary = Color(0xFF334155); // Koyu Grafit Slate (Yüksek Okunabilirlik)
  static const Color textMuted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // Dynamic Context-Aware Colors (Light / Dark / Custom Themes)
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static Color primaryOf(BuildContext context) => Theme.of(context).primaryColor;

  static Color bg(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  static Color cardBg(BuildContext context) =>
      Theme.of(context).cardTheme.color ?? (isDark(context) ? darkSurface : Colors.white);

  static Color cardBorder(BuildContext context) {
    final borderSide = Theme.of(context).cardTheme.shape is RoundedRectangleBorder
        ? (Theme.of(context).cardTheme.shape as RoundedRectangleBorder).side
        : null;
    return borderSide?.color ?? (isDark(context) ? darkBorder : border);
  }

  static Color text(BuildContext context) =>
      isDark(context) ? darkTextPrimary : textPrimary;

  static Color textSub(BuildContext context) =>
      isDark(context) ? darkTextSecondary : textSecondary;

  static Color subtle(BuildContext context) =>
      isDark(context) ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

  static Color inputBg(BuildContext context) =>
      Theme.of(context).inputDecorationTheme.fillColor ?? (isDark(context) ? darkSurface : const Color(0xFFFFFFFF));

  // Gradient accents
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
