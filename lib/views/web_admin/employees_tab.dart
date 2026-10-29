import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/employee.dart';
import '../../state/pdks_state.dart';

class EmployeesTab extends StatelessWidget {
  const EmployeesTab({super.key});

  void _showEmployeePhotoDialog(BuildContext context, Employee emp) {
    final pdks = context.read<PdksState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final urlCtrl = TextEditingController(text: emp.avatarUrl ?? '');

    final presetAvatars = [
      {'title': 'Erkek Yönetici', 'url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150'},
      {'title': 'Kadın Yönetici', 'url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'},
      {'title': 'Erkek Mühendis', 'url': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150'},
      {'title': 'Kadın İK / Uzman', 'url': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150'},
      {'title': 'Kurumsal Profesyonel', 'url': 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150'},
      {'title': 'Mutfak Şefi', 'url': 'https://images.unsplash.com/photo-1577219491135-ce391730fb2c?w=150'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.80,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOf(context).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.add_photo_alternate_rounded, color: AppColors.primaryOf(context), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${emp.fullName} • Fotoğraf Ekle',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                        ),
                        const SizedBox(height: 2),
                        Text('Hazır avatarlardan seçin veya resim bağlantısı girin', style: TextStyle(fontSize: 11, color: AppColors.textSub(context))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text('Hazır Avatarlar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text(context))),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: presetAvatars.map((av) {
                    final isSel = emp.avatarUrl == av['url'];
                    return GestureDetector(
                      onTap: () {
                        pdks.updateEmployeeAvatar(emp.id, av['url']!);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            content: Text('${emp.fullName} fotoğrafı güncellendi.'),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: isSel ? AppColors.primaryOf(context) : Colors.transparent, width: 3),
                                image: DecorationImage(image: NetworkImage(av['url']!), fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(av['title']!, style: TextStyle(fontSize: 10, color: AppColors.textSub(context))),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Text('Fotoğraf URL\'si', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text(context))),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: urlCtrl,
                      style: TextStyle(fontSize: 13, color: AppColors.text(context)),
                      decoration: InputDecoration(
                        hintText: 'https://...',
                        hintStyle: TextStyle(fontSize: 12, color: AppColors.textSub(context)),
                        filled: true,
                        fillColor: AppColors.inputBg(context),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.cardBorder(context))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.cardBorder(context))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOf(context),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    onPressed: () {
                      final val = urlCtrl.text.trim();
                      if (val.isNotEmpty) {
                        pdks.updateEmployeeAvatar(emp.id, val);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            content: Text('${emp.fullName} fotoğrafı güncellendi.'),
                          ),
                        );
                      }
                    },
                    child: const Text('Kaydet'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employees = context.watch<PdksState>().employees;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 28,
        isMobile ? 16 : 28,
        isMobile ? 16 : 28,
        MediaQuery.of(context).padding.bottom + (isMobile ? 16 : 28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personel Listesi (${employees.length})',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.text(context)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOf(context),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: isMobile ? 8 : 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: Text(isMobile ? 'Ekle' : 'Yeni Personel Ekle', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yeni personel ekleme formu açıldı.')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.cardBorder(context)),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: employees.length,
                separatorBuilder: (_, __) => Divider(color: AppColors.cardBorder(context), height: 1),
                itemBuilder: (_, index) {
                  final emp = employees[index];
                  final hasAvatar = emp.avatarUrl != null && emp.avatarUrl!.isNotEmpty;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    onTap: () => _showEmployeePhotoDialog(context, emp),
                    leading: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primaryOf(context).withOpacity(0.15),
                          backgroundImage: hasAvatar ? NetworkImage(emp.avatarUrl!) : null,
                          child: !hasAvatar
                              ? Text(
                                  emp.fullName.substring(0, 2).toUpperCase(),
                                  style: TextStyle(color: AppColors.primaryOf(context), fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOf(context),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, size: 9, color: Colors.white),
                        ),
                      ],
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            emp.fullName,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text(context)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOf(context).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            emp.roleDisplayName,
                            style: TextStyle(color: AppColors.primaryOf(context), fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text('${emp.department} • ${emp.title}', style: TextStyle(color: AppColors.textSub(context), fontSize: 11)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Kalan İzin', style: TextStyle(fontSize: 10, color: AppColors.textSub(context))),
                        Text('${emp.remainingLeaveDays} Gün', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.success)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
