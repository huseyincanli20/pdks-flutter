import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/location_service.dart';
import '../../core/services/wifi_network_service.dart';
import '../../core/services/biometric_service.dart';
import '../../models/attendance_record.dart';
import '../../state/pdks_state.dart';
import 'qr_scanner_screen.dart';
import 'leave_request_screen.dart';
import '../common/app_drawer.dart';
import '../notifications/notifications_screen.dart';
import '../cafeteria/cafeteria_menu_view_screen.dart';
import '../../core/utils/marquee_text.dart';

class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  State<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  bool _isLoading = false;

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  // GPS / Geofence ile Check-in / Check-out
  Future<void> _handleGpsCheck(AttendanceType type) async {
    setState(() => _isLoading = true);
    final pdksState = context.read<PdksState>();

    // 1. GPS ve Ofis Geofence Sınır Kontrolü
    final geofence = await LocationService.verifyOfficeGeofence();

    if (!geofence.isInside) {
      if (mounted) {
        _showErrorDialog(
          title: 'Geofence Sınırı Dışında',
          message: geofence.errorMessage ?? 'Ofis sınırları içinde değilsiniz.',
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    // 2. Biyometrik Doğrulama (FaceID / Parmak İzi)
    final bioSuccess = await BiometricService.authenticate(
      reason: '${type == AttendanceType.checkIn ? "Giriş" : "Çıkış"} işleminizi biyometrik olarak onaylayın',
    );

    if (!bioSuccess) {
      if (mounted) {
        _showErrorDialog(title: 'Biyometrik Hata', message: 'Biyometrik doğrulama onaylanamadı.');
      }
      setState(() => _isLoading = false);
      return;
    }

    // 3. Backend'e Gönderim
    await pdksState.performCheckInOut(
      type: type,
      method: VerificationMethod.geofenceGps,
      geofence: geofence,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text('${type == AttendanceType.checkIn ? "Giriş" : "Çıkış"} başarıyla kaydedildi! (Mesafe: ${geofence.distanceMeters.toStringAsFixed(0)}m)'),
      ),
    );
  }

  // Dinamik QR Kod Okutarak Giriş
  void _openQrScanner(AttendanceType type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(type: type),
      ),
    );
  }

  // Wi-Fi Kontrolü ile Hızlı Giriş
  Future<void> _handleWifiCheck(AttendanceType type) async {
    setState(() => _isLoading = true);
    final pdksState = context.read<PdksState>();

    final wifiResult = await WifiNetworkService.verifyOfficeNetwork();

    if (!wifiResult.isVerified) {
      if (mounted) {
        _showErrorDialog(title: 'Ağ Hatası', message: wifiResult.message ?? 'Şirket ağına bağlı değilsiniz.');
      }
      setState(() => _isLoading = false);
      return;
    }

    final dummyGeofence = GeofenceResult(
      isInside: true,
      distanceMeters: 5.0,
      allowedRadiusMeters: 150.0,
      latitude: 41.0082,
      longitude: 28.9784,
    );

    await pdksState.performCheckInOut(
      type: type,
      method: VerificationMethod.wifiIp,
      geofence: dummyGeofence,
      note: 'Ofis Wi-Fi (${wifiResult.networkName}) IP doğrulaması yapıldı.',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Ofis Wi-Fi üzerinden ${type == AttendanceType.checkIn ? "giriş" : "çıkış"} yapıldı!'),
      ),
    );
  }

  void _showErrorDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final user = pdks.currentUser;
    final isCheckedIn = pdks.isCheckedIn;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Merhaba, ${user.fullName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(user.department, style: TextStyle(fontSize: 12, color: AppColors.textSub(context))),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFFBBF24)
                  : AppColors.text(context),
            ),
            tooltip: Theme.of(context).brightness == Brightness.dark ? 'Aydınlık Temaya Geç' : 'Koyu Temaya Geç',
            onPressed: () => pdks.toggleTheme(),
          ),
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications_none_rounded, color: AppColors.text(context)),
                if (pdks.unreadNotificationsCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Center(
                        child: Text(
                          pdks.unreadNotificationsCount.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Bildirimler',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16.0,
                16.0,
                16.0,
                MediaQuery.of(context).padding.bottom + 28.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Canlı Durum ve Mesai Kartı (Apple & Samsung Glassmorphism style)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: isCheckedIn ? AppColors.successGradient : AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: (isCheckedIn ? AppColors.success : AppColors.primary).withOpacity(0.32),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isCheckedIn ? 'İŞ YERİNDESİNİZ' : 'MESAİ BAŞLAMADI',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              DateFormat('dd MMMM, EEEE', 'tr_TR').format(DateTime.now()),
                              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'BUGÜNKÜ ÇALIŞMA SÜRESİ',
                          style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatDuration(pdks.workedToday),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 22),
                        // Ana Check-in / Check-out Aksiyon Butonu
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: isCheckedIn ? AppColors.danger : AppColors.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 2,
                                ),
                                icon: Icon(
                                  isCheckedIn ? Icons.logout : Icons.login,
                                  size: 20,
                                ),
                                label: Text(
                                  isCheckedIn ? 'MESAİDEN ÇIK (GPS)' : 'MESAİYE BAŞLA (GPS)',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                ),
                                onPressed: () => _handleGpsCheck(
                                  isCheckedIn ? AttendanceType.checkOut : AttendanceType.checkIn,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.25),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              tooltip: 'Turnike QR Kod Okut',
                              icon: const Icon(Icons.qr_code_scanner, size: 22),
                              onPressed: () => _openQrScanner(
                                isCheckedIn ? AttendanceType.checkOut : AttendanceType.checkIn,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.25),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              tooltip: 'Ofis Wi-Fi ile Onayla',
                              icon: const Icon(Icons.wifi, size: 22),
                              onPressed: () => _handleWifiCheck(
                                isCheckedIn ? AttendanceType.checkOut : AttendanceType.checkIn,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 2. Hızlı Menü
                  Text(
                    'Hızlı İşlemler',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          icon: Icons.beach_access,
                          color: Colors.orange,
                          title: 'İzin Talebi',
                          subtitle: 'Kalan: ${user.remainingLeaveDays} Gün',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LeaveRequestScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionCard(
                          icon: Icons.history,
                          color: Colors.blue,
                          title: 'Giriş/Çıkışlar',
                          subtitle: '${pdks.records.length} Kayıt',
                          onTap: () {
                            _showAttendanceHistoryModal(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionCard(
                          icon: Icons.more_time,
                          color: Colors.purple,
                          title: 'Fazla Mesai',
                          subtitle: 'Talep Bildir',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Fazla mesai talep formu açıldı.')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Günün Yemekhane Menüsü Kartı (Hızlı Erişim)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CafeteriaMenuViewScreen()));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg(context),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFEA580C).withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEA580C).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.restaurant_rounded, color: Color(0xFFEA580C), size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Günün Yemekhane Menüsü',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEA580C).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '~${pdks.todayMenu.totalCalories} kcal',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${pdks.todayMenu.soup} • ${pdks.todayMenu.mainDish} • ${pdks.todayMenu.sideDish}',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSub(context)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFEA580C)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. Son Hareketler Listesi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Son Turnike & Konum Hareketleri',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                      ),
                      TextButton(
                        onPressed: () => _showAttendanceHistoryModal(context),
                        child: const Text('Tümünü Gör'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ...pdks.records.take(4).map((record) => _buildRecordTile(record)),
                ],
              ),
            ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text(context))),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: AppColors.textSub(context), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordTile(AttendanceRecord record) {
    final isCheckIn = record.type == AttendanceType.checkIn;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isCheckIn ? AppColors.success : AppColors.danger).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCheckIn ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCheckIn ? AppColors.success : AppColors.danger,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      record.typeLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isCheckIn ? AppColors.success : AppColors.danger,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(record.timestamp),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      record.verificationMethod == VerificationMethod.qrCode
                          ? Icons.qr_code
                          : record.verificationMethod == VerificationMethod.wifiIp
                              ? Icons.wifi
                              : Icons.gps_fixed,
                      size: 13,
                      color: AppColors.textSub(context),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: MarqueeText(
                        text: '${record.methodLabel} • ${record.note ?? ""}',
                        style: TextStyle(fontSize: 11, color: AppColors.textSub(context), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAttendanceHistoryModal(BuildContext context) {
    final records = context.read<PdksState>().records;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Tüm Giriş & Çıkış Hareketleri',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.cardBorder(context)),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.all(16),
                itemCount: records.length,
                itemBuilder: (_, index) => _buildRecordTile(records[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
