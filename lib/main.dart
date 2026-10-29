import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/responsive_layout.dart';
import 'state/pdks_state.dart';
import 'views/mobile/mobile_home_screen.dart';
import 'views/web_admin/admin_shell.dart';
import 'views/kiosk/kiosk_screen.dart';
import 'views/auth/auth_screen.dart';

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
    return MaterialApp(
      title: 'PDKS - Personel Devam Kontrol Sistemi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
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
          return state.isLoggedIn ? const MainAdaptiveRoot() : const AuthScreen();
        },
      ),
    );
  }
}

class MainAdaptiveRoot extends StatefulWidget {
  const MainAdaptiveRoot({super.key});

  @override
  State<MainAdaptiveRoot> createState() => _MainAdaptiveRootState();
}

class _MainAdaptiveRootState extends State<MainAdaptiveRoot> {
  // Demo modları: 'auto', 'mobile', 'web_admin', 'kiosk'
  String _activeViewMode = 'auto';

  @override
  Widget build(BuildContext context) {
    Widget currentWidget;

    if (_activeViewMode == 'mobile') {
      currentWidget = const MobileHomeScreen();
    } else if (_activeViewMode == 'web_admin') {
      currentWidget = AdminShell(
        onSwitchToMobile: () => setState(() => _activeViewMode = 'mobile'),
        onSwitchToKiosk: () => setState(() => _activeViewMode = 'kiosk'),
      );
    } else if (_activeViewMode == 'kiosk') {
      currentWidget = const KioskScreen();
    } else {
      // Auto: Ekrana göre otomatik karar ver
      currentWidget = ResponsiveLayout(
        mobile: const MobileHomeScreen(),
        desktop: AdminShell(
          onSwitchToMobile: () => setState(() => _activeViewMode = 'mobile'),
          onSwitchToKiosk: () => setState(() => _activeViewMode = 'kiosk'),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          currentWidget,

          // Sağ üstte hızlı platform değiştirme çubuğu (iOS/Android/Web/Kiosk simülasyonu)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPlatformChip('Oto', 'auto'),
                  _buildPlatformChip('Mobil (iOS/Android)', 'mobile'),
                  _buildPlatformChip('Web İK Paneli', 'web_admin'),
                  _buildPlatformChip('Tablet Kiosk', 'kiosk'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformChip(String label, String mode) {
    final isSelected = _activeViewMode == mode;
    return InkWell(
      onTap: () => setState(() => _activeViewMode = mode),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
