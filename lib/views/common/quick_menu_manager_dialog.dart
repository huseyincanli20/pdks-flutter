import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/employee.dart';
import '../../state/pdks_state.dart';

class QuickMenuManagerDialog extends StatefulWidget {
  const QuickMenuManagerDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const QuickMenuManagerDialog(),
    );
  }

  @override
  State<QuickMenuManagerDialog> createState() => _QuickMenuManagerDialogState();
}

class _QuickMenuManagerDialogState extends State<QuickMenuManagerDialog> {
  void _showAddMenuDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final subtitleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String selectedAction = 'info_dialog';
    int selectedIconCode = 0xe425; // near_me
    int selectedColorValue = 0xFF2563EB; // primary blue

    final availableIcons = [
      {'code': 0xe425, 'icon': Icons.near_me_rounded, 'name': 'Navigasyon / Konum'},
      {'code': 0xe3ab, 'icon': Icons.location_on_rounded, 'name': 'Pin / Saha'},
      {'code': 0xe156, 'icon': Icons.beach_access_rounded, 'name': 'İzin / Tatil'},
      {'code': 0xe314, 'icon': Icons.history_rounded, 'name': 'Geçmiş / Saat'},
      {'code': 0xe40f, 'icon': Icons.more_time_rounded, 'name': 'Fazla Mesai'},
      {'code': 0xe506, 'icon': Icons.restaurant_rounded, 'name': 'Yemek'},
      {'code': 0xe153, 'icon': Icons.campaign_rounded, 'name': 'Duyuru'},
      {'code': 0xe84f, 'icon': Icons.account_balance_wallet_rounded, 'name': 'Finans / Harcama'},
      {'code': 0xe88a, 'icon': Icons.home_work_rounded, 'name': 'Evden / Hibrit'},
    ];

    final availableColors = [
      0xFF2563EB, // Mavi
      0xFF10B981, // Yeşil
      0xFFF59E0B, // Kehribar
      0xFF8B5CF6, // Mor
      0xFFEF4444, // Kırmızı
      0xFF06B6D4, // Camgöbeği
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.add_circle_outline_rounded, color: Color(0xFF2563EB), size: 24),
                SizedBox(width: 8),
                Text('Yeni Hızlı Menü Ekle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Menü Başlığı *',
                      hintText: 'Örn: Şirket Aracı Talep',
                      prefixIcon: Icon(Icons.title_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: subtitleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Alt Başlık / Açıklama *',
                      hintText: 'Örn: Saha araç rezervasyonu yapın',
                      prefixIcon: Icon(Icons.subtitles_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedAction,
                    decoration: const InputDecoration(
                      labelText: 'Tıklama İşlemi',
                      prefixIcon: Icon(Icons.touch_app_rounded, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'field_work', child: Text('Dışarıda Çalışma (Konum İlet)')),
                      DropdownMenuItem(value: 'leave', child: Text('İzin Talebi Sayfası')),
                      DropdownMenuItem(value: 'records', child: Text('Giriş / Çıkışlar')),
                      DropdownMenuItem(value: 'overtime', child: Text('Fazla Mesai Talebi')),
                      DropdownMenuItem(value: 'cafeteria', child: Text('Yemekhane Menüsü')),
                      DropdownMenuItem(value: 'info_dialog', child: Text('Özel Bilgi / Duyuru Penceresi')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedAction = val);
                    },
                  ),
                  if (selectedAction == 'info_dialog') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: contentCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Açılacak Bilgi İçeriği',
                        hintText: 'Personele gösterilecek detaylı metin...',
                        prefixIcon: Icon(Icons.notes_rounded, size: 20),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Text('Simge Seçiniz:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableIcons.map((ic) {
                      final isSel = selectedIconCode == ic['code'];
                      return InkWell(
                        onTap: () => setDialogState(() => selectedIconCode = ic['code'] as int),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF2563EB).withOpacity(0.18) : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSel ? const Color(0xFF2563EB) : Colors.transparent, width: 2),
                          ),
                          child: Icon(ic['icon'] as IconData, size: 20, color: isSel ? const Color(0xFF2563EB) : Colors.grey),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  const Text('Renk Seçiniz:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: availableColors.map((colVal) {
                      final isSel = selectedColorValue == colVal;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setDialogState(() => selectedColorValue = colVal),
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Color(colVal),
                              shape: BoxShape.circle,
                              border: Border.all(color: isSel ? Colors.white : Colors.transparent, width: 2.5),
                              boxShadow: isSel ? [const BoxShadow(color: Colors.black26, blurRadius: 4)] : null,
                            ),
                            child: isSel ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final pdks = context.read<PdksState>();
                  final res = pdks.addQuickMenuItem(
                    title: titleCtrl.text,
                    subtitle: subtitleCtrl.text,
                    iconCode: selectedIconCode,
                    colorValue: selectedColorValue,
                    actionType: selectedAction,
                    customContent: contentCtrl.text.trim().isEmpty ? null : contentCtrl.text.trim(),
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res.message),
                      backgroundColor: res.success ? AppColors.success : AppColors.danger,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canManage = pdks.currentUser.role == UserRole.boss || pdks.currentUser.role == UserRole.admin;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.tune_rounded, color: Color(0xFF2563EB), size: 22),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Hızlı Menü Yönetimi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CEO ve Admin yetkisiyle personellerin gördüğü hızlı menüleri gizleyebilir veya yeni kurumsal kısayollar ekleyebilirsiniz.',
                style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 14),

              if (canManage) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Yeni Hızlı Menü Ekle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () => _showAddMenuDialog(context),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              const Text('Mevcut Menüler & Görünürlük:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              ...pdks.quickMenuItems.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: item.isVisible
                          ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                          : Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon, color: item.color, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                decoration: item.isVisible ? null : TextDecoration.lineThrough,
                                color: item.isVisible ? (isDark ? Colors.white : AppColors.textPrimary) : Colors.grey,
                              ),
                            ),
                            Text(
                              item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      if (canManage) ...[
                        Switch(
                          value: item.isVisible,
                          activeColor: const Color(0xFF10B981),
                          onChanged: (_) {
                            pdks.toggleQuickMenuItemVisibility(item.id);
                          },
                        ),
                        if (item.id.startsWith('qm_') && !['qm_leave', 'qm_records', 'qm_field_work', 'qm_overtime', 'qm_cafeteria'].contains(item.id))
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                            onPressed: () {
                              pdks.deleteQuickMenuItem(item.id);
                            },
                          ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('Tamam', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
