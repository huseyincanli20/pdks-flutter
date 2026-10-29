import 'dart:async';
import 'package:flutter/material.dart';
import 'ios_notification_stub.dart'
    if (dart.library.html) 'ios_notification_web.dart' as helper;

/// Apple iPhone (iOS) Tarzı Push Bildirim ve Ses Yönetim Servisi
class IosNotificationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  /// iPhone Bildirimi Tetikle (Ses + Web Push + iOS Dynamic Island Banner)
  static void showIosNotification({
    required String title,
    required String body,
    IconData? icon,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    // 1. Apple Klasik Bildirim Sesi (Tri-Tone / Glass)
    helper.platformPlayIosChime();

    // 2. Apple Yerel Bildirim Merkezi & Kilit Ekranı (UNUserNotificationCenter / Web Push)
    helper.platformTriggerWebNotification(title: title, body: body);

    // 3. Ekranda iOS Floating Push Banner Göster
    _showInAppIosBanner(
      title: title,
      body: body,
      icon: icon ?? Icons.notifications_active_rounded,
      iconColor: iconColor ?? const Color(0xFF2563EB),
      onTap: onTap,
    );
  }

  /// Apple Yerel Bildirim İznini İste (Kullanıcı Tıklaması ile)
  static Future<bool> requestAppleNotificationPermission() async {
    return await helper.platformRequestNotificationPermission();
  }

  /// Apple Bildirim İzin Durumu
  static String getPermissionStatus() {
    return helper.platformGetNotificationPermissionStatus();
  }

  /// Apple Bildirim Merkezine Test Bildirimi Gönder
  static void sendAppleTestNotification() {
    showIosNotification(
      title: '🍎 Apple Bildirim Merkezi',
      body: 'PDKS bildirimleri Apple Bildirim Merkezinde ve Kilit Ekranında başarıyla gösterilmektedir.',
      icon: Icons.apple_rounded,
      iconColor: const Color(0xFF10B981),
    );
  }

  static void _showInAppIosBanner({
    required String title,
    required String body,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    OverlayState? overlayState;
    try {
      overlayState = navigatorKey.currentState?.overlay;
    } catch (_) {
      // Headless / Unit test ortamlarında sessizce devam et
      return;
    }
    if (overlayState == null) return;

    // Önceki açık bildirimi temizle
    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _IosNotificationBannerWidget(
        title: title,
        body: body,
        icon: icon,
        iconColor: iconColor,
        onTap: () {
          entry.remove();
          _currentEntry = null;
          onTap?.call();
        },
        onDismiss: () {
          entry.remove();
          _currentEntry = null;
        },
      ),
    );

    _currentEntry = entry;
    overlayState.insert(entry);

    // 4.5 saniye sonra otomatik kapan
    _dismissTimer = Timer(const Duration(milliseconds: 4500), () {
      if (_currentEntry == entry) {
        entry.remove();
        _currentEntry = null;
      }
    });
  }
}

class _IosNotificationBannerWidget extends StatefulWidget {
  final String title;
  final String body;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _IosNotificationBannerWidget({
    required this.title,
    required this.body,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_IosNotificationBannerWidget> createState() => _IosNotificationBannerWidgetState();
}

class _IosNotificationBannerWidgetState extends State<_IosNotificationBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _dismissWithAnimation() async {
    await _animController.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: SlideTransition(
            position: _offsetAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: GestureDetector(
                onTap: widget.onTap,
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta != null && details.primaryDelta! < -4) {
                    _dismissWithAnimation();
                  }
                },
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xF2181F2C), // iOS Dark Glass
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.45),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                        BoxShadow(
                          color: widget.iconColor.withOpacity(0.2),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Apple iOS Başlık Çubuğu
                        Row(
                          children: [
                            // PDKS App Simgesi
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white24, width: 0.8),
                              ),
                              child: const Center(
                                child: Text(
                                  'P',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'PDKS',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: Colors.white38,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'ŞİMDİ',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            // Kapatma / Yukarı kaydır ipucu
                            Container(
                              width: 32,
                              height: 3.5,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Bildirim İçeriği
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: widget.iconColor.withOpacity(0.18),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(widget.icon, color: widget.iconColor, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.body,
                                    style: const TextStyle(
                                      color: Color(0xFFCBD5E1),
                                      fontSize: 12,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
