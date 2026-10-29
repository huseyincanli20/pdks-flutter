import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/payroll_slip.dart';
import '../../state/pdks_state.dart';
import 'payroll_detail_screen.dart';
import '../common/admin_edit_mode_bar.dart';
import '../../models/page_customization.dart';

class MyPayrollsScreen extends StatelessWidget {
  const MyPayrollsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final payrolls = pdks.currentUserPayrolls;
    final latest = pdks.latestUserPayroll;

    // Yıllık kümülatif toplamlar
    double cumulativeNet = 0;
    double cumulativeGross = 0;
    for (final p in payrolls) {
      cumulativeNet += p.netSalary;
      cumulativeGross += p.totalEarnings;
    }

    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('Maaş ve Bordrolarım', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: payrolls.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz Adınıza Tanzim Edilen Bordro Yok',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'İnsan Kaynakları departmanı aylık puantajı onayladığında bordronuz burada görüntülenecektir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sadece Admin Rolünde Gözüken Canlı Düzenleme Çubuğu
                  const AdminEditModeBar(
                    pageId: 'my_payrolls',
                    pageTitle: 'Bordrolarım Ekranı',
                    editableSections: [
                      PageSectionItem(id: 'latest_payroll_card', title: 'En Son Bordro Vurgu Kartı'),
                    ],
                  ),

                  // Son Bordro Kartı (Büyük Vurgulu)
                  if (latest != null) ...[
                    AdminEditableSection(
                      pageId: 'my_payrolls',
                      sectionId: 'latest_payroll_card',
                      sectionTitle: 'En Son Bordro Vurgu Kartı',
                      child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'EN SON BORDRO • ${latest.periodName}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: latest.status.color.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(latest.status.icon, color: Colors.white, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      latest.status.label,
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Net Ele Geçen Maaş',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            latest.formatCurrency(latest.netSalary),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildMiniStat('Brüt Ücret', latest.formatCurrency(latest.totalEarnings)),
                              const SizedBox(width: 16),
                              _buildMiniStat('Kesintiler', latest.formatCurrency(latest.totalDeductions)),
                              const SizedBox(width: 16),
                              _buildMiniStat('Fazla Mesai', '${latest.overtimeHours.toStringAsFixed(1)} Sa.'),
                            ],
                          ),
                          const Divider(height: 24, color: Colors.white24),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PayrollDetailScreen(payroll: latest),
                                ),
                              );
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Detaylı Bordro Pusulasını Aç', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Yıllık Kümülatif Kazanç İcmali
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.cardBorder(context)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.savings_outlined, color: Color(0xFF10B981), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('2026 Yılı Kümülatif Net Kazanç', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              const SizedBox(height: 2),
                              Text(
                                currencyFormat.format(cumulativeNet),
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Küm. Brüt', style: TextStyle(fontSize: 10, color: AppColors.textSub(context))),
                            Text(currencyFormat.format(cumulativeGross), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF10B981))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Geçmiş Bordrolar Başlığı
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'GEÇMİŞ AYLIK BORDROLAR (${payrolls.length})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        'PDKS Onaylı',
                        style: TextStyle(fontSize: 11, color: AppColors.textSub(context)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Bordro Listesi
                  ...payrolls.map((p) => _buildPayrollListTile(context, p)),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPayrollListTile(BuildContext context, PayrollSlip p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: p.status.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.receipt_outlined, color: p.status.color, size: 22),
        ),
        title: Row(
          children: [
            Text(
              p.periodName,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text(context)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: p.status.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                p.status.label,
                style: TextStyle(color: p.status.color, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Brüt: ${p.formatCurrency(p.totalEarnings)} • Mesai: ${p.overtimeHours.toStringAsFixed(1)} sa.',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              p.formatCurrency(p.netSalary),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
            ),
            const SizedBox(height: 2),
            const Text(
              'Net Tutar ›',
              style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PayrollDetailScreen(payroll: p)),
          );
        },
      ),
    );
  }
}
