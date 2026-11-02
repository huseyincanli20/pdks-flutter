import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/employee.dart';
import '../../models/quick_menu_item.dart';
import '../../state/pdks_state.dart';
import '../menu/profile_screen.dart';
import '../menu/contacts_screen.dart';
import '../menu/business_card_screen.dart';
import '../menu/settings_screen.dart';
import '../menu/about_screen.dart';
import '../menu/favorites_screen.dart';
import '../notifications/notifications_screen.dart';
import '../cafeteria/cafeteria_menu_view_screen.dart';
import '../payroll/my_payrolls_screen.dart';
import '../payroll/payroll_management_screen.dart';
import '../chat/chat_list_screen.dart';
import '../vehicle/vehicle_request_screen.dart';
import '../kiosk/kiosk_terminal_screen.dart';
import '../enterprise/enterprise_hub_screen.dart';
import '../mobile/leave_request_screen.dart';
import '../movement_management/employee_movement_management_screen.dart';
import 'field_work_dialog.dart';
import 'firebase_config_dialog.dart';
import 'quick_menu_manager_dialog.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _handleDrawerAction(BuildContext context, QuickMenuItem item, Employee user, PdksState pdks) {
    if (!pdks.hasPagePermission(item.actionType)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yetki Sınırı: Bu modüle erişim için rol yetkiniz bulunmamaktadır.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    switch (item.actionType) {
      case 'profile':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
        break;
      case 'payroll':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => (user.role == UserRole.hr || user.role == UserRole.boss || user.role == UserRole.admin)
                ? const PayrollManagementScreen()
                : const MyPayrollsScreen(),
          ),
        );
        break;
      case 'chat':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
        break;
      case 'contacts':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen()));
        break;
      case 'notifications':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
        break;
      case 'cafeteria':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CafeteriaMenuViewScreen()));
        break;
      case 'business_card':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessCardScreen()));
        break;
      case 'favorites':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
        break;
      case 'leave':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaveRequestScreen()));
        break;
      case 'records':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const EmployeeMovementManagementScreen(),
          ),
        );
        break;
      case 'field_work':
        FieldWorkDialog.show(context);
        break;
      case 'overtime':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fazla mesai talebiniz yöneticinize iletildi.')),
        );
        break;
      case 'vehicle_request':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleRequestScreen()));
        break;
      case 'shift_swap':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EnterpriseHubScreen(initialTabIndex: 1)));
        break;
      case 'helpdesk':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EnterpriseHubScreen(initialTabIndex: 2)));
        break;
      case 'announcements':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EnterpriseHubScreen(initialTabIndex: 3)));
        break;
      case 'onboarding':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EnterpriseHubScreen(initialTabIndex: 4)));
        break;
      case 'training':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EnterpriseHubScreen(initialTabIndex: 5)));
        break;
      case 'okr':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EnterpriseHubScreen(initialTabIndex: 6)));
        break;
      case 'visitors':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EnterpriseHubScreen(initialTabIndex: 7)));
        break;
      case 'hybrid_desk':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EnterpriseHubScreen(initialTabIndex: 8)));
        break;
      case 'branches':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EnterpriseHubScreen(initialTabIndex: 9)));
        break;
      case 'feedback':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EnterpriseHubScreen(initialTabIndex: 10)));
        break;
      case 'calibration':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EnterpriseHubScreen(initialTabIndex: 12)));
        break;
      case 'pdks_ai':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EnterpriseHubScreen(initialTabIndex: 14)));
        break;
      case 'kiosk_face':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const KioskTerminalScreen()));
        break;
      case 'digital_docs':
      case 'digital_signature':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EnterpriseHubScreen(initialTabIndex: 16)));
        break;
      case 'near_miss':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EnterpriseHubScreen(initialTabIndex: 17)));
        break;
      case 'ptt_radio':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EnterpriseHubScreen(initialTabIndex: 18)));
        break;
      case 'shuttle':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.directions_bus_rounded, color: Color(0xFF3B82F6), size: 22),
                SizedBox(width: 8),
                Expanded(child: Text('Şirket Servis Saatleri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              ],
            ),
            content: const Text(
              'Akşam Çıkış Servisleri (Kalkış: 18:15):\n\n'
              '1. Maslak - Levent - Zincirlikuyu - Kadıköy\n'
              '2. Maslak - Çağlayan - Mecidiyeköy - Bakırköy\n'
              '3. Maslak - Kozyatağı - Ataşehir - Ümraniye\n'
              '4. Maslak - Kağıthane - Eyüp - Gaziosmanpaşa\n\n'
              'Servis Sorumlusu İletişim: 0532 000 11 22',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kapat')),
            ],
          ),
        );
        break;
      case 'holidays':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: Color(0xFF6366F1), size: 22),
                SizedBox(width: 8),
                Expanded(child: Text('2026 Resmi Tatiller', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              ],
            ),
            content: const Text(
              '• 1 Ocak (Perşembe): Yılbaşı\n'
              '• 23 Nisan (Perşembe): Ulusal Egemenlik ve Çocuk Bayramı\n'
              '• 1 Mayıs (Cuma): Emek ve Dayanışma Günü\n'
              '• 19 Mayıs (Salı): Atatürk\'ü Anma, Gençlik ve Spor Bayramı\n'
              '• 15 Temmuz (Çarşamba): Demokrasi ve Milli Birlik Günü\n'
              '• 30 Ağustos (Pazar): Zafer Bayramı\n'
              '• 29 Ekim (Perşembe): Cumhuriyet Bayramı',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kapat')),
            ],
          ),
        );
        break;
      case 'doctor':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.medical_services_outlined, color: Color(0xFFEF4444), size: 22),
                SizedBox(width: 8),
                Expanded(child: Text('İş Yeri Hekimi & Revir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              ],
            ),
            content: const Text(
              'İş Yeri Hekimi: Dr. Mehmet Yılmaz\n'
              'Çalışma Saatleri: Hafta içi 09:00 - 17:30\n'
              'Konum: B Blok, Giriş Kat, Oda No: 104\n\n'
              'Acil Dahili Hatlar:\n'
              '• Revir: Dahili 1044\n'
              '• İK Masası: Dahili 1002\n'
              '• Güvenlik Masası: Dahili 1000\n'
              '• Genel Acil Çağrı: 112',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kapat')),
            ],
          ),
        );
        break;
      case 'enterprise_hub':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EnterpriseHubScreen()));
        break;
      case 'settings':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
        break;
      case 'about':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
        break;
      case 'cloud_db':
        showFirebaseConfigDialog(context);
        break;
      case 'info_dialog':
      default:
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(item.icon, color: item.color, size: 22),
                const SizedBox(width: 8),
                Expanded(child: Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              ],
            ),
            content: Text(item.customContent ?? item.subtitle, style: const TextStyle(fontSize: 13, height: 1.5)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kapat')),
            ],
          ),
        );
        break;
    }
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
        content: const Text(
          'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final pdks = context.read<PdksState>();
              Navigator.pop(ctx);
              Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
              pdks.logout();
            },
            child: const Text('Çıkış Yap', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final user = pdks.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color roleColor = user.role.color;
    final String roleName = user.roleDisplayName;

    return Drawer(
      backgroundColor: AppColors.bg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Üst Profil Bilgisi Kartı (Apple / Samsung OneUI Header)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF1E293B), Color(0xFF090D16)]
                        : const [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: roleColor, width: 2),
                          image: user.avatarImageProvider != null
                              ? DecorationImage(
                                  image: user.avatarImageProvider!,
                                  fit: BoxFit.cover,
                                )
                              : null,
                          gradient: user.avatarImageProvider == null
                              ? LinearGradient(
                                  colors: [roleColor.withOpacity(0.3), roleColor],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                        ),
                        child: user.avatarImageProvider == null
                            ? Center(
                                child: Text(
                                  user.fullName.isNotEmpty ? user.fullName.substring(0, 2).toUpperCase() : 'P',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.email,
                              style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: roleColor.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: roleColor.withOpacity(0.5), width: 0.8),
                              ),
                              child: Text(
                                roleName,
                                style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Hızlı Tema Değiştirme Butonu (Güneş / Ay)
                    IconButton(
                      icon: Icon(
                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: isDark ? const Color(0xFFFBBF24) : Colors.white70,
                        size: 22,
                      ),
                      tooltip: isDark ? 'Aydınlık Temaya Geç' : 'Koyu Temaya Geç',
                      onPressed: () {
                        pdks.toggleTheme();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 1),
                            content: Text(isDark ? 'Aydınlık tema açıldı.' : 'Koyu tema açıldı.'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Sadece Yönetici (Patron/CEO) ve Admin Rolüne Özel: Sayfa Düzenleme Modu Şalteri
            if (user.role == UserRole.admin || user.role == UserRole.boss) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: pdks.isAdminEditMode
                      ? const LinearGradient(
                          colors: [Color(0xFF9333EA), Color(0xFF7E22CE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: pdks.isAdminEditMode ? null : AppColors.cardBg(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: pdks.isAdminEditMode ? const Color(0xFFC084FC) : Colors.purple.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (pdks.isAdminEditMode ? const Color(0xFF9333EA) : Colors.black).withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: pdks.isAdminEditMode ? Colors.white.withOpacity(0.2) : Colors.purple.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.dashboard_customize_rounded,
                        color: pdks.isAdminEditMode ? Colors.white : const Color(0xFF9333EA),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sayfa Düzenleme Modu',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: pdks.isAdminEditMode ? Colors.white : AppColors.text(context),
                            ),
                          ),
                          Text(
                            pdks.isAdminEditMode ? 'Canlı düzenleme aktif' : 'Sayfalarda düzenlemeyi aç',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: pdks.isAdminEditMode ? Colors.white70 : AppColors.textSub(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: pdks.isAdminEditMode,
                      activeColor: Colors.white,
                      activeTrackColor: const Color(0xFF10B981),
                      onChanged: (val) {
                        pdks.setAdminEditMode(val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: val ? const Color(0xFF9333EA) : Colors.grey.shade800,
                            content: Text(val
                                ? 'Yönetici & Admin Düzenleme Modu Açıldı. Sayfaları canlı özelleştirebilirsiniz.'
                                : 'Düzenleme Modu Kapatıldı.'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 14, 6),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'HIZLI MENÜ',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  if (user.role == UserRole.admin || user.role == UserRole.boss)
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => QuickMenuManagerDialog.show(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9333EA).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF9333EA).withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tune_rounded, size: 12, color: Color(0xFF9333EA)),
                            SizedBox(width: 4),
                            Text(
                              'Menüyü Yönet',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF9333EA)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Dinamik Hızlı Menü ve Kurumsal Hizmetler
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                children: [
                  _buildDrawerTile(
                    context,
                    icon: Icons.swap_vert_circle_rounded,
                    color: const Color(0xFF0D9488),
                    title: pdks.canManageAllEmployeeMovements
                        ? 'Çalışan Hareket Yönetimi'
                        : 'Çalışan Hareketleri',
                    subtitle: pdks.canManageAllEmployeeMovements
                        ? 'Giriş, çıkış, mola, devam özeti & kontrol bekleyenler'
                        : 'Kendi giriş, çıkış ve mola hareketlerim',
                    onTapCustom: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EmployeeMovementManagementScreen(
                            initialTabIndex: pdks.canManageAllEmployeeMovements ? 0 : 1,
                          ),
                        ),
                      );
                    },
                  ),
                  // 1. Hızlı İşlemler (Kullanıcının Seçtiği 5 Temel Modül)
                  ...pdks.visibleQuickMenuItems.map((item) {
                    int? badge;
                    if (item.actionType == 'chat') badge = pdks.unreadChatCount;
                    if (item.actionType == 'notifications') badge = pdks.unreadNotificationsCount;

                    String sub = item.subtitle;
                    if (item.actionType == 'leave') {
                      sub = 'Kalan: ${user.remainingLeaveDays} Gün';
                    } else if (item.actionType == 'payroll') {
                      sub = (user.role == UserRole.hr || user.role == UserRole.boss || user.role == UserRole.admin)
                          ? 'Aylık maaş hesaplama, icmal & ödemeler'
                          : 'Aylık e-bordro pusulası & net kazanç';
                    } else if (item.actionType == 'settings') {
                      sub = 'Tema (${pdks.themeModeName}), bildirim & izinler';
                    }

                    return _buildDrawerTile(
                      context,
                      icon: item.icon,
                      color: item.color,
                      title: item.title,
                      subtitle: sub,
                      badgeCount: badge,
                      onTapCustom: () => _handleDrawerAction(context, item, user, pdks),
                    );
                  }),

                  const SizedBox(height: 14),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: Text(
                      'KURUMSAL HİZMETLER & SERVİSLER',
                      style: TextStyle(fontSize: 10.5, letterSpacing: 1.1, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                    ),
                  ),

                  // 2. Kurumsal & Saha Modülleri
                  _buildDrawerTile(
                    context,
                    icon: Icons.directions_bus_rounded,
                    color: const Color(0xFF3B82F6),
                    title: 'Servis Saatleri',
                    subtitle: 'Maslak, Levent, Kadıköy güzergahları',
                    onTapCustom: () => _handleDrawerAction(
                      context,
                      const QuickMenuItem(id: 'qm_shuttle', title: 'Servis Saatleri', subtitle: '', iconCode: 0xe1d5, colorValue: 0xFF3B82F6, actionType: 'shuttle'),
                      user,
                      pdks,
                    ),
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.calendar_month_rounded,
                    color: const Color(0xFF6366F1),
                    title: 'Resmi Tatiller',
                    subtitle: '2026 resmi tatil takvimi & köprüler',
                    onTapCustom: () => _handleDrawerAction(
                      context,
                      const QuickMenuItem(id: 'qm_holidays', title: 'Resmi Tatiller', subtitle: '', iconCode: 0xe122, colorValue: 0xFF6366F1, actionType: 'holidays'),
                      user,
                      pdks,
                    ),
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.medical_services_outlined,
                    color: const Color(0xFFEF4444),
                    title: 'Revir & Hekim',
                    subtitle: 'İş yeri hekimi, oda & acil hatlar',
                    onTapCustom: () => _handleDrawerAction(
                      context,
                      const QuickMenuItem(id: 'qm_doctor', title: 'Revir & Hekim', subtitle: '', iconCode: 0xe3e3, colorValue: 0xFFEF4444, actionType: 'doctor'),
                      user,
                      pdks,
                    ),
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.swap_horiz_rounded,
                    color: const Color(0xFF059669),
                    title: 'Vardiya & Takas',
                    subtitle: 'Vardiya takas talebi & açık vardiyalar',
                    onTapCustom: () => _handleDrawerAction(
                      context,
                      const QuickMenuItem(id: 'qm_shift_swap', title: 'Vardiya & Takas', subtitle: '', iconCode: 0xe627, colorValue: 0xFF059669, actionType: 'shift_swap'),
                      user,
                      pdks,
                    ),
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.support_agent_rounded,
                    color: const Color(0xFFEA580C),
                    title: 'Destek & Arıza',
                    subtitle: 'Teknik arıza ve IT destek talepleri',
                    onTapCustom: () => _handleDrawerAction(
                      context,
                      const QuickMenuItem(id: 'qm_helpdesk', title: 'Destek & Arıza', subtitle: '', iconCode: 0xf5dd, colorValue: 0xFFEA580C, actionType: 'helpdesk'),
                      user,
                      pdks,
                    ),
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFDC2626),
                    title: 'İSG Ramak Kala',
                    subtitle: '6331 İSG ve tehlike bildirimi',
                    onTapCustom: () => _handleDrawerAction(
                      context,
                      const QuickMenuItem(id: 'qm_near_miss', title: 'İSG Ramak Kala', subtitle: '', iconCode: 0xe2eb, colorValue: 0xFFDC2626, actionType: 'near_miss'),
                      user,
                      pdks,
                    ),
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.history_edu_rounded,
                    color: const Color(0xFF7C3AED),
                    title: '5070 E-İmza & ERP',
                    subtitle: 'Zaman damgası ve bordro onaylama',
                    onTapCustom: () => _handleDrawerAction(
                      context,
                      const QuickMenuItem(id: 'qm_digital_docs', title: '5070 E-İmza & ERP', subtitle: '', iconCode: 0xe204, colorValue: 0xFF7C3AED, actionType: 'digital_docs'),
                      user,
                      pdks,
                    ),
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.radio_rounded,
                    color: const Color(0xFF0D9488),
                    title: 'Saha Telsizi (PTT)',
                    subtitle: 'Anlık bas-konuş sesli telsiz kanalı',
                    onTapCustom: () => _handleDrawerAction(
                      context,
                      const QuickMenuItem(id: 'qm_ptt_radio', title: 'Saha Telsizi (PTT)', subtitle: '', iconCode: 0xe500, colorValue: 0xFF0D9488, actionType: 'ptt_radio'),
                      user,
                      pdks,
                    ),
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.desk_rounded,
                    color: const Color(0xFF2563EB),
                    title: 'Hibrit & Masa',
                    subtitle: 'Masa ve toplantı odası rezervasyonu',
                    onTapCustom: () => _handleDrawerAction(
                      context,
                      const QuickMenuItem(id: 'qm_hybrid_desk', title: 'Hibrit & Masa', subtitle: '', iconCode: 0xf69b, colorValue: 0xFF2563EB, actionType: 'hybrid_desk'),
                      user,
                      pdks,
                    ),
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.school_rounded,
                    color: const Color(0xFF8B5CF6),
                    title: 'Akademi & Eğitim',
                    subtitle: 'Eğitim videoları ve yetkinlik sınavı',
                    onTapCustom: () => _handleDrawerAction(
                      context,
                      const QuickMenuItem(id: 'qm_training', title: 'Akademi & Eğitim', subtitle: '', iconCode: 0xe559, colorValue: 0xFF8B5CF6, actionType: 'training'),
                      user,
                      pdks,
                    ),
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.track_changes_rounded,
                    color: const Color(0xFFD97706),
                    title: 'Hedef & OKR',
                    subtitle: 'Bireysel ve kurumsal hedefler',
                    onTapCustom: () => _handleDrawerAction(
                      context,
                      const QuickMenuItem(id: 'qm_okr', title: 'Hedef & OKR', subtitle: '', iconCode: 0xe673, colorValue: 0xFFD97706, actionType: 'okr'),
                      user,
                      pdks,
                    ),
                  ),
                  if (pdks.hasPagePermission('vehicle_request'))
                    _buildDrawerTile(
                      context,
                      icon: Icons.directions_car_rounded,
                      color: const Color(0xFF059669),
                      title: 'Araç Talebi & Filo',
                      subtitle: 'Şirket havuz araçları ve filo takibi',
                      destination: const VehicleRequestScreen(),
                    ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.camera_front_rounded,
                    color: const Color(0xFF10B981),
                    title: 'Kiosk Turnike Modu',
                    subtitle: 'Yüz tanıma ve turnike geçiş terminali',
                    destination: const KioskTerminalScreen(),
                  ),

                  const SizedBox(height: 14),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: Text(
                      'HESAP VE AYARLAR',
                      style: TextStyle(fontSize: 10.5, letterSpacing: 1.1, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                    ),
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.person_outline_rounded,
                    color: const Color(0xFF2563EB),
                    title: 'Profil',
                    subtitle: 'Kişisel bilgiler & izin bakiyesi',
                    destination: const ProfileScreen(),
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.notifications_none_rounded,
                    color: const Color(0xFF8B5CF6),
                    title: 'Bildirimler',
                    subtitle: pdks.unreadNotificationsCount > 0 ? '${pdks.unreadNotificationsCount} yeni bildirim' : 'Duyurular & onaylar',
                    destination: const NotificationsScreen(),
                    badgeCount: pdks.unreadNotificationsCount,
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.settings_outlined,
                    color: const Color(0xFF475569),
                    title: 'Ayarlar',
                    subtitle: 'Tema (${pdks.themeModeName}), bildirim & sistem',
                    destination: const SettingsScreen(),
                  ),
                  if (user.role == UserRole.admin || user.role == UserRole.boss)
                    _buildDrawerTile(
                      context,
                      icon: Icons.local_fire_department_rounded,
                      color: const Color(0xFFFF5722),
                      title: 'Firebase Bulut DB',
                      subtitle: pdks.isFirebaseConnected ? 'Merkezi bulut eşitlendi' : 'Yerel ve bulut senkronizasyonu',
                      onTapCustom: () => showFirebaseConfigDialog(context),
                    ),
                ],
              ),
            ),

            Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.cardBorder(context)),

            // En Altta: Oturumu Kapat
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showLogoutDialog(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.danger.withOpacity(0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Oturumu Kapat',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.danger),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    Widget? destination,
    VoidCallback? onTapCustom,
    int? badgeCount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pop(context);
            if (onTapCustom != null) {
              onTapCustom();
            } else if (destination != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder(context), width: 0.8),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text(context)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 11, color: AppColors.textSub(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (badgeCount != null && badgeCount > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOf(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
