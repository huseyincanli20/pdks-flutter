import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/employee.dart';
import '../../models/page_customization.dart';
import '../../state/pdks_state.dart';
import '../mobile/leave_request_screen.dart';
import '../common/quick_menu_manager_dialog.dart';
import '../common/field_work_dialog.dart';
import '../common/admin_edit_mode_bar.dart';
import '../cafeteria/cafeteria_menu_view_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  void _showInfoDialog(BuildContext context, String title, String content, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.text(context)),
              ),
            ),
          ],
        ),
        content: Text(
          content,
          style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : AppColors.textPrimary, height: 1.6),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final canManage = pdks.currentUser.role == UserRole.boss || pdks.currentUser.role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('Sık Kullanılanlar & Hızlı Menü', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Hızlı Menüyü Düzenle (CEO / Admin)',
              onPressed: () => QuickMenuManagerDialog.show(context),
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        children: [
          // Yönetici & Admin Düzenleme Çubuğu
          const AdminEditModeBar(
            pageId: 'favorites',
            pageTitle: 'Sık Kullanılanlar',
            editableSections: [
              PageSectionItem(id: 'dynamic_quick_menu', title: 'Hızlı Kısayollar (Özel Menü)'),
              PageSectionItem(id: 'corporate_services', title: 'Kurumsal Bilgi Kartları'),
            ],
          ),

          if (canManage) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF2563EB), size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Yönetici Yetkisi: Hızlı menüleri gizleyebilir veya yeni kısayollar ekleyebilirsiniz.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => QuickMenuManagerDialog.show(context),
                    child: const Text('Düzenle ›', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],

          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'HIZLI KISAYOLLAR & KURUMSAL SERVİSLER',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.1),
            ),
          ),

          // Dinamik Hızlı Menü Öğeleri
          AdminEditableSection(
            pageId: 'favorites',
            sectionId: 'dynamic_quick_menu',
            sectionTitle: 'Hızlı Kısayollar (Özel Menü)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: pdks.visibleQuickMenuItems.map((item) {
                return _buildFavoriteCard(
                  context,
                  icon: item.icon,
                  color: item.color,
                  title: item.title,
                  subtitle: item.subtitle,
                  onTap: () {
                    switch (item.actionType) {
                      case 'leave':
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaveRequestScreen()));
                        break;
                      case 'field_work':
                        FieldWorkDialog.show(context);
                        break;
                      case 'cafeteria':
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CafeteriaMenuViewScreen()));
                        break;
                      case 'overtime':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fazla mesai talebiniz yöneticinize iletildi.')),
                        );
                        break;
                      case 'info_dialog':
                      default:
                        _showInfoDialog(
                          context,
                          item.title,
                          item.customContent ?? item.subtitle,
                          item.icon,
                          item.color,
                        );
                        break;
                    }
                  },
                );
              }).toList(),
            ),
          ),

          AdminEditableSection(
            pageId: 'favorites',
            sectionId: 'corporate_services',
            sectionTitle: 'Kurumsal Bilgi Kartları',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFavoriteCard(
                  context,
                  icon: Icons.restaurant_rounded,
                  color: const Color(0xFF10B981),
                  title: 'Günün Yemek Menüsü',
                  subtitle: 'Süzme mercimek, ızgara tavuk, pilav & meyve',
                  onTap: () {
                    _showInfoDialog(
                      context,
                      'Günün Yemek Menüsü',
                      'Bugün şirket yemekhanemizde:\n\n• Süzme Mercimek Çorbası\n• Izgara Tavuk Fileto & Garnitür\n• Tereyağlı Pirinç Pilavı\n• Akdeniz Yeşillikleri Salatası\n• Mevsim Meyvesi & Ayran\n\nAfiyet olsun!',
                      Icons.restaurant_rounded,
                      const Color(0xFF10B981),
                    );
                  },
                ),
                _buildFavoriteCard(
                  context,
                  icon: Icons.directions_bus_rounded,
                  color: const Color(0xFF3B82F6),
                  title: 'Şirket Servis Saatleri',
                  subtitle: 'Kadıköy, Beşiktaş ve Bakırköy akşam güzergahları',
                  onTap: () {
                    _showInfoDialog(
                      context,
                      'Şirket Servis Saatleri',
                      'Akşam Çıkış Servisleri (Kalkış: 18:15):\n\n1. Hat: Maslak - Levent - Zincirlikuyu - Kadıköy\n2. Hat: Maslak - Çağlayan - Mecidiyeköy - Bakırköy\n3. Hat: Maslak - Kozyatağı - Ataşehir - Ümraniye\n4. Hat: Maslak - Kağıthane - Eyüp - Gaziosmanpaşa\n\nServis Sorumlusu İletişim: 0532 000 11 22',
                      Icons.directions_bus_rounded,
                      const Color(0xFF3B82F6),
                    );
                  },
                ),
                _buildFavoriteCard(
                  context,
                  icon: Icons.calendar_month_rounded,
                  color: const Color(0xFF6366F1),
                  title: 'Resmi Tatiller Takvimi',
                  subtitle: '2026 yılı resmi tatil günleri ve köprü tatilleri',
                  onTap: () {
                    _showInfoDialog(
                      context,
                      '2026 Resmi Tatil Günleri',
                      '• 1 Ocak (Perşembe): Yılbaşı\n• 23 Nisan (Perşembe): Ulusal Egemenlik ve Çocuk Bayramı\n• 1 Mayıs (Cuma): Emek ve Dayanışma Günü\n• 19 Mayıs (Salı): Atatürk\'ü Anma, Gençlik ve Spor Bayramı\n• 15 Temmuz (Çarşamba): Demokrasi ve Milli Birlik Günü\n• 30 Ağustos (Pazar): Zafer Bayramı\n• 29 Ekim (Perşembe): Cumhuriyet Bayramı',
                      Icons.calendar_month_rounded,
                      const Color(0xFF6366F1),
                    );
                  },
                ),
                _buildFavoriteCard(
                  context,
                  icon: Icons.medical_services_outlined,
                  color: const Color(0xFFEF4444),
                  title: 'İş Yeri Hekimi & Revir',
                  subtitle: 'Revir mesai saatleri ve acil durum dahili hatları',
                  onTap: () {
                    _showInfoDialog(
                      context,
                      'Revir & Acil Durum',
                      'İş Yeri Hekimi: Dr. Mehmet Yılmaz\nÇalışma Saatleri: Hafta içi 09:00 - 17:30\nKonum: B Blok, Giriş Kat, Oda No: 104\n\nAcil Dahili Hatlar:\n• Revir: Dahili 1044\n• İK Masası: Dahili 1002\n• Güvenlik Masası: Dahili 1000\n• Genel Acil Çağrı: 112',
                      Icons.medical_services_outlined,
                      const Color(0xFFEF4444),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text(context)),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(color: AppColors.textSub(context), fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
