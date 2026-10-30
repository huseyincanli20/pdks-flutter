import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/employee.dart';
import '../../models/vehicle_request.dart';
import '../../state/pdks_state.dart';
import '../common/admin_edit_mode_bar.dart';

class VehicleRequestScreen extends StatefulWidget {
  const VehicleRequestScreen({super.key});

  @override
  State<VehicleRequestScreen> createState() => _VehicleRequestScreenState();
}

class _VehicleRequestScreenState extends State<VehicleRequestScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  VehicleRequestStatus? _statusFilter;
  String _searchQuery = '';

  // Form State
  String _selectedVehicleType = 'Binek Otomobil (Sedan/HB)';
  final _destinationController = TextEditingController();
  final _purposeController = TextEditingController();
  final _notesController = TextEditingController();
  int _passengerCount = 1;
  bool _needsDriver = false;
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  bool _isSubmitting = false;

  final List<String> _vehicleTypes = const [
    'Binek Otomobil (Sedan/HB)',
    'SUV / 4x4 Arazi',
    'Hafif Ticari / Kamyonet',
    'Minibüs / Servis (16+1)',
    'VIP / Makam Aracı',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final now = DateTime.now();
    _startDate = now.add(const Duration(hours: 1));
    _startTime = TimeOfDay(hour: _startDate.hour, minute: 0);
    _endDate = now.add(const Duration(hours: 7));
    _endTime = TimeOfDay(hour: _endDate.hour, minute: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _destinationController.dispose();
    _purposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submitRequest() async {
    final startCombined = _combineDateAndTime(_startDate, _startTime);
    final endCombined = _combineDateAndTime(_endDate, _endTime);

    if (_destinationController.text.trim().isEmpty) {
      _showWarning('Lütfen gidilecek güzergah / varış noktasını belirtiniz.');
      return;
    }
    if (_purposeController.text.trim().isEmpty) {
      _showWarning('Lütfen araç talep nedenini veya saha görevini belirtiniz.');
      return;
    }
    if (endCombined.isBefore(startCombined)) {
      _showWarning('Dönüş / teslim tarihi başlangıç tarihinden önce olamaz.');
      return;
    }

    setState(() => _isSubmitting = true);
    final pdks = context.read<PdksState>();

    final res = await pdks.createVehicleRequest(
      vehicleType: _selectedVehicleType,
      startDate: startCombined,
      endDate: endCombined,
      destination: _destinationController.text.trim(),
      purpose: _purposeController.text.trim(),
      passengerCount: _passengerCount,
      needsDriver: _needsDriver,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (res.success) {
        _destinationController.clear();
        _purposeController.clear();
        _notesController.clear();
        _tabController.animateTo(0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text(res.message)),
              ],
            ),
          ),
        );
      } else {
        _showWarning(res.message);
      }
    }
  }

  void _showWarning(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
      ),
    );
  }

  void _showApprovalDialog(BuildContext context, VehicleRequest req) {
    final vehicleCtrl = TextEditingController(text: '34 ACME 2024 - Renault Megane');
    final driverCtrl = TextEditingController(text: req.needsDriver ? 'Murat Şen (Şoför)' : 'Personel Kendisi');
    final noteCtrl = TextEditingController(text: 'Araç anahtarı ve yakıt kartı güvenlik noktasından teslim alınabilir.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Araç Talebini Onayla',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Talep Eden: ${req.employeeName} (${req.employeeTitle})',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Text(
                'Güzergah: ${req.destination} • ${req.vehicleType}',
                style: TextStyle(fontSize: 12, color: AppColors.textSub(context)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: vehicleCtrl,
                decoration: InputDecoration(
                  labelText: 'Tahsis Edilen Araç & Plaka *',
                  prefixIcon: const Icon(Icons.directions_car_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  helperText: 'Örn: 06 PDKS 88 - Ford Transit',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: driverCtrl,
                decoration: InputDecoration(
                  labelText: 'Görevli Sürücü',
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Onay Notu & Teslimat Talimatı',
                  prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<PdksState>().approveVehicleRequest(
                    req.id,
                    assignedVehicle: vehicleCtrl.text.trim(),
                    assignedDriver: driverCtrl.text.trim(),
                    note: noteCtrl.text.trim(),
                  );
            },
            child: const Text('Onayla ve Tahsis Et'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, VehicleRequest req) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Talebi Reddet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sayın ${req.employeeName} kullanıcısının araç talebini reddetmek üzeresiniz.'),
            const SizedBox(height: 14),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Ret Gerekçesi *',
                hintText: 'Örn: İlgili tarihte uygun havuz aracı bulunmamaktadır.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) {
                _showWarning('Lütfen ret gerekçesi giriniz.');
                return;
              }
              Navigator.pop(ctx);
              context.read<PdksState>().rejectVehicleRequest(
                    req.id,
                    reason: reasonCtrl.text.trim(),
                  );
            },
            child: const Text('Talebi Reddet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final user = pdks.currentUser;

    final isManager = user.role == UserRole.vehicleRentalManager ||
        user.role == UserRole.serviceManager ||
        user.role == UserRole.boss ||
        user.role == UserRole.admin ||
        user.role == UserRole.hr;

    final allList = pdks.vehicleRequestsForCurrentUser;
    final filteredList = allList.where((r) {
      if (_statusFilter != null && r.status != _statusFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchDest = r.destination.toLowerCase().contains(q);
        final matchEmp = r.employeeName.toLowerCase().contains(q);
        final matchType = r.vehicleType.toLowerCase().contains(q);
        final matchPlate = r.assignedVehicle?.toLowerCase().contains(q) ?? false;
        if (!matchDest && !matchEmp && !matchType && !matchPlate) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Araç Talebi & Filo',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              isManager ? 'Filo Yönetimi & Talep Onay Paneli' : 'Şirket Havuz Araçları Talebi',
              style: TextStyle(fontSize: 11, color: AppColors.textSub(context)),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: user.role.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: user.role.color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(user.role.icon, size: 14, color: user.role.color),
                const SizedBox(width: 5),
                Text(
                  user.role.shortLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: user.role.color,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF059669),
          indicatorWeight: 3,
          labelColor: const Color(0xFF059669),
          unselectedLabelColor: AppColors.textSub(context),
          tabs: [
            Tab(
              icon: const Icon(Icons.list_alt_rounded, size: 20),
              text: isManager ? 'Tüm Filo Talepleri (${allList.length})' : 'Taleplerim (${allList.length})',
            ),
            const Tab(
              icon: Icon(Icons.add_circle_outline_rounded, size: 20),
              text: 'Yeni Araç Talebi',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const AdminEditModeBar(pageId: 'vehicle_request', pageTitle: 'Araç Talebi & Filo'),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsTab(context, pdks, user, isManager, allList, filteredList),
                _buildNewRequestFormTab(context, user),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: TALEPLER LİSTESİ
  // ==========================================
  Widget _buildRequestsTab(
    BuildContext context,
    PdksState pdks,
    Employee user,
    bool isManager,
    List<VehicleRequest> allList,
    List<VehicleRequest> filteredList,
  ) {
    final pendingCount = allList.where((r) => r.status == VehicleRequestStatus.pending).length;
    final approvedCount = allList.where((r) => r.status == VehicleRequestStatus.approved || r.status == VehicleRequestStatus.inUse).length;
    final completedCount = allList.where((r) => r.status == VehicleRequestStatus.completed).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // KPI Kartları
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: 'Bekleyen',
                count: pendingCount,
                color: const Color(0xFFD97706),
                icon: Icons.hourglass_top_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildKpiCard(
                title: 'Tahsisli / Sefer',
                count: approvedCount,
                color: const Color(0xFF10B981),
                icon: Icons.directions_car_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildKpiCard(
                title: 'Tamamlanan',
                count: completedCount,
                color: const Color(0xFF6B7280),
                icon: Icons.task_alt_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Arama ve Filtre Çipleri
        TextField(
          decoration: InputDecoration(
            hintText: 'Güzergah, personel, araç tipi veya plaka ara...',
            hintStyle: const TextStyle(fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            filled: true,
            fillColor: AppColors.cardBg(context),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.cardBorder(context)),
            ),
          ),
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
        ),
        const SizedBox(height: 10),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('Tümü', null),
              const SizedBox(width: 6),
              _buildFilterChip('Beklemede', VehicleRequestStatus.pending),
              const SizedBox(width: 6),
              _buildFilterChip('Onaylanan', VehicleRequestStatus.approved),
              const SizedBox(width: 6),
              _buildFilterChip('Seferde', VehicleRequestStatus.inUse),
              const SizedBox(width: 6),
              _buildFilterChip('Tamamlandı', VehicleRequestStatus.completed),
              const SizedBox(width: 6),
              _buildFilterChip('Reddedildi', VehicleRequestStatus.rejected),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (filteredList.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder(context)),
            ),
            child: Column(
              children: [
                Icon(Icons.directions_car_outlined, size: 54, color: AppColors.textSub(context).withOpacity(0.5)),
                const SizedBox(height: 12),
                const Text(
                  'Kayıtlı Araç Talebi Bulunamadı',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  _searchQuery.isNotEmpty || _statusFilter != null
                      ? 'Filtreleme kriterlerine uyan talep yok.'
                      : 'Henüz yeni bir araç talebi oluşturulmamış.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSub(context)),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Yeni Talep Oluştur'),
                  onPressed: () => _tabController.animateTo(1),
                ),
              ],
            ),
          )
        else
          ...filteredList.map((req) => _buildRequestCard(context, req, isManager)),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VehicleRequestStatus? status) {
    final isSelected = _statusFilter == status;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: const Color(0xFF059669).withOpacity(0.18),
      side: BorderSide(
        color: isSelected ? const Color(0xFF059669) : Colors.grey.withOpacity(0.3),
      ),
      onSelected: (_) => setState(() => _statusFilter = status),
    );
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d.$m $h:$min';
  }

  Widget _buildRequestCard(BuildContext context, VehicleRequest req, bool isManager) {
    final statusColor = req.status.color;
    final statusLabel = req.status.label;
    final statusIcon = req.status.icon;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Satır: Personel Bilgisi & Durum Rozeti
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF059669).withOpacity(0.15),
                  child: const Icon(Icons.person_rounded, size: 20, color: Color(0xFF059669)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.employeeName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        '${req.employeeDepartment} • ${req.employeeTitle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: AppColors.textSub(context)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 18),

            // Güzergah & Amaç
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.near_me_rounded, size: 16, color: Color(0xFF059669)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    req.destination,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Text(
                req.purpose,
                style: TextStyle(fontSize: 12, color: AppColors.textSub(context)),
              ),
            ),
            const SizedBox(height: 10),

            // Detay Çipleri: Araç Tipi, Süre, Yolcu Sayısı
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildTag(Icons.directions_car_rounded, req.vehicleType, const Color(0xFF2563EB)),
                _buildTag(Icons.schedule_rounded, '${_formatDateTime(req.startDate)} - ${_formatDateTime(req.endDate)} (${req.durationLabel})', const Color(0xFF6B7280)),
                _buildTag(Icons.group_rounded, '${req.passengerCount} Kişi', const Color(0xFF8B5CF6)),
                if (req.needsDriver)
                  _buildTag(Icons.airline_seat_recline_normal_rounded, 'Şoförlü Araç', const Color(0xFFEA580C)),
              ],
            ),

            // Tahsis Edilen Araç Rozeti (Onaylandıysa)
            if (req.assignedVehicle != null && req.assignedVehicle!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.key_rounded, size: 16, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Tahsis Edilen Araç: ${req.assignedVehicle}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF065F46)),
                          ),
                        ),
                      ],
                    ),
                    if (req.assignedDriver != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Sürücü: ${req.assignedDriver}',
                        style: TextStyle(fontSize: 11, color: Colors.green.shade900),
                      ),
                    ],
                    if (req.approvalNote != null && req.approvalNote!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Not: ${req.approvalNote}',
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.green.shade800),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Ret Gerekçesi
            if (req.status == VehicleRequestStatus.rejected && req.approvalNote != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Ret Gerekçesi: ${req.approvalNote}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Yönetici Aksiyon Butonları (Araç Kiralama Sorumlusu, CEO, Admin)
            if (isManager) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (req.status == VehicleRequestStatus.pending) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: BorderSide(color: const Color(0xFFEF4444).withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 14),
                      label: const Text('Reddet', style: TextStyle(fontSize: 11.5)),
                      onPressed: () => _showRejectDialog(context, req),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 14),
                      label: const Text('Onayla & Araç Ata', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      onPressed: () => _showApprovalDialog(context, req),
                    ),
                  ] else if (req.status == VehicleRequestStatus.approved) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 14),
                      label: const Text('Seferi Başlat', style: TextStyle(fontSize: 11.5)),
                      onPressed: () {
                        context.read<PdksState>().updateVehicleRequestStatus(req.id, VehicleRequestStatus.inUse);
                      },
                    ),
                  ] else if (req.status == VehicleRequestStatus.inUse) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B7280),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      icon: const Icon(Icons.task_alt_rounded, size: 14),
                      label: const Text('Aracı Teslim Al (Tamamla)', style: TextStyle(fontSize: 11.5)),
                      onPressed: () {
                        context.read<PdksState>().updateVehicleRequestStatus(req.id, VehicleRequestStatus.completed);
                      },
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: YENİ ARAÇ TALEBİ FORMU
  // ==========================================
  Widget _buildNewRequestFormTab(BuildContext context, Employee user) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Başlık Kartı
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF047857)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF059669).withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.car_rental_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kurumsal Araç Talebi',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Saha operasyonları, arıza, müşteri ziyareti ve transferler için filo aracı tahsisi talep edin.',
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Araç Tipi Seçimi
        const Text(
          'Araç Tipi Seçimi *',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _vehicleTypes.map((type) {
            final isSelected = _selectedVehicleType == type;
            return ChoiceChip(
              label: Text(type, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              selected: isSelected,
              selectedColor: const Color(0xFF059669).withOpacity(0.18),
              side: BorderSide(
                color: isSelected ? const Color(0xFF059669) : Colors.grey.withOpacity(0.3),
                width: isSelected ? 1.5 : 1,
              ),
              onSelected: (_) => setState(() => _selectedVehicleType = type),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),

        // Gidilecek Güzergah
        TextField(
          controller: _destinationController,
          decoration: InputDecoration(
            labelText: 'Gidilecek Güzergah / Varış Noktası *',
            hintText: 'Örn: Sincan OSB Şantiyesi, Eskişehir Fabrika',
            prefixIcon: const Icon(Icons.near_me_rounded, color: Color(0xFF059669), size: 20),
            filled: true,
            fillColor: AppColors.cardBg(context),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 14),

        // Talep Nedeni / Saha Görevi
        TextField(
          controller: _purposeController,
          decoration: InputDecoration(
            labelText: 'Talep Nedeni & Saha Görevi *',
            hintText: 'Örn: Acil elektrik arıza bakımı, test cihazı nakliyesi',
            prefixIcon: const Icon(Icons.assignment_outlined, color: Color(0xFF059669), size: 20),
            filled: true,
            fillColor: AppColors.cardBg(context),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 16),

        // Tarih ve Saat Seçicileri
        Row(
          children: [
            Expanded(
              child: _buildDateTimePicker(
                title: 'Alış Tarihi & Saati',
                date: _startDate,
                time: _startTime,
                onDatePick: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) setState(() => _startDate = picked);
                },
                onTimePick: () async {
                  final picked = await showTimePicker(context: context, initialTime: _startTime);
                  if (picked != null) setState(() => _startTime = picked);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDateTimePicker(
                title: 'Teslim Tarihi & Saati',
                date: _endDate,
                time: _endTime,
                onDatePick: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate,
                    firstDate: _startDate,
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) setState(() => _endDate = picked);
                },
                onTimePick: () async {
                  final picked = await showTimePicker(context: context, initialTime: _endTime);
                  if (picked != null) setState(() => _endTime = picked);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Yolcu Sayısı & Şoför Tercihi
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBg(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder(context)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.group_rounded, color: Color(0xFF059669), size: 20),
                      SizedBox(width: 8),
                      Text('Yolcu Sayısı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                        onPressed: _passengerCount > 1 ? () => setState(() => _passengerCount--) : null,
                      ),
                      Text(
                        '$_passengerCount Kişi',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        onPressed: _passengerCount < 20 ? () => setState(() => _passengerCount++) : null,
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 10),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Şirket Şoförü Talep Ediyorum', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('Açık ise filo havuzundan görevli şoför tahsis edilir.', style: TextStyle(fontSize: 11)),
                value: _needsDriver,
                activeColor: const Color(0xFF059669),
                onChanged: (val) => setState(() => _needsDriver = val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Ekstra Notlar
        TextField(
          controller: _notesController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Ek Açıklama & Bagaj/Yük Bilgisi (İsteğe Bağlı)',
            hintText: 'Örn: Ağır teknik ölçüm cihazı veya numune kolileri taşınacaktır.',
            prefixIcon: const Icon(Icons.notes_rounded, color: Colors.grey, size: 20),
            filled: true,
            fillColor: AppColors.cardBg(context),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 22),

        // Gönder Butonu
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded),
            label: Text(
              _isSubmitting ? 'Talep İletiliyor...' : 'Araç Talebini Filo Yönetimine Gönder',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            onPressed: _isSubmitting ? null : _submitRequest,
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker({
    required String title,
    required DateTime date,
    required TimeOfDay time,
    required VoidCallback onDatePick,
    required VoidCallback onTimePick,
  }) {
    final dateStr = '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
          const SizedBox(height: 6),
          InkWell(
            onTap: onDatePick,
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(dateStr, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: onTimePick,
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
