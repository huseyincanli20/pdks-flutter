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
                        title: 'Toplam Personel',
                        value: pdks.totalEmployeesCount.toString(),
                        icon: Icons.people,
                        color: AppColors.primary,
                        subtitle: 'Tüm aktif çalışanlar',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKpiCard(
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
                    title: 'Toplam Personel',
                    value: pdks.totalEmployeesCount.toString(),
                    icon: Icons.people,
                    color: AppColors.primary,
                    subtitle: 'Tüm aktif çalışanlar',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKpiCard(
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
                    title: 'Geç Kalanlar',
                    value: pdks.lateEmployeesCount.toString(),
                    icon: Icons.timer_off,
                    color: AppColors.danger,
                    subtitle: '09:00 sonrası giriş',
                  ),
                ),
              ],
            ),

          SizedBox(height: isMobile ? 20 : 28),

          // Alt Panel: Canlı Hareket Akışı & Departman Durumu
          if (isMobile)
            Column(
              children: [
                _buildLiveMovementCard(pdks),
                const SizedBox(height: 20),
                _buildDepartmentCard(),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildLiveMovementCard(pdks)),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: _buildDepartmentCard()),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
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
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMovementCard(PdksState pdks) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Canlı Turnike & GPS Akışı',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
              columns: const [
                DataColumn(label: Text('Personel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('İşlem', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Saat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Yöntem', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Not', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
              rows: pdks.records.map((r) {
                final isCheckIn = r.type == AttendanceType.checkIn;
                return DataRow(
                  cells: [
                    DataCell(Text(r.employeeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isCheckIn ? AppColors.success : AppColors.danger).withOpacity(0.1),
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
                    DataCell(Text(DateFormat('HH:mm').format(r.timestamp), style: const TextStyle(fontSize: 12))),
                    DataCell(Text(r.methodLabel, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
                    DataCell(Text(r.note ?? 'Doğrulandı', style: const TextStyle(fontSize: 11, color: AppColors.textMuted))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Departman Katılım Oranları', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 18),
          _buildDepartmentProgress('Yazılım & Ar-Ge', 0.90, '5/6 Personel'),
          const SizedBox(height: 14),
          _buildDepartmentProgress('İnsan Kaynakları', 1.0, '2/2 Personel'),
          const SizedBox(height: 14),
          _buildDepartmentProgress('Satış & Pazarlama', 0.75, '3/4 Personel'),
          const SizedBox(height: 14),
          _buildDepartmentProgress('Mali İşler & Muhasebe', 1.0, '3/3 Personel'),
          const SizedBox(height: 14),
          _buildDepartmentProgress('Operasyon & Saha', 0.90, '9/10 Personel'),
        ],
      ),
    );
  }

  Widget _buildDepartmentProgress(String name, double percent, String count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            Text(count, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(percent >= 0.9 ? AppColors.success : (percent >= 0.7 ? AppColors.primary : AppColors.warning)),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
