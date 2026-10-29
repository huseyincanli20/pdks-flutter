import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/employee.dart';
import '../../state/pdks_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _deptController;
  late TextEditingController _titleController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<PdksState>().currentUser;
    _nameController = TextEditingController(text: user.fullName);
    _phoneController = TextEditingController(text: user.phone);
    _deptController = TextEditingController(text: user.department);
    _titleController = TextEditingController(text: user.title);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _deptController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    context.read<PdksState>().updateProfile(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      department: _deptController.text.trim(),
      title: _titleController.text.trim(),
    );
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Profil bilgileriniz başarıyla güncellendi.'),
          ],
        ),
      ),
    );
  }

  void _showAvatarPickerModal(BuildContext context, Employee user) {
    final pdks = context.read<PdksState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final urlCtrl = TextEditingController(text: user.avatarUrl ?? '');

    final presetAvatars = [
      {'title': 'Erkek Yönetici', 'url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150'},
      {'title': 'Kadın Yönetici', 'url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'},
      {'title': 'Erkek Mühendis', 'url': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150'},
      {'title': 'Kadın İK / Uzman', 'url': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150'},
      {'title': 'Kurumsal Profesyonel', 'url': 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150'},
      {'title': 'Kadın Mühendis', 'url': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150'},
      {'title': 'Yönetici / Lider', 'url': 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150'},
      {'title': 'Mutfak Şefi', 'url': 'https://images.unsplash.com/photo-1577219491135-ce391730fb2c?w=150'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                    child: Icon(Icons.add_a_photo_rounded, color: AppColors.primaryOf(context), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Profil Fotoğrafı Seç', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                        const SizedBox(height: 2),
                        Text('Hazır avatarlardan seçin veya fotoğraf URL\'si girin', style: TextStyle(fontSize: 11, color: AppColors.textSub(context))),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Text('Hazır Kurumsal Avatarlar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text(context))),
              const SizedBox(height: 12),

              // 8 Avatar Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: presetAvatars.length,
                itemBuilder: (context, i) {
                  final av = presetAvatars[i];
                  final isSelected = user.avatarUrl == av['url'];

                  return GestureDetector(
                    onTap: () {
                      pdks.updateCurrentUserAvatar(av['url']!);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          content: Text('Profil fotoğrafınız güncellendi.'),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.primaryOf(context) : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2)),
                            ],
                            image: DecorationImage(
                              image: NetworkImage(av['url']!),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: isSelected
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryOf(context).withOpacity(0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check, color: Colors.white, size: 24),
                                )
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          av['title']!,
                          style: TextStyle(fontSize: 10, color: AppColors.textSub(context)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),
              Text('Özel Fotoğraf Bağlantısı (URL)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text(context))),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: urlCtrl,
                      style: TextStyle(fontSize: 13, color: AppColors.text(context)),
                      decoration: InputDecoration(
                        hintText: 'https://ornek.com/resim.jpg',
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onPressed: () {
                      final val = urlCtrl.text.trim();
                      if (val.isNotEmpty) {
                        pdks.updateCurrentUserAvatar(val);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            content: Text('Profil fotoğrafınız güncellendi.'),
                          ),
                        );
                      }
                    },
                    child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),

              if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Center(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Mevcut Fotoğrafı Kaldır', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () {
                      pdks.updateCurrentUserAvatar('');
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text('Fotoğraf kaldırıldı, harf logosu aktif.'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<PdksState>().currentUser;

    Color roleColor;
    String roleName;
    switch (user.role) {
      case UserRole.boss:
        roleColor = const Color(0xFFD97706);
        roleName = 'Patron / CEO';
        break;
      case UserRole.admin:
        roleColor = const Color(0xFF9333EA);
        roleName = 'Süper Admin';
        break;
      case UserRole.hr:
        roleColor = const Color(0xFF0284C7);
        roleName = 'İnsan Kaynakları';
        break;
      case UserRole.employee:
      default:
        roleColor = const Color(0xFF2563EB);
        roleName = 'Personel';
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('Profilim', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: _isEditing ? AppColors.success : AppColors.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            icon: Icon(_isEditing ? Icons.check_circle_outline : Icons.edit_outlined, size: 18),
            label: Text(_isEditing ? 'Kaydet' : 'Düzenle'),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          children: [
            // Apple/Samsung Modern Profil Kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.cardBorder(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      GestureDetector(
                        onTap: () => _showAvatarPickerModal(context, user),
                        child: Container(
                          width: 94,
                          height: 94,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: roleColor, width: 3),
                            image: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(user.avatarUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            gradient: user.avatarUrl == null || user.avatarUrl!.isEmpty
                                ? LinearGradient(
                                    colors: [roleColor.withOpacity(0.2), roleColor],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                          ),
                          child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                              ? Center(
                                  child: Text(
                                    user.fullName.isNotEmpty ? user.fullName.substring(0, 2).toUpperCase() : 'P',
                                    style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showAvatarPickerModal(context, user),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: roleColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                              width: 2.5,
                            ),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user.fullName,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user.department} • ${user.title}',
                    style: TextStyle(color: AppColors.textSub(context), fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: roleColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      roleName,
                      style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Kalan İzin & Çalışma Durumu (2'li Kompakt Kartlar)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(20),
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.beach_access, color: AppColors.success, size: 18),
                            ),
                            const SizedBox(width: 8),
                            Text('Kalan İzin', style: TextStyle(color: AppColors.textSub(context), fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${user.remainingLeaveDays} Gün',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(20),
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.history, color: AppColors.primary, size: 18),
                            ),
                            const SizedBox(width: 8),
                            Text('Kullanılan', style: TextStyle(color: AppColors.textSub(context), fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${user.usedLeaveDays} Gün',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Inset Grouped Kişisel Bilgiler Kartı (iOS & OneUI Style)
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
                  Text('Kişisel Bilgiler', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                  const SizedBox(height: 16),
                  _buildModernField('Ad Soyad', _nameController, Icons.person_outline_rounded, enabled: _isEditing),
                  const SizedBox(height: 14),
                  _buildReadOnlyField('E-Posta Adresi', user.email, Icons.mail_outline_rounded),
                  const SizedBox(height: 14),
                  _buildModernField('Telefon Numarası', _phoneController, Icons.phone_outlined, enabled: _isEditing),
                  const SizedBox(height: 14),
                  _buildModernField('Departman', _deptController, Icons.business_outlined, enabled: _isEditing),
                  const SizedBox(height: 14),
                  _buildModernField('Unvan', _titleController, Icons.badge_outlined, enabled: _isEditing),
                  const SizedBox(height: 14),
                  _buildReadOnlyField('Giriş PIN Kodu', '•••• (Güvenli Kriptolu)', Icons.lock_outline_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernField(String label, TextEditingController controller, IconData icon, {required bool enabled}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSub(context))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text(context)),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: enabled ? AppColors.primary : AppColors.textSub(context)),
            filled: true,
            fillColor: enabled ? AppColors.cardBg(context) : AppColors.inputBg(context),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.cardBorder(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.cardBorder(context)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSub(context))),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.inputBg(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder(context)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSub(context)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text(context)),
                ),
              ),
              const Icon(Icons.lock_rounded, size: 14, color: AppColors.textMuted),
            ],
          ),
        ),
      ],
    );
  }
}
