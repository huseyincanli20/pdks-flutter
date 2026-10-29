import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/location_service.dart';
import '../../core/services/wifi_network_service.dart';
import '../../core/services/biometric_service.dart';
import '../../models/attendance_record.dart';
import '../../models/employee.dart';
import '../../models/leave_request.dart';
import '../../state/pdks_state.dart';
import 'qr_scanner_screen.dart';
import 'leave_request_screen.dart';
import '../common/app_drawer.dart';
import '../notifications/notifications_screen.dart';
import '../cafeteria/cafeteria_menu_view_screen.dart';
import '../menu/business_card_screen.dart';
import '../menu/contacts_screen.dart';
import '../menu/settings_screen.dart';
import '../payroll/my_payrolls_screen.dart';
import '../../core/utils/marquee_text.dart';

class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  State<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  int _currentIndex = 0;
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
        _showErrorDialog(
          title: 'Şirket Wi-Fi Ağı Bulunamadı',
          message: wifiResult.message ?? 'Lütfen şirket Wi-Fi ağına bağlanın.',
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    final geofence = await LocationService.verifyOfficeGeofence();

    await pdksState.performCheckInOut(
      type: type,
      method: VerificationMethod.wifiIp,
      geofence: geofence,
      note: 'Ofis Wi-Fi (${wifiResult.networkName}) IP doğrulaması yapıldı.',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text('${wifiResult.networkName} ağı üzerinden ${type == AttendanceType.checkIn ? "giriş" : "çıkış"} onaylandı!'),
      ),
    );
  }

  void _showErrorDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppColors.danger),
            SizedBox(width: 10),
            Text('Oturumu Kapat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<PdksState>().logout();
            },
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle(Employee user, PdksState pdks) {
    switch (_currentIndex) {
      case 0:
        return 'Merhaba, ${user.fullName}';
      case 1:
        return 'Giriş & Çıkış Hareketleri';
      case 2:
        return 'İzinlerim & Talepler';
      case 3:
        return 'Profil & Dijital Kartvizit';
      default:
        return 'PDKS Mobil';
    }
  }

  String _getAppBarSubtitle(Employee user, PdksState pdks) {
    switch (_currentIndex) {
      case 0:
        return '${user.department} • ${pdks.activeCompany.name}';
      case 1:
        return 'Toplam ${pdks.records.length} Kayıt Bulundu';
      case 2:
        return 'Kalan Yıllık İzin: ${user.remainingLeaveDays} Gün';
      case 3:
        return '${user.fullName} (${user.title})';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final user = pdks.currentUser;
    final isCheckedIn = pdks.isCheckedIn;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getAppBarTitle(user, pdks),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _getAppBarSubtitle(user, pdks),
              style: TextStyle(fontSize: 11, color: AppColors.textSub(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
          : IndexedStack(
              index: _currentIndex,
              children: [
                _buildHomeTab(pdks, user, isCheckedIn),
                _buildRecordsTab(pdks, user),
                _buildLeavesTab(pdks, user),
                _buildProfileTab(pdks, user),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_toggle_off_rounded, color: AppColors.primary),
            label: 'Hareketler',
          ),
          NavigationDestination(
            icon: Icon(Icons.beach_access_outlined),
            selectedIcon: Icon(Icons.beach_access_rounded, color: AppColors.primary),
            label: 'İzinlerim',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
            label: 'Profilim',
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: ANA SAYFA (DEVAM & ÇALIŞMA SÜRESİ)
  // ==========================================
  Widget _buildHomeTab(PdksState pdks, Employee user, bool isCheckedIn) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16.0,
        14.0,
        16.0,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Çalışma Durumu ve Canlı Süre Kartı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCheckedIn
                    ? [const Color(0xFF10B981), const Color(0xFF059669)]
                    : [const Color(0xFF64748B), const Color(0xFF475569)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: (isCheckedIn ? const Color(0xFF10B981) : Colors.black).withOpacity(0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                            isCheckedIn ? 'İŞ YERİNDESİNİZ' : 'MESAİ DIŞI',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('d MMMM yyyy, EEEE', 'tr_TR').format(DateTime.now()),
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'BUGÜNKÜ ÇALIŞMA SÜRESİ',
                  style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(pdks.workedToday),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),

                // İşlem Butonları (Check In / Out, QR, Wi-Fi)
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: isCheckedIn ? AppColors.danger : AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        icon: Icon(isCheckedIn ? Icons.logout_rounded : Icons.login_rounded, size: 20),
                        label: Text(
                          isCheckedIn ? 'MESAİDEN ÇIK (GPS)' : 'MESAİYE GİR (GPS)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: () => _handleGpsCheck(isCheckedIn ? AttendanceType.checkOut : AttendanceType.checkIn),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                        tooltip: 'Turnike QR Okut',
                        onPressed: () => _openQrScanner(isCheckedIn ? AttendanceType.checkOut : AttendanceType.checkIn),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.wifi_rounded, color: Colors.white),
                        tooltip: 'Şirket Wi-Fi Giriş',
                        onPressed: () => _handleWifiCheck(isCheckedIn ? AttendanceType.checkOut : AttendanceType.checkIn),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. Hızlı İşlemler
          Text(
            'Hızlı İşlemler',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.beach_access_rounded,
                  color: Colors.amber.shade700,
                  title: 'İzin Talebi',
                  subtitle: 'Kalan: ${user.remainingLeaveDays} Gün',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaveRequestScreen()));
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.history_rounded,
                  color: Colors.blue.shade600,
                  title: 'Giriş/Çıkışlar',
                  subtitle: '${pdks.records.length} Kayıt',
                  onTap: () => setState(() => _currentIndex = 1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.more_time_rounded,
                  color: Colors.purple.shade600,
                  title: 'Fazla Mesai',
                  subtitle: 'Talep Bildir',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fazla mesai talebiniz yöneticinize iletildi.')),
                    );
                  },
                ),
              ),
            ],
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
                onPressed: () => setState(() => _currentIndex = 1),
                child: const Text('Tümünü Gör'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (pdks.records.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Henüz bir hareket kaydınız bulunmuyor.', style: TextStyle(color: AppColors.textSub(context))),
              ),
            )
          else
            ...pdks.records.take(4).map((record) => _buildRecordTile(record)),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: HAREKETLERİM (GİRİŞ - ÇIKIŞ GEÇMİŞİ)
  // ==========================================
  Widget _buildRecordsTab(PdksState pdks, Employee user) {
    final records = pdks.records;
    final checkIns = records.where((r) => r.type == AttendanceType.checkIn).length;
    final checkOuts = records.where((r) => r.type == AttendanceType.checkOut).length;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Özet Metrik Kartı
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.cardBorder(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Toplam', '${records.length}', Icons.list_alt_rounded, AppColors.primary),
                Container(width: 1, height: 32, color: AppColors.cardBorder(context)),
                _buildStatItem('Girişler', '$checkIns', Icons.arrow_downward_rounded, AppColors.success),
                Container(width: 1, height: 32, color: AppColors.cardBorder(context)),
                _buildStatItem('Çıkışlar', '$checkOuts', Icons.arrow_upward_rounded, AppColors.danger),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Tüm Hareket Kayıtları (${records.length})',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
          ),
          const SizedBox(height: 12),

          if (records.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.history_toggle_off_rounded, size: 48, color: AppColors.textSub(context).withOpacity(0.4)),
                    const SizedBox(height: 12),
                    Text('Henüz kayıtlı devam hareketi bulunmuyor.', style: TextStyle(color: AppColors.textSub(context))),
                  ],
                ),
              ),
            )
          else
            ...records.map((r) => _buildRecordTile(r)),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: İZİNLERİM & TALEPLERİM
  // ==========================================
  Widget _buildLeavesTab(PdksState pdks, Employee user) {
    final userLeaves = pdks.leaves.where((l) => l.employeeId == user.id).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // İzin Bakiyesi Kartı
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.beach_access_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Kalan Yıllık İzin Hakkınız', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        '${user.remainingLeaveDays} Gün',
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Toplam Hak: ${user.annualLeaveAllowance} Gün  •  Kullanılan: ${user.usedLeaveDays} Gün',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Yeni İzin Talebi Aç Butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOf(context),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Yeni İzin Talebi Oluştur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaveRequestScreen()));
              },
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'İzin Taleplerim (${userLeaves.length})',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
          ),
          const SizedBox(height: 12),

          if (userLeaves.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.event_busy_rounded, size: 48, color: AppColors.textSub(context).withOpacity(0.4)),
                    const SizedBox(height: 12),
                    Text('Aktif veya geçmiş bir izin talebiniz bulunmuyor.', style: TextStyle(color: AppColors.textSub(context))),
                  ],
                ),
              ),
            )
          else
            ...userLeaves.map((l) {
              Color statusColor;
              IconData statusIcon;
              switch (l.status) {
                case LeaveStatus.approved:
                  statusColor = AppColors.success;
                  statusIcon = Icons.check_circle_rounded;
                  break;
                case LeaveStatus.pending:
                  statusColor = AppColors.warning;
                  statusIcon = Icons.schedule_rounded;
                  break;
                case LeaveStatus.rejected:
                  statusColor = AppColors.danger;
                  statusIcon = Icons.cancel_rounded;
                  break;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.cardBorder(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryOf(context).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                l.typeLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryOf(context),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${l.totalDays} Gün',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text(context)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, color: statusColor, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                l.statusLabel,
                                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.date_range_rounded, size: 14, color: AppColors.textSub(context)),
                        const SizedBox(width: 6),
                        Text(
                          '${DateFormat('dd.MM.yyyy').format(l.startDate)} - ${DateFormat('dd.MM.yyyy').format(l.endDate)}',
                          style: TextStyle(fontSize: 12, color: AppColors.text(context), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    if (l.reason.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        l.reason,
                        style: TextStyle(fontSize: 12, color: AppColors.textSub(context)),
                      ),
                    ],
                    if (l.managerComment != null && l.managerComment!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Yönetici Yanıtı: ${l.managerComment}',
                          style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 4: PROFİLİM & DİJİTAL KARTVİZİT
  // ==========================================
  Widget _buildProfileTab(PdksState pdks, Employee user) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Apple / Samsung Wallet Tarzı PDKS PASS Kartı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0A0F1D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.badge_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'PDKS PASS • PERSONEL',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1),
                        ),
                      ],
                    ),
                    const Icon(Icons.nfc_rounded, color: Colors.white54, size: 24),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  user.fullName,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${user.title}  •  ${user.department}',
                  style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  pdks.activeCompany.name,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 18),
                Divider(color: Colors.white.withOpacity(0.12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, color: Colors.white60, size: 14),
                    const SizedBox(width: 8),
                    Text(user.phone, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.mail_outline_rounded, color: Colors.white60, size: 14),
                    const SizedBox(width: 8),
                    Text(user.email, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Kısayol Menüleri
          _buildProfileTile(
            icon: Icons.receipt_long_rounded,
            color: const Color(0xFF10B981),
            title: 'Maaş & Bordrolarım',
            subtitle: pdks.latestUserPayroll != null
                ? '${pdks.latestUserPayroll!.periodName} • Net: ${pdks.latestUserPayroll!.formatCurrency(pdks.latestUserPayroll!.netSalary)}'
                : 'Aylık resmi e-bordro pusulaları ve net hak edişler',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPayrollsScreen()));
            },
          ),
          _buildProfileTile(
            icon: Icons.qr_code_rounded,
            color: const Color(0xFF2563EB),
            title: 'Dijital Kartvizitim (QR & Paylaş)',
            subtitle: 'Rehbere ekleme barkodu & Apple/Samsung Wallet',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessCardScreen()));
            },
          ),
          _buildProfileTile(
            icon: Icons.people_alt_outlined,
            color: const Color(0xFF4F46E5),
            title: 'Şirket Rehberi & Mesai Arkadaşları',
            subtitle: 'Dahili numaralar ve şirket içi iletişim',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen()));
            },
          ),
          _buildProfileTile(
            icon: Icons.restaurant_rounded,
            color: const Color(0xFFEA580C),
            title: 'Günün Yemekhane Menüsü',
            subtitle: 'Öğle yemeği listesi ve kalori bilgisi',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CafeteriaMenuViewScreen()));
            },
          ),
          _buildProfileTile(
            icon: Icons.settings_outlined,
            color: const Color(0xFF475569),
            title: 'Görünüm & Tema Ayarları',
            subtitle: 'Aydınlık, Koyu ve kurumsal renk temaları',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          _buildProfileTile(
            icon: Icons.logout_rounded,
            color: AppColors.danger,
            title: 'Oturumu Kapat',
            subtitle: 'Hesabınızdan güvenli çıkış yapın',
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text(context))),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.textSub(context))),
        trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textSub(context), size: 18),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSub(context))),
      ],
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
}
