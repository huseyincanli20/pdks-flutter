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
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isExporting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Puantaj_Raporu_${_selectedYear}_${_selectedMonth.toString().padLeft(2, '0')}.xlsx başarıyla indirildi.'),
        ),
      );
    }
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
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aylık Puantaj Raporu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Ekim 2026 • 22 İş Günü • 176 Saat',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: _isExporting
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.table_view, size: 16),
                    label: const Text('Excel İndir (.xlsx)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    onPressed: _isExporting ? null : _exportExcel,
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aylık Puantaj & Bordro Raporu',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Seçili Dönem: Ekim 2026 • 22 İş Günü • 176 Normal Çalışma Saati',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
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

          const SizedBox(height: 18),

          // Puantaj Tablosu
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: isMobile ? 18 : 28,
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                      headingRowHeight: 44,
                      dataRowMinHeight: 48,
                      dataRowMaxHeight: 52,
                      columns: const [
                        DataColumn(label: Text('Personel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(label: Text('Departman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(label: Text('Normal (Saat)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(label: Text('Fazla Mesai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(label: Text('İzin (Gün)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(label: Text('Gecikme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(label: Text('Durum', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      ],
                      rows: employees.map((emp) {
                        final normalHours = 176 - (emp.usedLeaveDays * 8);
                        final overtimeHours = emp.id == 1 ? 12.5 : (emp.id == 3 ? 8.0 : 0.0);

                        return DataRow(
                          cells: [
                            DataCell(Text(emp.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                            DataCell(Text(emp.department, style: const TextStyle(fontSize: 12))),
                            DataCell(Text('$normalHours Sa.', style: const TextStyle(fontSize: 12))),
                            DataCell(
                              Text(
                                overtimeHours > 0 ? '+$overtimeHours Sa.' : '-',
                                style: TextStyle(
                                  color: overtimeHours > 0 ? AppColors.success : AppColors.textMuted,
                                  fontWeight: overtimeHours > 0 ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataCell(Text('${emp.usedLeaveDays} Gün', style: const TextStyle(fontSize: 12))),
                            DataCell(
                              Text(
                                emp.id == 4 ? '1 Sa. 15 Dk.' : '-',
                                style: TextStyle(
                                  color: emp.id == 4 ? AppColors.danger : AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('Bordroya Hazır', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
