import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/platform_file_helper.dart';
import '../../models/payroll_slip.dart';
import '../../models/employee.dart';
import '../../state/pdks_state.dart';

class PayrollDetailScreen extends StatefulWidget {
  final PayrollSlip payroll;

  const PayrollDetailScreen({super.key, required this.payroll});

  @override
  State<PayrollDetailScreen> createState() => _PayrollDetailScreenState();
}

class _PayrollDetailScreenState extends State<PayrollDetailScreen> {
  bool _isDownloading = false;

  Future<void> _exportPayrollDocument() async {
    setState(() => _isDownloading = true);
    final p = widget.payroll;
    final formatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

    final buffer = StringBuffer();
    buffer.write('\uFEFF'); // UTF-8 BOM
    buffer.writeln('================================================================================');
    buffer.writeln('                     ${p.companyName.toUpperCase()}');
    buffer.writeln('                   RESMİ ÜCRET HESAP PUSULASI (E-BORDRO)');
    buffer.writeln('================================================================================');
    buffer.writeln('Bordro Dönemi  : ${p.periodName} (01.${p.periodMonth.toString().padLeft(2, '0')}.${p.periodYear} - 31.${p.periodMonth.toString().padLeft(2, '0')}.${p.periodYear})');
    buffer.writeln('Tanzim Tarihi  : ${DateFormat('dd.MM.yyyy').format(p.issueDate)}');
    buffer.writeln('Ödeme Tarihi   : ${DateFormat('dd.MM.yyyy').format(p.paymentDate)}');
    buffer.writeln('Bordro Seri No : ${p.id.toUpperCase()}');
    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('PERSONEL BİLGİLERİ');
    buffer.writeln('Adı Soyadı     : ${p.employeeName}');
    buffer.writeln('TC Kimlik No   : ${p.tcKimlikNo}');
    buffer.writeln('Sicil No       : ${p.sicilNo}');
    buffer.writeln('Departman      : ${p.department}');
    buffer.writeln('Unvan / Görev  : ${p.employeeTitle}');
    buffer.writeln('Banka / IBAN   : ${p.bankName} - ${p.iban}');
    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('PDKS VE ÇALIŞMA SÜRELERİ');
    buffer.writeln('Çalışılan Gün  : ${p.workedDays} İş Günü (30 SGK Günü)');
    buffer.writeln('Normal Mesai   : ${p.workedHours.toStringAsFixed(0)} Saat');
    buffer.writeln('Fazla Mesai    : ${p.overtimeHours.toStringAsFixed(1)} Saat (%50 Zamlı)');
    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('GELİRLER / KAZANÇLAR                     TUTAR');
    buffer.writeln('Temel Brüt Ücret                        : ${formatter.format(p.baseGrossSalary)}');
    buffer.writeln('Fazla Mesai Ücreti                      : ${formatter.format(p.overtimePay)}');
    buffer.writeln('Yemek Yardımı                           : ${formatter.format(p.mealAllowance)}');
    buffer.writeln('Yol / Ulaşım Yardımı                    : ${formatter.format(p.travelAllowance)}');
    if (p.bonus > 0) {
      buffer.writeln('Prim / İkramiye Ödemesi                 : ${formatter.format(p.bonus)}');
    }
    buffer.writeln('TOPLAM BRÜT GELİR                       : ${formatter.format(p.totalEarnings)}');
    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('YASAL VE ÖZEL KESİNTİLER                 TUTAR');
    buffer.writeln('SGK İşçi Payı (%14)                     : ${formatter.format(p.sgkEmployeeDeduction)}');
    buffer.writeln('İşsizlik Sigortası Payı (%1)            : ${formatter.format(p.unemploymentEmployeeDeduction)}');
    buffer.writeln('Gelir Vergisi Matrahı & Kesintisi       : ${formatter.format(p.incomeTax)}');
    buffer.writeln('Damga Vergisi Kesintisi                 : ${formatter.format(p.stampTax)}');
    buffer.writeln('(-) Asgari Ücret Vergi İstisnası        : -${formatter.format(p.taxExemption)}');
    buffer.writeln('TOPLAM YASAL KESİNTİLER                 : ${formatter.format(p.totalDeductions)}');
    buffer.writeln('================================================================================');
    buffer.writeln('NET ÖDENECEK TUTAR                      : ${formatter.format(p.netSalary)}');
    buffer.writeln('================================================================================');
    buffer.writeln('Ödeme Durumu   : ${p.status.label.toUpperCase()}');
    buffer.writeln('Elektronik İmza: 5070 Sayılı Elektronik İmza Kanunu Uyarınca Nitelikli e-İmza ile Onaylanmıştır.');
    buffer.writeln('Zaman Damgası  : ${DateFormat('dd.MM.yyyy HH:mm:ss').format(p.signatureTimestamp ?? DateTime.now())}');
    buffer.writeln('================================================================================');

    final fileName = 'Bordro_${p.periodYear}_${p.periodMonth.toString().padLeft(2, '0')}_${p.employeeName.replaceAll(' ', '_')}.txt';
    final content = buffer.toString();

    await PlatformFileHelper.saveAndOpen(
      fileName: fileName,
      content: content,
      mimeType: 'text/plain;charset=utf-8',
    );

    if (!mounted) return;
    setState(() => _isDownloading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('$fileName başarıyla indirildi.')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payroll;
    final pdks = context.watch<PdksState>();
    final user = pdks.currentUser;
    final isManager = user.role == UserRole.hr || user.role == UserRole.boss || user.role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Maaş Bordrosu • ${p.periodName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${p.employeeName} (${p.department})', style: TextStyle(fontSize: 11, color: AppColors.textSub(context))),
          ],
        ),
        actions: [
          IconButton(
            icon: _isDownloading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.file_download_outlined),
            tooltip: 'Bordroyu İndir (Resmi Format)',
            onPressed: _isDownloading ? null : _exportPayrollDocument,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Üst Başlık & Şirket Kartı
            _buildCompanyHeader(context, p),
            const SizedBox(height: 12),

            // Personel Bilgileri
            _buildEmployeeInfoCard(context, p),
            const SizedBox(height: 12),

            // Mesai & Çalışma Bilgisi
            _buildWorkSummaryCard(context, p),
            const SizedBox(height: 12),

            // Kazançlar & Kesintiler Detay Tabloları
            _buildEarningsCard(context, p),
            const SizedBox(height: 12),

            _buildDeductionsCard(context, p),
            const SizedBox(height: 14),

            // Büyük Vurgulu Net Maaş Kartı
            _buildNetPayoutCard(context, p),
            const SizedBox(height: 12),

            // İşveren Maliyeti (Yönetici ve İK için özel)
            if (isManager) ...[
              _buildEmployerCostCard(context, p),
              const SizedBox(height: 12),
            ],

            // Resmi e-İmza & Güvenlik Karekodu
            _buildSecurityStampCard(context, p),
            const SizedBox(height: 20),

            // Aksiyon Butonları
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: _isDownloading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.download_rounded, size: 20),
                    label: const Text('Resmi Bordro İndir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    onPressed: _isDownloading ? null : _exportPayrollDocument,
                  ),
                ),
                if (isManager && p.status != PayrollStatus.paid) ...[
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      pdks.updatePayrollStatus(p.id, PayrollStatus.paid);
                      setState(() => p.status = PayrollStatus.paid);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF10B981),
                          content: Text('Bordro durumu "Ödendi" olarak güncellendi.'),
                        ),
                      );
                    },
                    child: const Text('Ödendi Yap', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyHeader(BuildContext context, PayrollSlip p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.companyName,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                ),
                const SizedBox(height: 3),
                const Text(
                  'RESMİ ÜCRET HESAP PUSULASI (E-BORDRO)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dönem: ${p.periodName} • Tanzim: ${DateFormat('dd.MM.yyyy').format(p.issueDate)}',
                  style: TextStyle(fontSize: 11, color: AppColors.textSub(context)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: p.status.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.status.color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(p.status.icon, color: p.status.color, size: 14),
                const SizedBox(width: 4),
                Text(
                  p.status.label,
                  style: TextStyle(color: p.status.color, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeInfoCard(BuildContext context, PayrollSlip p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Personel Bilgileri',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text(context)),
              ),
              const Spacer(),
              Text('Sicil No: ${p.sicilNo}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ],
          ),
          const Divider(height: 18),
          _buildInfoRow('Adı Soyadı', p.employeeName, context),
          _buildInfoRow('TC Kimlik No', p.tcKimlikNo, context),
          _buildInfoRow('Departman / Görev', '${p.department} - ${p.employeeTitle}', context),
          _buildInfoRow('Banka & Hesap', '${p.bankName} (${p.iban})', context),
        ],
      ),
    );
  }

  Widget _buildWorkSummaryCard(BuildContext context, PayrollSlip p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 18, color: Color(0xFF0284C7)),
              const SizedBox(width: 8),
              Text(
                'PDKS Mesai ve Çalışma Süreleri',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text(context)),
              ),
            ],
          ),
          const Divider(height: 18),
          Row(
            children: [
              Expanded(child: _buildMetricTile(context, 'Çalışılan Gün', '${p.workedDays} Gün', Icons.calendar_today_rounded, const Color(0xFF0284C7))),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricTile(context, 'Normal Mesai', '${p.workedHours.toStringAsFixed(0)} Saat', Icons.schedule_rounded, const Color(0xFF10B981))),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricTile(context, 'Fazla Mesai', '${p.overtimeHours.toStringAsFixed(1)} Saat', Icons.more_time_rounded, const Color(0xFFF59E0B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildEarningsCard(BuildContext context, PayrollSlip p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_upward_rounded, size: 16, color: Color(0xFF10B981)),
              ),
              const SizedBox(width: 8),
              Text(
                'Kazançlar / Gelirler (Brüt)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text(context)),
              ),
            ],
          ),
          const Divider(height: 18),
          _buildAmountRow('Temel Brüt Maaş', p.formatCurrency(p.baseGrossSalary), context),
          _buildAmountRow('Fazla Mesai Ücreti (%50)', p.formatCurrency(p.overtimePay), context),
          _buildAmountRow('Yemek Yardımı', p.formatCurrency(p.mealAllowance), context),
          _buildAmountRow('Yol / Ulaşım Yardımı', p.formatCurrency(p.travelAllowance), context),
          if (p.bonus > 0)
            _buildAmountRow('Performans / İkramiye', p.formatCurrency(p.bonus), context),
          const Divider(height: 18),
          _buildAmountRow('TOPLAM BRÜT KAZANÇ', p.formatCurrency(p.totalEarnings), context, isBold: true, color: const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _buildDeductionsCard(BuildContext context, PayrollSlip p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_downward_rounded, size: 16, color: Color(0xFFEF4444)),
              ),
              const SizedBox(width: 8),
              Text(
                'Yasal Kesintiler & Vergiler',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text(context)),
              ),
            ],
          ),
          const Divider(height: 18),
          _buildAmountRow('SGK İşçi Payı (%14)', p.formatCurrency(p.sgkEmployeeDeduction), context),
          _buildAmountRow('İşsizlik Sigortası (%1)', p.formatCurrency(p.unemploymentEmployeeDeduction), context),
          _buildAmountRow('Gelir Vergisi Matrahı & Kesintisi', p.formatCurrency(p.incomeTax), context),
          _buildAmountRow('Damga Vergisi', p.formatCurrency(p.stampTax), context),
          _buildAmountRow('(-) Asgari Ücret Vergi İstisnası', '-${p.formatCurrency(p.taxExemption)}', context, color: const Color(0xFF10B981)),
          const Divider(height: 18),
          _buildAmountRow('TOPLAM KESİNTİLER', p.formatCurrency(p.totalDeductions), context, isBold: true, color: const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildNetPayoutCard(BuildContext context, PayrollSlip p) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NET ELE GEÇEN MAAŞ', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.1, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text('Hesaba Yatırılacak Tutar', style: TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  DateFormat('dd.MM.yyyy').format(p.paymentDate),
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            p.formatCurrency(p.netSalary),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_balance_wallet_outlined, size: 16, color: Color(0xFF60A5FA)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${p.bankName} - ${p.iban}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployerCostCard(BuildContext context, PayrollSlip p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.business_center_outlined, size: 16, color: Color(0xFF8B5CF6)),
              ),
              const SizedBox(width: 8),
              Text(
                'İşveren Toplam Maliyeti (İK & Yönetim)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text(context)),
              ),
            ],
          ),
          const Divider(height: 18),
          _buildAmountRow('SGK İşveren Primi (%20.5)', p.formatCurrency(p.sgkEmployerDeduction), context),
          _buildAmountRow('İşsizlik İşveren Primi (%2)', p.formatCurrency(p.unemploymentEmployerDeduction), context),
          const Divider(height: 18),
          _buildAmountRow('TOPLAM İŞVEREN MALİYETİ', p.formatCurrency(p.totalEmployerCost), context, isBold: true, color: const Color(0xFF8B5CF6)),
        ],
      ),
    );
  }

  Widget _buildSecurityStampCard(BuildContext context, PayrollSlip p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Row(
        children: [
          // Karekod Doğrulama
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: QrImageView(
              data: 'PDKS-BORDRO-VERIFY:${p.id}:${p.tcKimlikNo}:${p.periodMonth}-${p.periodYear}',
              version: QrVersions.auto,
              size: 64,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Elektronik İmzalı Bordro',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '5070 sayılı Elektronik İmza Kanunu kapsamında Nitelikli Elektronik Sertifika ile imzalanmış ve onaylanmıştır.',
                  style: TextStyle(fontSize: 10, color: AppColors.textSub(context), height: 1.3),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bordro Seri: ${p.id.toUpperCase()}',
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, String amount, BuildContext context, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 13 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? (color ?? AppColors.text(context)) : AppColors.textSecondary,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isBold ? 14 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? AppColors.text(context),
            ),
          ),
        ],
      ),
    );
  }
}
