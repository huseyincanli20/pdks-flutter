import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/attendance_record.dart';
import '../../state/pdks_state.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final isMobile = MediaQuery.of(context).size.width < 768;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 28,
        isMobile ? 16 : 28,
        isMobile ? 16 : 28,
        MediaQuery.of(context).padding.bottom + 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4 KPI Sayaç Kartı - Mobilde 2x2, Geniş ekranda 4'lü yan yana
          if (isMobile)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        context,
                        title: 'Toplam Personel',
                        value: pdks.totalEmployeesCount.toString(),
                        icon: Icons.people,
                        color: AppColors.primaryOf(context),
                        subtitle: 'Tüm aktif çalışanlar',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKpiCard(
                        context,
                        title: 'Anlık Ofiste',
                        value: pdks.presentEmployeesCount.toString(),
                        icon: Icons.check_circle,
                        color: AppColors.success,
                        subtitle: 'Mesaisi süren',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        context,
                        title: 'İzinli / Raporlu',
                        value: pdks.onLeaveEmployeesCount.toString(),
                        icon: Icons.beach_access,
                        color: AppColors.warning,
                        subtitle: 'Onaylı izinler',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKpiCard(
                        context,
                        title: 'Geç Kalan',
                        value: pdks.lateEmployeesCount.toString(),
                        icon: Icons.timer_off,
                        color: AppColors.danger,
                        subtitle: '09:00 sonrası',
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    context,
                    title: 'Toplam Personel',
                    value: pdks.totalEmployeesCount.toString(),
                    icon: Icons.people,
                    color: AppColors.primaryOf(context),
                    subtitle: 'Tüm aktif çalışanlar',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKpiCard(
                    context,
                    title: 'Anlık Ofiste / İçeride',
                    value: pdks.presentEmployeesCount.toString(),
                    icon: Icons.check_circle,
                    color: AppColors.success,
                    subtitle: 'Mesaisi devam eden',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKpiCard(
                    context,
                    title: 'İzinli / Raporlu',
                    value: pdks.onLeaveEmployeesCount.toString(),
                    icon: Icons.beach_access,
                    color: AppColors.warning,
                    subtitle: 'Onaylanmış izinler',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKpiCard(
                    context,
                    title: 'Geç Kalanlar',
                    value: pdks.lateEmployeesCount.toString(),
                    icon: Icons.timer_off,
                    color: AppColors.danger,
                    subtitle: '09:00 sonrası giriş',
                  ),
                ),
              ],
            ),

          const SizedBox(height: 20),

          // Saha ve Dışarıda Çalışma Durumu
          _buildFieldWorkSection(context, pdks),

          SizedBox(height: isMobile ? 20 : 28),

          // Alt Panel: Canlı Hareket Akışı & Departman Durumu
          if (isMobile)
            Column(
              children: [
                _buildLiveMovementCard(context, pdks),
                const SizedBox(height: 20),
                _buildDepartmentCard(context),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildLiveMovementCard(context, pdks)),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: _buildDepartmentCard(context)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
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
              Text(
                title,
                style: TextStyle(color: AppColors.textSub(context), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text(context)),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: AppColors.textSub(context)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMovementCard(BuildContext context, PdksState pdks) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Canlı Turnike & GPS Akışı',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.text(context)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(radius: 3, backgroundColor: AppColors.success),
                    SizedBox(width: 5),
                    Text('Canlı', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowHeight: 38,
              dataRowMinHeight: 46,
              dataRowMaxHeight: 46,
              headingRowColor: WidgetStateProperty.all(AppColors.subtle(context)),
              columns: [
                DataColumn(label: Text('Personel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.text(context)))),
                DataColumn(label: Text('İşlem', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.text(context)))),
                DataColumn(label: Text('Saat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.text(context)))),
                DataColumn(label: Text('Yöntem', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.text(context)))),
                DataColumn(label: Text('Not', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.text(context)))),
              ],
              rows: pdks.records.map((r) {
                final isCheckIn = r.type == AttendanceType.checkIn;
                return DataRow(
                  cells: [
                    DataCell(Text(r.employeeName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.text(context)))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isCheckIn ? AppColors.success : AppColors.danger).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          r.typeLabel,
                          style: TextStyle(
                            color: isCheckIn ? AppColors.success : AppColors.danger,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(DateFormat('HH:mm').format(r.timestamp), style: TextStyle(fontSize: 12, color: AppColors.text(context)))),
                    DataCell(Text(r.methodLabel, style: TextStyle(fontSize: 11, color: AppColors.textSub(context)))),
                    DataCell(Text(r.note ?? 'Doğrulandı', style: TextStyle(fontSize: 11, color: AppColors.textSub(context)))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Departman Katılım Oranları', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          const SizedBox(height: 18),
          _buildDepartmentProgress(context, 'Yazılım & Ar-Ge', 0.90, '5/6 Personel'),
          const SizedBox(height: 14),
          _buildDepartmentProgress(context, 'İnsan Kaynakları', 1.0, '2/2 Personel'),
          const SizedBox(height: 14),
          _buildDepartmentProgress(context, 'Satış & Pazarlama', 0.75, '3/4 Personel'),
          const SizedBox(height: 14),
          _buildDepartmentProgress(context, 'Mali İşler & Muhasebe', 1.0, '3/3 Personel'),
          const SizedBox(height: 14),
          _buildDepartmentProgress(context, 'Operasyon & Saha', 0.90, '9/10 Personel'),
        ],
      ),
    );
  }

  Widget _buildFieldWorkSection(BuildContext context, PdksState pdks) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldRecords = pdks.records
        .where((r) => r.note != null && r.note!.contains('Dışarıda Çalışma'))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: fieldRecords.isNotEmpty
              ? const Color(0xFF10B981).withOpacity(0.4)
              : AppColors.cardBorder(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on_rounded, color: Color(0xFF10B981), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Saha / Dışarıda Çalışma Bildirimleri',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${fieldRecords.length} Kayıt',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (fieldRecords.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Şu an sahada veya ofis dışında çalışan personel bildirimi bulunmamaktadır.',
                style: TextStyle(fontSize: 12, color: AppColors.textSub(context)),
              ),
            )
          else
            ...fieldRecords.take(4).map((rec) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFF10B981),
                      child: Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(rec.employeeName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('GPS İletildi', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(rec.note ?? '', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
                          if (rec.userLatitude != null && rec.userLongitude != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '📍 Koordinat: ${rec.userLatitude!.toStringAsFixed(4)}° K, ${rec.userLongitude!.toStringAsFixed(4)}° D',
                              style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      '${rec.timestamp.hour.toString().padLeft(2, '0')}:${rec.timestamp.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSub(context)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDepartmentProgress(BuildContext context, String name, double percent, String count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.text(context))),
            Text(count, style: TextStyle(color: AppColors.textSub(context), fontSize: 11)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: AppColors.subtle(context),
            valueColor: AlwaysStoppedAnimation<Color>(percent >= 0.9 ? AppColors.success : (percent >= 0.7 ? AppColors.primaryOf(context) : AppColors.warning)),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
