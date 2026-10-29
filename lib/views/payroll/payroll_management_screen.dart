import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/platform_file_helper.dart';
import '../../models/payroll_slip.dart';
import '../../state/pdks_state.dart';
import 'payroll_detail_screen.dart';
import '../common/admin_edit_mode_bar.dart';
import '../../models/page_customization.dart';

class PayrollManagementScreen extends StatefulWidget {
  const PayrollManagementScreen({super.key});

  @override
  State<PayrollManagementScreen> createState() => _PayrollManagementScreenState();
}

class _PayrollManagementScreenState extends State<PayrollManagementScreen> {
  int _selectedMonth = 10;
  final int _selectedYear = 2026;
  String _searchQuery = '';
  String _selectedDepartment = 'Tümü';
  bool _isExporting = false;

  final List<Map<String, dynamic>> _months = [
    {'month': 10, 'year': 2026, 'name': 'Ekim 2026'},
    {'month': 9, 'year': 2026, 'name': 'Eylül 2026'},
    {'month': 8, 'year': 2026, 'name': 'Ağustos 2026'},
  ];

  Future<void> _exportPayrollSummaryExcel() async {
    setState(() => _isExporting = true);
    final pdks = context.read<PdksState>();

    final filteredPayrolls = pdks.payrolls.where(
      (p) => p.periodMonth == _selectedMonth && p.periodYear == _selectedYear,
    ).toList();

    final buffer = StringBuffer();
    buffer.write('\uFEFF'); // UTF-8 BOM
    buffer.writeln('${pdks.activeCompany.name.toUpperCase()} - PERSONEL AYLIK BORDRO VE MALİYET İCMALİ');
    buffer.writeln('Dönem: $_selectedMonth/$_selectedYear;Oluşturulma: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())};Bordro Adedi: ${filteredPayrolls.length}');
    buffer.writeln('');
    buffer.writeln('Sıra;Sicil No;Personel Adı Soyadı;Departman;Unvan;Temel Brüt (TL);Fazla Mesai (TL);Yol/Yemek (TL);Brüt Toplam (TL);SGK İşçi (TL);Vergi Kesintisi (TL);Toplam Kesinti (TL);Net Ödenen (TL);İşveren SGK (TL);Toplam Şirket Maliyeti (TL);Durum');

    for (int i = 0; i < filteredPayrolls.length; i++) {
      final p = filteredPayrolls[i];
      buffer.writeln(
        '${i + 1};${p.sicilNo};"${p.employeeName}";"${p.department}";"${p.employeeTitle}";${p.baseGrossSalary.toStringAsFixed(2)};${p.overtimePay.toStringAsFixed(2)};${(p.mealAllowance + p.travelAllowance).toStringAsFixed(2)};${p.totalEarnings.toStringAsFixed(2)};${p.sgkEmployeeDeduction.toStringAsFixed(2)};${(p.incomeTax + p.stampTax - p.taxExemption).toStringAsFixed(2)};${p.totalDeductions.toStringAsFixed(2)};${p.netSalary.toStringAsFixed(2)};${p.sgkEmployerDeduction.toStringAsFixed(2)};${p.totalEmployerCost.toStringAsFixed(2)};${p.status.label}',
      );
    }

    final fileName = 'Bordro_Icmal_${_selectedYear}_${_selectedMonth.toString().padLeft(2, '0')}.csv';
    final content = buffer.toString();

    await PlatformFileHelper.saveAndOpen(
      fileName: fileName,
      content: content,
      mimeType: 'text/csv;charset=utf-8',
    );

    if (!mounted) return;
    setState(() => _isExporting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        content: Text('$fileName başarıyla dışa aktarıldı.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

    // Aktif ayın bordroları
    final monthPayrolls = pdks.payrolls.where(
      (p) => p.periodMonth == _selectedMonth && p.periodYear == _selectedYear,
    ).toList();

    // Filtreleme (arama & departman)
    final filteredList = monthPayrolls.where((p) {
      final matchesSearch = p.employeeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.department.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.employeeTitle.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesDept = _selectedDepartment == 'Tümü' || p.department == _selectedDepartment;
      return matchesSearch && matchesDept;
    }).toList();

    // Departman listesi
    final departments = ['Tümü', ...{...monthPayrolls.map((p) => p.department)}];

    // Finansal toplamlar
    double totalGross = 0;
    double totalNet = 0;
    double totalDeductions = 0;
    double totalEmployerCost = 0;

    for (final p in monthPayrolls) {
      totalGross += p.totalEarnings;
      totalNet += p.netSalary;
      totalDeductions += p.totalDeductions;
      totalEmployerCost += p.totalEmployerCost;
    }

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bordro & Maaş Yönetimi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${pdks.activeCompany.name} • Kurumsal Bordro Sistemi', style: TextStyle(fontSize: 11, color: AppColors.textSub(context))),
          ],
        ),
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.table_view_outlined),
            tooltip: 'Excel / CSV İcmal İndir',
            onPressed: _isExporting ? null : _exportPayrollSummaryExcel,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sadece Admin Rolünde Gözüken Canlı Düzenleme Çubuğu
            const AdminEditModeBar(
              pageId: 'payroll_management',
              pageTitle: 'Bordro & Maaş Yönetimi',
              editableSections: [
                PageSectionItem(id: 'period_selector', title: 'Dönem Seçici Kartı'),
                PageSectionItem(id: 'kpi_cards', title: 'Finansal KPI Özet Kartları'),
                PageSectionItem(id: 'actions_bar', title: 'Hızlı Bordro Butonları'),
              ],
            ),

