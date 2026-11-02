import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/employee.dart';
import '../../models/employee_movement.dart';
import '../../state/pdks_state.dart';
import '../../core/utils/movement_calculation_engine.dart';
import '../../core/utils/csv_download_helper.dart';

/// PDKS Çalışan Hareket Yönetimi Ana Ekranı
/// Tasarım Sistemi: Açık zemin (#F8FAFC), Koyu Lacivert sol menü (#0F172A), Turkuaz vurgu (#0D9488).
class EmployeeMovementManagementScreen extends StatefulWidget {
  final int initialTabIndex;
  final bool isEmbedded;
  final VoidCallback? onBackToPortal;

  const EmployeeMovementManagementScreen({
    super.key,
    this.initialTabIndex = 0,
    this.isEmbedded = false,
    this.onBackToPortal,
  });

  @override
  State<EmployeeMovementManagementScreen> createState() =>
      _EmployeeMovementManagementScreenState();
}

class _EmployeeMovementManagementScreenState
    extends State<EmployeeMovementManagementScreen> {
  // Tasarım Renk Paleti (Açık Zemin, Koyu Lacivert Menü, Turkuaz Vurgu)
  static const Color kBgLight = Color(0xFFF8FAFC);
  static const Color kNavySidebar = Color(0xFF0F172A);
  static const Color kNavySecondary = Color(0xFF1E293B);
  static const Color kTurquoise = Color(0xFF0D9488);
  static const Color kTurquoiseLight = Color(0xFFCCFBF1);
  static const Color kBorderColor = Color(0xFFE2E8F0);
  static const Color kTextPrimary = Color(0xFF0F172A);
  static const Color kTextSecondary = Color(0xFF475569);

  late int _selectedTab;
  late DateTime _selectedDate;

  // Çalışan Hareketleri Sekmesi Filtre ve Tablo Durumu
  final TextEditingController _movSearchCtrl = TextEditingController();
  DateTime? _movFilterStartDate;
  DateTime? _movFilterEndDate;
  String _movFilterDepartment = 'Tümü';
  int? _movFilterEmployeeId;
  MovementType? _movFilterType;
  String _movSortField = 'timestamp';
  bool _movSortAscending = false;
  int _movCurrentPage = 1;
  int _movPageSize = 10;

  // Yan Panel (Side Drawer) Durumları
  EmployeeMovementRecord? _selectedMovementForDetail;
  Employee? _selectedEmployeeForDetail;

  // Personeller Sekmesi Arama & Filtre
  final TextEditingController _empSearchCtrl = TextEditingController();
  String _empFilterDepartment = 'Tümü';
  String _empFilterActive = 'Tümü';

  // Günlük Devam Özeti Filtreleri
  final TextEditingController _sumSearchCtrl = TextEditingController();
  DailyAttendanceStatus? _sumFilterStatus;
  bool _sumOnlyLate = false;
  String _sumFilterDepartment = 'Tümü';

  // Kontrol Bekleyenler Filtresi
  AnomalyCategory? _anomFilterCategory;
  bool _showResolvedAnomalies = false;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _movSearchCtrl.dispose();
    _empSearchCtrl.dispose();
    _sumSearchCtrl.dispose();
    super.dispose();
  }

  void _showFeedbackSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFFEF4444) : kTurquoise,
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 960;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kTurquoise,
          primary: kTurquoise,
          surface: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kBorderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kBorderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kTurquoise, width: 2),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: kBgLight,
        drawer: isDesktop
            ? null
            : Drawer(
                backgroundColor: kNavySidebar,
                child: SafeArea(child: _buildSidebarMenu(pdks, isInDrawer: true)),
              ),
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isDesktop)
                SizedBox(
                  width: 260,
                  child: _buildSidebarMenu(pdks, isInDrawer: false),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopToolbar(context, pdks, isDesktop: isDesktop),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildActiveScreenContent(context, pdks),
                          ),
                          if (_selectedMovementForDetail != null && _selectedTab == 1)
                            _buildMovementDetailSidePanel(
                              context,
                              pdks,
                              _selectedMovementForDetail!,
                            ),
                          if (_selectedEmployeeForDetail != null && _selectedTab == 2)
                            _buildEmployeeDetailSidePanel(
                              context,
                              pdks,
                              _selectedEmployeeForDetail!,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SOL MENÜ (KOYU LACİVERT MENÜ & TURKUAZ VURGU)
  // ===========================================================================
  Widget _buildSidebarMenu(PdksState pdks, {required bool isInDrawer}) {
    final anomalies = pdks
        .getAnomaliesForDate(_selectedDate)
        .where((a) => a.approvalStatus == CorrectionApprovalStatus.pending)
        .toList();

    final navItems = [
      (index: 0, icon: Icons.dashboard_rounded, label: 'Genel Bakış', badge: null),
      (index: 1, icon: Icons.swap_vert_circle_rounded, label: 'Çalışan Hareketleri', badge: null),
      (index: 2, icon: Icons.badge_rounded, label: 'Personeller', badge: '${pdks.employees.length}'),
      (index: 3, icon: Icons.fact_check_rounded, label: 'Günlük Devam Özeti', badge: null),
      (index: 4, icon: Icons.schedule_rounded, label: 'Vardiyalar', badge: '${pdks.pdksShiftDefinitions.length}'),
      (
        index: 5,
        icon: Icons.warning_amber_rounded,
        label: 'Kontrol Bekleyenler',
        badge: anomalies.isNotEmpty ? '${anomalies.length}' : null,
      ),
    ];

    return Container(
      color: kNavySidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kTurquoise,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.fingerprint_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PDKS Yönetim',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Çalışan Hareket Sistemi',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final item in navItems)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          setState(() {
                            _selectedTab = item.index;
                            _selectedMovementForDetail = null;
                            _selectedEmployeeForDetail = null;
                          });
                          if (isInDrawer && Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedTab == item.index
                                ? kTurquoise
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 20,
                                color: _selectedTab == item.index
                                    ? Colors.white
                                    : const Color(0xFFCBD5E1),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    color: _selectedTab == item.index
                                        ? Colors.white
                                        : const Color(0xFFE2E8F0),
                                    fontWeight: _selectedTab == item.index
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                              if (item.badge != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: item.index == 5
                                        ? const Color(0xFFEF4444)
                                        : Colors.white.withOpacity(0.16),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    item.badge!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Demo Modu & Saat Dilimi Bilgi Kartı
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kNavySecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kTurquoise.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF2DD4BF), size: 16),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Demo Modu Aktif',
                        style: TextStyle(
                          color: Color(0xFF2DD4BF),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Veriler yerel depoda (localStorage) kalıcı saklanır. Gerçek turnike cihazı bağlantısı yoktur.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, height: 1.35),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Saat Dilimi: Europe/Istanbul',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.onBackToPortal != null || Navigator.canPop(context)) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(Icons.arrow_back_rounded, size: 15),
                      label: const Text('Ana Portala Dön', style: TextStyle(fontSize: 11.5)),
                      onPressed: () {
                        if (widget.onBackToPortal != null) {
                          widget.onBackToPortal!();
                        } else if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ÜST ARAÇ ÇUBUĞU (TOP TOOLBAR)
  // ===========================================================================
  Widget _buildTopToolbar(BuildContext context, PdksState pdks, {required bool isDesktop}) {
    final titles = [
      'Genel Bakış',
      'Çalışan Hareketleri',
      'Personeller',
      'Günlük Devam Özeti',
      'Vardiyalar',
      'Kontrol Bekleyenler',
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 12, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: kBorderColor)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isDesktop)
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu_rounded, color: kTextPrimary),
                    tooltip: 'Menüyü Aç',
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titles[_selectedTab],
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
                  ),
                  Text(
                    'Seçili Gün: ${MovementCalculationEngine.formatDate(_selectedDate)} • Saat Dilimi: $kDefaultTimezone',
                    style: const TextStyle(fontSize: 12, color: kTextSecondary),
                  ),
                ],
              ),
            ],
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              // Demo Modu Rozeti
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.science_outlined, size: 15, color: Color(0xFFB45309)),
                    SizedBox(width: 5),
                    Text(
                      'Demo Modu (Yerel Depolama)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),

              // Tarih Seçici (gg.aa.yyyy)
              Container(
                decoration: BoxDecoration(
                  color: kBgLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kBorderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      tooltip: 'Önceki Gün',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                        });
                      },
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2024, 1, 1),
                          lastDate: DateTime(2030, 12, 31),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = DateTime(picked.year, picked.month, picked.day);
                          });
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 15, color: kTurquoise),
                            const SizedBox(width: 6),
                            Text(
                              MovementCalculationEngine.formatDate(_selectedDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: kTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                      tooltip: 'Sonraki Gün',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.add(const Duration(days: 1));
                        });
                      },
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: kTurquoise,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () {
                        final now = DateTime.now();
                        setState(() {
                          _selectedDate = DateTime(now.year, now.month, now.day);
                        });
                      },
                      child: const Text('Bugün', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              // Yeni Hareket Ekle Butonu
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kTurquoise,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'Yeni Hareket Ekle',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () => _showMovementFormDialog(context, pdks),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveScreenContent(BuildContext context, PdksState pdks) {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewScreen(context, pdks);
      case 1:
        return _buildMovementsScreen(context, pdks);
      case 2:
        return _buildEmployeesScreen(context, pdks);
      case 3:
        return _buildDailySummaryScreen(context, pdks);
      case 4:
        return _buildShiftsScreen(context, pdks);
      case 5:
        return _buildPendingReviewScreen(context, pdks);
      default:
        return _buildOverviewScreen(context, pdks);
    }
  }

  // ===========================================================================
  // 1. EKRAN: GENEL BAKIŞ
  // ===========================================================================
  Widget _buildOverviewScreen(BuildContext context, PdksState pdks) {
    final summaries = pdks.getDailySummariesForDate(_selectedDate);
    final totalEmployees = summaries.length;
    final insideCount =
        summaries.where((s) => s.status == DailyAttendanceStatus.working).length;
    final onBreakCount =
        summaries.where((s) => s.status == DailyAttendanceStatus.onBreak).length;
    final lateCount = summaries.where((s) => s.isLate).length;
    final missingCount =
        summaries.where((s) => s.status == DailyAttendanceStatus.missingMovement).length;

    // Seçili güne ait son hareketler
    final dayMovements = <EmployeeMovementRecord>[];
    for (final s in summaries) {
      dayMovements.addAll(s.dayMovements);
    }
    dayMovements.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Seçili güne ait kontrol bekleyen kayıtlar
    final pendingAnomalies = pdks
        .getAnomaliesForDate(_selectedDate)
        .where((a) => a.approvalStatus == CorrectionApprovalStatus.pending)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 5 Dinamik Gösterge Kartı (Tıklanınca ilgili filtrelenmiş liste açılır)
          LayoutBuilder(
            builder: (ctx, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final cardWidth = isWide
                  ? (constraints.maxWidth - 48) / 5
                  : (constraints.maxWidth >= 520
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth);

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildOverviewKpiCard(
                    width: cardWidth,
                    title: 'Toplam Personel',
                    count: totalEmployees,
                    subtitle: 'Personel listesini aç',
                    icon: Icons.groups_rounded,
                    color: const Color(0xFF0F172A),
                    onTap: () {
                      setState(() {
                        _selectedTab = 2;
                        _empFilterActive = 'Tümü';
                      });
                    },
                  ),
                  _buildOverviewKpiCard(
                    width: cardWidth,
                    title: 'İçeride',
                    count: insideCount,
                    subtitle: 'Aktif çalışanları filtrele',
                    icon: Icons.work_history_rounded,
                    color: kTurquoise,
                    onTap: () {
                      setState(() {
                        _selectedTab = 3;
                        _sumFilterStatus = DailyAttendanceStatus.working;
                        _sumOnlyLate = false;
                      });
                    },
                  ),
                  _buildOverviewKpiCard(
                    width: cardWidth,
                    title: 'Molada',
                    count: onBreakCount,
                    subtitle: 'Moladaki personelleri gör',
                    icon: Icons.coffee_rounded,
                    color: const Color(0xFFD97706),
                    onTap: () {
                      setState(() {
                        _selectedTab = 3;
                        _sumFilterStatus = DailyAttendanceStatus.onBreak;
                        _sumOnlyLate = false;
                      });
                    },
                  ),
                  _buildOverviewKpiCard(
                    width: cardWidth,
                    title: 'Geç Kalan',
                    count: lateCount,
                    subtitle: 'Toleransı aşan girişler',
                    icon: Icons.schedule_send_rounded,
                    color: const Color(0xFFEA580C),
                    onTap: () {
                      setState(() {
                        _selectedTab = 3;
                        _sumFilterStatus = null;
                        _sumOnlyLate = true;
                      });
                    },
                  ),
                  _buildOverviewKpiCard(
                    width: cardWidth,
                    title: 'Eksik Hareket',
                    count: missingCount,
                    subtitle: 'Kontrol bekleyenleri aç',
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFEF4444),
                    onTap: () {
                      setState(() {
                        _selectedTab = 5;
                        _anomFilterCategory = null;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Alt İki Sütun: Günün Son Hareketleri & Kontrol Bekleyen Kayıtlar
          LayoutBuilder(
            builder: (ctx, constraints) {
              final isTwoCol = constraints.maxWidth >= 880;
              final leftPanel = _buildOverviewRecentMovementsCard(dayMovements);
              final rightPanel = _buildOverviewPendingRecordsCard(pdks, pendingAnomalies);

              if (isTwoCol) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: leftPanel),
                    const SizedBox(width: 16),
                    Expanded(flex: 5, child: rightPanel),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  leftPanel,
                  const SizedBox(height: 16),
                  rightPanel,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewKpiCard({
    required double width,
    required String title,
    required int count,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    Icon(Icons.arrow_forward_rounded, size: 16, color: color),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: kTextSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewRecentMovementsCard(List<EmployeeMovementRecord> dayMovements) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, color: kTurquoise, size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Günün Son Hareketleri',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: kTurquoise),
                icon: const Icon(Icons.open_in_new_rounded, size: 15),
                label: const Text('Tüm Hareketler', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                onPressed: () {
                  setState(() {
                    _selectedTab = 1;
                  });
                },
              ),
            ],
          ),
          const Divider(color: kBorderColor, height: 20),
          if (dayMovements.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  'Seçili tarihte henüz kayıtlı hareket bulunmuyor.',
                  style: TextStyle(color: kTextSecondary, fontSize: 13),
                ),
              ),
            )
          else
            ...dayMovements.take(8).map((mov) {
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() {
                    _selectedTab = 1;
                    _selectedMovementForDetail = mov;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: mov.type.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          MovementCalculationEngine.formatTime(mov.timestamp),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: mov.type.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${mov.employeeName} (${mov.sicilNo})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: kTextPrimary,
                              ),
                            ),
                            Text(
                              '${mov.department} • ${mov.deviceDoor}',
                              style: const TextStyle(fontSize: 11.5, color: kTextSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(mov.type.label, mov.type.color),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildOverviewPendingRecordsCard(
    PdksState pdks,
    List<MovementAnomalyItem> pendingAnomalies,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C), size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Kontrol Bekleyen Kayıtlar (${pendingAnomalies.length})',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: kTurquoise),
                onPressed: () => setState(() => _selectedTab = 5),
                child: const Text('Tümünü İncele', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(color: kBorderColor, height: 20),
          if (pendingAnomalies.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  'Seçili tarihte kontrol bekleyen eksik veya hatalı kayıt yok.',
                  style: TextStyle(color: kTextSecondary, fontSize: 13),
                ),
              ),
            )
          else
            ...pendingAnomalies.take(5).map((anom) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: anom.category.color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: anom.category.color.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${anom.employeeName} (${anom.sicilNo})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: kTextPrimary,
                            ),
                          ),
                        ),
                        _buildStatusBadge(anom.category.label, anom.category.color),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      anom.description,
                      style: const TextStyle(fontSize: 11.5, color: kTextSecondary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF10B981),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Onayla', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            final res = await pdks.approveAnomalyOrCorrection(anom);
                            _showFeedbackSnackBar(res.message, isError: !res.success);
                          },
                        ),
                        const SizedBox(width: 6),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Reddet', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () => _showRejectAnomalyDialog(context, pdks, anom),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. EKRAN: ÇALIŞAN HAREKETLERİ
  // ===========================================================================
  List<EmployeeMovementRecord> _getFilteredAndSortedMovements(PdksState pdks) {
    final query = _movSearchCtrl.text.trim().toLowerCase();
    final all = pdks.employeeMovements;

    final filtered = all.where((m) {
      if (query.isNotEmpty) {
        final matchName = m.employeeName.toLowerCase().contains(query);
        final matchSicil = m.sicilNo.toLowerCase().contains(query);
        if (!matchName && !matchSicil) return false;
      }
      if (_movFilterDepartment != 'Tümü' && m.department != _movFilterDepartment) {
        return false;
      }
      if (_movFilterEmployeeId != null && m.employeeId != _movFilterEmployeeId) {
        return false;
      }
      if (_movFilterType != null && m.type != _movFilterType) {
        return false;
      }
      if (_movFilterStartDate != null) {
        final start = DateTime(
          _movFilterStartDate!.year,
          _movFilterStartDate!.month,
          _movFilterStartDate!.day,
        );
        if (m.timestamp.isBefore(start)) return false;
      }
      if (_movFilterEndDate != null) {
        final end = DateTime(
          _movFilterEndDate!.year,
          _movFilterEndDate!.month,
          _movFilterEndDate!.day,
          23,
          59,
          59,
        );
        if (m.timestamp.isAfter(end)) return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      int cmp;
      switch (_movSortField) {
        case 'sicilNo':
          cmp = a.sicilNo.compareTo(b.sicilNo);
          break;
        case 'employeeName':
          cmp = a.employeeName.compareTo(b.employeeName);
          break;
        case 'type':
          cmp = a.type.label.compareTo(b.type.label);
          break;
        case 'timestamp':
        default:
          cmp = a.timestamp.compareTo(b.timestamp);
          break;
      }
      return _movSortAscending ? cmp : -cmp;
    });

    return filtered;
  }

  Widget _buildMovementsScreen(BuildContext context, PdksState pdks) {
    final departments = <String>{
      'Tümü',
      ...pdks.employees.map((e) => e.department),
    }.toList();

    final filtered = _getFilteredAndSortedMovements(pdks);
    final totalPages = (filtered.length / _movPageSize).ceil().clamp(1, 9999);
    final safePage = _movCurrentPage.clamp(1, totalPages);
    final startIndex = (safePage - 1) * _movPageSize;
    final pageItems = filtered.skip(startIndex).take(_movPageSize).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filtre Araç Çubuğu
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Ad, soyad veya sicil numarası ile arama
                    SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _movSearchCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Ad, Soyad veya Sicil No Ara',
                          prefixIcon: Icon(Icons.search_rounded, size: 18),
                        ),
                        onChanged: (_) => setState(() => _movCurrentPage = 1),
                      ),
                    ),

                    // Departman Filtresi
                    SizedBox(
                      width: 190,
                      child: DropdownButtonFormField<String>(
                        value: departments.contains(_movFilterDepartment)
                            ? _movFilterDepartment
                            : 'Tümü',
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Departman'),
                        items: departments
                            .map((d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(d, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _movFilterDepartment = val ?? 'Tümü';
                            _movCurrentPage = 1;
                          });
                        },
                      ),
                    ),

                    // Personel Filtresi
                    SizedBox(
                      width: 210,
                      child: DropdownButtonFormField<int?>(
                        value: _movFilterEmployeeId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Personel'),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Tüm Personeller', style: TextStyle(fontSize: 13)),
                          ),
                          ...pdks.employees.map(
                            (e) => DropdownMenuItem<int?>(
                              value: e.id,
                              child: Text(
                                '${e.fullName} (${e.displaySicilNo})',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _movFilterEmployeeId = val;
                            _movCurrentPage = 1;
                          });
                        },
                      ),
                    ),

                    // Hareket Türü Filtresi
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<MovementType?>(
                        value: _movFilterType,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Hareket Türü'),
                        items: [
                          const DropdownMenuItem<MovementType?>(
                            value: null,
                            child: Text('Tüm Türler', style: TextStyle(fontSize: 13)),
                          ),
                          ...MovementType.values.map(
                            (t) => DropdownMenuItem<MovementType?>(
                              value: t,
                              child: Text(t.label, style: const TextStyle(fontSize: 13)),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _movFilterType = val;
                            _movCurrentPage = 1;
                          });
                        },
                      ),
                    ),

                    // Tarih Aralığı Seçici
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kTextPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.date_range_rounded, size: 17, color: kTurquoise),
                      label: Text(
                        _movFilterStartDate != null && _movFilterEndDate != null
                            ? '${MovementCalculationEngine.formatDate(_movFilterStartDate!)} - ${MovementCalculationEngine.formatDate(_movFilterEndDate!)}'
                            : 'Tarih Aralığı Seç',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () async {
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2024, 1, 1),
                          lastDate: DateTime(2030, 12, 31),
                          initialDateRange: _movFilterStartDate != null && _movFilterEndDate != null
                              ? DateTimeRange(start: _movFilterStartDate!, end: _movFilterEndDate!)
                              : null,
                        );
                        if (range != null) {
                          setState(() {
                            _movFilterStartDate = range.start;
                            _movFilterEndDate = range.end;
                            _movCurrentPage = 1;
                          });
                        }
                      },
                    ),

                    // Filtreleri Temizle
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
                      icon: const Icon(Icons.filter_alt_off_rounded, size: 17),
                      label: const Text('Filtreleri Temizle', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        setState(() {
                          _movSearchCtrl.clear();
                          _movFilterStartDate = null;
                          _movFilterEndDate = null;
                          _movFilterDepartment = 'Tümü';
                          _movFilterEmployeeId = null;
                          _movFilterType = null;
                          _movCurrentPage = 1;
                        });
                      },
                    ),

                    // CSV Olarak İndir
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kNavySidebar,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 17),
                      label: Text(
                        'CSV İndir (${filtered.length})',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        final csvContent = MovementCalculationEngine.generateMovementsCsv(filtered);
                        final fileName =
                            'calisan_hareketleri_${MovementCalculationEngine.formatDate(_selectedDate).replaceAll('.', '_')}.csv';
                        await downloadCsvFile(fileName, csvContent);
                        _showFeedbackSnackBar(
                          '${filtered.length} kayıt Türkçe karakterler korunarak CSV ($fileName) olarak dışa aktarıldı.',
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tablo Kartı
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sıralama ve Kayıt Bilgisi Üst Barı
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Text(
                        'Toplam ${filtered.length} hareket kaydı listeleniyor',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: kTextPrimary,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Sırala: ', style: TextStyle(fontSize: 12, color: kTextSecondary)),
                          DropdownButton<String>(
                            value: _movSortField,
                            underline: const SizedBox.shrink(),
                            style: const TextStyle(fontSize: 12.5, color: kTextPrimary, fontWeight: FontWeight.w600),
                            items: const [
                              DropdownMenuItem(value: 'timestamp', child: Text('Tarih ve Saat')),
                              DropdownMenuItem(value: 'sicilNo', child: Text('Sicil Numarası')),
                              DropdownMenuItem(value: 'employeeName', child: Text('Ad Soyad')),
                              DropdownMenuItem(value: 'type', child: Text('Hareket Türü')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _movSortField = val);
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              _movSortAscending
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 17,
                              color: kTurquoise,
                            ),
                            tooltip: _movSortAscending ? 'Artan Sıralama' : 'Azalan Sıralama',
                            onPressed: () => setState(() => _movSortAscending = !_movSortAscending),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(color: kBorderColor, height: 1),

                if (pageItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        const Icon(Icons.search_off_rounded, size: 42, color: kTextSecondary),
                        const SizedBox(height: 10),
                        const Text(
                          'Seçilen arama ve filtre kriterlerine uygun hareket kaydı bulunamadı.',
                          style: TextStyle(color: kTextSecondary, fontSize: 13.5),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _movSearchCtrl.clear();
                              _movFilterStartDate = null;
                              _movFilterEndDate = null;
                              _movFilterDepartment = 'Tümü';
                              _movFilterEmployeeId = null;
                              _movFilterType = null;
                            });
                          },
                          child: const Text('Filtreleri Sıfırla'),
                        ),
                      ],
                    ),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                      columnSpacing: 18,
                      columns: const [
                        DataColumn(label: Text('Tarih ve Saat', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Sicil Numarası', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Ad Soyad', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Departman', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Vardiya', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Hareket Türü', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Cihaz / Kapı', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Kaynak', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Açıklama', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('İşlemler', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: pageItems.map((mov) {
                        final isSelected = _selectedMovementForDetail?.id == mov.id;
                        return DataRow(
                          selected: isSelected,
                          cells: [
                            DataCell(
                              Text(
                                MovementCalculationEngine.formatDateTime(mov.timestamp),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                              ),
                            ),
                            DataCell(
                              Text(
                                mov.sicilNo,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                mov.employeeName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            DataCell(Text(mov.department, style: const TextStyle(fontSize: 12.5))),
                            DataCell(Text(mov.shiftName, style: const TextStyle(fontSize: 12))),
                            DataCell(_buildStatusBadge(mov.type.label, mov.type.color)),
                            DataCell(Text(mov.deviceDoor, style: const TextStyle(fontSize: 12.5))),
                            DataCell(_buildStatusBadge(mov.source.label, mov.source.color)),
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 210),
                                child: Text(
                                  mov.note.isEmpty ? '-' : mov.note,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: kTextSecondary),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility_outlined, size: 18, color: kTurquoise),
                                    tooltip: 'Yan Panelde Detay Göster',
                                    onPressed: () {
                                      setState(() {
                                        _selectedMovementForDetail = mov;
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFFD97706)),
                                    tooltip: 'Hareketi Düzelt',
                                    onPressed: () => _showMovementFormDialog(
                                      context,
                                      pdks,
                                      existingMovement: mov,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),

                // Sayfalama (Pagination) Alt Çubuğu
                const Divider(color: kBorderColor, height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Sayfa başına: ', style: TextStyle(fontSize: 12, color: kTextSecondary)),
                          DropdownButton<int>(
                            value: _movPageSize,
                            underline: const SizedBox.shrink(),
                            items: const [
                              DropdownMenuItem(value: 10, child: Text('10')),
                              DropdownMenuItem(value: 20, child: Text('20')),
                              DropdownMenuItem(value: 50, child: Text('50')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _movPageSize = val;
                                  _movCurrentPage = 1;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Sayfa $safePage / $totalPages',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded),
                            onPressed: safePage > 1
                                ? () => setState(() => _movCurrentPage = safePage - 1)
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded),
                            onPressed: safePage < totalPages
                                ? () => setState(() => _movCurrentPage = safePage + 1)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Hareket Detayı Yan Paneli (Ham Cihaz Kaydı + Düzeltme İzlenebilirlik Geçmişi)
  Widget _buildMovementDetailSidePanel(
    BuildContext context,
    PdksState pdks,
    EmployeeMovementRecord mov,
  ) {
    return Container(
      width: 360,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: kBorderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: kNavySidebar,
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF2DD4BF), size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Hareket Detayı & İzlenebilirlik',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                  onPressed: () => setState(() => _selectedMovementForDetail = null),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildDetailRow('Personel', '${mov.employeeName} (${mov.sicilNo})'),
                _buildDetailRow('Departman', mov.department),
                _buildDetailRow('Vardiya', mov.shiftName),
                _buildDetailRow('Hareket Türü', mov.type.label),
                _buildDetailRow(
                  'Tarih ve Saat',
                  MovementCalculationEngine.formatDateTime(mov.timestamp),
                ),
                _buildDetailRow('Cihaz / Kapı', mov.deviceDoor),
                _buildDetailRow('Kaynak', mov.source.label),
                _buildDetailRow('Açıklama', mov.note.isEmpty ? '-' : mov.note),
                const SizedBox(height: 16),

                // Ham Cihaz Hareketi Kartı (Düzeltme Sırasında Korunur)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kBorderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.memory_rounded, size: 16, color: kTurquoise),
                          SizedBox(width: 6),
                          Text(
                            'Ham Cihaz Kaydı (Değiştirilemez)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                              color: kTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tür: ${mov.rawDeviceSnapshot.type.label}\n'
                        'Zaman: ${MovementCalculationEngine.formatDateTime(mov.rawDeviceSnapshot.timestamp)}\n'
                        'Cihaz/Kapı: ${mov.rawDeviceSnapshot.deviceDoor}\n'
                        'İlk Kaynak: ${mov.rawDeviceSnapshot.source.label}',
                        style: const TextStyle(fontSize: 12, color: kTextSecondary, height: 1.45),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Düzeltme Geçmişi
                const Text(
                  'Düzeltme Geçmişi',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: kTextPrimary),
                ),
                const SizedBox(height: 8),
                if (mov.correctionHistory.isEmpty)
                  const Text(
                    'Bu hareket kaydı üzerinde manuel düzeltme yapılmamıştır.',
                    style: TextStyle(fontSize: 12, color: kTextSecondary),
                  )
                else
                  ...mov.correctionHistory.map((corr) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: corr.approvalStatus.color.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: corr.approvalStatus.color.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                MovementCalculationEngine.formatDateTime(corr.correctedAt),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              _buildStatusBadge(
                                corr.approvalStatus.label,
                                corr.approvalStatus.color,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Önceki Değer: ${corr.previousValueSummary}',
                            style: const TextStyle(fontSize: 11.5, color: kTextSecondary),
                          ),
                          Text(
                            'Yeni Değer: ${corr.newValueSummary}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: kTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gerekçe: ${corr.reason}',
                            style: const TextStyle(fontSize: 11.5, color: kTextPrimary),
                          ),
                          Text(
                            'İşlemi Yapan: ${corr.actorName}',
                            style: const TextStyle(fontSize: 11, color: kTextSecondary),
                          ),
                          if (corr.rejectionReason != null && corr.rejectionReason!.isNotEmpty)
                            Text(
                              'Red Gerekçesi: ${corr.rejectionReason}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kTurquoise,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: const Text('Bu Hareketi Düzelt'),
                  onPressed: () => _showMovementFormDialog(context, pdks, existingMovement: mov),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: kTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                color: kTextPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. EKRAN: PERSONELLER
  // ===========================================================================
  Widget _buildEmployeesScreen(BuildContext context, PdksState pdks) {
    final query = _empSearchCtrl.text.trim().toLowerCase();
    final departments = <String>{
      'Tümü',
      ...pdks.employees.map((e) => e.department),
    }.toList();

    final filteredEmployees = pdks.employees.where((e) {
      if (query.isNotEmpty) {
        final matchName = e.fullName.toLowerCase().contains(query);
        final matchSicil = e.displaySicilNo.toLowerCase().contains(query);
        if (!matchName && !matchSicil) return false;
      }
      if (_empFilterDepartment != 'Tümü' && e.department != _empFilterDepartment) {
        return false;
      }
      if (_empFilterActive == 'Aktif' && !e.isActive) return false;
      if (_empFilterActive == 'Pasif' && e.isActive) return false;
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Üst Arama & Personel Ekleme Çubuğu
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorderColor),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _empSearchCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Personel Adı veya Sicil No Ara',
                          prefixIcon: Icon(Icons.search_rounded, size: 18),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<String>(
                        value: departments.contains(_empFilterDepartment)
                            ? _empFilterDepartment
                            : 'Tümü',
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Departman'),
                        items: departments
                            .map((d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(d, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => _empFilterDepartment = val ?? 'Tümü'),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: DropdownButtonFormField<String>(
                        value: _empFilterActive,
                        decoration: const InputDecoration(labelText: 'Aktiflik Durumu'),
                        items: const [
                          DropdownMenuItem(value: 'Tümü', child: Text('Tümü', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'Aktif', child: Text('Aktif', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'Pasif', child: Text('Pasif', style: TextStyle(fontSize: 13))),
                        ],
                        onChanged: (val) => setState(() => _empFilterActive = val ?? 'Tümü'),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kTurquoise,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: const Text(
                    'Yeni Personel Ekle',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _showEmployeeFormDialog(context, pdks),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Personeller Tablosu
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorderColor),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                columns: const [
                  DataColumn(label: Text('Sicil Numarası', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Ad Soyad', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Departman', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Unvan', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Vardiya', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Aktiflik Durumu', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('İşlemler', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: filteredEmployees.map((emp) {
                  final shift = pdks.getShiftForEmployee(emp.id);
                  return DataRow(
                    selected: _selectedEmployeeForDetail?.id == emp.id,
                    cells: [
                      DataCell(
                        Text(
                          emp.displaySicilNo,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          emp.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(Text(emp.department)),
                      DataCell(Text(emp.title)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (shift.crossesMidnight)
                              const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(Icons.nights_stay_rounded, size: 15, color: Color(0xFF6366F1)),
                              ),
                            Text(shift.name, style: const TextStyle(fontSize: 12.5)),
                          ],
                        ),
                      ),
                      DataCell(
                        _buildStatusBadge(
                          emp.isActive ? 'Aktif' : 'Pasif',
                          emp.isActive ? const Color(0xFF10B981) : const Color(0xFF64748B),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton.icon(
                              style: TextButton.styleFrom(foregroundColor: kTurquoise),
                              icon: const Icon(Icons.analytics_outlined, size: 17),
                              label: const Text('Detay & Özet', style: TextStyle(fontSize: 12)),
                              onPressed: () {
                                setState(() {
                                  _selectedEmployeeForDetail = emp;
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFFD97706)),
                              tooltip: 'Personeli Düzenle',
                              onPressed: () => _showEmployeeFormDialog(
                                context,
                                pdks,
                                existingEmployee: emp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Personel Detay Yan Paneli (Hareket Geçmişi & Günlük Devam Özeti)
  Widget _buildEmployeeDetailSidePanel(
    BuildContext context,
    PdksState pdks,
    Employee emp,
  ) {
    final shift = pdks.getShiftForEmployee(emp.id);
    final summary = MovementCalculationEngine.calculateDailySummary(
      employee: emp,
      date: _selectedDate,
      shift: shift,
      allMovements: pdks.employeeMovements,
      leaves: pdks.leaves,
      includeFieldDutyInNetWork: pdks.includeFieldDutyInNetWork,
    );
    final empMovements = pdks.employeeMovements
        .where((m) => m.employeeId == emp.id)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Container(
      width: 380,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: kBorderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: kNavySidebar,
            child: Row(
              children: [
                const Icon(Icons.badge_rounded, color: Color(0xFF2DD4BF), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${emp.fullName} (${emp.displaySicilNo})',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                  onPressed: () => setState(() => _selectedEmployeeForDetail = null),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildDetailRow('Departman', emp.department),
                _buildDetailRow('Unvan', emp.title),
                _buildDetailRow('Planlanan Vardiya', shift.name),
                _buildDetailRow('Durum', emp.isActive ? 'Aktif' : 'Pasif'),
                const Divider(height: 24),

                // Seçili Gün Devam Özeti Kartı
                Text(
                  'Günlük Devam Özeti (${MovementCalculationEngine.formatDate(_selectedDate)})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: kTextPrimary),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kBgLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kBorderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Günlük Durum:', style: TextStyle(fontSize: 12, color: kTextSecondary)),
                          _buildStatusBadge(summary.status.label, summary.status.color),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'İlk Giriş',
                        summary.firstCheckIn != null
                            ? MovementCalculationEngine.formatDateTime(summary.firstCheckIn!)
                            : '-',
                      ),
                      _buildDetailRow(
                        'Son Çıkış',
                        summary.lastCheckOut != null
                            ? MovementCalculationEngine.formatDateTime(summary.lastCheckOut!)
                            : '-',
                      ),
                      _buildDetailRow(
                        'Toplam Mola',
                        MovementCalculationEngine.formatDuration(summary.totalBreakDuration),
                      ),
                      _buildDetailRow(
                        'Net Çalışma',
                        MovementCalculationEngine.formatDuration(summary.netWorkDuration),
                      ),
                      _buildDetailRow(
                        'Geç Kalma',
                        MovementCalculationEngine.formatDuration(summary.lateDuration),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  'Personel Hareket Geçmişi (${empMovements.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: kTextPrimary),
                ),
                const SizedBox(height: 8),
                if (empMovements.isEmpty)
                  const Text(
                    'Bu personele ait hareket kaydı bulunmuyor.',
                    style: TextStyle(fontSize: 12, color: kTextSecondary),
                  )
                else
                  ...empMovements.map((m) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kBorderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                MovementCalculationEngine.formatDateTime(m.timestamp),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              Text(
                                '${m.deviceDoor} • ${m.source.label}',
                                style: const TextStyle(fontSize: 11, color: kTextSecondary),
                              ),
                            ],
                          ),
                          _buildStatusBadge(m.type.label, m.type.color),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. EKRAN: GÜNLÜK DEVAM ÖZETİ
  // ===========================================================================
  Widget _buildDailySummaryScreen(BuildContext context, PdksState pdks) {
    final allSummaries = pdks.getDailySummariesForDate(_selectedDate);
    final query = _sumSearchCtrl.text.trim().toLowerCase();
    final departments = <String>{
      'Tümü',
      ...pdks.employees.map((e) => e.department),
    }.toList();

    final filtered = allSummaries.where((s) {
      if (query.isNotEmpty) {
        final matchName = s.employeeName.toLowerCase().contains(query);
        final matchSicil = s.sicilNo.toLowerCase().contains(query);
        if (!matchName && !matchSicil) return false;
      }
      if (_sumFilterDepartment != 'Tümü' && s.department != _sumFilterDepartment) {
        return false;
      }
      if (_sumFilterStatus != null && s.status != _sumFilterStatus) {
        return false;
      }
      if (_sumOnlyLate && !s.isLate) {
        return false;
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filtre ve Görev Süresi Hesaplama Kuralı Ayarı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 240,
                      child: TextField(
                        controller: _sumSearchCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Personel veya Sicil Ara',
                          prefixIcon: Icon(Icons.search_rounded, size: 18),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    SizedBox(
                      width: 190,
                      child: DropdownButtonFormField<DailyAttendanceStatus?>(
                        value: _sumFilterStatus,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Durum Filtresi'),
                        items: [
                          const DropdownMenuItem<DailyAttendanceStatus?>(
                            value: null,
                            child: Text('Tüm Durumlar', style: TextStyle(fontSize: 13)),
                          ),
                          ...DailyAttendanceStatus.values.map(
                            (st) => DropdownMenuItem<DailyAttendanceStatus?>(
                              value: st,
                              child: Text(st.label, style: const TextStyle(fontSize: 13)),
                            ),
                          ),
                        ],
                        onChanged: (val) => setState(() => _sumFilterStatus = val),
                      ),
                    ),
                    SizedBox(
                      width: 190,
                      child: DropdownButtonFormField<String>(
                        value: departments.contains(_sumFilterDepartment)
                            ? _sumFilterDepartment
                            : 'Tümü',
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Departman'),
                        items: departments
                            .map((d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(d, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => _sumFilterDepartment = val ?? 'Tümü'),
                      ),
                    ),
                    FilterChip(
                      selected: _sumOnlyLate,
                      selectedColor: const Color(0xFFFEF3C7),
                      checkmarkColor: const Color(0xFFB45309),
                      label: const Text('Sadece Geç Kalanlar'),
                      onSelected: (val) => setState(() => _sumOnlyLate = val),
                    ),
                    if (_sumFilterStatus != null || _sumOnlyLate || _sumFilterDepartment != 'Tümü' || _sumSearchCtrl.text.isNotEmpty)
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        label: const Text('Filtreyi Temizle'),
                        onPressed: () {
                          setState(() {
                            _sumSearchCtrl.clear();
                            _sumFilterStatus = null;
                            _sumOnlyLate = false;
                            _sumFilterDepartment = 'Tümü';
                          });
                        },
                      ),
                  ],
                ),
                const Divider(height: 22, color: kBorderColor),
                // Ayarlanabilir Görev Süresi Kuralı
                Row(
                  children: [
                    Switch(
                      value: pdks.includeFieldDutyInNetWork,
                      activeColor: kTurquoise,
                      onChanged: (val) => pdks.setIncludeFieldDutyInNetWork(val),
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Görevde geçen süreyi (Görev çıkışı – Görev dönüşü) net çalışma süresine dahil et',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: kTextPrimary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Günlük Devam Özeti Tablosu
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorderColor),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                columnSpacing: 18,
                columns: const [
                  DataColumn(label: Text('Personel', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Planlanan Vardiya', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('İlk Giriş', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Son Çıkış', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Toplam Mola', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Net Çalışma Süresi', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Geç Kalma', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Erken Çıkış', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('İnceleme Bekleyen Fazla Süre', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Durum', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: filtered.map((s) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              s.employeeName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              '${s.sicilNo} • ${s.department}',
                              style: const TextStyle(fontSize: 11, color: kTextSecondary),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          '${s.plannedShift.name}\n(Tolerans: ${s.plannedShift.lateToleranceMinutes} dk)',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                      ),
                      DataCell(
                        Text(
                          s.firstCheckIn != null
                              ? MovementCalculationEngine.formatDateTime(s.firstCheckIn!)
                              : '-',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(
                        Text(
                          s.lastCheckOut != null
                              ? MovementCalculationEngine.formatDateTime(s.lastCheckOut!)
                              : '-',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(
                        Text(
                          MovementCalculationEngine.formatDuration(s.totalBreakDuration),
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                      DataCell(
                        Text(
                          MovementCalculationEngine.formatDuration(
                            s.netWorkDuration,
                            nullPlaceholder: s.status == DailyAttendanceStatus.missingMovement
                                ? 'İnceleme Bekliyor'
                                : 'Devam Ediyor',
                          ),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: s.netWorkDuration == null
                                ? const Color(0xFFD97706)
                                : kTextPrimary,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          s.lateDuration.inMinutes > 0
                              ? MovementCalculationEngine.formatDuration(s.lateDuration)
                              : '0 dk',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: s.isLate ? FontWeight.bold : FontWeight.normal,
                            color: s.isLate ? const Color(0xFFEF4444) : kTextSecondary,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          s.earlyLeaveDuration.inMinutes > 0
                              ? MovementCalculationEngine.formatDuration(s.earlyLeaveDuration)
                              : '0 dk',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: s.isEarlyLeave ? FontWeight.bold : FontWeight.normal,
                            color: s.isEarlyLeave ? const Color(0xFFEA580C) : kTextSecondary,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          s.pendingExtraDuration.inMinutes > 0
                              ? MovementCalculationEngine.formatDuration(s.pendingExtraDuration)
                              : '0 dk',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: s.pendingExtraDuration.inMinutes > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: s.pendingExtraDuration.inMinutes > 0
                                ? const Color(0xFF7C3AED)
                                : kTextSecondary,
                          ),
                        ),
                      ),
                      DataCell(_buildStatusBadge(s.status.label, s.status.color)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. EKRAN: VARDİYALAR
  // ===========================================================================
  Widget _buildShiftsScreen(BuildContext context, PdksState pdks) {
    final shifts = pdks.pdksShiftDefinitions;
    final shiftMap = pdks.employeeShiftMap;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tanımlı Vardiyalar & Tolerans Kuralları',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextPrimary),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kTurquoise,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Yeni Vardiya Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _showShiftFormDialog(context, pdks),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Vardiya Kartları
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: shifts.map((shift) {
              final assignedEmployees = pdks.employees
                  .where((e) => (shiftMap[e.id] ?? 1) == shift.id)
                  .toList();

              return Container(
                width: 380,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: shift.crossesMidnight
                        ? const Color(0xFF6366F1).withOpacity(0.45)
                        : kBorderColor,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          shift.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: kTextPrimary,
                          ),
                        ),
                        if (shift.crossesMidnight)
                          _buildStatusBadge('Gece Vardiyası', const Color(0xFF6366F1))
                        else
                          _buildStatusBadge('Gündüz Vardiyası', kTurquoise),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.access_time_filled_rounded, color: kTurquoise, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          '${shift.startTime} - ${shift.endTime}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Planlanan Mola', '${shift.plannedBreakMinutes} dakika'),
                    _buildDetailRow('Geç Kalma Toleransı', '${shift.lateToleranceMinutes} dakika'),
                    _buildDetailRow(
                      'Planlanan Net Süre',
                      MovementCalculationEngine.formatDuration(
                        Duration(minutes: shift.plannedNetWorkMinutes),
                      ),
                    ),
                    _buildDetailRow('Atanmış Personel', '${assignedEmployees.length} Kişi'),
                    const Divider(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(foregroundColor: kTurquoise),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Düzenle'),
                          onPressed: () => _showShiftFormDialog(
                            context,
                            pdks,
                            existingShift: shift,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Personele Vardiya Atama Tablosu
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Personele Vardiya Atama',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Personellerin çalışma vardiyasını değiştirdiğinizde günlük devam özetleri ve geç kalma toleransları anında yeniden hesaplanır.',
                  style: TextStyle(fontSize: 12, color: kTextSecondary),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                    columns: const [
                      DataColumn(label: Text('Sicil No', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Ad Soyad', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Departman', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Atanmış Vardiya Seçimi', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: pdks.employees.map((emp) {
                      final currentShift = pdks.getShiftForEmployee(emp.id);
                      return DataRow(
                        cells: [
                          DataCell(Text(emp.displaySicilNo, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(emp.fullName, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(emp.department)),
                          DataCell(
                            DropdownButton<int>(
                              value: currentShift.id,
                              underline: const SizedBox.shrink(),
                              items: shifts
                                  .map(
                                    (s) => DropdownMenuItem<int>(
                                      value: s.id,
                                      child: Text(
                                        '${s.name} (Mola: ${s.plannedBreakMinutes}dk, Tol: ${s.lateToleranceMinutes}dk)',
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (newShiftId) async {
                                if (newShiftId != null) {
                                  final res = await pdks.assignShiftToEmployee(
                                    employeeId: emp.id,
                                    shiftId: newShiftId,
                                  );
                                  _showFeedbackSnackBar(res.message, isError: !res.success);
                                }
                              },
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. EKRAN: KONTROL BEKLEYENLER
  // ===========================================================================
  Widget _buildPendingReviewScreen(BuildContext context, PdksState pdks) {
    final allAnomalies = pdks.getAnomaliesForDate(_selectedDate);
    final filtered = allAnomalies.where((a) {
      if (!_showResolvedAnomalies && a.approvalStatus != CorrectionApprovalStatus.pending) {
        return false;
      }
      if (_anomFilterCategory != null && a.category != _anomFilterCategory) {
        return false;
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kategori Filtre Barı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorderColor),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Tümü'),
                      selected: _anomFilterCategory == null,
                      selectedColor: kTurquoiseLight,
                      onSelected: (_) => setState(() => _anomFilterCategory = null),
                    ),
                    ...AnomalyCategory.values.map((cat) {
                      return ChoiceChip(
                        label: Text(cat.label),
                        selected: _anomFilterCategory == cat,
                        selectedColor: cat.color.withOpacity(0.18),
                        onSelected: (_) => setState(() => _anomFilterCategory = cat),
                      );
                    }),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _showResolvedAnomalies,
                      activeColor: kTurquoise,
                      onChanged: (val) => setState(() => _showResolvedAnomalies = val ?? false),
                    ),
                    const Text(
                      'Onaylanan / Reddedilenleri de Göster',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorderColor),
              ),
              child: const Column(
                children: [
                  Icon(Icons.verified_rounded, size: 44, color: Color(0xFF10B981)),
                  SizedBox(height: 10),
                  Text(
                    'Bu filtrede kontrol bekleyen eksik veya hatalı kayıt bulunmuyor.',
                    style: TextStyle(fontSize: 14, color: kTextSecondary),
                  ),
                ],
              ),
            )
          else
            ...filtered.map((anom) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: anom.category.color.withOpacity(0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: anom.category.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(anom.category.icon, color: anom.category.color, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                anom.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                  color: kTextPrimary,
                                ),
                              ),
                              Text(
                                '${anom.employeeName} (${anom.sicilNo}) • ${anom.department} • ${anom.shiftName}',
                                style: const TextStyle(fontSize: 12, color: kTextSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _buildStatusBadge(anom.category.label, anom.category.color),
                            _buildStatusBadge(anom.approvalStatus.label, anom.approvalStatus.color),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      anom.description,
                      style: const TextStyle(fontSize: 13, color: kTextPrimary, height: 1.4),
                    ),
                    if (anom.reviewedBy != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'İşlemi Yapan Yönetici: ${anom.reviewedBy} • Açıklama/Gerekçe: ${anom.rejectionReason ?? "-"}',
                        style: const TextStyle(fontSize: 11.5, color: kTextSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (anom.relatedMovementId != null)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.edit_note_rounded, size: 17),
                            label: const Text('Hareketi Düzelt'),
                            onPressed: () {
                              final targetMov = pdks.employeeMovements
                                  .where((m) => m.id == anom.relatedMovementId)
                                  .firstOrNull;
                              if (targetMov != null) {
                                _showMovementFormDialog(
                                  context,
                                  pdks,
                                  existingMovement: targetMov,
                                );
                              }
                            },
                          ),
                        const SizedBox(width: 8),
                        if (anom.approvalStatus == CorrectionApprovalStatus.pending) ...[
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.check_rounded, size: 17),
                            label: const Text('Onayla', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              final res = await pdks.approveAnomalyOrCorrection(anom);
                              _showFeedbackSnackBar(res.message, isError: !res.success);
                            },
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.close_rounded, size: 17),
                            label: const Text('Gerekçe ile Reddet', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () => _showRejectAnomalyDialog(context, pdks, anom),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ===========================================================================
  // FORM DİYALOGLARI (HAREKET EKLE/DÜZELT, PERSONEL EKLE/DÜZENLE, VARDİYA, REDDETME)
  // ===========================================================================

  /// Hareket Ekleme ve Manuel Düzeltme Formu
  /// Kurallar:
  /// - Personel, hareket türü ve tarih-saat zorunlu.
  /// - Cihaz / kapı ve açıklama alanları bulunur.
  /// - Manuel düzeltmede gerekçe zorunlu.
  /// - Form hataları ilgili alanın altında gösterilir.
  /// - Kayıt sırasında tekrar tıklama engellenir.
  /// - İptal işlemi kayıt oluşturmaz.
  void _showMovementFormDialog(
    BuildContext context,
    PdksState pdks, {
    EmployeeMovementRecord? existingMovement,
  }) {
    final isEdit = existingMovement != null;
    int? selectedEmpId = existingMovement?.employeeId ?? pdks.employees.firstOrNull?.id;
    MovementType? selectedType = existingMovement?.type ?? MovementType.checkIn;
    DateTime? selectedDateTime = existingMovement?.timestamp ??
        DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          DateTime.now().hour,
          DateTime.now().minute,
        );

    final doorCtrl = TextEditingController(
      text: existingMovement?.deviceDoor ?? 'Ana Giriş Turnike 1',
    );
    final noteCtrl = TextEditingController(text: existingMovement?.note ?? '');
    final reasonCtrl = TextEditingController();

    String? empError;
    String? typeError;
    String? dateTimeError;
    String? reasonError;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isEdit ? 'Hareket Kaydını Düzelt' : 'Yeni Çalışan Hareketi Ekle',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 460,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Personel Seçimi (Zorunlu)
                      DropdownButtonFormField<int>(
                        value: selectedEmpId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Personel *',
                          errorText: empError,
                        ),
                        items: pdks.employees
                            .map(
                              (e) => DropdownMenuItem<int>(
                                value: e.id,
                                child: Text('${e.fullName} (${e.displaySicilNo})'),
                              ),
                            )
                            .toList(),
                        onChanged: isEdit
                            ? null
                            : (val) {
                                setDialogState(() {
                                  selectedEmpId = val;
                                  empError = null;
                                });
                              },
                      ),
                      const SizedBox(height: 14),

                      // 2. Hareket Türü Seçimi (Zorunlu)
                      DropdownButtonFormField<MovementType>(
                        value: selectedType,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Hareket Türü *',
                          errorText: typeError,
                        ),
                        items: MovementType.values
                            .map(
                              (t) => DropdownMenuItem<MovementType>(
                                value: t,
                                child: Text(t.label),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedType = val;
                            typeError = null;
                          });
                        },
                      ),
                      const SizedBox(height: 14),

                      // 3. Tarih ve Saat Seçimi (Zorunlu - gg.aa.yyyy SS:dd)
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          final base = selectedDateTime ?? DateTime.now();
                          final pickedDate = await showDatePicker(
                            context: ctx,
                            initialDate: base,
                            firstDate: DateTime(2024, 1, 1),
                            lastDate: DateTime(2030, 12, 31),
                          );
                          if (pickedDate == null || !ctx.mounted) return;
                          final pickedTime = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.fromDateTime(base),
                            builder: (context, child) {
                              return MediaQuery(
                                data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                child: child!,
                              );
                            },
                          );
                          if (pickedTime == null) return;
                          setDialogState(() {
                            selectedDateTime = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                            dateTimeError = null;
                          });
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Tarih ve Saat (gg.aa.yyyy SS:dd) *',
                            errorText: dateTimeError,
                            suffixIcon: const Icon(Icons.access_time_rounded, size: 18),
                          ),
                          child: Text(
                            selectedDateTime != null
                                ? MovementCalculationEngine.formatDateTime(selectedDateTime!)
                                : 'Tarih ve saat seçiniz',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 4. Cihaz / Kapı Alanı
                      TextField(
                        controller: doorCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Cihaz / Kapı',
                          hintText: 'Örn: Ana Giriş Turnike 1',
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 5. Açıklama Alanı
                      TextField(
                        controller: noteCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Açıklama',
                          hintText: 'Hareketle ilgili açıklama veya not...',
                        ),
                      ),

                      // 6. Manuel Düzeltmede Zorunlu Gerekçe Alanı
                      if (isEdit) ...[
                        const SizedBox(height: 14),
                        TextField(
                          controller: reasonCtrl,
                          maxLines: 2,
                          onChanged: (_) {
                            if (reasonError != null) {
                              setDialogState(() => reasonError = null);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Düzeltme Gerekçesi (Zorunlu) *',
                            hintText: 'Bu kaydın neden düzeltildiğini açıklayınız...',
                            errorText: reasonError,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kTurquoise,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          // Alan altı doğrulama kontrolleri
                          bool hasError = false;
                          if (selectedEmpId == null) {
                            empError = 'Lütfen bir personel seçiniz.';
                            hasError = true;
                          }
                          if (selectedType == null) {
                            typeError = 'Lütfen hareket türü seçiniz.';
                            hasError = true;
                          }
                          if (selectedDateTime == null) {
                            dateTimeError = 'Lütfen geçerli bir tarih ve saat seçiniz.';
                            hasError = true;
                          }
                          if (isEdit && reasonCtrl.text.trim().isEmpty) {
                            reasonError = 'Manuel düzeltmelerde gerekçe alanı zorunludur.';
                            hasError = true;
                          }

                          if (hasError) {
                            setDialogState(() {});
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          if (isEdit) {
                            final res = await pdks.correctEmployeeMovement(
                              movementId: existingMovement.id,
                              newType: selectedType!,
                              newTimestamp: selectedDateTime!,
                              newDeviceDoor: doorCtrl.text,
                              newNote: noteCtrl.text,
                              reason: reasonCtrl.text,
                            );
                            if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                            _showFeedbackSnackBar(res.message, isError: !res.success);
                          } else {
                            final res = await pdks.addEmployeeMovement(
                              employeeId: selectedEmpId!,
                              type: selectedType!,
                              timestamp: selectedDateTime!,
                              deviceDoor: doorCtrl.text,
                              note: noteCtrl.text,
                            );
                            if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                            _showFeedbackSnackBar(res.message, isError: !res.success);
                          }
                        },
                  child: Text(isSubmitting ? 'Kaydediliyor...' : 'Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Personel Ekleme / Düzenleme Diyaloğu (Benzersiz Sicil Numarası Doğrulamalı)
  void _showEmployeeFormDialog(
    BuildContext context,
    PdksState pdks, {
    Employee? existingEmployee,
  }) {
    final isEdit = existingEmployee != null;
    final sicilCtrl = TextEditingController(
      text: existingEmployee?.displaySicilNo ??
          'SIC-${(pdks.employees.length + 1).toString().padLeft(4, '0')}',
    );
    final nameCtrl = TextEditingController(text: existingEmployee?.fullName ?? '');
    final deptCtrl = TextEditingController(
      text: existingEmployee?.department ?? 'Yazılım & Ar-Ge',
    );
    final titleCtrl = TextEditingController(text: existingEmployee?.title ?? 'Uzman');
    int selectedShiftId = existingEmployee != null
        ? pdks.getShiftForEmployee(existingEmployee.id).id
        : (pdks.pdksShiftDefinitions.firstOrNull?.id ?? 1);
    bool isActive = existingEmployee?.isActive ?? true;

    String? sicilError;
    String? nameError;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isEdit ? 'Personel Bilgilerini Düzenle' : 'Yeni Personel Ekle',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 440,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: sicilCtrl,
                        onChanged: (_) {
                          if (sicilError != null) setDialogState(() => sicilError = null);
                        },
                        decoration: InputDecoration(
                          labelText: 'Sicil Numarası (Benzersiz) *',
                          hintText: 'Örn: SIC-0015',
                          errorText: sicilError,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: nameCtrl,
                        onChanged: (_) {
                          if (nameError != null) setDialogState(() => nameError = null);
                        },
                        decoration: InputDecoration(
                          labelText: 'Ad Soyad *',
                          errorText: nameError,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: deptCtrl,
                        decoration: const InputDecoration(labelText: 'Departman'),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(labelText: 'Unvan'),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<int>(
                        value: selectedShiftId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Vardiya'),
                        items: pdks.pdksShiftDefinitions
                            .map(
                              (s) => DropdownMenuItem<int>(
                                value: s.id,
                                child: Text(s.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedShiftId = val);
                        },
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Aktif Personel', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                        value: isActive,
                        activeColor: kTurquoise,
                        onChanged: (val) => setDialogState(() => isActive = val),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kTurquoise,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final cleanSicil = sicilCtrl.text.trim().toUpperCase();
                          final cleanName = nameCtrl.text.trim();
                          bool hasErr = false;

                          if (cleanSicil.isEmpty) {
                            sicilError = 'Sicil numarası zorunludur.';
                            hasErr = true;
                          } else {
                            final duplicate = pdks.employees.any(
                              (e) =>
                                  e.id != existingEmployee?.id &&
                                  e.displaySicilNo.trim().toUpperCase() == cleanSicil,
                            );
                            if (duplicate) {
                              sicilError = 'Bu sicil numarası başka bir personele kayıtlıdır.';
                              hasErr = true;
                            }
                          }
                          if (cleanName.isEmpty) {
                            nameError = 'Ad soyad alanı zorunludur.';
                            hasErr = true;
                          }

                          if (hasErr) {
                            setDialogState(() {});
                            return;
                          }

                          setDialogState(() => isSubmitting = true);
                          final res = await pdks.saveEmployeeFromMovementPanel(
                            existingId: existingEmployee?.id,
                            sicilNo: cleanSicil,
                            fullName: cleanName,
                            department: deptCtrl.text,
                            title: titleCtrl.text,
                            shiftId: selectedShiftId,
                            isActive: isActive,
                          );

                          if (!res.success) {
                            setDialogState(() {
                              isSubmitting = false;
                              sicilError = res.message;
                            });
                            return;
                          }

                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                          _showFeedbackSnackBar(res.message);
                        },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Vardiya Ekleme / Düzenleme Diyaloğu
  void _showShiftFormDialog(
    BuildContext context,
    PdksState pdks, {
    PdksShiftDefinition? existingShift,
  }) {
    final nameCtrl = TextEditingController(text: existingShift?.name ?? '');
    final startCtrl = TextEditingController(text: existingShift?.startTime ?? '08:30');
    final endCtrl = TextEditingController(text: existingShift?.endTime ?? '17:30');
    final breakCtrl = TextEditingController(
      text: (existingShift?.plannedBreakMinutes ?? 60).toString(),
    );
    final tolCtrl = TextEditingController(
      text: (existingShift?.lateToleranceMinutes ?? 15).toString(),
    );

    String? nameError;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                existingShift != null ? 'Vardiyayı Düzenle' : 'Yeni Vardiya Tanımla',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Vardiya Adı *',
                          hintText: 'Örn: Gece Vardiyası (22:00 - 06:00)',
                          errorText: nameError,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: startCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Başlangıç Saati (24s)',
                                hintText: '08:30',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: endCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Bitiş Saati (24s)',
                                hintText: '17:30',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: breakCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Planlanan Mola (dk)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: tolCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Geç Kalma Toleransı (dk)',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kTurquoise,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) {
                      setDialogState(() => nameError = 'Vardiya adı zorunludur.');
                      return;
                    }
                    final shift = PdksShiftDefinition(
                      id: existingShift?.id ?? (DateTime.now().millisecondsSinceEpoch % 100000),
                      companyId: pdks.activeCompanyId,
                      name: nameCtrl.text.trim(),
                      startTime: startCtrl.text.trim(),
                      endTime: endCtrl.text.trim(),
                      plannedBreakMinutes: int.tryParse(breakCtrl.text.trim()) ?? 60,
                      lateToleranceMinutes: int.tryParse(tolCtrl.text.trim()) ?? 15,
                    );
                    final res = await pdks.savePdksShiftDefinition(shift);
                    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                    _showFeedbackSnackBar(res.message, isError: !res.success);
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Yönetici İçin Gerekçe İle Reddetme Diyaloğu (Gerekçe Zorunlu)
  void _showRejectAnomalyDialog(
    BuildContext context,
    PdksState pdks,
    MovementAnomalyItem anomaly,
  ) {
    final reasonCtrl = TextEditingController();
    String? reasonError;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Kaydı Gerekçe İle Reddet',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${anomaly.employeeName} (${anomaly.sicilNo}) - ${anomaly.title}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonCtrl,
                      maxLines: 3,
                      onChanged: (_) {
                        if (reasonError != null) setDialogState(() => reasonError = null);
                      },
                      decoration: InputDecoration(
                        labelText: 'Red Gerekçesi (Zorunlu) *',
                        hintText: 'Reddetme nedenini açıkça yazınız...',
                        errorText: reasonError,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (reasonCtrl.text.trim().isEmpty) {
                      setDialogState(() {
                        reasonError = 'Reddetme işlemi için gerekçe girilmesi zorunludur.';
                      });
                      return;
                    }
                    final res = await pdks.rejectAnomalyOrCorrection(
                      anomaly: anomaly,
                      rejectionReason: reasonCtrl.text,
                    );
                    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                    _showFeedbackSnackBar(res.message, isError: !res.success);
                  },
                  child: const Text('Reddet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Metin + Renk Durum Rozeti
  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}
