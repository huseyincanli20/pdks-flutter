import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdks_flutter/core/constants/app_colors.dart';
import 'package:pdks_flutter/core/theme/app_theme.dart';
import 'package:pdks_flutter/core/theme/app_theme_type.dart';
import 'package:pdks_flutter/models/app_notification.dart';
import 'package:pdks_flutter/state/pdks_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('İki Tema (Aydınlık & Koyu) ve Zıtlık Test Paketi', () {
    test('1. Sadece 2 adet tema türü bulunmalı (light ve dark)', () {
      expect(AppThemeType.values.length, 2);
      expect(AppThemeType.values, contains(AppThemeType.light));
      expect(AppThemeType.values, contains(AppThemeType.dark));
    });

    test('2. Aydınlık Tema yüksek kontrastlı ve ferah beyaz olmalı', () {
      final lightTheme = AppTheme.lightTheme;
      expect(lightTheme.brightness, Brightness.light);
      expect(lightTheme.scaffoldBackgroundColor, AppColors.background);
      expect(lightTheme.colorScheme.onSurface, AppColors.textPrimary);
      expect(lightTheme.primaryColor, const Color(0xFF2563EB));
    });

    test('3. Koyu Tema AMOLED siyahı ve yüksek kontrastlı beyaz/cyan olmalı', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.brightness, Brightness.dark);
      expect(darkTheme.scaffoldBackgroundColor, AppColors.darkBackground);
      expect(darkTheme.cardColor, AppColors.darkSurface);
      expect(darkTheme.colorScheme.onSurface, AppColors.darkTextPrimary);
      expect(darkTheme.primaryColor, const Color(0xFF38BDF8));
    });

    test('4. PdksState içinde tema değiştirme ve toggleTheme düzgün çalışmalı', () {
      final state = PdksState();
      // Başlangıç teması aydınlık
      state.setTheme(AppThemeType.light);
      expect(state.currentTheme, AppThemeType.light);
      expect(state.themeMode, ThemeMode.light);

      // Koyu temaya geçiş
      state.toggleTheme();
      expect(state.currentTheme, AppThemeType.dark);
      expect(state.themeMode, ThemeMode.dark);

      // Tekrar aydınlık temaya dönüş
      state.toggleTheme();
      expect(state.currentTheme, AppThemeType.light);
      expect(state.themeMode, ThemeMode.light);
    });
  });

  group('Bildirimleri Silme Test Paketi', () {
    late PdksState state;

    setUp(() {
      state = PdksState();
    });

    test('1. Tekil Bildirim Silme (deleteNotification) Başarıyla Çalışmalı', () {
      final notif1 = AppNotification(
        id: 'test_notif_1',
        title: 'Toplantı Hatırlatması',
        message: '14:00 İK koordinasyon toplantısı.',
        timestamp: DateTime.now(),
        type: NotificationType.announcement,
        icon: Icons.campaign_rounded,
        color: const Color(0xFF10B981),
      );
      final notif2 = AppNotification(
        id: 'test_notif_2',
        title: 'İzin Talebi Onayı',
        message: 'Yıllık izin talebiniz onaylandı.',
        timestamp: DateTime.now(),
        type: NotificationType.leave,
        icon: Icons.beach_access_rounded,
        color: const Color(0xFF2563EB),
      );

      state.addNotification(notif1);
      state.addNotification(notif2);

      expect(state.notifications.any((n) => n.id == 'test_notif_1'), isTrue);
      expect(state.notifications.any((n) => n.id == 'test_notif_2'), isTrue);

      // notif1 siliniyor
      state.deleteNotification('test_notif_1');

      expect(state.notifications.any((n) => n.id == 'test_notif_1'), isFalse);
      expect(state.notifications.any((n) => n.id == 'test_notif_2'), isTrue);
    });

    test('2. Tüm Bildirimleri Temizle / Sil (clearAllNotifications) Başarıyla Çalışmalı', () {
      state.addNotification(AppNotification(
        id: 'clear_test_1',
        title: 'Test 1',
        message: 'Mesaj 1',
        timestamp: DateTime.now(),
        type: NotificationType.system,
        icon: Icons.notifications,
        color: Colors.blue,
      ));
      state.addNotification(AppNotification(
        id: 'clear_test_2',
        title: 'Test 2',
        message: 'Mesaj 2',
        timestamp: DateTime.now(),
        type: NotificationType.system,
        icon: Icons.notifications,
        color: Colors.blue,
      ));

      expect(state.notifications.isNotEmpty, isTrue);

      state.clearAllNotifications();

      expect(state.notifications.isEmpty, isTrue);
    });
  });
}
