import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/shift_schedule.dart';
import '../../state/pdks_state.dart';

class ShiftsTab extends StatelessWidget {
  const ShiftsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final shifts = pdks.shifts;
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
                'Vardiya & Çalışma Saatleri',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text(context),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOf(context),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: isMobile ? 8 : 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: Text(isMobile ? 'Ekle' : 'Yeni Vardiya', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () => _showAddShiftDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: shifts.isEmpty
                ? Center(
                    child: Text(
                      'Kayıtlı aktif vardiya bulunamadı.',
                      style: TextStyle(color: AppColors.textSub(context)),
                    ),
                  )
                : ListView.separated(
                    itemCount: shifts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final shift = shifts[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg(context),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.cardBorder(context)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    shift.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                      color: AppColors.text(context),
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryOf(context).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${shift.assignedEmployeeCount} Personel',
                                        style: TextStyle(
                                          color: AppColors.primaryOf(context),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                      tooltip: 'Vardiyayı Sil',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _confirmDeleteShift(context, shift),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.access_time_filled_rounded, size: 24, color: AppColors.primaryOf(context)),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${shift.startTime} - ${shift.endTime}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.text(context),
                                      ),
                                    ),
                                    Text(
                                      'Mola: ${shift.breakMinutes} dk',
                                      style: TextStyle(
                                        color: AppColors.textSub(context),
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: shift.activeDays
                                  .map((day) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.subtle(context),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppColors.cardBorder(context)),
                                        ),
                                        child: Text(
                                          day,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.text(context),
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteShift(BuildContext context, ShiftSchedule shift) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vardiyayı Sil'),
        content: Text('"${shift.title}" vardiyasını kalıcı olarak silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              context.read<PdksState>().deleteShift(shift.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"${shift.title}" vardiyası veritabanından silindi.')),
              );
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showAddShiftDialog(BuildContext context) {
    final titleController = TextEditingController();
    final startController = TextEditingController(text: '08:30');
    final endController = TextEditingController(text: '17:30');
    final breakController = TextEditingController(text: '60');
    final days = <String>['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma'];
    final selectedDays = <String>{'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma'};

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Yeni Vardiya Tanımla', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 440,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Vardiya Başlığı',
                          hintText: 'örn: Akşam Vardiyası (16:00 - 00:00)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: startController,
                              decoration: InputDecoration(
                                labelText: 'Başlangıç Saati',
                                hintText: '08:30',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: endController,
                              decoration: InputDecoration(
                                labelText: 'Bitiş Saati',
                                hintText: '17:30',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: breakController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Mola Süresi (Dakika)',
                          hintText: '60',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('Aktif Günler:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ...days,
                          'Cumartesi',
                          'Pazar',
                        ].map((d) {
                          final isSelected = selectedDays.contains(d);
                          return FilterChip(
                            label: Text(d, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : null)),
                            selected: isSelected,
                            selectedColor: AppColors.primaryOf(context),
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  selectedDays.add(d);
                                } else {
                                  selectedDays.remove(d);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOf(context),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lütfen vardiya başlığı giriniz.')),
                      );
                      return;
                    }

                    final newShift = ShiftSchedule(
                      id: DateTime.now().millisecondsSinceEpoch % 100000,
                      companyId: context.read<PdksState>().activeCompanyId,
                      title: title,
                      startTime: startController.text.trim(),
                      endTime: endController.text.trim(),
                      breakMinutes: int.tryParse(breakController.text.trim()) ?? 60,
                      activeDays: selectedDays.toList(),
                      assignedEmployeeCount: 0,
                    );

                    context.read<PdksState>().addShift(newShift);
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('"$title" vardiyası başarıyla veritabanına eklendi.')),
                    );
                  },
                  child: const Text('Vardiyayı Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
