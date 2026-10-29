import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/employee.dart';
import '../../state/pdks_state.dart';
import '../menu/profile_screen.dart';
import '../menu/contacts_screen.dart';
import '../menu/business_card_screen.dart';
import '../menu/favorites_screen.dart';
import '../menu/settings_screen.dart';
import '../menu/about_screen.dart';
import '../notifications/notifications_screen.dart';
import '../cafeteria/cafeteria_menu_view_screen.dart';
import '../payroll/my_payrolls_screen.dart';
import '../payroll/payroll_management_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

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

    Color roleColor;
    String roleName;
    switch (user.role) {
      case UserRole.boss:
        roleColor = const Color(0xFFD97706);
        roleName = 'Patron / CEO';
        break;
      case UserRole.admin:
        roleColor = const Color(0xFF9333EA);
        roleName = 'Sistem Admin';
        break;
      case UserRole.hr:
        roleColor = const Color(0xFF0284C7);
        roleName = 'İnsan Kaynakları';
        break;
      case UserRole.employee:
      default:
        roleColor = const Color(0xFF2563EB);
        roleName = 'Personel';
        break;
    }

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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
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
                          image: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(user.avatarUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          gradient: user.avatarUrl == null || user.avatarUrl!.isEmpty
                              ? LinearGradient(
                                  colors: [roleColor.withOpacity(0.3), roleColor],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                        ),
                        child: user.avatarUrl == null || user.avatarUrl!.isEmpty
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

            // Sadece Admin Rolüne Özel: Sayfa Düzenleme Modu Ana Şalteri
            if (user.role == UserRole.admin) ...[
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
                                ? 'Admin Düzenleme Modu Açıldı. Sayfaları canlı özelleştirebilirsiniz.'
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

            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
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
            ),

            // Menü Öğeleri Listesi
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                children: [
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
                    icon: Icons.receipt_long_rounded,
                    color: const Color(0xFF10B981),
                    title: (user.role == UserRole.hr || user.role == UserRole.boss || user.role == UserRole.admin)
                        ? 'Bordro & Maaş Yönetimi'
                        : 'Maaş & Bordrolarım',
                    subtitle: (user.role == UserRole.hr || user.role == UserRole.boss || user.role == UserRole.admin)
                        ? 'Aylık maaş hesaplama, icmal & ödemeler'
                        : 'Aylık e-bordro pusulası & net kazanç',
                    destination: (user.role == UserRole.hr || user.role == UserRole.boss || user.role == UserRole.admin)
                        ? const PayrollManagementScreen()
                        : const MyPayrollsScreen(),
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.people_alt_outlined,
                    color: const Color(0xFF4F46E5),
                    title: 'Kişiler',
                    subtitle: 'Şirket rehberi & mesai arkadaşları',
                    destination: const ContactsScreen(),
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.notifications_none_rounded,
                    color: const Color(0xFF8B5CF6),
                    title: 'Bildirimler',
                    subtitle: pdks.unreadNotificationsCount > 0 ? '${pdks.unreadNotificationsCount} yeni bildirim' : 'Duyurular & onaylar',
                    destination: const NotificationsScreen(),
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.restaurant_rounded,
                    color: const Color(0xFFEA580C),
                    title: 'Yemekhane Menüsü',
                    subtitle: 'Günün menüsü & 2 haftalık çizelge',
                    destination: const CafeteriaMenuViewScreen(),
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.badge_outlined,
                    color: const Color(0xFF0D9488),
                    title: 'Kartvizit',
                    subtitle: 'Dijital QR kodlu şirket kartı',
                    destination: const BusinessCardScreen(),
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.star_border_rounded,
                    color: const Color(0xFFD97706),
                    title: 'Sık Kullanılanlar',
                    subtitle: 'Hızlı kısayollar, yemek & servis',
                    destination: const FavoritesScreen(),
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.settings_outlined,
                    color: const Color(0xFF475569),
                    title: 'Ayarlar',
                    subtitle: 'Tema (${pdks.themeModeName}), bildirim & izinler',
                    destination: const SettingsScreen(),
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.info_outline_rounded,
                    color: const Color(0xFF0284C7),
                    title: 'Hakkımda',
                    subtitle: 'Sürüm 1.0.0 & sistem güvenliği',
                    destination: const AboutScreen(),
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
                        Text(
                          'Oturumu Kapat',
                          style: TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Spacer(),
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
    required Widget destination,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
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
                const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
