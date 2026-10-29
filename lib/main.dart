import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'models/employee.dart';
import 'state/pdks_state.dart';
import 'views/auth/auth_screen.dart';
import 'views/mobile/mobile_home_screen.dart';
import 'views/hr/hr_shell.dart';
import 'views/boss/boss_shell.dart';
import 'views/admin/admin_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    final themeMode = context.watch<PdksState>().themeMode;

    return MaterialApp(
      title: 'PDKS - Personel Devam Kontrol Sistemi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
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

          // 4 TİP MOD: YALNIZCA GİRİŞ BİLGİLERİNE (ROLE) GÖRE GÖRÜLEBİLİR:
          switch (state.currentUser.role) {
            case UserRole.employee:
              return const MobileHomeScreen(); // 1. PERSONEL MODU
            case UserRole.hr:
              return const HrShell();          // 2. İK (İNSAN KAYNAKLARI) MODU
            case UserRole.boss:
              return const BossShell();        // 3. PATRON (YÖNETİM & CEO) MODU
            case UserRole.admin:
              return const AdminShell();       // 4. ADMİN (SİSTEM YÖNETİCİSİ) MODU
          }
        },
      ),
    );
  }
}
