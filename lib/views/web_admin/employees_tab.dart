import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/employee.dart';
import '../../state/pdks_state.dart';
import '../common/phone_push_notification_banner.dart';

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

  void _openApprovalSheet(BuildContext context, PdksState pdks, Employee emp) {
    final formKey = GlobalKey<FormState>();
    final deptCtrl = TextEditingController(text: 'Yazılım & Ar-Ge');
    final titleCtrl = TextEditingController(text: 'Yazılım Uzmanı');
    final salaryCtrl = TextEditingController(text: '52000');
    UserRole selectedRole = UserRole.employee;

    final departments = [
      'Yazılım & Ar-Ge',
      'İnsan Kaynakları',
      'Satış & Pazarlama',
      'Mali İşler & Muhasebe',
      'Operasyon & Lojistik',
      'Mutfak & Yemekhane',
      'Yönetim',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            16,
            22,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
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
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Personel Kaydını Onayla & Görev Ata',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Adayın görev, departman ve unvan bilgilerini tanımlayın.',
                              style: TextStyle(fontSize: 11, color: AppColors.textSub(context)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Aday Bilgi Kartı
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOf(context).withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryOf(context).withOpacity(0.18)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primaryOf(context),
                          radius: 20,
                          child: Text(
                            emp.fullName.isNotEmpty ? emp.fullName.substring(0, 2).toUpperCase() : 'P',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(emp.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('${emp.email} • ${emp.phone}', style: TextStyle(fontSize: 11.5, color: AppColors.textSub(context))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Departman Seçimi
                  const Text('Departman Belirleyin *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: departments.map((d) {
                      final isSelected = deptCtrl.text == d;
                      return ChoiceChip(
                        label: Text(d, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        selected: isSelected,
                        selectedColor: AppColors.primaryOf(context).withOpacity(0.2),
                        onSelected: (val) {
                          if (val) {
                            setSheetState(() => deptCtrl.text = d);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: deptCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Departman Adı',
                      prefixIcon: Icon(Icons.business_outlined, size: 20),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Departman zorunludur' : null,
                  ),
                  const SizedBox(height: 12),

                  // Unvan
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Görevi / Unvanı *',
                      hintText: 'Örn: Kıdemli Yazılım Geliştirici',
                      prefixIcon: Icon(Icons.badge_outlined, size: 20),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Unvan zorunludur' : null,
                  ),
                  const SizedBox(height: 12),

                  // Başlangıç Maaşı
                  TextFormField(
                    controller: salaryCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Aylık Brüt Maaş (TL)',
                      prefixIcon: Icon(Icons.payments_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Rol Seçimi
                  DropdownButtonFormField<UserRole>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Sistem Rolü',
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem(value: UserRole.employee, child: Text('Standart Personel (Mobil)')),
                      DropdownMenuItem(value: UserRole.hr, child: Text('İnsan Kaynakları (İK)')),
                      DropdownMenuItem(value: UserRole.cafeteria, child: Text('Yemekhane Personeli')),
                    ],
                    onChanged: (val) {
                      if (val != null) setSheetState(() => selectedRole = val);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Onayla Butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Personeli Onayla ve Sisteme Al', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        final salary = double.tryParse(salaryCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ?? 52000.0;
                        final result = pdks.approveEmployeeRegistration(
                          employeeId: emp.id,
                          department: deptCtrl.text.trim(),
                          title: titleCtrl.text.trim(),
                          baseSalary: salary,
                          role: selectedRole,
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: result.success ? AppColors.success : AppColors.danger,
                            behavior: SnackBarBehavior.floating,
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(result.message)),
                              ],
                            ),
                          ),
                        );

                        if (result.success && result.dispatchedNotification != null) {
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (context.mounted) {
                              PhonePushNotificationBanner.show(
                                context,
                                notification: result.dispatchedNotification!,
                              );
                            }
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showRejectConfirmation(BuildContext context, PdksState pdks, Employee emp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.person_remove_rounded, color: AppColors.danger),
            SizedBox(width: 10),
            Text('Başvuruyu Reddet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Text(
          '${emp.fullName} personeline ait kayıt başvurusunu reddetmek ve listeden kaldırmak istediğinize emin misiniz?',
          style: const TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final result = pdks.rejectEmployeeRegistration(emp.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: result.success ? AppColors.danger : AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  content: Text(result.message),
                ),
              );
            },
            child: const Text('Reddet ve Sil', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openEmployeeEditSheet(BuildContext context, Employee emp) {
    final pdks = context.read<PdksState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formKey = GlobalKey<FormState>();

    final nameCtrl = TextEditingController(text: emp.fullName);
    final phoneCtrl = TextEditingController(text: emp.phone);
    final deptCtrl = TextEditingController(text: emp.department);
    final titleCtrl = TextEditingController(text: emp.title);
    final salaryCtrl = TextEditingController(text: emp.baseGrossSalary.toStringAsFixed(0));
    final heightCtrl = TextEditingController(text: (emp.heightCm ?? 178).toString());
    final weightCtrl = TextEditingController(text: (emp.weightKg ?? 75).toString());
    final leaveAllowanceCtrl = TextEditingController(text: emp.annualLeaveAllowance.toString());

    DateTime hireDate = emp.hireDate ?? emp.registeredAt ?? DateTime(2023, 4, 1);
    UserRole selectedRole = emp.role;
    String shirtSize = emp.shirtSize ?? 'L';
    String pantSize = emp.pantSize ?? '32';
    int shoeSize = emp.shoeSize ?? 42;
    String outerwearSize = emp.outerwearSize ?? 'L';

    const shirtSizes = ['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL'];
    const pantSizes = ['28', '30', '32', '34', '36', '38', '40', '42', '44'];
    const shoeSizes = [38, 39, 40, 41, 42, 43, 44, 45, 46];
    const outerwearSizes = ['S', 'M', 'L', 'XL', '2XL', '3XL'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
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
          child: Column(
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
              const SizedBox(height: 14),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF2563EB).withOpacity(0.15),
                    backgroundImage: emp.avatarUrl != null && emp.avatarUrl!.isNotEmpty
                        ? NetworkImage(emp.avatarUrl!)
                        : null,
                    child: emp.avatarUrl == null || emp.avatarUrl!.isEmpty
                        ? Text(
                            emp.fullName.isNotEmpty ? emp.fullName.substring(0, 2).toUpperCase() : 'P',
                            style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 13),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${emp.fullName} - Bilgileri Düzenle',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context)),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'İK Yetkili Paneli • Personel Bilgilerini Güncelleme',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kişisel & Kurumsal
                        const Text(
                          'Kurumsal & İletişim Bilgileri',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB)),
                        ),
                        const SizedBox(height: 10),

                        TextFormField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Ad Soyad *',
                            prefixIcon: const Icon(Icons.person_outline, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Ad Soyad boş bırakılamaz' : null,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: phoneCtrl,
                          maxLength: 11,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Telefon Numarası (En fazla 11 hane) *',
                            counterText: '',
                            hintText: '05XX XXX XX XX',
                            prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Telefon numarası zorunludur' : null,
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: deptCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Departman *',
                                  prefixIcon: const Icon(Icons.business_outlined, size: 20),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Departman boş bırakılamaz' : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: titleCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Unvan *',
                                  prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Unvan boş bırakılamaz' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<UserRole>(
                                value: selectedRole,
                                decoration: InputDecoration(
                                  labelText: 'Yetki Rolü',
                                  prefixIcon: const Icon(Icons.admin_panel_settings_outlined, size: 20),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                ),
                                items: UserRole.values.map((role) {
                                  return DropdownMenuItem(
                                    value: role,
                                    child: Text(role.label, style: const TextStyle(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setModalState(() => selectedRole = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: salaryCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  labelText: 'Brüt Maaş (₺)',
                                  prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                                  suffixText: '₺',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: hireDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime.now(),
                                    locale: const Locale('tr', 'TR'),
                                  );
                                  if (picked != null) {
                                    setModalState(() => hireDate = picked);
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'İşe İlk Giriş Tarihi',
                                    prefixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    filled: true,
                                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  ),
                                  child: Text(
                                    DateFormat('dd.MM.yyyy').format(hireDate),
                                    style: TextStyle(fontSize: 13, color: AppColors.text(context)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: leaveAllowanceCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  labelText: 'Yıllık İzin (Gün)',
                                  prefixIcon: const Icon(Icons.beach_access_rounded, size: 20),
                                  suffixText: 'Gün',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Fiziksel Bilgiler
                        const Text(
                          'Fiziksel Bilgiler (Boy & Kilo)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0284C7)),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: heightCtrl,
                                maxLength: 3,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  labelText: 'Boy',
                                  counterText: '',
                                  suffixText: 'cm',
                                  prefixIcon: const Icon(Icons.height_rounded, size: 20),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: weightCtrl,
                                maxLength: 3,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  labelText: 'Kilo',
                                  counterText: '',
                                  suffixText: 'kg',
                                  prefixIcon: const Icon(Icons.monitor_weight_outlined, size: 20),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Kıyafet & Zimmet Bedenleri
                        const Text(
                          'Kıyafet & Beden Ölçüleri (İş Kıyafeti / Forma)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF8B5CF6)),
                        ),
                        const SizedBox(height: 8),

                        // Tişört / Gömlek
                        _buildModalChipSelector(
                          title: 'Tişört / Gömlek Bedeni',
                          current: shirtSize,
                          options: shirtSizes,
                          color: const Color(0xFF3B82F6),
                          isDark: isDark,
                          context: context,
                          onSelected: (val) => setModalState(() => shirtSize = val),
                        ),
                        const SizedBox(height: 10),

                        // Pantolon Bedeni
                        _buildModalChipSelector(
                          title: 'Pantolon Bedeni',
                          current: pantSize,
                          options: pantSizes,
                          color: const Color(0xFF10B981),
                          isDark: isDark,
                          context: context,
                          onSelected: (val) => setModalState(() => pantSize = val),
                        ),
                        const SizedBox(height: 10),

                        // İş Ayakkabısı No
                        _buildModalChipSelector(
                          title: 'İş Ayakkabısı Numarası',
                          current: shoeSize.toString(),
                          options: shoeSizes.map((e) => e.toString()).toList(),
                          color: const Color(0xFFF59E0B),
                          isDark: isDark,
                          context: context,
                          onSelected: (val) => setModalState(() => shoeSize = int.parse(val)),
                        ),
                        const SizedBox(height: 10),

                        // Mont / Yelek
                        _buildModalChipSelector(
                          title: 'Mont / Yelek / İş Tulumu',
                          current: outerwearSize,
                          options: outerwearSizes,
                          color: const Color(0xFF8B5CF6),
                          isDark: isDark,
                          context: context,
                          onSelected: (val) => setModalState(() => outerwearSize = val),
                        ),
                        const SizedBox(height: 16),

                        // Fotoğraf Değiştir Butonu
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: const Text('Profil Fotoğrafını Değiştir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          onPressed: () {
                            _showEmployeePhotoDialog(context, emp);
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),

              // Alt Butonlar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('İptal', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        final salary = double.tryParse(salaryCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ?? emp.baseGrossSalary;
                        final height = int.tryParse(heightCtrl.text.trim()) ?? emp.heightCm;
                        final weight = int.tryParse(weightCtrl.text.trim()) ?? emp.weightKg;
                        final leave = int.tryParse(leaveAllowanceCtrl.text.trim()) ?? emp.annualLeaveAllowance;

                        final result = pdks.updateEmployeeByHr(
                          employeeId: emp.id,
                          fullName: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          department: deptCtrl.text.trim(),
                          title: titleCtrl.text.trim(),
                          baseSalary: salary,
                          role: selectedRole,
                          hireDate: hireDate,
                          heightCm: height,
                          weightKg: weight,
                          shirtSize: shirtSize,
                          pantSize: pantSize,
                          shoeSize: shoeSize,
                          outerwearSize: outerwearSize,
                          annualLeaveAllowance: leave,
                        );

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: result.success ? AppColors.success : AppColors.danger,
                            behavior: SnackBarBehavior.floating,
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(result.message)),
                              ],
                            ),
                          ),
                        );

                        if (result.success && result.dispatchedNotification != null) {
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (context.mounted) {
                              PhonePushNotificationBanner.show(
                                context,
                                notification: result.dispatchedNotification!,
                              );
                            }
                          });
                        }
                      },
                      child: const Text('Kaydet ve Güncelle', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalChipSelector({
    required String title,
    required String current,
    required List<String> options,
    required Color color,
    required bool isDark,
    required BuildContext context,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSub(context))),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options.map((opt) {
              final isSelected = opt == current;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(opt),
                  selected: isSelected,
                  onSelected: (_) => onSelected(opt),
                  selectedColor: color,
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : AppColors.text(context),
                  ),
                  backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  side: BorderSide(color: isSelected ? color : AppColors.cardBorder(context)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final employees = pdks.employees;
    final pendingEmployees = pdks.pendingEmployees;
    final isMobile = MediaQuery.of(context).size.width < 768;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          // İK Onayı Bekleyen Personeller Kutusu
          if (pendingEmployees.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF59E0B).withOpacity(0.14),
                    const Color(0xFFD97706).withOpacity(0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'İK ONAYI BEKLEYEN KAYITLAR',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${pendingEmployees.length} Talep',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Yeni kayıt olan adayların departman ve unvanını atayarak onaylayın.',
                              style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...pendingEmployees.map((pending) => Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder(context)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFF59E0B).withOpacity(0.15),
                          child: Text(
                            pending.fullName.isNotEmpty ? pending.fullName.substring(0, 2).toUpperCase() : 'P',
                            style: TextStyle(color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706), fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(pending.fullName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.text(context))),
                              Text(
                                '${pending.email} • ${pending.phone}',
                                style: TextStyle(fontSize: 11, color: AppColors.textSub(context)),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(isDark ? 0.22 : 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '⏳ İK Onayı Bekliyor',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
                          tooltip: 'Başvuruyu Reddet',
                          onPressed: () => _showRejectConfirmation(context, pdks, pending),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Onayla', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: () => _openApprovalSheet(context, pdks, pending),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],

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
                    onTap: () => _openEmployeeEditSheet(context, emp),
                    leading: GestureDetector(
                      onTap: () => _showEmployeePhotoDialog(context, emp),
                      child: Stack(
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
                    subtitle: Text('${emp.department} • ${emp.title} • ${emp.phone}', style: TextStyle(color: AppColors.textSub(context), fontSize: 11)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Kalan İzin', style: TextStyle(fontSize: 10, color: AppColors.textSub(context))),
                            Text('${emp.remainingLeaveDays} Gün', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.success)),
                          ],
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF2563EB), size: 22),
                          tooltip: 'Personel Bilgilerini Düzenle',
                          onPressed: () => _openEmployeeEditSheet(context, emp),
                        ),
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
