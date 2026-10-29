import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/employee.dart';
import '../../models/page_customization.dart';
import '../../state/pdks_state.dart';

class AdminEditModeBar extends StatelessWidget {
  final String pageId;
  final String pageTitle;
  final List<PageSectionItem>? editableSections;
  final VoidCallback? onCustomEdit;

  const AdminEditModeBar({
    super.key,
    required this.pageId,
    required this.pageTitle,
    this.editableSections,
    this.onCustomEdit,
  });

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();

    // SADECE YÖNETİCİ (PATRON/CEO) VE ADMİN DEĞİŞTİREBİLİR
    final isAuthorized = pdks.isLoggedIn &&
        (pdks.currentUser.role == UserRole.admin || pdks.currentUser.role == UserRole.boss);

    final config = pdks.getPageCustomization(pageId);

    // Yetkisiz kullanıcılar için sadece aktif duyuru veya bakım modu varsa göster, yoksa gizle
    if (!isAuthorized) {
      if (!config.showAnnouncement && !config.isMaintenanceMode) {
        return const SizedBox.shrink();
      }
    }

    final isEditActive = pdks.isAdminEditMode && isAuthorized;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Duyuru Kutusu (Eğer Admin bu sayfaya duyuru eklediyse)
        if (config.showAnnouncement && config.announcementText != null && config.announcementText!.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: (config.accentColor ?? const Color(0xFF2563EB)).withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: (config.accentColor ?? const Color(0xFF2563EB)).withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Icon(Icons.campaign_rounded, color: config.accentColor ?? const Color(0xFF2563EB), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    config.announcementText!,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text(context),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 2. Bakım Modu Uyarısı (Eğer Admin bu sayfayı bakıma aldıysa)
        if (config.isMaintenanceMode)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade700.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Admin Bildirimi: Bu sayfa şu anda güncelleme/bakım aşamasındadır.',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                  ),
                ),
              ],
            ),
          ),

        // 3. Yönetici & Admin Düzenleme Modu Kontrol Çubuğu (Yalnızca yetkililere görünür)
        if (isAuthorized)
          Container(
          margin: const EdgeInsets.fromLTRB(14, 6, 14, 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isEditActive
                  ? [const Color(0xFF9333EA), const Color(0xFF7E22CE)]
                  : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isEditActive ? const Color(0xFF9333EA) : Colors.black).withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isEditActive ? Icons.build_circle_rounded : Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          isEditActive ? 'DÜZENLEME MODU AÇIK' : 'YÖNETİCİ & ADMİN DÜZENLEME',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isEditActive ? const Color(0xFF10B981) : Colors.white24,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isEditActive ? 'AKTİF' : 'GÖZLEMCİ',
                            style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      isEditActive
                          ? 'Sayfadaki başlıkları ve bölümleri özelleştirin'
                          : '$pageTitle ekranını yönetmek için düzenlemeyi açın',
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Düzenleme Butonları
              if (isEditActive) ...[
                IconButton(
                  icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                  tooltip: 'Sayfayı Özelleştir',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _openPageCustomizationSheet(context, pdks),
                ),
                if (editableSections != null && editableSections!.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.visibility_rounded, color: Colors.white, size: 20),
                    tooltip: 'Bölüm Görünürlükleri',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _openSectionVisibilitySheet(context, pdks),
                  ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.18),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => pdks.toggleAdminEditMode(),
                  child: const Text('Kapat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ] else ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9333EA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    elevation: 0,
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: const Text('Düzenle', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  onPressed: () => pdks.toggleAdminEditMode(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _openPageCustomizationSheet(BuildContext context, PdksState pdks) {
    final current = pdks.getPageCustomization(pageId);

    final titleCtrl = TextEditingController(text: current.customTitle ?? '');
    final subtitleCtrl = TextEditingController(text: current.customSubtitle ?? '');
    final announcementCtrl = TextEditingController(text: current.announcementText ?? '');
    bool showAnnouncement = current.showAnnouncement;
    bool isMaintenance = current.isMaintenanceMode;
    Color? selectedColor = current.accentColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              18,
              20,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sürükleme Çubuğu
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9333EA).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.tune_rounded, color: Color(0xFF9333EA), size: 22),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$pageTitle Sayfasını Düzenle',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const Text('Admin canlı arayüz özelleştirme paneli', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Sayfa Başlığı
                  Text('Özel Sayfa Başlığı', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      hintText: 'Varsayılan: $pageTitle',
                      filled: true,
                      fillColor: AppColors.inputBg(context),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.cardBorder(context))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.cardBorder(context))),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Sayfa Açıklaması
                  Text('Alt Başlık / Açıklama', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: subtitleCtrl,
                    decoration: InputDecoration(
                      hintText: 'Personele yönelik açıklama metni',
                      filled: true,
                      fillColor: AppColors.inputBg(context),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.cardBorder(context))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.cardBorder(context))),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sayfa Üstü Şirket Duyurusu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.campaign_rounded, size: 18, color: Color(0xFFEA580C)),
                          const SizedBox(width: 6),
                          Text('Sayfa İçi Duyuru Bandı', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                        ],
                      ),
                      Switch.adaptive(
                        value: showAnnouncement,
                        activeColor: const Color(0xFF9333EA),
                        onChanged: (v) => setModalState(() => showAnnouncement = v),
                      ),
                    ],
                  ),
                  if (showAnnouncement) ...[
                    const SizedBox(height: 6),
                    TextField(
                      controller: announcementCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Örn: "Yeni mesai düzeni yürürlüğe girmiştir."',
                        filled: true,
                        fillColor: AppColors.inputBg(context),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.cardBorder(context))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.cardBorder(context))),
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Sayfa Vurgu Rengi
                  Text('Sayfa Vurgu Rengi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildColorOption(null, 'Varsayılan', selectedColor, (c) => setModalState(() => selectedColor = c)),
                      const SizedBox(width: 8),
                      _buildColorOption(const Color(0xFF2563EB), 'Mavi', selectedColor, (c) => setModalState(() => selectedColor = c)),
                      const SizedBox(width: 8),
                      _buildColorOption(const Color(0xFF10B981), 'Yeşil', selectedColor, (c) => setModalState(() => selectedColor = c)),
                      const SizedBox(width: 8),
                      _buildColorOption(const Color(0xFFEA580C), 'Turuncu', selectedColor, (c) => setModalState(() => selectedColor = c)),
                      const SizedBox(width: 8),
                      _buildColorOption(const Color(0xFF9333EA), 'Mor', selectedColor, (c) => setModalState(() => selectedColor = c)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Bakım Modu Switch
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Bakım Modu Uyarısı', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Personele bu sayfada güncelleme yapıldığını bildirir', style: TextStyle(fontSize: 11)),
                    value: isMaintenance,
                    activeColor: Colors.amber.shade800,
                    onChanged: (v) => setModalState(() => isMaintenance = v),
                  ),

                  const SizedBox(height: 20),

                  // Kaydet ve Sıfırla Butonları
                  Row(
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          pdks.resetPageCustomization(pageId);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sayfa ayarları varsayılana döndürüldü.')),
                          );
                        },
                        child: const Text('Sıfırla'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9333EA),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Ayarları Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            final updated = current.copyWith(
                              customTitle: titleCtrl.text.trim().isEmpty ? null : titleCtrl.text.trim(),
                              customSubtitle: subtitleCtrl.text.trim().isEmpty ? null : subtitleCtrl.text.trim(),
                              announcementText: announcementCtrl.text.trim().isEmpty ? null : announcementCtrl.text.trim(),
                              showAnnouncement: showAnnouncement,
                              isMaintenanceMode: isMaintenance,
                              accentColor: selectedColor,
                            );
                            pdks.updatePageCustomization(updated);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sayfa ayarları başarıyla kaydedildi! 🛠️'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openSectionVisibilitySheet(BuildContext context, PdksState pdks) {
    if (editableSections == null || editableSections!.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final config = pdks.getPageCustomization(pageId);
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9333EA).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.visibility_rounded, color: Color(0xFF9333EA), size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bölüm Görünürlükleri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Kullanıcıların göreceği kart ve modülleri açıp kapatın', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: editableSections!.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final sec = editableSections![i];
                      final isHidden = config.isSectionHidden(sec.id);
                      return SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isHidden ? Colors.grey.withOpacity(0.15) : const Color(0xFF9333EA).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(sec.icon, size: 20, color: isHidden ? Colors.grey : const Color(0xFF9333EA)),
                        ),
                        title: Text(sec.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isHidden ? Colors.grey : null)),
                        subtitle: Text(sec.description, style: const TextStyle(fontSize: 11)),
                        value: !isHidden,
                        activeColor: const Color(0xFF9333EA),
                        onChanged: (visible) {
                          pdks.togglePageSection(pageId, sec.id);
                          setSheetState(() {});
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9333EA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Tamam', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildColorOption(Color? color, String tooltip, Color? selectedColor, Function(Color?) onSelect) {
    final isSelected = selectedColor == color;
    return GestureDetector(
      onTap: () => onSelect(color),
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color ?? Colors.grey.shade400,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: (color ?? Colors.grey).withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
        ),
      ),
    );
  }
}

