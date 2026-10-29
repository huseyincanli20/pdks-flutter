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
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('Bildirim Tercihleri'),
          _buildSwitchTile(
            title: 'Mesai Başlama Hatırlatıcısı',
            subtitle: 'Her sabah 08:20\'de giriş yapma uyarısı',
            value: _notifyCheckIn,
            onChanged: (val) => setState(() => _notifyCheckIn = val),
          ),
          _buildSwitchTile(
            title: 'Çıkış Unutma Uyarısı',
            subtitle: 'Akşam 18:00\'de çıkış kartını okutma bildirimi',
            value: _notifyCheckOut,
            onChanged: (val) => setState(() => _notifyCheckOut = val),
          ),
          _buildSwitchTile(
            title: 'İzin Durum Bildirimleri',
            subtitle: 'Yöneticiniz izin onayladığında/reddettiğinde anında ilet',
            value: _notifyLeaves,
            onChanged: (val) => setState(() => _notifyLeaves = val),
          ),

          const SizedBox(height: 20),
          _buildSectionHeader('Güvenlik & Biyometri'),
          _buildSwitchTile(
            title: 'Biyometrik Onay (FaceID / Parmak İzi)',
            subtitle: 'Giriş ve çıkışlarda fiziksel kimlik onayı iste',
            value: _biometricEnabled,
            onChanged: (val) => setState(() => _biometricEnabled = val),
          ),
          _buildSwitchTile(
            title: 'Otomatik Yüksek GPS Hassasiyeti',
            subtitle: 'Geofence doğrulaması için Fused Location kullan',
            value: _autoGps,
            onChanged: (val) => setState(() => _autoGps = val),
          ),

          const SizedBox(height: 20),
          _buildSectionHeader('Uygulama Tercihleri'),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: Colors.white,
            leading: const Icon(Icons.language, color: AppColors.primary),
            title: const Text('Dil / Language', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            trailing: const Text('Türkçe (TR)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          const SizedBox(height: 8),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: Colors.white,
            leading: const Icon(Icons.brightness_6_outlined, color: AppColors.primary),
            title: const Text('Tema Görünümü', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            trailing: const Text('Aydınlık (Light)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        activeColor: AppColors.primary,
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
