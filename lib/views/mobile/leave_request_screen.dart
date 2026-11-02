import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../models/leave_request.dart';
import '../../state/pdks_state.dart';
import '../common/admin_edit_mode_bar.dart';
import '../../models/page_customization.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  LeaveType _selectedType = LeaveType.annual;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 3));

  // Saatlik İzin Değişkenleri
  DateTime _hourlyDate = DateTime.now();
  TimeOfDay _hourlyStartTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _hourlyEndTime = const TimeOfDay(hour: 12, minute: 0);

  // Sağlık / Rapor Belge Yükleme Değişkenleri
  String? _attachedDocName;
  String? _attachedDocPath;
  String? _attachedDocBase64;
  int? _attachedDocSizeKb;

  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  int get _calculatedDays => _endDate.difference(_startDate).inDays + 1;

  double get _calculatedHours {
    final startMinutes = _hourlyStartTime.hour * 60 + _hourlyStartTime.minute;
    final endMinutes = _hourlyEndTime.hour * 60 + _hourlyEndTime.minute;
    final diff = endMinutes - startMinutes;
    if (diff <= 0) return 0.5;
    return double.parse((diff / 60.0).toStringAsFixed(1));
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _pickHourlyDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _hourlyDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _hourlyDate = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _hourlyStartTime,
    );
    if (picked != null) {
      setState(() => _hourlyStartTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _hourlyEndTime,
    );
    if (picked != null) {
      setState(() => _hourlyEndTime = picked);
    }
  }

  Future<void> _pickMedicalDocument() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.cardBg(context),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.upload_file_rounded, color: Color(0xFF0284C7), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sağlık Raporu / Belge Yükle',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'iOS & Android üzerinden PDF veya fotoğraf seçin',
                          style: TextStyle(fontSize: 12, color: AppColors.textSub(context)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_rounded, color: Colors.blue),
                ),
                title: const Text('Dosyalardan Seç (PDF, DOCX, Resim)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('Cihaz dosya yöneticisi veya iCloud/Drive', style: TextStyle(fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final result = await FilePicker.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
                      withData: true,
                    );
                    if (result != null && result.files.isNotEmpty) {
                      final file = result.files.first;
                      setState(() {
                        _attachedDocName = file.name;
                        _attachedDocPath = file.path;
                        _attachedDocSizeKb = (file.size / 1024).round();
                        if (file.bytes != null) {
                          _attachedDocBase64 = base64Encode(file.bytes!);
                        }
                      });
                    }
                  } catch (e) {
                    debugPrint('Dosya seçme hatası: $e');
                  }
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Colors.purple),
                ),
                title: const Text('Fotoğraf Galerisinden Seç (iOS & Android)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('Kayıtlı reçete veya rapor fotoğrafları', style: TextStyle(fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                    if (image != null) {
                      final bytes = await image.readAsBytes();
                      setState(() {
                        _attachedDocName = image.name.isNotEmpty ? image.name : 'saglik_raporu_${DateTime.now().millisecondsSinceEpoch}.jpg';
                        _attachedDocPath = image.path;
                        _attachedDocSizeKb = (bytes.length / 1024).round();
                        _attachedDocBase64 = base64Encode(bytes);
                      });
                    }
                  } catch (e) {
                    debugPrint('Galeri seçme hatası: $e');
                  }
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.teal),
                ),
                title: const Text('Kamera ile Belge Çek', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('Anlık sağlık raporu veya vizite kağıdı', style: TextStyle(fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final picker = ImagePicker();
                    final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                    if (photo != null) {
                      final bytes = await photo.readAsBytes();
                      setState(() {
                        _attachedDocName = photo.name.isNotEmpty ? photo.name : 'kamera_rapor_${DateTime.now().millisecondsSinceEpoch}.jpg';
                        _attachedDocPath = photo.path;
                        _attachedDocSizeKb = (bytes.length / 1024).round();
                        _attachedDocBase64 = base64Encode(bytes);
                      });
                    }
                  } catch (e) {
                    debugPrint('Kamera hatası: $e');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    DateTime reqStart;
    DateTime reqEnd;
    double? totalHours;

    if (_selectedType == LeaveType.hourly) {
      reqStart = DateTime(_hourlyDate.year, _hourlyDate.month, _hourlyDate.day, _hourlyStartTime.hour, _hourlyStartTime.minute);
      reqEnd = DateTime(_hourlyDate.year, _hourlyDate.month, _hourlyDate.day, _hourlyEndTime.hour, _hourlyEndTime.minute);
      totalHours = _calculatedHours;
    } else {
      reqStart = _startDate;
      reqEnd = _endDate;
      totalHours = null;
    }

    final success = await context.read<PdksState>().submitLeaveRequest(
      type: _selectedType,
      startDate: reqStart,
      endDate: reqEnd,
      reason: _reasonController.text.trim(),
      totalHours: totalHours,
      documentName: _attachedDocName,
      documentPath: _attachedDocPath,
      documentBase64: _attachedDocBase64,
    );

    setState(() => _isSubmitting = false);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedType == LeaveType.hourly
                      ? '$_calculatedHours saatlik izin talebiniz yöneticinize iletildi.'
                      : 'İzin talebiniz yöneticinize iletildi.',
                ),
              ),
            ],
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<PdksState>().currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('İzin Talebi Oluştur'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sadece Admin Rolünde Gözüken Canlı Düzenleme Çubuğu
              const AdminEditModeBar(
                pageId: 'leave_request',
                pageTitle: 'İzin Talebi Sayfası',
                editableSections: [
                  PageSectionItem(id: 'leave_balance_card', title: 'İzin Bakiyesi Kartı'),
                ],
              ),

              // Bakiye Kartı
              AdminEditableSection(
                pageId: 'leave_request',
                sectionId: 'leave_balance_card',
                sectionTitle: 'İzin Bakiyesi Kartı',
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder(context)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOf(context).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.beach_access_rounded, color: AppColors.primaryOf(context), size: 28),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kalan Yıllık İzin Hakkınız', style: TextStyle(color: AppColors.textSub(context), fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(
                            '${user.remainingLeaveDays} Gün',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.primaryOf(context)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Text('İzin Türü', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text(context))),
              const SizedBox(height: 10),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: LeaveType.values.map((type) {
                  final isSelected = _selectedType == type;
                  String label = '';
                  switch (type) {
                    case LeaveType.annual:
                      label = 'Yıllık İzin';
                      break;
                    case LeaveType.medical:
                      label = 'Sağlık / Rapor';
                      break;
                    case LeaveType.excused:
                      label = 'Mazeret İzni';
                      break;
                    case LeaveType.unpaid:
                      label = 'Ücretsiz İzin';
                      break;
                    case LeaveType.hourly:
                      label = 'Saatlik İzin ⏱️';
                      break;
                  }
                  final chipTextColor = isSelected
                      ? Colors.white
                      : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B));
                  return ChoiceChip(
                    label: Text(
                      label,
                      style: TextStyle(
                        color: chipTextColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    selected: isSelected,
                    showCheckmark: false,
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    selectedColor: AppColors.primaryOf(context),
                    side: BorderSide(
                      color: isSelected ? AppColors.primaryOf(context) : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      width: isSelected ? 1.5 : 1,
                    ),
                    labelStyle: TextStyle(
                      color: chipTextColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedType = type);
                    },
                  );
                }).toList(),
              ),

              // SAĞLIK / RAPOR SEÇİLDİYSE: BELGE VE RAPOR YÜKLEME ALANI
              if (_selectedType == LeaveType.medical) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text('Rapor / Belge Ekle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text(context))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('iOS & Android', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_attachedDocName == null) ...[
                  InkWell(
                    onTap: _pickMedicalDocument,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF0284C7).withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.cloud_upload_outlined, color: Color(0xFF0284C7), size: 28),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Sağlık Raporu veya Belge Yükle',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text(context)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'PDF, JPG, PNG veya Kamera ile çekim (Max 15MB)',
                            style: TextStyle(fontSize: 11, color: AppColors.textSub(context)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.withOpacity(0.4), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _attachedDocName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text(context)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_attachedDocSizeKb ?? 0} KB • Belge yüklendi',
                                style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                          tooltip: 'Belgeyi Kaldır',
                          onPressed: () {
                            setState(() {
                              _attachedDocName = null;
                              _attachedDocPath = null;
                              _attachedDocBase64 = null;
                              _attachedDocSizeKb = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 24),

              // SAATLİK İZİN VEYA GÜNLÜK İZİN TARİH SEÇİMİ
              if (_selectedType == LeaveType.hourly) ...[
                Text('İzin Günü', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text(context))),
                const SizedBox(height: 10),
                InkWell(
                  onTap: _pickHourlyDate,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder(context)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primaryOf(context)),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('dd.MM.yyyy, EEEE', 'tr_TR').format(_hourlyDate),
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.text(context)),
                            ),
                          ],
                        ),
                        const Icon(Icons.edit_calendar_rounded, size: 18, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),
                Text('Saat Aralığı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text(context))),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickStartTime,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.cardBorder(context)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Başlangıç Saati', style: TextStyle(fontSize: 11, color: AppColors.textSub(context))),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.schedule_rounded, size: 18, color: AppColors.primaryOf(context)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_hourlyStartTime.hour.toString().padLeft(2, '0')}:${_hourlyStartTime.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _pickEndTime,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.cardBorder(context)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Bitiş Saati', style: TextStyle(fontSize: 11, color: AppColors.textSub(context))),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.schedule_send_rounded, size: 18, color: AppColors.primaryOf(context)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_hourlyEndTime.hour.toString().padLeft(2, '0')}:${_hourlyEndTime.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOf(context).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 18, color: AppColors.primaryOf(context)),
                      const SizedBox(width: 8),
                      Text(
                        'Toplam Süre: ',
                        style: TextStyle(fontSize: 12, color: AppColors.text(context)),
                      ),
                      Text(
                        '$_calculatedHours Saat',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryOf(context)),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text('Tarih Aralığı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text(context))),
                const SizedBox(height: 10),

                InkWell(
                  onTap: _pickDateRange,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder(context)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primaryOf(context)),
                            const SizedBox(width: 12),
                            Text(
                              '${DateFormat('dd.MM.yyyy').format(_startDate)} - ${DateFormat('dd.MM.yyyy').format(_endDate)}',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.text(context)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOf(context).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$_calculatedDays Gün',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryOf(context), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              Text('Talep Açıklaması / Not', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text(context))),
              const SizedBox(height: 10),

              TextFormField(
                controller: _reasonController,
                maxLines: 4,
                style: TextStyle(color: AppColors.text(context)),
                decoration: InputDecoration(
                  hintText: 'İzin alma gerekçenizi ve acil durumda ulaşılabilecek bilgiyi yazınız...',
                  hintStyle: TextStyle(color: AppColors.textSub(context)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Lütfen bir gerekçe belirtin.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOf(context),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, size: 18),
                  label: const Text('İzin Talebini Onaya Gönder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  onPressed: _isSubmitting ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
