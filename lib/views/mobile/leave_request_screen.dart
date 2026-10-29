import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  int get _calculatedDays => _endDate.difference(_startDate).inDays + 1;

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final success = await context.read<PdksState>().submitLeaveRequest(
      type: _selectedType,
      startDate: _startDate,
      endDate: _endDate,
      reason: _reasonController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('İzin talebiniz yöneticinize iletildi.'),
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

              const SizedBox(height: 24),
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
