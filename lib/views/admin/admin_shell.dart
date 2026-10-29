import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/employee.dart';
import '../../state/pdks_state.dart';
import '../common/app_drawer.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final user = pdks.currentUser;

    final tabs = [
      _buildRolesManagementTab(context, pdks),
      _buildGeofenceSettingsTab(context, pdks),
      _buildSecurityAuditTab(context),
      _buildKioskSettingsTab(context),
    ];

    final titles = [
      'Rol Yönetimi',
      'Geofence & Lokasyon',
      'Anti-Cheat Güvenlik',
      'Kiosk & Turnike',
    ];

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin • ${titles[_currentIndex]}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text('${user.fullName} (Süper Admin)', style: TextStyle(fontSize: 11, color: AppColors.textSub(context))),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.admin_panel_settings_rounded, color: Colors.purple, size: 14),
                SizedBox(width: 4),
                Text('Sistem Admin', style: TextStyle(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: tabs[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.manage_accounts_outlined),
            selectedIcon: Icon(Icons.manage_accounts, color: AppColors.primary),
            label: 'Roller',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on, color: AppColors.primary),
            label: 'Geofence',
          ),
          NavigationDestination(
            icon: Icon(Icons.security_outlined),
            selectedIcon: Icon(Icons.security, color: AppColors.primary),
            label: 'Güvenlik',
          ),
          NavigationDestination(
            icon: Icon(Icons.tablet_outlined),
            selectedIcon: Icon(Icons.tablet, color: AppColors.primary),
            label: 'Kiosk',
          ),
        ],
      ),
    );
  }

  // 1. Kullanıcı Rolleri Değiştirme Sekmesi
  Widget _buildRolesManagementTab(BuildContext context, PdksState pdks) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      children: [
        Text(
          'Kullanıcı Rolü & Yetki Atama',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
        ),
        const SizedBox(height: 4),
        Text(
          'Kullanıcı giriş yaptığında açılacak ekranı (Personel, İK, Patron veya Admin) buradan belirleyin.',
          style: TextStyle(color: AppColors.textSub(context), fontSize: 12),
        ),
        const SizedBox(height: 16),

        ...pdks.employees.map((emp) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder(context)),
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        emp.fullName.substring(0, 2).toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emp.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${emp.department} • PIN: ${emp.pinCode}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<UserRole>(
                        value: emp.role,
                        isDense: true,
                        items: UserRole.values.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(
                              role.shortLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: role == UserRole.admin
                                    ? Colors.purple
                                    : role == UserRole.boss
                                        ? Colors.orange.shade800
                                        : role == UserRole.hr
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (newRole) {
                          if (newRole != null) {
                            pdks.changeEmployeeRole(emp.id, newRole);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppColors.success,
                                content: Text('${emp.fullName} rolü ${newRole.label} olarak güncellendi.'),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // 2. Geofence & Ofis Lokasyon Ayarları
  Widget _buildGeofenceSettingsTab(BuildContext context, PdksState pdks) {
    final latCtrl = TextEditingController(text: pdks.officeLat.toString());
    final lngCtrl = TextEditingController(text: pdks.officeLng.toString());
    final radCtrl = TextEditingController(text: pdks.allowedRadiusMeters.toStringAsFixed(0));
    final wifiCtrl = TextEditingController(text: pdks.allowedWifiSsid);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ofis Geofence & Lokasyon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          const SizedBox(height: 4),
          Text('Personelin giriş yapabilmesi için izin verilen ofis yarıçapı ve GPS sınırları.', style: TextStyle(color: AppColors.textSub(context), fontSize: 12)),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.cardBorder(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: latCtrl,
                  decoration: InputDecoration(
                    labelText: 'Ofis Enlemi (Latitude)',
                    prefixIcon: const Icon(Icons.explore_outlined, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: lngCtrl,
                  decoration: InputDecoration(
                    labelText: 'Ofis Boylamı (Longitude)',
                    prefixIcon: const Icon(Icons.explore_outlined, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: radCtrl,
                  decoration: InputDecoration(
                    labelText: 'İzin Verilen Yarıçap (Metre)',
                    prefixIcon: const Icon(Icons.radar, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: wifiCtrl,
                  decoration: InputDecoration(
                    labelText: 'Ofis Wi-Fi SSID Adı',
                    prefixIcon: const Icon(Icons.wifi, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Ayarları Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      final lat = double.tryParse(latCtrl.text) ?? pdks.officeLat;
                      final lng = double.tryParse(lngCtrl.text) ?? pdks.officeLng;
                      final radius = double.tryParse(radCtrl.text) ?? pdks.allowedRadiusMeters;
                      pdks.updateSystemSettings(lat: lat, lng: lng, radius: radius, wifiSsid: wifiCtrl.text.trim());

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.success,
                          content: Text('Geofence ve Ağ ayarları başarıyla güncellendi!'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Güvenlik ve Anti-Cheat Denetim Logları
  Widget _buildSecurityAuditTab(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      children: [
        const Text('Güvenlik & Anti-Cheat Denetimi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Sahte GPS (Mock Location) ve yetkisiz işlem teşebbüsleri.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 16),

        _buildAuditTile(
          context,
          title: 'Sahte GPS Engellendi',
          subtitle: 'Ahmet Yılmaz • Mock Location tespit edildi, işlem engellendi.',
          time: 'Bugün 08:34',
          isWarning: true,
        ),
        _buildAuditTile(
          context,
          title: 'QR Kod Zaman Aşımı',
          subtitle: 'Turnike 1 • Süresi dolmuş QR okutuldu (Süre > 10s).',
          time: 'Dün 17:45',
          isWarning: true,
        ),
        _buildAuditTile(
          context,
          title: 'Yetkili Giriş Doğrulandı',
          subtitle: 'Zeynep Kaya • Geofence 18m mesafe içinde onaylandı.',
          time: 'Dün 08:28',
          isWarning: false,
        ),
        _buildAuditTile(
          context,
          title: 'Wi-Fi IP Eşleşmesi',
          subtitle: 'Mehmet Demir • Kurumsal Sirket_Personel ağı ile check-in yapıldı.',
          time: 'Dün 09:12',
          isWarning: false,
        ),
      ],
    );
  }

  Widget _buildAuditTile(BuildContext context, {required String title, required String subtitle, required String time, required bool isWarning}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder(context)),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isWarning ? AppColors.danger : AppColors.success).withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isWarning ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
              color: isWarning ? AppColors.danger : AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isWarning ? AppColors.danger : AppColors.text(context)),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.textSub(context))),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  // 4. Kiosk & Turnike Cihaz Ayarları
  Widget _buildKioskSettingsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Turnike & Kiosk Yapılandırması', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          const SizedBox(height: 4),
          Text('Turnike tabletindeki dinamik QR kodun güvenlik parametreleri.', style: TextStyle(color: AppColors.textSub(context), fontSize: 12)),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.cardBorder(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.timer_rounded, color: AppColors.primary),
                  title: Text('Dinamik QR Kod Yenilenme Süresi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('Her 10 saniyede bir yeni HMAC token üretilir', style: TextStyle(fontSize: 11)),
                  trailing: Chip(
                    label: Text('10 sn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                const Divider(color: Color(0xFFF1F5F9)),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.key_rounded, color: AppColors.primary),
                  title: Text('HMAC Gizli Anahtar (Secret Salt)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('PDKS_SUPER_SECRET_SALT_2026', style: TextStyle(fontSize: 11)),
                  trailing: Icon(Icons.lock_rounded, size: 18, color: AppColors.textMuted),
                ),
                const Divider(color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Cihaz Token Anahtarını Döndür (Rotate Key)', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.success,
                          content: Text('Kiosk güvenlik token anahtarı başarıyla yenilendi!'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
