import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../state/pdks_state.dart';
import '../menu/profile_screen.dart';
import '../menu/contacts_screen.dart';
import '../menu/business_card_screen.dart';
import '../menu/favorites_screen.dart';
import '../menu/settings_screen.dart';
import '../menu/about_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            child: const Text('İptal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close drawer
              context.read<PdksState>().logout();
            },
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<PdksState>().currentUser;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Üst Profil Bilgisi Başlığı
            InkWell(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Text(
                        user.fullName.isNotEmpty ? user.fullName.substring(0, 2).toUpperCase() : 'P',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.title,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Menü Öğeleri Listesi
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                children: [
                  _buildDrawerTile(
                    context,
                    icon: Icons.person_outline,
                    color: Colors.blue,
                    title: 'Profil',
                    subtitle: 'Kişisel bilgiler & izin bakiyesi',
                    destination: const ProfileScreen(),
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.people_alt_outlined,
                    color: Colors.indigo,
                    title: 'Kişiler',
                    subtitle: 'Şirket rehberi & mesai arkadaşları',
                    destination: const ContactsScreen(),
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.badge_outlined,
                    color: Colors.teal,
                    title: 'Kartvizit',
                    subtitle: 'Dijital QR kodlu şirket kartı',
                    destination: const BusinessCardScreen(),
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.star_border_rounded,
                    color: Colors.amber.shade800,
                    title: 'Sık Kullanılanlar',
                    subtitle: 'Hızlı kısayollar & pratik işlemler',
                    destination: const FavoritesScreen(),
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.settings_outlined,
                    color: Colors.blueGrey,
                    title: 'Ayarlar',
                    subtitle: 'Bildirimler, biyometri & izinler',
                    destination: const SettingsScreen(),
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.info_outline,
                    color: Colors.cyan.shade700,
                    title: 'Hakkımda',
                    subtitle: 'Sürüm 1.0.0 & sistem lisansı',
                    destination: const AboutScreen(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // En Altta: Oturumu Kapat
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.danger.withOpacity(0.3)),
                ),
                tileColor: AppColors.danger.withOpacity(0.08),
                leading: const Icon(Icons.logout, color: AppColors.danger),
                title: const Text(
                  'Oturumu Kapat',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.danger),
                onTap: () => _showLogoutDialog(context),
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
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
        onTap: () {
          Navigator.pop(context); // Close Drawer
          Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
        },
      ),
    );
  }
}
