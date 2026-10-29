import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
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
                            style: TextStyle(color: Colors.white54, fontSize: 12),
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
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primaryLight,
                            child: Text('İK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
        leading: Icon(icon, color: isSelected ? Colors.white : Colors.white60, size: 20),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: () => setState(() => _selectedIndex = index),
      ),
    );
  }
}
