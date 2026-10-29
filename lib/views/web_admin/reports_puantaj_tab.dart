import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../state/pdks_state.dart';

class ReportsPuantajTab extends StatefulWidget {
  const ReportsPuantajTab({super.key});

  @override
  State<ReportsPuantajTab> createState() => _ReportsPuantajTabState();
}

class _ReportsPuantajTabState extends State<ReportsPuantajTab> {
  final int _selectedMonth = 10;
  final int _selectedYear = 2026;
  bool _isExporting = false;

  void _exportExcel() async {
    setState(() => _isExporting = true);
    await Future.delayed(const Duration(seconds: 1)); // İndirme simülasyonu
    setState(() => _isExporting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Puantaj_Raporu_${_selectedYear}_${_selectedMonth.toString().padLeft(2, '0')}.xlsx başarıyla oluşturuldu ve indirildi.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final employees = context.watch<PdksState>().employees;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aylık Puantaj & Bordro Hesaplama Raporu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Seçili Dönem: Ekim 2026 • 22 İş Günü • 176 Normal Çalışma Saati',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A), // Excel Yeşili
                      foregroundColor: Colors.white,
                    ),
                    icon: _isExporting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.table_view, size: 18),
                    label: const Text('Excel Olarak İndir (.xlsx)'),
                    onPressed: _isExporting ? null : _exportExcel,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Puantaj Tablosu
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  columns: const [
                    DataColumn(label: Text('Personel', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Departman', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Normal Mesai (Saat)', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Fazla Mesai (Saat)', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Kullanılan İzin (Gün)', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Eksik / Gecikme', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Puantaj Durumu', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: employees.map((emp) {
                    final normalHours = 176 - (emp.usedLeaveDays * 8);
                    final overtimeHours = emp.id == 1 ? 12.5 : (emp.id == 3 ? 8.0 : 0.0);

                    return DataRow(
                      cells: [
                        DataCell(Text(emp.fullName, style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(emp.department)),
                        DataCell(Text('$normalHours Sa.')),
                        DataCell(
                          Text(
                            '+$overtimeHours Sa.',
                            style: TextStyle(
                              color: overtimeHours > 0 ? AppColors.success : AppColors.textMuted,
                              fontWeight: overtimeHours > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        DataCell(Text('${emp.usedLeaveDays} Gün')),
                        DataCell(
                          Text(
                            emp.id == 4 ? '1 Sa. 15 Dk.' : '0 Dk.',
                            style: TextStyle(
                              color: emp.id == 4 ? AppColors.danger : AppColors.textMuted,
                              fontWeight: emp.id == 4 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Bordroya Hazır', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
