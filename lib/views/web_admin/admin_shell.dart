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
import 'dashboard_tab.dart';
import 'employees_tab.dart';
import 'shifts_tab.dart';
import 'leaves_management_tab.dart';
import 'reports_puantaj_tab.dart';

class AdminShell extends StatefulWidget {
  final VoidCallback onSwitchToMobile;
  final VoidCallback onSwitchToKiosk;

  const AdminShell({
    super.key,
    required this.onSwitchToMobile,
    required this.onSwitchToKiosk,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'İK Genel Bakış & Dashboard',
    'Personel Yönetimi',
    'Vardiya & Çalışma Takvimi',
    'İzin Talepleri & Onay Yönetimi',
    'Puantaj & Bordro Raporları',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Row(
        children: [
          // Sol Sidebar Navigasyon
          Container(
            width: 260,
            color: const Color(0xFF0F172A),
            child: Column(
              children: [
                // Logo & Şirket Başlığı
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.fingerprint, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PDKS Web',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'Yönetici Paneli',
                            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(color: Colors.white12, height: 1),

                const SizedBox(height: 16),

                // Menü Öğeleri
                _buildNavItem(0, Icons.dashboard_outlined, 'Dashboard'),
                _buildNavItem(1, Icons.people_outline, 'Personeller'),
                _buildNavItem(2, Icons.calendar_month_outlined, 'Vardiya & Takvim'),
                _buildNavItem(3, Icons.beach_access_outlined, 'İzin Yönetimi'),
                _buildNavItem(4, Icons.assessment_outlined, 'Puantaj & Rapor'),

                const Spacer(),

                // Mod Değiştirme Kısayolları (Demo kolaylığı)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        tileColor: Colors.white.withOpacity(0.06),
                        leading: const Icon(Icons.tablet_mac, color: Colors.white70, size: 20),
                        title: const Text('Turnike Kiosk Modu', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        onTap: widget.onSwitchToKiosk,
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        tileColor: Colors.white.withOpacity(0.06),
                        leading: const Icon(Icons.smartphone, color: Colors.white70, size: 20),
                        title: const Text('Mobil Görünüme Geç', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        onTap: widget.onSwitchToMobile,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sağ Ana İçerik Alanı
          Expanded(
            child: Column(
              children: [
                // Üst Başlık Barı (Topbar)
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _titles[_selectedIndex],
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.cloud_done, color: AppColors.success, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Sistem Çevrimiçi',
                                  style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          PopupMenuButton<String>(
                            tooltip: 'Hesap & Menü',
                            offset: const Offset(0, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                context.watch<PdksState>().currentUser.fullName.isNotEmpty
                                    ? context.watch<PdksState>().currentUser.fullName.substring(0, 2).toUpperCase()
                                    : 'P',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            onSelected: (val) {
                              switch (val) {
                                case 'profile':
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                                  break;
                                case 'contacts':
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen()));
                                  break;
                                case 'business_card':
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessCardScreen()));
                                  break;
                                case 'favorites':
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
                                  break;
                                case 'settings':
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                                  break;
                                case 'about':
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
                                  break;
                                case 'logout':
                                  context.read<PdksState>().logout();
                                  break;
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'profile',
                                child: Row(children: [Icon(Icons.person_outline, size: 20), SizedBox(width: 12), Text('Profil')]),
                              ),
                              const PopupMenuItem(
                                value: 'contacts',
                                child: Row(children: [Icon(Icons.people_alt_outlined, size: 20), SizedBox(width: 12), Text('Kişiler')]),
                              ),
                              const PopupMenuItem(
                                value: 'business_card',
                                child: Row(children: [Icon(Icons.badge_outlined, size: 20), SizedBox(width: 12), Text('Kartvizit')]),
                              ),
                              const PopupMenuItem(
                                value: 'favorites',
                                child: Row(children: [Icon(Icons.star_border, size: 20), SizedBox(width: 12), Text('Sık Kullanılanlar')]),
                              ),
                              const PopupMenuItem(
                                value: 'settings',
                                child: Row(children: [Icon(Icons.settings_outlined, size: 20), SizedBox(width: 12), Text('Ayarlar')]),
                              ),
                              const PopupMenuItem(
                                value: 'about',
                                child: Row(children: [Icon(Icons.info_outline, size: 20), SizedBox(width: 12), Text('Hakkımda')]),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'logout',
                                child: Row(children: [Icon(Icons.logout, size: 20, color: AppColors.danger), SizedBox(width: 12), Text('Oturumu Kapat', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold))]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Gövde İçeriği
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: const [
                      DashboardTab(),
                      EmployeesTab(),
                      ShiftsTab(),
                      LeavesManagementTab(),
                      ReportsPuantajTab(),
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

  Widget _buildNavItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: isSelected ? AppColors.primary : Colors.transparent,
        leading: Icon(icon, color: isSelected ? Colors.white : const Color(0xFFCBD5E1), size: 20),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        onTap: () => setState(() => _selectedIndex = index),
      ),
    );
  }
}
