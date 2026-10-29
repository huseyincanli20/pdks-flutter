import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/database_service.dart';
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
  static const List<Map<String, dynamic>> _quickPresets = [
    {
      'title': 'Profil',
      'subtitle': 'Kişisel bilgiler & izin bakiyesi',
      'actionType': 'profile',
      'iconCode': 0xe491,
      'colorValue': 0xFF2563EB,
    },
    {
      'title': 'Bordro & Maaş',
      'subtitle': 'Aylık maaş hesaplama & icmal',
      'actionType': 'payroll',
      'iconCode': 0xf00ee,
      'colorValue': 0xFF10B981,
    },
    {
      'title': 'Mesajlaşma',
      'subtitle': 'Şirket içi kanallar & 1-e-1 sohbet',
      'actionType': 'chat',
      'iconCode': 0xe153,
      'colorValue': 0xFF0284C7,
    },
    {
      'title': 'Kişiler',
      'subtitle': 'Şirket rehberi & mesai arkadaşları',
      'actionType': 'contacts',
      'iconCode': 0xe49b,
      'colorValue': 0xFF4F46E5,
    },
    {
      'title': 'Bildirimler',
      'subtitle': 'Duyurular & sistem onayları',
      'actionType': 'notifications',
      'iconCode': 0xe44f,
      'colorValue': 0xFF8B5CF6,
    },
    {
      'title': 'Yemekhane Menüsü',
      'subtitle': 'Günün menüsü & 2 haftalık çizelge',
      'actionType': 'cafeteria',
      'iconCode': 0xe506,
      'colorValue': 0xFFEA580C,
    },
    {
      'title': 'Kartvizit',
      'subtitle': 'Dijital QR kodlu şirket kartı',
      'actionType': 'business_card',
      'iconCode': 0xf04ee,
      'colorValue': 0xFF0D9488,
    },
    {
      'title': 'Sık Kullanılanlar',
      'subtitle': 'Hızlı kısayollar, yemek & servis',
      'actionType': 'favorites',
      'iconCode': 0xe5f9,
      'colorValue': 0xFFD97706,
    },
    {
      'title': 'İzin Talebi',
      'subtitle': 'Yıllık izin veya mazeret talebi oluşturun',
      'actionType': 'leave',
      'iconCode': 0xe156,
      'colorValue': 0xFFF59E0B,
    },
    {
      'title': 'Giriş / Çıkışlar',
      'subtitle': 'Geçmiş devam ve yoklama kayıtları',
      'actionType': 'records',
      'iconCode': 0xe314,
      'colorValue': 0xFF2563EB,
    },
    {
      'title': 'Dışarıda Çalışma 📍',
      'subtitle': 'Saha görevi ve anlık konum bildirimi',
      'actionType': 'field_work',
      'iconCode': 0xe425,
      'colorValue': 0xFF10B981,
    },
    {
      'title': 'Fazla Mesai Talebi',
      'subtitle': 'Ek mesai saat talebi bildirin',
      'actionType': 'overtime',
      'iconCode': 0xe40f,
      'colorValue': 0xFF9333EA,
    },
    {
      'title': 'Ayarlar',
      'subtitle': 'Tema, bildirim ve sistem tercihleri',
      'actionType': 'settings',
      'iconCode': 0xe57f,
      'colorValue': 0xFF475569,
    },
    {
      'title': 'Hakkımda',
      'subtitle': 'Sürüm 1.0.0 & sistem güvenliği',
      'actionType': 'about',
      'iconCode': 0xe33d,
      'colorValue': 0xFF0284C7,
    },
    {
      'title': 'Firebase Bulut DB',
      'subtitle': 'Merkezi bulut senkronizasyonu',
      'actionType': 'cloud_db',
      'iconCode': 0xe87a,
      'colorValue': 0xFFFF5722,
    },
  ];

  void _showAddMenuDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final subtitleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String selectedAction = 'info_dialog';
    int selectedIconCode = 0xe425; // near_me
    int selectedColorValue = 0xFF2563EB; // primary blue

    final availableIcons = [
      {'code': 0xe491, 'icon': Icons.person_rounded, 'name': 'Profil'},
      {'code': 0xf00ee, 'icon': Icons.receipt_long_rounded, 'name': 'Bordro / Fatura'},
      {'code': 0xe153, 'icon': Icons.chat_bubble_rounded, 'name': 'Mesajlaşma'},
      {'code': 0xe49b, 'icon': Icons.people_alt_rounded, 'name': 'Kişiler'},
      {'code': 0xe44f, 'icon': Icons.notifications_rounded, 'name': 'Bildirim'},
      {'code': 0xe506, 'icon': Icons.restaurant_rounded, 'name': 'Yemek'},
      {'code': 0xf04ee, 'icon': Icons.badge_rounded, 'name': 'Kartvizit'},
      {'code': 0xe5f9, 'icon': Icons.star_rounded, 'name': 'Yıldız / Favori'},
      {'code': 0xe156, 'icon': Icons.beach_access_rounded, 'name': 'İzin / Tatil'},
      {'code': 0xe314, 'icon': Icons.history_rounded, 'name': 'Geçmiş / Saat'},
      {'code': 0xe425, 'icon': Icons.near_me_rounded, 'name': 'Navigasyon / Konum'},
      {'code': 0xe3ab, 'icon': Icons.location_on_rounded, 'name': 'Pin / Saha'},
      {'code': 0xe40f, 'icon': Icons.more_time_rounded, 'name': 'Fazla Mesai'},
      {'code': 0xe57f, 'icon': Icons.settings_rounded, 'name': 'Ayarlar'},
      {'code': 0xe33d, 'icon': Icons.info_rounded, 'name': 'Bilgi'},
      {'code': 0xe87a, 'icon': Icons.local_fire_department_rounded, 'name': 'Firebase Bulut'},
    ];

    final availableColors = [
      0xFF2563EB, // Mavi
      0xFF10B981, // Yeşil
      0xFFF59E0B, // Kehribar
      0xFF8B5CF6, // Mor
      0xFFEF4444, // Kırmızı
      0xFF06B6D4, // Camgöbeği
      0xFFEA580C, // Turuncu
      0xFF0D9488, // Teal
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
                  const Text('Hazır Sistem Şablonları:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _quickPresets.map((p) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text(p['title'] as String, style: const TextStyle(fontSize: 11)),
                            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            onPressed: () {
                              setDialogState(() {
                                titleCtrl.text = p['title'] as String;
                                subtitleCtrl.text = p['subtitle'] as String;
                                selectedAction = p['actionType'] as String;
                                selectedIconCode = p['iconCode'] as int;
                                selectedColorValue = p['colorValue'] as int;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                      labelText: 'Tıklama İşlemi / Hedef Sayfa',
                      prefixIcon: Icon(Icons.touch_app_rounded, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'profile', child: Text('Profil & İzin Bakiyesi')),
                      DropdownMenuItem(value: 'payroll', child: Text('Bordro & Maaş Yönetimi')),
                      DropdownMenuItem(value: 'chat', child: Text('Mesajlaşma (Sohbet & Kanallar)')),
                      DropdownMenuItem(value: 'contacts', child: Text('Kişiler (Şirket Rehberi)')),
                      DropdownMenuItem(value: 'notifications', child: Text('Bildirimler')),
                      DropdownMenuItem(value: 'cafeteria', child: Text('Yemekhane Menüsü')),
                      DropdownMenuItem(value: 'business_card', child: Text('Dijital Kartvizit')),
                      DropdownMenuItem(value: 'favorites', child: Text('Sık Kullanılanlar')),
                      DropdownMenuItem(value: 'leave', child: Text('İzin Talebi Sayfası')),
                      DropdownMenuItem(value: 'records', child: Text('Giriş / Çıkışlar')),
                      DropdownMenuItem(value: 'field_work', child: Text('Dışarıda Çalışma (Konum İlet)')),
                      DropdownMenuItem(value: 'overtime', child: Text('Fazla Mesai Talebi')),
                      DropdownMenuItem(value: 'settings', child: Text('Uygulama Ayarları')),
                      DropdownMenuItem(value: 'about', child: Text('Hakkımda & Sürüm')),
                      DropdownMenuItem(value: 'cloud_db', child: Text('Firebase Bulut DB')),
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
    final defaultIds = DatabaseService.defaultQuickMenuItems().map((d) => d.id).toSet();

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hızlı Menü Yönetimi',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${pdks.visibleQuickMenuItems.length} / ${pdks.quickMenuItems.length} Menü Aktif',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CEO ve Admin yetkisiyle tüm uygulama sayfalarını hızlı menüye ekleyebilir, istemediklerinizi tek tıkla gizleyebilirsiniz.',
                style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 14),

              if (canManage) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Yeni Menü Ekle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () => _showAddMenuDialog(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Varsayılana Sıfırla', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        final res = pdks.resetQuickMenuItemsToDefault();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res.message),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              const Text('Tüm Menüler & Görünürlük Durumu:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              ...pdks.quickMenuItems.map((item) {
                final isDefault = defaultIds.contains(item.id);

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
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    item.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      decoration: item.isVisible ? null : TextDecoration.lineThrough,
                                      color: item.isVisible ? (isDark ? Colors.white : AppColors.textPrimary) : Colors.grey,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isDefault) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('Sistem', style: TextStyle(fontSize: 8.5, color: Colors.blue, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
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
                        if (!isDefault)
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
          child: const Text('Kapat', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
