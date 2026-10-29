import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifyCheckIn = true;
  bool _notifyCheckOut = true;
  bool _notifyLeaves = true;
  bool _biometricEnabled = true;
  bool _autoGps = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Ayarlar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        children: [
          _buildSectionHeader('BİLDİRİM VE HATIRLATICILAR'),
          _buildCardGroup([
            _buildSwitchItem(
              title: 'Mesai Başlama Hatırlatıcısı',
              subtitle: 'Sabah 08:20\'de giriş yapmayı hatırlat',
              icon: Icons.notifications_active_outlined,
              iconColor: const Color(0xFF3B82F6),
              value: _notifyCheckIn,
              onChanged: (val) => setState(() => _notifyCheckIn = val),
            ),
            const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF1F5F9)),
            _buildSwitchItem(
              title: 'Çıkış Unutma Uyarısı',
              subtitle: 'Akşam 18:00\'de çıkış kartını okutma bildirimi',
              icon: Icons.alarm_outlined,
              iconColor: const Color(0xFFF59E0B),
              value: _notifyCheckOut,
              onChanged: (val) => setState(() => _notifyCheckOut = val),
            ),
            const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF1F5F9)),
            _buildSwitchItem(
              title: 'İzin Durum Bildirimleri',
              subtitle: 'Yöneticiniz talebi yanıtladığında anında ilet',
              icon: Icons.beach_access_outlined,
              iconColor: const Color(0xFF10B981),
              value: _notifyLeaves,
              onChanged: (val) => setState(() => _notifyLeaves = val),
            ),
          ]),

          const SizedBox(height: 20),
          _buildSectionHeader('GÜVENLİK VE BİYOMETRİ'),
          _buildCardGroup([
            _buildSwitchItem(
              title: 'Biyometrik Onay (FaceID / TouchID)',
              subtitle: 'Giriş ve çıkışlarda fiziksel kimlik onayı iste',
              icon: Icons.fingerprint_rounded,
              iconColor: const Color(0xFF6366F1),
              value: _biometricEnabled,
              onChanged: (val) => setState(() => _biometricEnabled = val),
            ),
            const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF1F5F9)),
            _buildSwitchItem(
              title: 'Fused GPS Hassas Konum',
              subtitle: 'Geofence sınır doğrulaması için yüksek hassasiyet',
              icon: Icons.my_location_rounded,
              iconColor: const Color(0xFF06B6D4),
              value: _autoGps,
              onChanged: (val) => setState(() => _autoGps = val),
            ),
          ]),

          const SizedBox(height: 20),
          _buildSectionHeader('UYGULAMA VE DİL TERCİHLERİ'),
          _buildCardGroup([
            _buildActionItem(
              title: 'Uygulama Dili',
              subtitle: 'Türkçe (TR)',
              icon: Icons.language_rounded,
              iconColor: const Color(0xFF8B5CF6),
              trailingText: 'Türkçe',
              onTap: () {},
            ),
            const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF1F5F9)),
            _buildActionItem(
              title: 'Görünüm Teması',
              subtitle: 'Sistem varsayılanı (Aydınlık)',
              icon: Icons.brightness_6_outlined,
              iconColor: const Color(0xFF64748B),
              trailingText: 'Aydınlık',
              onTap: () {},
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.1),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String trailingText,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Text(trailingText, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