/// Admin Düzenleme Modu için Bölüm Sarmalayıcısı
class AdminEditableSection extends StatelessWidget {
  final String pageId;
  final String sectionId;
  final String sectionTitle;
  final Widget child;

  const AdminEditableSection({
    super.key,
    required this.pageId,
    required this.sectionId,
    required this.sectionTitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final isAuthorized = pdks.isLoggedIn &&
        (pdks.currentUser.role == UserRole.admin || pdks.currentUser.role == UserRole.boss);

    // Normal kullanıcıysa ve bölüm gizlendiyse gösterme
    final config = pdks.getPageCustomization(pageId);
    final isHidden = config.isSectionHidden(sectionId);

    if (isHidden && (!isAuthorized || !pdks.isAdminEditMode)) {
      return const SizedBox.shrink();
    }

    if (!isAuthorized || !pdks.isAdminEditMode) {
      return child;
    }

    // Admin Düzenleme Modu Aktifse: Bölümün etrafını çizgiyle vurgula ve düzenleme rozeti göster
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHidden ? Colors.red.withOpacity(0.6) : const Color(0xFF9333EA).withOpacity(0.5),
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: Stack(
        children: [
          Opacity(
            opacity: isHidden ? 0.35 : 1.0,
            child: child,
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isHidden ? Colors.red : const Color(0xFF9333EA),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: InkWell(
                onTap: () => pdks.togglePageSection(pageId, sectionId),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isHidden ? 'Gizli' : 'Görünür',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
