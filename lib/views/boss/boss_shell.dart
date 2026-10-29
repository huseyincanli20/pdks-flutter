import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/attendance_record.dart';
import '../../state/pdks_state.dart';
import '../common/app_drawer.dart';

class BossShell extends StatelessWidget {
  const BossShell({super.key});

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final user = pdks.currentUser;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Patron Paneli (Yönetim)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${user.fullName} • ${user.title}', style: TextStyle(fontSize: 11, color: AppColors.textSub(context))),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFB45309)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.workspace_premium, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('CEO / Yönetim', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16.0,
          16.0,
          16.0,
          MediaQuery.of(context).padding.bottom + 24.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CEO Stratejik Karşılama Kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ŞİRKET ÇALIŞMA & MALİYET ÖZETİ',
                        style: TextStyle(color: Colors.white60, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Ekim 2026', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Genel Devamlılık Oranı: %94.2',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Toplam 6 personelden 4\'ü şu an aktif mesaide.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Toplam Fazla Mesai', style: TextStyle(color: Colors.white60, fontSize: 11)),
                          SizedBox(height: 2),
                          Text('+24.5 Saat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Tahmini Mesai Maliyeti', style: TextStyle(color: Colors.white60, fontSize: 11)),
                          SizedBox(height: 2),
                          Text('₺36.750 TL', style: TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Anlık Durum Sayaçları
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    context,
                    title: 'Aktif İçeride',
                    value: pdks.presentEmployeesCount.toString(),
                    color: AppColors.success,
                    icon: Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    context,
                    title: 'İzinli / Raporlu',
                    value: pdks.onLeaveEmployeesCount.toString(),
                    color: AppColors.warning,
                    icon: Icons.beach_access,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    context,
                    title: 'Geç Kalan',
                    value: pdks.lateEmployeesCount.toString(),
                    color: AppColors.danger,
                    icon: Icons.alarm_off,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Departman Performansı & Devam Tablosu
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Departman Bazlı Devam Oranları', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                  const SizedBox(height: 16),
                  _buildDeptRow(context, 'Yazılım & Ar-Ge Ekibi', 0.96, '5/6 Aktif', AppColors.primary),
                  const SizedBox(height: 12),
                  _buildDeptRow(context, 'İnsan Kaynakları', 1.0, '2/2 Aktif', AppColors.success),
                  const SizedBox(height: 12),
                  _buildDeptRow(context, 'Satış & Pazarlama', 0.88, '3/4 Aktif', AppColors.warning),
                  const SizedBox(height: 12),
                  _buildDeptRow(context, 'Mali İşler & Muhasebe', 0.94, '3/3 Aktif', AppColors.primary),
                  const SizedBox(height: 12),
                  _buildDeptRow(context, 'Operasyon & Saha', 0.90, '9/10 Aktif', AppColors.info),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Son Yönetici Logları
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Son Giriş & Turnike Hareketleri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                  const SizedBox(height: 12),
                  ...pdks.records.take(3).map((r) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            Icon(
                              r.type == AttendanceType.checkIn ? Icons.login : Icons.logout,
                              size: 16,
                              color: r.type == AttendanceType.checkIn ? AppColors.success : AppColors.danger,
                            ),
                            const SizedBox(width: 8),
                            Text(r.employeeName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text(context))),
                            const Spacer(),
                            Text(r.methodLabel, style: TextStyle(fontSize: 11, color: AppColors.textSub(context))),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(BuildContext context, {required String title, required String value, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 11, color: AppColors.textSub(context))),
        ],
      ),
    );
  }

  Widget _buildDeptRow(BuildContext context, String name, double percent, String count, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.text(context))),
            Text(count, style: TextStyle(color: AppColors.textSub(context), fontSize: 11)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: AppColors.cardBorder(context),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
