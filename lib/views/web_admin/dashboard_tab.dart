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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4 KPI Sayaç Kartı
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

          const SizedBox(height: 32),

          // Alt Panel: Canlı Turnike / Hareket Akışı & Departman Durumu
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sol: Canlı Hareket Listesi
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Canlı PDKS Turnike & GPS Akışı',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Real-Time', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(1.2),
                          2: FlexColumnWidth(1.5),
                          3: FlexColumnWidth(1.2),
                          4: FlexColumnWidth(2),
                        },
                        children: [
                          const TableRow(
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 1))),
                            children: [
                              Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Personel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
                              Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('İşlem', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
                              Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Zaman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
                              Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Yöntem', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
                              Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Doğrulama / Not', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
                            ],
                          ),
                          ...pdks.records.map((r) {
                            final isCheckIn = r.type == AttendanceType.checkIn;
                            return TableRow(
                              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Text(r.employeeName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (isCheckIn ? AppColors.success : AppColors.danger).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      r.typeLabel,
                                      style: TextStyle(
                                        color: isCheckIn ? AppColors.success : AppColors.danger,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Text(DateFormat('HH:mm:ss').format(r.timestamp), style: const TextStyle(fontSize: 13)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Text(r.methodLabel, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Text(r.note ?? 'Doğrulandı', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // Sağ: Departman Katılım Özeti
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Departman Katılım Oranları', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      _buildDepartmentProgress('Yazılım & Ar-Ge', 0.85, '5/6 Personel'),
                      const SizedBox(height: 16),
                      _buildDepartmentProgress('İnsan Kaynakları', 1.0, '2/2 Personel'),
                      const SizedBox(height: 16),
                      _buildDepartmentProgress('Satış & Pazarlama', 0.60, '3/5 Personel'),
                      const SizedBox(height: 16),
                      _buildDepartmentProgress('Mali İşler & Muhasebe', 0.75, '3/4 Personel'),
                      const SizedBox(height: 16),
                      _buildDepartmentProgress('Operasyon & Lojistik', 0.90, '9/10 Personel'),
                    ],
                  ),
                ),
              ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
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
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text(count, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(percent > 0.7 ? AppColors.primary : AppColors.warning),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
