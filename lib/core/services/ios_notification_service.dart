import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'ios_notification_stub.dart'
    if (dart.library.html) 'ios_notification_web.dart' as helper;

/// Apple iPhone (iOS) Tarzı Push Bildirim ve Ses Yönetim Servisi
class IosNotificationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  /// Kullanıcı Talebi: "uygulamanın içindeki bildirimi gizle"
  /// Varsayılan olarak FALSE (Uygulama içinde gezinirken ekranda açılır bildirim balonu gösterilmez, gizlenir)
  static bool enableInAppBanner = false;

  /// Filtre Kuralı: "sadece mesaj bildirimi ve bir şey onaylandığında bildirim gelsin."
  static bool isAllowedNotification(String title, String body) {
    final lowerTitle = title.toLowerCase();
    final lowerBody = body.toLowerCase();
    final isMessage = lowerTitle.contains('💬') ||
        lowerTitle.contains('mesaj') ||
        lowerBody.contains('mesaj');
    final isApproval = lowerTitle.contains('onay') ||
        lowerBody.contains('onaylandı') ||
        lowerTitle.contains('tebrikler');
    return isMessage || isApproval;
  }

  /// iPhone Bildirimi Tetikle (Apple Notification Center + Tri-Tone Ses)
  /// Sadece mesaj veya onay bildirimlerinde çalışır. Uygulama içi banner gizlidir.
  static void showIosNotification({
    required String title,
    required String body,
    IconData? icon,
    Color? iconColor,
    VoidCallback? onTap,
    bool force = false,
  }) {
    // Kural Kontrolü: Yalnızca Mesaj Bildirimi VEYA Bir Şey Onaylandığında Bildirim Gönder!
    if (!force && !isAllowedNotification(title, body)) {
      return;
    }

    // 1. Apple Klasik Bildirim Sesi (Tri-Tone / Glass)
    helper.platformPlayIosChime();

    // 2. Apple Yerel Bildirim Merkezi & Kilit Ekranı (UNUserNotificationCenter / Web Push)
    helper.platformTriggerWebNotification(title: title, body: body);

    // 3. Ekranda iOS Floating Push Banner Göster (Uygulama içi bildirim)
    // "uygulamanın içindeki bildirimi gizle" kuralı gereğince enableInAppBanner false ise ekrana banner çıkmaz.
    if (enableInAppBanner) {
      _showInAppIosBanner(
        title: title,
        body: body,
        icon: icon ?? Icons.notifications_active_rounded,
        iconColor: iconColor ?? const Color(0xFF2563EB),
        onTap: onTap,
      );
    }
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
      title: '✅ İzin Talebiniz Onaylandı',
      body: 'PDKS test bildirimi: Yıllık izin talebiniz İnsan Kaynakları tarafından onaylanmıştır.',
      icon: Icons.check_circle_rounded,
      iconColor: const Color(0xFF10B981),
      force: true,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xB81A2230), // Apple iOS Kilit Ekranı Cam Efekti
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white.withOpacity(0.18), width: 0.8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Apple iOS Squircle Uygulama İkonu (Screenshot ile birebir)
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  widget.icon,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Bildirim Metin Alanı
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 1. Satır: Uygulama Adı + Zaman Damgası
                                  const Row(
                                    children: [
                                      Text(
                                        'PDKS Enterprise',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      Spacer(),
                                      Text(
                                        'şimdi',
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  // 2. Satır: Bildirim Başlığı (Kalın)
                                  Text(
                                    widget.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  // 3. Satır: Bildirim Detayı
                                  Text(
                                    widget.body,
                                    style: const TextStyle(
                                      color: Color(0xFFE2E8F0),
                                      fontSize: 12.5,
                                      height: 1.25,
                                      letterSpacing: -0.1,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
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
        ),
      ),
    );
  }
}
