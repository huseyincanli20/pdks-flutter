import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../state/pdks_state.dart';

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

  void _showThemePickerModal(BuildContext context) {
    final pdks = context.read<PdksState>();
    final currentMode = pdks.themeMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Çekmece Tutamacı
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 18),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.palette_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Görünüm Teması',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Uygulama renk modunu tercihinize göre belirleyin',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 1. Sistem Varsayılanı
              _buildThemeOptionTile(
                ctx,
                title: 'Sistem Varsayılanı',
                subtitle: 'Telefonunuzun (iOS / Android) temasını otomatik takip eder',
                icon: Icons.brightness_auto_rounded,
                iconColor: const Color(0xFF3B82F6),
                isSelected: currentMode == ThemeMode.system,
                onTap: () {
                  pdks.setThemeMode(ThemeMode.system);
                  Navigator.pop(ctx);
                  _showToast(context, 'Sistem teması etkinleştirildi.');
                },
              ),
              const SizedBox(height: 10),

              // 2. Aydınlık (Light) Tema
              _buildThemeOptionTile(
                ctx,
                title: 'Aydınlık (Light) Mod',
                subtitle: 'Ferah, canlı ve berrak gündüz görünümü',
                icon: Icons.light_mode_rounded,
                iconColor: const Color(0xFFF59E0B),
                isSelected: currentMode == ThemeMode.light,
                onTap: () {
                  pdks.setThemeMode(ThemeMode.light);
                  Navigator.pop(ctx);
                  _showToast(context, 'Aydınlık tema etkinleştirildi.');
                },
              ),
              const SizedBox(height: 10),

              // 3. Koyu (Dark) Tema
              _buildThemeOptionTile(
                ctx,
                title: 'Koyu (Dark / Gece) Mod',
                subtitle: 'AMOLED derin siyah tonlar, göz konforu ve pil tasarrufu',
                icon: Icons.dark_mode_rounded,
                iconColor: const Color(0xFF8B5CF6),
                isSelected: currentMode == ThemeMode.dark,
                onTap: () {
                  pdks.setThemeMode(ThemeMode.dark);
                  Navigator.pop(ctx);
                  _showToast(context, 'Koyu tema etkinleştirildi.');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        content: Text(message),
      ),
    );
  }

  Widget _buildThemeOptionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(isDark ? 0.2 : 0.08)
                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? Colors.white : AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                )
              else
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? Colors.white30 : Colors.grey.shade400, width: 1.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();

    return Scaffold(
      backgroundColor: AppColors.bg(context),
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
          _buildSectionHeader('GÖRÜNÜM VE TEMA TERCİHİ'),
          _buildCardGroup(context, [
            _buildActionItem(
              context,
              title: 'Görünüm Teması',
              subtitle: 'Aydınlık, Koyu veya Otomatik Sistem Teması',
              icon: Icons.palette_outlined,
              iconColor: const Color(0xFF3B82F6),
              trailingText: pdks.themeModeName,
              trailingBadgeColor: AppColors.primary,
              onTap: () => _showThemePickerModal(context),
            ),
          ]),

          const SizedBox(height: 20),
          _buildSectionHeader('BİLDİRİM VE HATIRLATICILAR'),
          _buildCardGroup(context, [
            _buildSwitchItem(
              context,
              title: 'Mesai Başlama Hatırlatıcısı',
              subtitle: 'Sabah 08:20\'de giriş yapmayı hatırlat',
              icon: Icons.notifications_active_outlined,
              iconColor: const Color(0xFF3B82F6),
              value: _notifyCheckIn,
              onChanged: (val) => setState(() => _notifyCheckIn = val),
            ),
            Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.cardBorder(context)),
            _buildSwitchItem(
              context,
              title: 'Çıkış Unutma Uyarısı',
              subtitle: 'Akşam 18:00\'de çıkış kartını okutma bildirimi',
              icon: Icons.alarm_outlined,
              iconColor: const Color(0xFFF59E0B),
              value: _notifyCheckOut,
              onChanged: (val) => setState(() => _notifyCheckOut = val),
            ),
            Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.cardBorder(context)),
            _buildSwitchItem(
              context,
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
          _buildCardGroup(context, [
            _buildSwitchItem(
              context,
              title: 'Biyometrik Onay (FaceID / TouchID)',
              subtitle: 'Giriş ve çıkışlarda fiziksel kimlik onayı iste',
              icon: Icons.fingerprint_rounded,
              iconColor: const Color(0xFF6366F1),
              value: _biometricEnabled,
              onChanged: (val) => setState(() => _biometricEnabled = val),
            ),
            Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.cardBorder(context)),
            _buildSwitchItem(
              context,
              title: 'Fused GPS Hassas Konum',
              subtitle: 'Geofence sınır doğrulaması için yüksek hassasiyet',
              icon: Icons.my_location_rounded,
              iconColor: const Color(0xFF06B6D4),
              value: _autoGps,
              onChanged: (val) => setState(() => _autoGps = val),
            ),
          ]),

          const SizedBox(height: 20),
          _buildSectionHeader('DİL VE BÖLGE'),
          _buildCardGroup(context, [
            _buildActionItem(
              context,
              title: 'Uygulama Dili',
              subtitle: 'Varsayılan sistem dili',
              icon: Icons.language_rounded,
              iconColor: const Color(0xFF8B5CF6),
              trailingText: 'Türkçe (TR)',
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

  Widget _buildCardGroup(BuildContext context, List<Widget> children) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _buildSwitchItem(
    BuildContext context, {
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
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.textSub(context))),
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

  Widget _buildActionItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String trailingText,
    Color? trailingBadgeColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
                    Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.textSub(context))),
                  ],
                ),
              ),
              if (trailingBadgeColor != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: trailingBadgeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    trailingText,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: trailingBadgeColor),
                  ),
                )
              else
                Text(trailingText, style: TextStyle(fontSize: 13, color: AppColors.textSub(context))),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
