import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/app_notification.dart';
import '../../state/pdks_state.dart';
import '../../core/services/ios_notification_service.dart';
import '../cafeteria/cafeteria_menu_view_screen.dart';
import '../mobile/leave_request_screen.dart';
import '../common/email_preview_dialog.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'all';
  bool _isAppleLockScreenMode = true; // Kullanıcının istediği iOS Kilit Ekranı varsayılan
  bool _isFlashlightOn = false;

  String _formatLockScreenDate(DateTime dt) {
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    const months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    final dayName = days[(dt.weekday - 1).clamp(0, 6)];
    final monthName = months[(dt.month - 1).clamp(0, 11)];
    return '${dt.day} $monthName $dayName';
  }

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk. önce';
    if (diff.inHours < 24) return '${diff.inHours} sa. önce';
    return '${diff.inDays} gün önce';
  }

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allNotifications = pdks.notifications;
    // Kullanıcı Kuralı: "sadece mesaj bildirimi ve bir şey onaylandığında bildirim gelsin."
    final messageAndApprovalNotifications = allNotifications.where((n) => n.isAllowedForDisplay).toList();

    List<AppNotification> filtered = messageAndApprovalNotifications;

    if (_selectedFilter == 'unread') {
      filtered = messageAndApprovalNotifications.where((n) => !n.isRead).toList();
    } else if (_selectedFilter == 'approvals') {
      filtered = messageAndApprovalNotifications.where((n) => n.isApproval).toList();
    } else if (_selectedFilter == 'messages') {
      filtered = messageAndApprovalNotifications.where((n) => n.isMessage).toList();
    } else if (_selectedFilter == 'all_history') {
      filtered = allNotifications;
    }

    return Scaffold(
      backgroundColor: _isAppleLockScreenMode ? const Color(0xFF090D14) : AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: _isAppleLockScreenMode ? const Color(0xFF0F172A) : null,
        title: Text(
          _isAppleLockScreenMode ? '🍎 Apple Kilit Ekranı' : 'Bildirimler',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          // Görünüm Modu Değiştirici (Apple Kilit Ekranı <-> Standart Liste)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: _isAppleLockScreenMode
                  ? Colors.white.withOpacity(0.12)
                  : AppColors.primaryOf(context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isAppleLockScreenMode
                    ? Colors.white.withOpacity(0.2)
                    : AppColors.primaryOf(context).withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => setState(() => _isAppleLockScreenMode = true),
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isAppleLockScreenMode ? const Color(0xFF2563EB) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.apple_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Kilit Ekranı',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _isAppleLockScreenMode = false),
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: !_isAppleLockScreenMode ? const Color(0xFF2563EB) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.view_agenda_rounded,
                          size: 16,
                          color: !_isAppleLockScreenMode ? Colors.white : Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Liste',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: !_isAppleLockScreenMode ? Colors.white : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          if (!_isAppleLockScreenMode && pdks.unreadNotificationsCount > 0)
            IconButton(
              tooltip: 'Tümünü Okundu Say',
              icon: const Icon(Icons.done_all_rounded, size: 20),
              onPressed: () {
                pdks.markAllNotificationsAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text('Tüm bildirimler okundu olarak işaretlendi.'),
                  ),
                );
              },
            ),
        ],
      ),
      body: _isAppleLockScreenMode
          ? _buildAppleLockScreenView(context, filtered, pdks)
          : _buildStandardListView(context, filtered, allNotifications, messageAndApprovalNotifications, pdks, isDark),
    );
  }

  // ==========================================
  // 1. APPLE KİLİT EKRANI (Screenshot ile Birebir)
  // ==========================================
  Widget _buildAppleLockScreenView(BuildContext context, List<AppNotification> notifications, PdksState pdks) {
    final now = DateTime.now();
    // Örnek: "29 Eki Per" veya bugünün canlı tarihi (Özel Türkçe formatlayıcı ile)
    final dateStr = _formatLockScreenDate(now);
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2A1520), // Ekrandaki koyu mürdüm / bordo ton
            Color(0xFF161C26), // Orta derin lacivert
            Color(0xFF090D14), // Dip koyu siyah
          ],
        ),
      ),
      child: Stack(
        children: [
          // Fener açıldığında hafif ışık huzmesi efekti
          if (_isFlashlightOn)
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.08),
              ),
            ),

          // Ana Kaydırılabilir İçerik
          SafeArea(
            child: Column(
              children: [
                // 1. Apple Durum Çubuğu & Dynamic Island
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  child: Row(
                    children: [
                      // Operatör & Sessiz Mod
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Turkcell',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.notifications_off_rounded, size: 14, color: Colors.white70),
                        ],
                      ),
                      const Spacer(),
                      // Dynamic Island
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white12, width: 0.8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.airplay_rounded, size: 14, color: Color(0xFF38BDF8)),
                            SizedBox(width: 6),
                            Text(
                              'PDKS',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Şebeke, Wi-Fi, Pil %100
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.signal_cellular_4_bar_rounded, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          const Icon(Icons.wifi_rounded, size: 15, color: Colors.white),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '100',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    children: [
                      const SizedBox(height: 12),

                      // 2. Büyük Apple Saati ve Tarih (Screenshot'taki gibi)
                      Center(
                        child: Column(
                          children: [
                            Text(
                              dateStr,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              timeStr,
                              style: TextStyle(
                                color: const Color(0xFFE2B6C3).withOpacity(0.85),
                                fontSize: 78,
                                fontWeight: FontWeight.bold,
                                height: 1.05,
                                letterSpacing: -2.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.35),
                                    blurRadius: 18,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 3. Apple Medya & Canlı Mesai Kartı (Now Playing / Live Activity)
                      _buildAppleLiveActivityCard(context, pdks),
                      const SizedBox(height: 14),

                      // 4. Stacked Kilit Ekranı Bildirim Kartları (Gmail, PDKS, Duyuru vb.)
                      if (notifications.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'Eski bildirim yok',
                              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                            ),
                          ),
                        )
                      else
                        ...notifications.map((item) => _buildAppleLockScreenNotificationItem(context, item, pdks)),

                      const SizedBox(height: 70), // Alt butonlar için boşluk
                    ],
                  ),
                ),

                // 5. Alt Bar: El Feneri + Ana Ekran Çizgisi + Kamera (Screenshot ile birebir)
                Padding(
                  padding: const EdgeInsets.fromLTRB(36, 0, 36, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // El Feneri Butonu
                      InkWell(
                        onTap: () => setState(() => _isFlashlightOn = !_isFlashlightOn),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _isFlashlightOn
                                ? Colors.white
                                : const Color(0x661E293B),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 0.8),
                            boxShadow: _isFlashlightOn
                                ? [BoxShadow(color: Colors.white.withOpacity(0.6), blurRadius: 20)]
                                : null,
                          ),
                          child: Icon(
                            Icons.flashlight_on_rounded,
                            color: _isFlashlightOn ? Colors.black : Colors.white,
                            size: 22,
                          ),
                        ),
                      ),

                      // Home Çizgisi
                      Container(
                        width: 134,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      // Kamera Butonu
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              behavior: SnackBarBehavior.floating,
                              content: Text('📷 PDKS QR & Kamera Modülü Açılıyor...'),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0x661E293B),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 0.8),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Apple Canlı Aktivite / Medya Çalar Kartı
  Widget _buildAppleLiveActivityCard(BuildContext context, PdksState pdks) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xB31E2430),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.18), width: 0.8),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Küçük Resim / Kapak
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFE11D48), Color(0xFFF97316)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.business_center_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PDKS Enterprise • ${pdks.activeCompany.name}',
                          style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Aktif Vardiya & Canlı Mesai Takibi',
                          style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pdks.lastCheckInTime != null ? '🟢 Mesai Başlatıldı (Kioska Bağlı)' : '⚪ Giriş Bekleniyor (Geofence Aktif)',
                          style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.airplay_rounded, color: Colors.white60, size: 20),
                ],
              ),
              const SizedBox(height: 10),
              // İlerleme Çubuğu
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pdks.lastCheckInTime != null ? 0.65 : 0.15,
                  minHeight: 4,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 4),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('08:30', style: TextStyle(color: Colors.white60, fontSize: 10)),
                  Text('18:00', style: TextStyle(color: Colors.white60, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Apple Kilit Ekranı Bildirim Kartı (Gmail / YouTube / Snapchat görünümünde)
  Widget _buildAppleLockScreenNotificationItem(BuildContext context, AppNotification item, PdksState pdks) {
    final relativeTime = _formatRelativeTime(item.timestamp);

    // Kategoriye uygun simge & gradyan
    Gradient iconGradient;
    IconData iconData;
    String appName;

    switch (item.type) {
      case NotificationType.cafeteria:
        iconGradient = const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEA580C)]);
        iconData = Icons.restaurant_rounded;
        appName = 'PDKS Yemekhane';
        break;
      case NotificationType.announcement:
        iconGradient = const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]);
        iconData = Icons.campaign_rounded;
        appName = 'PDKS Duyuru';
        break;
      case NotificationType.attendance:
      case NotificationType.leave:
        iconGradient = const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]);
        iconData = Icons.access_time_filled_rounded;
        appName = 'PDKS Mesai';
        break;
      default:
        iconGradient = const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]);
        iconData = Icons.notifications_rounded;
        appName = 'PDKS Enterprise';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                pdks.markNotificationAsRead(item.id);
                IosNotificationService.showIosNotification(
                  title: item.title,
                  body: item.message,
                  icon: iconData,
                );
                if (item.type == NotificationType.cafeteria) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CafeteriaMenuViewScreen()));
                } else if (item.type == NotificationType.leave) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaveRequestScreen()));
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xB31E2430), // Cam dokusu
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.18), width: 0.8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Apple iOS Squircle Simgesi (Screenshot'taki gibi)
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: iconGradient,
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
                        child: Icon(iconData, color: Colors.white, size: 21),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Bildirim Metni
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Satır: Uygulama Adı + Zaman Damgası
                          Row(
                            children: [
                              Text(
                                appName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                relativeTime,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),

                          // 2. Satır: Başlık (Kalın)
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),

                          // 3. Satır: Detay
                          Text(
                            item.message,
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
    );
  }

  // ==========================================
  // 2. STANDART LİSTE GÖRÜNÜMÜ (Yönetim & Filtreler)
  // ==========================================
  Widget _buildStandardListView(
    BuildContext context,
    List<AppNotification> filtered,
    List<AppNotification> allNotifications,
    List<AppNotification> messageAndApprovalNotifications,
    PdksState pdks,
    bool isDark,
  ) {
    return Column(
      children: [
        // Test Butonu & Filtreler
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.cardBg(context),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(color: Color(0xFF2563EB), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.apple_rounded, size: 18),
                      label: const Text('Apple Push Bildirimini Test Et', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        IosNotificationService.sendAppleTestNotification();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'Mesaj & Onaylar (${messageAndApprovalNotifications.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip('approvals', 'Onaylananlar ✅'),
                    const SizedBox(width: 8),
                    _buildFilterChip('messages', 'Mesajlar 💬'),
                    const SizedBox(width: 8),
                    _buildFilterChip('unread', 'Okunmamış (${messageAndApprovalNotifications.where((n) => !n.isRead).length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip('all_history', 'Tüm Geçmiş'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: AppColors.cardBorder(context)),

        // Bildirim Listesi
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOf(context).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.primaryOf(context)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bildirim Bulunmuyor',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bu filtreye uygun herhangi bir bildiriminiz yok.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSub(context)),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    MediaQuery.of(context).padding.bottom + 20,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _buildNotificationCard(context, item, isDark, pdks);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipTextColor = isSelected
        ? Colors.white
        : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B));

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: chipTextColor,
        ),
      ),
      selected: isSelected,
      showCheckmark: false,
      selectedColor: AppColors.primaryOf(context),
      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      side: BorderSide(
        color: isSelected ? AppColors.primaryOf(context) : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
      ),
      onSelected: (_) => setState(() => _selectedFilter = key),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotification item, bool isDark, PdksState pdks) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          pdks.markNotificationAsRead(item.id);
          if (item.type == NotificationType.cafeteria) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CafeteriaMenuViewScreen()));
          } else if (item.type == NotificationType.leave) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaveRequestScreen()));
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: item.isRead
                ? AppColors.cardBg(context)
                : (isDark
                    ? item.color.withOpacity(0.12)
                    : item.color.withOpacity(0.06)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: item.isRead
                  ? AppColors.cardBorder(context)
                  : item.color.withOpacity(0.4),
              width: item.isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                              color: AppColors.text(context),
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: item.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: TextStyle(
                        fontSize: 12,
                        color: item.isRead ? AppColors.textSub(context) : AppColors.text(context),
                        height: 1.35,
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (item.targetPhone != null && item.targetPhone!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                                const SizedBox(width: 4),
                                Text(
                                  'SMS & Push: ${item.targetPhone}',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                                ),
                              ],
                            ),
                          ),
                        if (item.targetEmail != null && item.targetEmail!.isNotEmpty)
                          InkWell(
                            onTap: item.isEmailSent
                                ? () => EmailPreviewDialog.show(context, notification: item, companyName: pdks.activeCompany.name)
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.mark_email_read_rounded, size: 12, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'E-Posta Gönderildi: ${item.targetEmail}',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                                  ),
                                  if (item.isEmailSent) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.open_in_new_rounded, size: 10, color: Color(0xFF1D4ED8)),
                                  ],
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('dd MMM yyyy • HH:mm').format(item.timestamp),
                          style: TextStyle(fontSize: 10, color: AppColors.textSub(context).withOpacity(0.8)),
                        ),
                        if (item.type == NotificationType.cafeteria)
                          Text(
                            'Menüyü Gör ›',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: item.color),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
