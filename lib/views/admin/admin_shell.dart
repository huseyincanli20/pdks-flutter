import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/employee.dart';
import '../../state/pdks_state.dart';
import '../common/app_drawer.dart';
import '../notifications/notifications_screen.dart';
import '../common/admin_edit_mode_bar.dart';
import '../../models/page_customization.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  late TextEditingController _latCtrl;
  late TextEditingController _lngCtrl;
  late TextEditingController _radCtrl;
  late TextEditingController _wifiCtrl;
  bool _isLatApproved = true;
  bool _isLngApproved = true;

  @override
  void initState() {
    super.initState();
    final pdks = context.read<PdksState>();
    _latCtrl = TextEditingController(text: pdks.officeLat.toStringAsFixed(5));
    _lngCtrl = TextEditingController(text: pdks.officeLng.toStringAsFixed(5));
    _radCtrl = TextEditingController(text: pdks.allowedRadiusMeters.toStringAsFixed(0));
    _wifiCtrl = TextEditingController(text: pdks.allowedWifiSsid);
  }

  @override
  void dispose() {
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _radCtrl.dispose();
    _wifiCtrl.dispose();
    super.dispose();
  }

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
      body: Column(
        children: [
          AdminEditModeBar(
            pageId: 'admin_shell',
            pageTitle: 'Admin Yönetim Paneli',
            editableSections: [
              PageSectionItem(id: 'tab_$_currentIndex', title: '${titles[_currentIndex]} Sekme İçeriği'),
            ],
          ),
          Expanded(child: tabs[_currentIndex]),
        ],
      ),
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
                          '${emp.department} • PIN: ${emp.pinCode} • ${emp.roleDisplayName}',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          Text('Ofis Geofence & Şirket Koordinatları', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          const SizedBox(height: 4),
          Text('Personelin giriş ve çıkış yapabilmesi için şirketin resmi enlem/boylam koordinatları ve onay durumu.', style: TextStyle(color: AppColors.textSub(context), fontSize: 12)),
          const SizedBox(height: 16),

          // Şirket Adresi ve Koordinat Kartı (Sincan / Ankara)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Fırat Cd. 14, 06946 Sincan Ankara',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text(context)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Şirket Konumu', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Koordinatlar: 40,01461° K, 32,51520° D',
                        style: TextStyle(fontSize: 11, color: AppColors.textSub(context), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  icon: const Icon(Icons.sync_rounded, size: 16),
                  label: const Text('Doldur', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    setState(() {
                      _latCtrl.text = '40.01461';
                      _lngCtrl.text = '32.51520';
                      _isLatApproved = true;
                      _isLngApproved = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.primary,
                        content: Text('Sincan/Ankara koordinatları yüklendi ve onaylandı.'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Form Alanları Kartı
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
                // 1. Ofis Enlemi (Latitude) + Onay Kutucuğu
                Text('Ofis Enlemi (Latitude)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSub(context))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _latCtrl,
                        decoration: InputDecoration(
                          hintText: '40.01461',
                          prefixIcon: const Icon(Icons.explore_outlined, color: AppColors.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Enlem Onay Kutucuğu
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isLatApproved
                            ? AppColors.success.withOpacity(isDark ? 0.2 : 0.1)
                            : (isDark ? const Color(0xFF131B2E) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isLatApproved ? AppColors.success : AppColors.cardBorder(context),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: _isLatApproved,
                            activeColor: AppColors.success,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              setState(() => _isLatApproved = val ?? false);
                            },
                          ),
                          InkWell(
                            onTap: () => setState(() => _isLatApproved = !_isLatApproved),
                            child: Text(
                              'Onayla',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _isLatApproved ? AppColors.success : AppColors.textSub(context),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 2. Ofis Boylamı (Longitude) + Onay Kutucuğu
                Text('Ofis Boylamı (Longitude)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSub(context))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _lngCtrl,
                        decoration: InputDecoration(
                          hintText: '32.51520',
                          prefixIcon: const Icon(Icons.explore_outlined, color: AppColors.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Boylam Onay Kutucuğu
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isLngApproved
                            ? AppColors.success.withOpacity(isDark ? 0.2 : 0.1)
                            : (isDark ? const Color(0xFF131B2E) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isLngApproved ? AppColors.success : AppColors.cardBorder(context),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: _isLngApproved,
                            activeColor: AppColors.success,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              setState(() => _isLngApproved = val ?? false);
                            },
                          ),
                          InkWell(
                            onTap: () => setState(() => _isLngApproved = !_isLngApproved),
                            child: Text(
                              'Onayla',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _isLngApproved ? AppColors.success : AppColors.textSub(context),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 3. İzin Verilen Yarıçap
                Text('İzin Verilen Yarıçap (Metre)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSub(context))),
                const SizedBox(height: 6),
                TextField(
                  controller: _radCtrl,
                  decoration: InputDecoration(
                    hintText: '150',
                    prefixIcon: const Icon(Icons.radar, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                // 4. Ofis Wi-Fi SSID
                Text('Ofis Wi-Fi SSID Adı', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSub(context))),
                const SizedBox(height: 6),
                TextField(
                  controller: _wifiCtrl,
                  decoration: InputDecoration(
                    hintText: 'Sirket_Personel',
                    prefixIcon: const Icon(Icons.wifi, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),

                const SizedBox(height: 22),

                // Kaydet Butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Şirket Koordinatlarını ve Ayarları Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      final lat = double.tryParse(_latCtrl.text.replaceAll(',', '.')) ?? pdks.officeLat;
                      final lng = double.tryParse(_lngCtrl.text.replaceAll(',', '.')) ?? pdks.officeLng;
                      final radius = double.tryParse(_radCtrl.text) ?? pdks.allowedRadiusMeters;

                      setState(() {
                        _isLatApproved = true;
                        _isLngApproved = true;
                      });

                      pdks.updateSystemSettings(
                        lat: lat,
                        lng: lng,
                        radius: radius,
                        wifiSsid: _wifiCtrl.text.trim(),
                        address: 'Fırat Cd. 14, 06946 Sincan Ankara',
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.success,
                          content: Text('Şirket koordinatları ($lat, $lng - Fırat Cd. 14, Sincan) onaylandı ve kaydedildi!'),
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