            // Üst Dönem Seçici ve Şirket Rozeti
            AdminEditableSection(
              pageId: 'payroll_management',
              sectionId: 'period_selector',
              sectionTitle: 'Dönem Seçici Kartı',
              child: _buildPeriodSelector(context),
            ),
            const SizedBox(height: 14),

            // Finansal KPI Kartları (Brüt, Net, Kesintiler, Şirket Maliyeti)
            AdminEditableSection(
              pageId: 'payroll_management',
              sectionId: 'kpi_cards',
              sectionTitle: 'Finansal KPI Özet Kartları',
              child: _buildFinancialSummaryCards(context, totalGross, totalNet, totalDeductions, totalEmployerCost, currency),
            ),
            const SizedBox(height: 14),

            // Hızlı İşlem Butonları (Hesapla, Onayla, Öde)
            AdminEditableSection(
              pageId: 'payroll_management',
              sectionId: 'actions_bar',
              sectionTitle: 'Hızlı Bordro Butonları',
              child: _buildActionButtons(context, pdks),
            ),
            const SizedBox(height: 16),

            // Arama & Departman Filtre Çubuğu
            _buildFilterBar(context, departments),
            const SizedBox(height: 14),

            // Personel Bordro Listesi Başlığı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PERSONEL BORDROLARI (${filteredList.length})',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  'Toplam Personel: ${monthPayrolls.length}',
                  style: TextStyle(fontSize: 11, color: AppColors.textSub(context)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Bordro Listesi
            if (filteredList.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.cardBg(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.cardBorder(context)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      'Bu döneme veya kritere ait bordro bulunamadı',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.autorenew_rounded, size: 18),
                      label: const Text('Bu Ay İçin Bordroları Hesapla'),
                      onPressed: () {
                        pdks.recalculateCompanyPayroll(_selectedMonth, _selectedYear);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              )
            else
              ...filteredList.map((p) => _buildPayrollCard(context, p, pdks)),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.date_range_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Bordro Dönemi:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text(context)),
              ),
            ],
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedMonth,
              borderRadius: BorderRadius.circular(14),
              dropdownColor: AppColors.cardBg(context),
              items: _months.map((m) {
                return DropdownMenuItem<int>(
                  value: m['month'] as int,
                  child: Text(
                    m['name'] as String,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedMonth = val);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummaryCards(
    BuildContext context,
    double totalGross,
    double totalNet,
    double totalDeductions,
    double totalEmployerCost,
    NumberFormat currency,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'Toplam Net Maaş',
                value: currency.format(totalNet),
                subtitle: 'Ödenecek net havuz',
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'Toplam Brüt Bütçe',
                value: currency.format(totalGross),
                subtitle: 'Temel + Mesai + Prim',
                icon: Icons.payments_outlined,
                color: const Color(0xFF2563EB),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'Yasal Kesintiler',
                value: currency.format(totalDeductions),
                subtitle: 'SGK & Gelir Vergisi',
                icon: Icons.account_tree_outlined,
                color: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'Toplam Şirket Maliyeti',
                value: currency.format(totalEmployerCost),
                subtitle: 'İşveren Payları Dahil',
                icon: Icons.business_outlined,
                color: const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 10, color: AppColors.textSub(context))),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, PdksState pdks) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.autorenew_rounded, size: 16),
            label: const Text('Bordro Hesapla', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () {
              pdks.recalculateCompanyPayroll(_selectedMonth, _selectedYear);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  content: Text('$_selectedMonth/$_selectedYear dönemi için tüm bordrolar yeniden hesaplandı.'),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 11),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.verified_outlined, size: 16),
            label: const Text('Toplu Onayla', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () {
              pdks.bulkApprovePayrolls(_selectedMonth, _selectedYear);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF0284C7),
                  behavior: SnackBarBehavior.floating,
                  content: Text('Tüm bordrolar toplu olarak onaylandı.'),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 11),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.check_circle_outline, size: 16),
            label: const Text('Toplu Öde', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () {
              pdks.bulkPayPayrolls(_selectedMonth, _selectedYear);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  content: Text('Tüm bordrolar "Ödendi" olarak güncellendi.'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context, List<String> departments) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Personel veya unvan ara...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              filled: true,
              fillColor: AppColors.cardBg(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.cardBorder(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.cardBorder(context)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder(context)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDepartment,
                isExpanded: true,
                dropdownColor: AppColors.cardBg(context),
                items: departments.map((d) {
                  return DropdownMenuItem<String>(
                    value: d,
                    child: Text(
                      d,
                      style: TextStyle(fontSize: 12, color: AppColors.text(context)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedDepartment = val);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPayrollCard(BuildContext context, PayrollSlip p, PdksState pdks) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PayrollDetailScreen(payroll: p)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          p.employeeName.isNotEmpty ? p.employeeName.substring(0, 2).toUpperCase() : 'P',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.employeeName,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${p.department} • ${p.employeeTitle}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: p.status.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        p.status.label,
                        style: TextStyle(color: p.status.color, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCol('Brüt Kazanç', p.formatCurrency(p.totalEarnings)),
                    _buildStatCol('Kesintiler', p.formatCurrency(p.totalDeductions)),
                    _buildStatCol('Net Maaş', p.formatCurrency(p.netSalary), isHighlight: true),
                    _buildStatCol('İşveren Mal.', p.formatCurrency(p.totalEmployerCost)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCol(String label, String value, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isHighlight ? const Color(0xFF10B981) : null,
          ),
        ),
      ],
    );
  }
}
