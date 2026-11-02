import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/employee.dart';
import '../../models/page_customization.dart';
import '../../state/pdks_state.dart';
import '../common/admin_edit_mode_bar.dart';

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
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  late DateTime _hireDate;
  late String _selectedShirtSize;
  late String _selectedPantSize;
  late int _selectedShoeSize;
  late String _selectedOuterwearSize;

  bool _isEditing = false;

  final List<String> _shirtSizes = const ['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL'];
  final List<String> _pantSizes = const ['28', '30', '32', '34', '36', '38', '40', '42', '44'];
  final List<int> _shoeSizes = const [38, 39, 40, 41, 42, 43, 44, 45, 46];
  final List<String> _outerwearSizes = const ['S', 'M', 'L', 'XL', '2XL', '3XL'];

  @override
  void initState() {
    super.initState();
    final user = context.read<PdksState>().currentUser;
    _nameController = TextEditingController(text: user.fullName);
    _phoneController = TextEditingController(text: user.phone);
    _deptController = TextEditingController(text: user.department);
    _titleController = TextEditingController(text: user.title);
    _heightController = TextEditingController(text: (user.heightCm ?? 178).toString());
    _weightController = TextEditingController(text: (user.weightKg ?? 75).toString());

    _hireDate = user.hireDate ?? user.registeredAt ?? DateTime(2023, 4, 1);
    _selectedShirtSize = user.shirtSize ?? 'L';
    _selectedPantSize = user.pantSize ?? '32';
    _selectedShoeSize = user.shoeSize ?? 42;
    _selectedOuterwearSize = user.outerwearSize ?? 'L';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _deptController.dispose();
    _titleController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final phone = _phoneController.text.trim();
    if (phone.length > 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Telefon numarası en fazla 11 haneli olmalıdır.'),
        ),
      );
      return;
    }

    final height = int.tryParse(_heightController.text.trim()) ?? 178;
    final weight = int.tryParse(_weightController.text.trim()) ?? 75;

    context.read<PdksState>().updateProfile(
      fullName: _nameController.text.trim(),
      phone: phone,
      department: _deptController.text.trim(),
      title: _titleController.text.trim(),
      hireDate: _hireDate,
      heightCm: height,
      weightKg: weight,
      shirtSize: _selectedShirtSize,
      pantSize: _selectedPantSize,
      shoeSize: _selectedShoeSize,
      outerwearSize: _selectedOuterwearSize,
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
            Text('Profil bilgileriniz ve kıyafet bedenleriniz kaydedildi.'),
          ],
        ),
      ),
    );
  }

  void _showAvatarPickerModal(BuildContext context, Employee user) {
    final pdks = context.read<PdksState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profil Fotoğrafı Yükle',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.text(context)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'iOS ve Android cihazınızdan yeni fotoğraf yükleyin',
                        style: TextStyle(fontSize: 11, color: AppColors.textSub(context)),
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

              // 1. Galeriden Seç (iOS & Android)
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF2563EB), size: 22),
                ),
                title: const Text('Fotoğraf Galerisinden Seç', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('iOS Fotoğraflar veya Android Galeri albümünüzden seçin', style: TextStyle(fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 800, maxHeight: 800);
                    if (image != null) {
                      final bytes = await image.readAsBytes();
                      final base64Uri = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                      pdks.updateCurrentUserAvatar(base64Uri);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            content: Text('Profil fotoğrafınız başarıyla güncellendi.'),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    debugPrint('Galeri fotoğraf hatası: $e');
                  }
                },
              ),
              const SizedBox(height: 12),

              // 2. Kamera ile Çek (iOS & Android)
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF10B981), size: 22),
                ),
                title: const Text('Kamera ile Yeni Fotoğraf Çek', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('iOS veya Android kameranızla anlık özçekim yapın', style: TextStyle(fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final picker = ImagePicker();
                    final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 800, maxHeight: 800);
                    if (photo != null) {
                      final bytes = await photo.readAsBytes();
                      final base64Uri = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                      pdks.updateCurrentUserAvatar(base64Uri);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            content: Text('Profil fotoğrafınız başarıyla güncellendi.'),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    debugPrint('Kamera hatası: $e');
                  }
                },
              ),

              if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  tileColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
                  ),
                  title: const Text('Mevcut Fotoğrafı Kaldır', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red)),
                  subtitle: const Text('Varsayılan baş harf simgesine geri döner', style: TextStyle(fontSize: 11)),
                  onTap: () {
                    pdks.updateCurrentUserAvatar('');
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profil fotoğrafınız kaldırıldı.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectHireDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _hireDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null && picked != _hireDate) {
      setState(() => _hireDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<PdksState>().currentUser;
    final isHrOrAdmin = user.role == UserRole.hr || user.role == UserRole.admin;

    final Color roleColor = user.role.color;
    final String roleName = user.roleDisplayName;

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
            // Yönetici & Admin Sayfa Düzenleme Çubuğu
            const AdminEditModeBar(
              pageId: 'profile',
              pageTitle: 'Profil Sayfası',
              editableSections: [
                PageSectionItem(id: 'profile_header', title: 'Profil & Kimlik Kartı'),
                PageSectionItem(id: 'leave_stats', title: 'İzin Bakiyesi & Çalışma Durumu'),
                PageSectionItem(id: 'personal_info', title: 'Kişisel & Kurumsal Bilgiler'),
                PageSectionItem(id: 'clothing_sizes', title: 'Kıyafet & Zimmet Bedenleri'),
              ],
            ),

            // Profil Kartı
            AdminEditableSection(
              pageId: 'profile',
              sectionId: 'profile_header',
              sectionTitle: 'Profil & Kimlik Kartı',
              child: Container(
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
                            image: user.avatarImageProvider != null
                                ? DecorationImage(
                                    image: user.avatarImageProvider!,
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            gradient: user.avatarImageProvider == null
                                ? LinearGradient(
                                    colors: [roleColor.withOpacity(0.2), roleColor],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                          ),
                          child: user.avatarImageProvider == null
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
            ),

            const SizedBox(height: 16),

            // Kalan İzin & Çalışma Durumu (2'li Kompakt Kartlar)
            AdminEditableSection(
              pageId: 'profile',
              sectionId: 'leave_stats',
              sectionTitle: 'İzin Bakiyesi & Çalışma Durumu',
              child: Row(
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
            ),

            const SizedBox(height: 16),

            // Kişisel & Kurumsal Bilgiler Kartı
            AdminEditableSection(
              pageId: 'profile',
              sectionId: 'personal_info',
              sectionTitle: 'Kişisel & Kurumsal Bilgiler',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Kişisel & Kurumsal Bilgiler', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                      if (!isHrOrAdmin && _isEditing)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_rounded, size: 12, color: Colors.amber),
                              SizedBox(width: 4),
                              Text(
                                'Ad-Soyad/Departman/Unvan İK Korumalı',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Ad Soyad: Sadece İK veya Admin Değiştirebilir
                  if (isHrOrAdmin)
                    _buildModernField('Ad Soyad', _nameController, Icons.person_outline_rounded, enabled: _isEditing)
                  else
                    _buildReadOnlyField(
                      'Ad Soyad',
                      user.fullName,
                      Icons.person_outline_rounded,
                      lockNote: 'Ad Soyad değişikliği sadece İK tarafından yapılabilir.',
                    ),
                  const SizedBox(height: 14),

                  _buildReadOnlyField('E-Posta Adresi', user.email, Icons.mail_outline_rounded),
                  const SizedBox(height: 14),

                  _buildModernField(
                    'Telefon Numarası (En Fazla 11 Hane)',
                    _phoneController,
                    Icons.phone_outlined,
                    enabled: _isEditing,
                    maxLength: 11,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // İşe İlk Giriş Tarihi
                  _buildHireDateField(context, isHrOrAdmin: isHrOrAdmin),
                  const SizedBox(height: 14),

                  // Departman: Sadece İK veya Admin Değiştirebilir
                  if (isHrOrAdmin)
                    _buildModernField('Departman', _deptController, Icons.business_outlined, enabled: _isEditing)
                  else
                    _buildReadOnlyField(
                      'Departman',
                      user.department,
                      Icons.business_outlined,
                      lockNote: 'Departman değişikliği sadece İK tarafından yapılabilir.',
                    ),
                  const SizedBox(height: 14),

                  // Unvan: Sadece İK veya Admin Değiştirebilir
                  if (isHrOrAdmin)
                    _buildModernField('Unvan', _titleController, Icons.badge_outlined, enabled: _isEditing)
                  else
                    _buildReadOnlyField(
                      'Unvan',
                      user.title,
                      Icons.badge_outlined,
                      lockNote: 'Unvan değişikliği sadece İK tarafından yapılabilir.',
                    ),

                  // NOT: "giriş pin kodu yazan yeri gizle" talebi gereğince PIN alanı kaldırılmıştır.
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Fiziksel Bilgiler Kartı (Boy & Kilo)
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.fitness_center_rounded, color: Color(0xFF0284C7), size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text('Fiziksel Bilgiler (Boy & Kilo)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernField(
                          'Boy (cm)',
                          _heightController,
                          Icons.height_rounded,
                          enabled: _isEditing,
                          maxLength: 3,
                          keyboardType: TextInputType.number,
                          suffixText: 'cm',
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModernField(
                          'Kilo (kg)',
                          _weightController,
                          Icons.monitor_weight_outlined,
                          enabled: _isEditing,
                          maxLength: 3,
                          keyboardType: TextInputType.number,
                          suffixText: 'kg',
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Kıyafet & Zimmet Beden Bilgileri Kartı
            AdminEditableSection(
              pageId: 'profile',
              sectionId: 'clothing_sizes',
              sectionTitle: 'Kıyafet & Zimmet Bedenleri',
              child: Container(
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.checkroom_rounded, color: Color(0xFF8B5CF6), size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kıyafet & Beden Bilgileri',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                            ),
                            Text(
                              'Kurumsal forma, iş tulumu ve güvenlik ayakkabısı',
                              style: TextStyle(fontSize: 11, color: AppColors.textSub(context)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1. Tişört / Üst Beden
                  _buildSizeOptionRow(
                    label: 'Tişört / Gömlek Bedeni',
                    icon: Icons.dry_cleaning_rounded,
                    color: const Color(0xFF3B82F6),
                    selectedValue: _selectedShirtSize,
                    options: _shirtSizes,
                    onSelected: (val) => setState(() => _selectedShirtSize = val),
                  ),
                  const SizedBox(height: 14),

                  // 2. Pantolon Bedeni
                  _buildSizeOptionRow(
                    label: 'Pantolon Bedeni',
                    icon: Icons.roller_shades_closed,
                    color: const Color(0xFF10B981),
                    selectedValue: _selectedPantSize,
                    options: _pantSizes,
                    onSelected: (val) => setState(() => _selectedPantSize = val),
                  ),
                  const SizedBox(height: 14),

                  // 3. Ayakkabı Numarası
                  _buildShoeSizeRow(
                    label: 'İş Ayakkabısı Numarası',
                    icon: Icons.skateboarding,
                    color: const Color(0xFFF59E0B),
                    selectedValue: _selectedShoeSize,
                    options: _shoeSizes,
                    onSelected: (val) => setState(() => _selectedShoeSize = val),
                  ),
                  const SizedBox(height: 14),

                  // 4. Mont / Yelek Bedeni
                  _buildSizeOptionRow(
                    label: 'Mont / Yelek / İş Tulumu',
                    icon: Icons.layers_rounded,
                    color: const Color(0xFF8B5CF6),
                    selectedValue: _selectedOuterwearSize,
                    options: _outerwearSizes,
                    onSelected: (val) => setState(() => _selectedOuterwearSize = val),
                  ),
                ],
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHireDateField(BuildContext context, {required bool isHrOrAdmin}) {
    final dateStr = DateFormat('dd MMMM yyyy', 'tr_TR').format(_hireDate);
    final canEdit = isHrOrAdmin && _isEditing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('İşe İlk Giriş Tarihi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSub(context))),
            if (canEdit)
              InkWell(
                onTap: () => _selectHireDate(context),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text('Tarih Değiştir', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: canEdit ? () => _selectHireDate(context) : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: canEdit ? AppColors.cardBg(context) : AppColors.inputBg(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: canEdit ? const Color(0xFF2563EB) : AppColors.cardBorder(context)),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_available_rounded, size: 20, color: Color(0xFF2563EB)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    dateStr,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text(context)),
                  ),
                ),
                if (canEdit)
                  const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF2563EB))
                else
                  const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF10B981)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSizeOptionRow({
    required String label,
    required IconData icon,
    required Color color,
    required String selectedValue,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSub(context))),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Beden: $selectedValue',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (_isEditing)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options.map((opt) {
                final isCurrent = opt == selectedValue;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(opt),
                    selected: isCurrent,
                    onSelected: (_) => onSelected(opt),
                    selectedColor: color,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? Colors.white : AppColors.text(context),
                    ),
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    side: BorderSide(color: isCurrent ? color : AppColors.cardBorder(context)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  ),
                );
              }).toList(),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.inputBg(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder(context)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kayıtlı Ölçü',
                  style: TextStyle(fontSize: 12, color: AppColors.textSub(context)),
                ),
                Text(
                  selectedValue,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildShoeSizeRow({
    required String label,
    required IconData icon,
    required Color color,
    required int selectedValue,
    required List<int> options,
    required ValueChanged<int> onSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSub(context))),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Numara: $selectedValue',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (_isEditing)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options.map((sizeNum) {
                final isCurrent = sizeNum == selectedValue;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(sizeNum.toString()),
                    selected: isCurrent,
                    onSelected: (_) => onSelected(sizeNum),
                    selectedColor: color,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? Colors.white : AppColors.text(context),
                    ),
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    side: BorderSide(color: isCurrent ? color : AppColors.cardBorder(context)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  ),
                );
              }).toList(),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.inputBg(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder(context)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kayıtlı Ayakkabı Numarası',
                  style: TextStyle(fontSize: 12, color: AppColors.textSub(context)),
                ),
                Text(
                  '$selectedValue Numara',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildModernField(
    String label,
    TextEditingController controller,
    IconData icon, {
    required bool enabled,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? suffixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSub(context))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLength: maxLength,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text(context)),
          decoration: InputDecoration(
            counterText: '',
            suffixText: suffixText,
            suffixStyle: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSub(context)),
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

  Widget _buildReadOnlyField(String label, String value, IconData icon, {String? lockNote}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSub(context))),
            if (lockNote != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 12, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    'Sadece İK',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                  ),
                ],
              ),
          ],
        ),
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
        if (lockNote != null && _isEditing) ...[
          const SizedBox(height: 4),
          Text(
            lockNote,
            style: TextStyle(fontSize: 10.5, color: Colors.amber.shade800, fontStyle: FontStyle.italic),
          ),
        ],
      ],
    );
  }
}
