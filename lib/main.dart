import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_type.dart';
import 'core/services/ios_notification_service.dart';
import 'core/services/database_service.dart';
import 'models/employee.dart';
import 'state/pdks_state.dart';
import 'views/auth/auth_screen.dart';
import 'views/mobile/mobile_home_screen.dart';
import 'views/hr/hr_shell.dart';
import 'views/boss/boss_shell.dart';
import 'views/admin/admin_shell.dart';
import 'views/cafeteria/cafeteria_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService().init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => PdksState(),
      child: const PdksApp(),
    ),
  );
}

class PdksApp extends StatelessWidget {
  const PdksApp({super.key});

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final themeData = pdks.activeThemeData;
    final themeMode = pdks.themeMode;

    return MaterialApp(
      navigatorKey: IosNotificationService.navigatorKey,
      title: 'PDKS - Personel Devam Kontrol Sistemi',
      debugShowCheckedModeBanner: false,
      theme: pdks.currentTheme == AppThemeType.system ? AppTheme.lightTheme : themeData,
      darkTheme: pdks.currentTheme == AppThemeType.system ? AppTheme.darkTheme : themeData,
      themeMode: themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      home: Consumer<PdksState>(
        builder: (context, state, _) {
          // Kullanıcı giriş yapmadıysa Giriş/Kayıt ekranını göster
          if (!state.isLoggedIn) {
            return const AuthScreen();
          }

          // 5 TİP MOD: YALNIZCA GİRİŞ BİLGİLERİNE (ROLE) GÖRE GÖRÜLEBİLİR:
          switch (state.currentUser.role) {
            case UserRole.employee:
              return const MobileHomeScreen(); // 1. PERSONEL MODU
            case UserRole.hr:
              return const HrShell();          // 2. İK (İNSAN KAYNAKLARI) MODU
            case UserRole.boss:
              return const BossShell();        // 3. PATRON (YÖNETİM & CEO) MODU
            case UserRole.admin:
              return const AdminShell();       // 4. ADMİN (SİSTEM YÖNETİCİSİ) MODU
            case UserRole.cafeteria:
              return const CafeteriaShell();   // 5. YEMEKHANE PERSONELİ MODU
          }
        },
      ),
    );
  }
}
