import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/platform_file_helper.dart';
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

  Future<void> _exportAndOpenExcel() async {
    setState(() => _isExporting = true);
    final pdks = context.read<PdksState>();
    final employees = pdks.employees;

    // Gerçek Excel / CSV formatında tablo oluşturulur (UTF-8 BOM ile Türkçe karakter uyumlu)
    final buffer = StringBuffer();
    buffer.write('\uFEFF'); // UTF-8 BOM for Microsoft Excel & Apple Numbers
    buffer.writeln('T.C. ACME KORPORASYON A.Ş. - PERSONEL AYLIK PUANTAJ VE DEVAM ÇİZELGESİ');
    buffer.writeln('Dönem: Ekim $_selectedYear;Toplam İş Günü: 22 Gün;Standart Mesai: 176 Saat;Rapor Tarihi: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}');
    buffer.writeln('');
    buffer.writeln('Sıra No;Sicil No;Personel Adı Soyadı;Departman;Unvan;Normal Çalışma (Saat);Fazla Mesai (Saat);Eksik Mesai (Saat);Kullanılan İzin (Gün);Kalan İzin (Gün);Toplam Hak Ediş (Saat);Puantaj Onay Durumu');

    for (int i = 0; i < employees.length; i++) {
      final emp = employees[i];
      final normalHours = 112 + (i * 12);
      final otHours = (i % 2 == 0) ? (i * 4.5).toStringAsFixed(1) : '0';
      final missingHours = (i == 4) ? '8' : '0';
      final netHours = normalHours + double.parse(otHours) - double.parse(missingHours);

      buffer.writeln(
        '${i + 1};${1001 + emp.id};"${emp.fullName}";"${emp.department}";"${emp.title}";$normalHours;$otHours;$missingHours;${emp.usedLeaveDays};${emp.remainingLeaveDays};$netHours;Onaylandı',
      );
    }

    final fileName = 'Puantaj_Raporu_${_selectedYear}_${_selectedMonth.toString().padLeft(2, '0')}.csv';
    final content = buffer.toString();

    // Dosyayı cihazda indir ve hemen açılmasını tetikle
    await PlatformFileHelper.saveAndOpen(
      fileName: fileName,
      content: content,
      mimeType: 'text/csv;charset=utf-8',
    );

    if (!mounted) return;
    setState(() => _isExporting = false);
    _showExcelDownloadedDialog(context, fileName, content);
  }

  void _showExcelDownloadedDialog(BuildContext context, String fileName, String content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.table_view_rounded, color: Color(0xFF16A34A), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Excel Raporu İndirildi',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fileName,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aylık puantaj verileriniz hazırlandı ve cihazınıza indirildi. Dosyayı Excel, Numbers veya Google E-Tablolar ile görüntüleyebilirsiniz.',
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : AppColors.textPrimary, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131B2E) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder(context)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'UTF-8 Türkçe Karakter Desteği Aktif',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Kapat', style: TextStyle(color: AppColors.textSub(context), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Excel ile Aç / İndir', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx);
              PlatformFileHelper.saveAndOpen(
                fileName: fileName,
                content: content,
                mimeType: 'text/csv;charset=utf-8',
              );
            },
          ),
        ],
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
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aylık Puantaj Raporu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ekim 2026 • 22 İş Günü • 176 Saat',
                  style: TextStyle(color: AppColors.textSub(context), fontSize: 12),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: _isExporting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.table_view_rounded, size: 18),
                    label: Text(
                      _isExporting ? 'Hazırlanıyor...' : 'Excel İndir ve Aç (.xlsx)',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isExporting ? null : _exportAndOpenExcel,
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aylık Puantaj & Bordro Raporu',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                    ),
                    Text(
                      'Seçili Dönem: Ekim 2026 • 22 İş Günü • 176 Normal Çalışma Saati',
                      style: TextStyle(color: AppColors.textSub(context), fontSize: 13),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _isExporting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.table_view_rounded, size: 18),
                  label: Text(
                    _isExporting ? 'Hazırlanıyor...' : 'Excel İndir ve Aç (.xlsx)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isExporting ? null : _exportAndOpenExcel,
                ),
              ],
            ),

          const SizedBox(height: 18),

          // Puantaj Tablosu
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder(context)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AppColors.subtle(context)),
                      columnSpacing: 24,
                      columns: const [
                        DataColumn(label: Text('Personel', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Departman', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Normal (Saat)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Fazla Mesai', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Kalan İzin', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Onay Durumu', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: employees.map((emp) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                                    child: Text(
                                      emp.fullName.isNotEmpty ? emp.fullName.substring(0, 1) : 'P',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(emp.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            DataCell(Text(emp.department)),
                            DataCell(Text('${112 + (emp.id * 12)} Sa.')),
                            DataCell(
                              Text(
                                emp.id % 2 == 0 ? '+${emp.id * 4.5} Sa.' : '-',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: emp.id % 2 == 0 ? AppColors.success : AppColors.textSecondary,
                                ),
                              ),
                            ),
                            DataCell(Text('${emp.remainingLeaveDays} Gün')),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Onaylandı',
                                  style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
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
