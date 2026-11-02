import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/shift_swap_request.dart';
import '../../models/helpdesk_ticket.dart';
import '../../models/company_announcement.dart';
import '../../models/visitor_record.dart';
import '../../models/hybrid_booking.dart';
import '../../models/employee_feedback.dart';
import '../../models/employee.dart';
import '../../models/ai_anomaly_and_insights.dart';
import '../../models/push_to_talk_and_media.dart';
import '../kiosk/kiosk_terminal_screen.dart';
import '../common/digital_signature_pad_dialog.dart';
import '../../state/pdks_state.dart';

class EnterpriseHubScreen extends StatefulWidget {
  final int initialTabIndex;
  const EnterpriseHubScreen({super.key, this.initialTabIndex = 0});

  @override
  State<EnterpriseHubScreen> createState() => _EnterpriseHubScreenState();
}

class _EnterpriseHubScreenState extends State<EnterpriseHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // AI & Anomali State
  final TextEditingController _aiPromptController = TextEditingController();
  bool _isAiResponding = false;
  String? _selectedShiftDept;
  SmartShiftOptimization? _latestOptimization;

  // 5070 E-İmza & ERP Export State
  String _selectedErpFormat = 'logo';
  final String _selectedErpPeriod = '2026-10';
  String? _generatedErpContent;

  // PTT Saha Telsizi State
  String _activePttChannelId = 'ptt_genel';
  bool _isTransmittingVoice = false;

  final List<({String title, IconData icon, String subtitle})> _tabs = const [
    (title: 'Yönetim Özeti', icon: Icons.dashboard_rounded, subtitle: 'KPI & Analitik'),
    (title: 'Vardiya & Takas', icon: Icons.swap_horiz_rounded, subtitle: 'Takas & Boş Vardiya'),
    (title: 'Destek & Bakım', icon: Icons.build_circle_rounded, subtitle: 'Arıza & Teknisyen'),
    (title: 'Duyurular', icon: Icons.campaign_rounded, subtitle: 'Zorunlu Onaylar'),
    (title: 'Özlük & Onboarding', icon: Icons.folder_shared_rounded, subtitle: 'Belgeler & İşe Giriş'),
    (title: 'Akademi & Eğitim', icon: Icons.school_rounded, subtitle: 'Sınav & Yetkinlik'),
    (title: 'Hedef & OKR', icon: Icons.track_changes_rounded, subtitle: 'Performans'),
    (title: 'Ziyaretçi & Taşeron', icon: Icons.badge_rounded, subtitle: 'QR Geçiş Kartı'),
    (title: 'Hibrit & Masa', icon: Icons.desk_rounded, subtitle: 'Rezervasyon'),
    (title: 'Şubeler & Vekalet', icon: Icons.corporate_fare_rounded, subtitle: 'Organizasyon'),
    (title: 'Geri Bildirim', icon: Icons.rate_review_rounded, subtitle: 'Anket & Öneri'),
    (title: 'Entegrasyon & Offline', icon: Icons.sync_alt_rounded, subtitle: 'ERP & Kuyruk'),
    (title: 'Kalibrasyon & CMMS', icon: Icons.precision_manufacturing_rounded, subtitle: 'ISO 9001/17025'),
    (title: 'Mevzuat & Denetim', icon: Icons.gavel_rounded, subtitle: '4857 & Audit Log'),
    (title: 'PDKS AI & Anomali', icon: Icons.psychology_rounded, subtitle: '4857 Asistan & Buddy-Punch'),
    (title: 'Kiosk Yüz & Turnike', icon: Icons.camera_front_rounded, subtitle: 'Canlılık & TCP/IP Röle'),
    (title: '5070 E-İmza & ERP', icon: Icons.draw_rounded, subtitle: 'Zaman Damgası & Bordro İhracat'),
    (title: 'İSG & Ramak Kala', icon: Icons.health_and_safety_rounded, subtitle: '6331 İSG & Geofence KKD'),
    (title: 'Saha Telsizi (PTT)', icon: Icons.radio_rounded, subtitle: 'Bas-Konuş & Sesli Telsiz'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, _tabs.length - 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _aiPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kurumsal Modüller', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text('19 Gelişmiş İK, Tesis, Güvenlik & Operasyon Modülü', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF1E1B4B), // Deep Indigo
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF6366F1),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: _tabs.map((t) => Tab(
            icon: Icon(t.icon, size: 20),
            text: t.title,
          )).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExecutiveDashboardTab(),
          _buildShiftSwapTab(),
          _buildHelpdeskTab(),
          _buildAnnouncementsTab(),
          _buildPersonnelAndOnboardingTab(),
          _buildTrainingTab(),
          _buildPerformanceTab(),
          _buildVisitorsTab(),
          _buildHybridWorkTab(),
          _buildBranchesAndDelegationTab(),
          _buildFeedbackTab(),
          _buildIntegrationsTab(),
          _buildCalibrationAndCmmsTab(),
          _buildLaborLawAndAuditTab(),
          _buildAiAndAnomalyTab(),
          _buildKioskAndTurnstileTab(),
          _buildDigitalSignatureAndErpTab(),
          _buildOccupationalSafetyTab(),
          _buildPushToTalkTab(),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. YÖNETİM GÖSTERGE PANELİ (EXECUTIVE DASHBOARD)
  // ===========================================================================
  Widget _buildExecutiveDashboardTab() {
    final pdks = context.watch<PdksState>();
    final stats = pdks.executiveDashboardStats;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('📊 Kurumsal Durum ve Anahtar Göstergeler (KPI)'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Aktif Personel', '${stats.totalEmployees}', Icons.people, Colors.blue)),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricCard('Bugün Ofiste', '${stats.activeCheckedInToday}', Icons.how_to_reg, Colors.teal)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Devam Oranı', '%${stats.attendanceRatePercent.toStringAsFixed(1)}', Icons.pie_chart, Colors.indigo)),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricCard('Fazla Mesai', '${stats.totalOvertimeHours.toStringAsFixed(0)} Saat', Icons.timer, Colors.amber)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Açık Arıza / Bakım', '${stats.openHelpdeskTicketsCount}', Icons.build, Colors.orange)),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricCard('Tesis İçi Ziyaretçi', '${stats.insideVisitorsCount}', Icons.badge, Colors.purple)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Aktif Şubeler', '${stats.activeBranchesCount}', Icons.apartment, Colors.cyan)),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricCard('Memnuniyet Puanı', '${stats.employeeSatisfactionScore.toStringAsFixed(1)} / 5.0', Icons.star, Colors.amber.shade700)),
          ],
        ),
        const SizedBox(height: 20),
        _buildInfoCard(
          title: '📌 Yönetim Bilgi Notu',
          body: 'Bu gösterge paneli; yoklama hareketleri, bordrolar, arıza biletleri, ziyaretçi logları ve çalışan memnuniyet anketlerinden anlık olarak veritabanından çekilip hesaplanmaktadır.',
          color: Colors.indigo,
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. GELİŞMİŞ VARDİYA TAKASI & AÇIK VARDİYALAR
  // ===========================================================================
  Widget _buildShiftSwapTab() {
    final pdks = context.watch<PdksState>();
    final swaps = pdks.shiftSwaps;
    final openSlots = pdks.openShiftSlots;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('🔄 Onaylı Vardiya Takas Talepleri'),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Takas İste', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
              onPressed: () => _showAddShiftSwapDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (swaps.isEmpty)
          _buildEmptyText('Aktif vardiya takas talebi bulunmuyor.')
        else
          ...swaps.map((s) => Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: s.status == 'approved' ? Colors.green.shade100 : (s.status == 'rejected' ? Colors.red.shade100 : Colors.amber.shade100),
                    child: Icon(
                      s.status == 'approved' ? Icons.check : (s.status == 'rejected' ? Icons.close : Icons.hourglass_top),
                      color: s.status == 'approved' ? Colors.green : (s.status == 'rejected' ? Colors.red : Colors.orange),
                    ),
                  ),
                  title: Text('${s.requesterName} ➔ ${s.targetName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('${s.shiftTitle}\nTarih: ${s.targetDate.day}.${s.targetDate.month}.${s.targetDate.year}\nSebep: ${s.reason}'),
                  isThreeLine: true,
                  trailing: s.status == 'pending'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              onPressed: () => pdks.updateShiftSwapStatus(s.id, 'approved'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => pdks.updateShiftSwapStatus(s.id, 'rejected'),
                            ),
                          ],
                        )
                      : Chip(
                          label: Text(s.status == 'approved' ? 'Onaylandı' : 'Reddedildi', style: const TextStyle(fontSize: 11, color: Colors.white)),
                          backgroundColor: s.status == 'approved' ? Colors.green : Colors.red,
                        ),
                ),
              )),
        const SizedBox(height: 20),
        _buildSectionHeader('📅 Başvuruya Açık Boş Vardiyalar'),
        const SizedBox(height: 10),
        if (openSlots.isEmpty)
          _buildEmptyText('Şu anda açık vardiya ilanı bulunmuyor.')
        else
          ...openSlots.map((slot) => Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.event_available, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(slot.shiftTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Tarih: ${slot.date.day}.${slot.date.month}.${slot.date.year} • İhtiyaç: ${slot.requiredHeadcount} Kişi', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('Başvuranlar: ${slot.appliedEmployeeIds.length} Personel', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                        onPressed: () {
                          pdks.applyToOpenShift(slot.id);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vardiyaya başvurunuz kaydedildi.')));
                        },
                        child: const Text('Başvur', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  // ===========================================================================
  // 3. TEKNİK DESTEK & BAKIM TALEPLERİ (HELPDESK)
  // ===========================================================================
  Widget _buildHelpdeskTab() {
    final pdks = context.watch<PdksState>();
    final tickets = pdks.helpdeskTickets;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('🛠️ Teknik Arıza ve Destek Masası'),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Arıza Bildir', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
              onPressed: () => _showAddTicketDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (tickets.isEmpty)
          _buildEmptyText('Açık destek veya arıza kaydı bulunmuyor.')
        else
          ...tickets.map((t) => Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _buildPriorityBadge(t.priority),
                              const SizedBox(width: 8),
                              Text(t.category.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                            ],
                          ),
                          _buildStatusBadge(t.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(t.description, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      const Divider(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Bildiren: ${t.requesterName}', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                          if (t.assignedTechnicianName != null)
                            Text('Teknisyen: ${t.assignedTechnicianName}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo))
                          else
                            TextButton(
                              onPressed: () => pdks.assignTechnician(t.id, 8, 'Murat Usta (Teknisyen)'),
                              child: const Text('Teknisyen Ata', style: TextStyle(fontSize: 11)),
                            ),
                        ],
                      ),
                      if (t.status != 'resolved') ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            label: const Text('Çözüldü Olarak İşaretle', style: TextStyle(fontSize: 12)),
                            onPressed: () => pdks.resolveHelpdeskTicket(t.id, 'Sorun teknisyen tarafından yerinde giderildi.'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  // ===========================================================================
  // 4. DUYURULAR VE OKUNDU ONAYI
  // ===========================================================================
  Widget _buildAnnouncementsTab() {
    final pdks = context.watch<PdksState>();
    final announcements = pdks.announcements;
    final currentUserId = pdks.currentUser.id;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('📣 Şirket İçi Duyurular & Talimatlar'),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Duyuru Yayınla', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
              onPressed: () => _showAddAnnouncementDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (announcements.isEmpty)
          _buildEmptyText('Yayınlanmış duyuru bulunmuyor.')
        else
          ...announcements.map((a) {
            final isRead = a.readEmployeeIds.contains(currentUserId);
            final isConfirmed = a.confirmedEmployeeIds.contains(currentUserId);

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (a.isMandatory)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(6)),
                            child: const Text('ZORUNLU ONAY', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        Text(a.category.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const Spacer(),
                        Text('${a.publishedAt.day}.${a.publishedAt.month}.${a.publishedAt.year}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(a.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(a.content, style: const TextStyle(fontSize: 13, height: 1.4)),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('👁️ ${a.readEmployeeIds.length} Okundu • ✅ ${a.confirmedEmployeeIds.length} Onaylandı', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                        if (a.isMandatory && !isConfirmed)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check, size: 14),
                            label: const Text('Okudum, Onaylıyorum', style: TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                            onPressed: () {
                              pdks.confirmAnnouncement(a.id);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Duyuru okundu onayı veritabanına kaydedildi.')));
                            },
                          )
                        else if (!isRead)
                          TextButton(
                            onPressed: () => pdks.markAnnouncementRead(a.id),
                            child: const Text('Okundu İşaretle', style: TextStyle(fontSize: 11)),
                          )
                        else
                          const Text('Onayınız Alındı ✓', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // ===========================================================================
  // 5. PERSONEL ÖZLÜK & ONBOARDING / OFFBOARDING
  // ===========================================================================
  Widget _buildPersonnelAndOnboardingTab() {
    final pdks = context.watch<PdksState>();
    final docs = pdks.documents;
    final tasks = pdks.onboardingTasks;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('📁 Personel Özlük Dosyası & Evrak Geçerlilik'),
        const SizedBox(height: 10),
        if (docs.isEmpty)
          _buildEmptyText('Kayıtlı özlük evrakı bulunmuyor.')
        else
          ...docs.map((d) => Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 30),
                  title: Text(d.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  subtitle: Text('Tür: ${d.documentType} • Yükleme: ${d.uploadDate.day}.${d.uploadDate.month}.${d.uploadDate.year}\n${d.expiryDate != null ? 'Bitiş Tarihi: ${d.expiryDate!.day}.${d.expiryDate!.month}.${d.expiryDate!.year}' : 'Süresiz'}'),
                  trailing: d.status == 'expiring_soon'
                      ? const Chip(label: Text('Süresi Yaklaşıyor', style: TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: Colors.orange)
                      : const Icon(Icons.verified, color: Colors.green, size: 20),
                ),
              )),
        const SizedBox(height: 20),
        _buildSectionHeader('🚀 İşe Giriş / Ayrılış Kontrol Listesi (Onboarding)'),
        const SizedBox(height: 10),
        if (tasks.isEmpty)
          _buildEmptyText('Tanımlı oryantasyon görevi bulunmuyor.')
        else
          ...tasks.map((task) => CheckboxListTile(
                value: task.isCompleted,
                title: Text(task.title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, decoration: task.isCompleted ? TextDecoration.lineThrough : null)),
                subtitle: Text('Kategori: ${task.category.toUpperCase()} • Sorumlu Rol: ${task.assignedRole.toUpperCase()}', style: const TextStyle(fontSize: 11)),
                onChanged: (val) => pdks.toggleOnboardingTask(task.id, val ?? false),
              )),
      ],
    );
  }

  // ===========================================================================
  // 6. EĞİTİM & YETKİNLİK TAKİBİ
  // ===========================================================================
  Widget _buildTrainingTab() {
    final pdks = context.watch<PdksState>();
    final courses = pdks.trainingCourses;
    final records = pdks.trainingRecords;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('🎓 Kurumsal Eğitim Kataloğu & Sınavlar'),
        const SizedBox(height: 10),
        ...courses.map((c) => Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(label: Text(c.category.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: Colors.indigo),
                        Text('⏱️ ${c.durationMinutes} dk • Geçme Notu: ${c.passingScore}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                    const SizedBox(height: 4),
                    Text(c.description, style: const TextStyle(fontSize: 12.5, color: Colors.black87)),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                        onPressed: () {
                          pdks.assignTraining(c.id, c.title, pdks.currentUser.id);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Eğitim profilinize atandı.')));
                        },
                        child: const Text('Eğitime Başla', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 20),
        _buildSectionHeader('📜 Tamamlanan Eğitimler & Sertifikalarım'),
        const SizedBox(height: 10),
        ...records.map((r) => ListTile(
              leading: Icon(r.status == 'completed' ? Icons.verified : Icons.timelapse, color: r.status == 'completed' ? Colors.green : Colors.orange),
              title: Text(r.courseTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              subtitle: Text(r.status == 'completed' ? 'Puan: ${r.score}/100 • Geçerlilik: ${r.certificateExpiry?.year}' : 'Devam Ediyor'),
              trailing: r.status != 'completed'
                  ? ElevatedButton(
                      onPressed: () => pdks.completeTraining(r.id, 92),
                      child: const Text('Sınavı Bitir', style: TextStyle(fontSize: 10)),
                    )
                  : const Chip(label: Text('Sertifikalı', style: TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: Colors.green),
            )),
      ],
    );
  }

  // ===========================================================================
  // 7. PERFORMANS & HEDEF YÖNETİMİ (OKRs)
  // ===========================================================================
  Widget _buildPerformanceTab() {
    final pdks = context.watch<PdksState>();
    final goals = pdks.performanceGoals;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('🎯 Dönemlik Hedefler & Başarı Göstergeleri (OKRs)'),
        const SizedBox(height: 12),
        if (goals.isEmpty)
          _buildEmptyText('Tanımlı performans hedefi bulunmuyor.')
        else
          ...goals.map((g) => Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(label: Text(g.period, style: const TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: Colors.deepPurple),
                          Text('Ağırlık: %${g.weightPercentage.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(g.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(g.description, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('İlerleme:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text('%${g.currentProgress.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (g.currentProgress / 100).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
                        ),
                      ),
                      if (g.managerFeedback != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text('💬 Yönetici Notu: ${g.managerFeedback}', style: const TextStyle(fontSize: 12, color: Colors.deepPurple)),
                        ),
                      ],
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  // ===========================================================================
  // 8. ZİYARETÇİ VE TAŞERON YÖNETİMİ
  // ===========================================================================
  Widget _buildVisitorsTab() {
    final pdks = context.watch<PdksState>();
    final visitors = pdks.visitorRecords;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('🤝 Ziyaretçi & Taşeron Geçiş Kayıtları'),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Ziyaretçi Ekle', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              onPressed: () => _showAddVisitorDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (visitors.isEmpty)
          _buildEmptyText('Kayıtlı ziyaretçi bulunmuyor.')
        else
          ...visitors.map((v) => Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(v.visitorFullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                              if (v.isContractor)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  margin: const EdgeInsets.only(left: 6),
                                  decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                                  child: const Text('TAŞERON', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orange)),
                                ),
                            ],
                          ),
                          Chip(
                            label: Text(v.status == 'inside' ? 'Tesis İçi' : (v.status == 'completed' ? 'Ayrıldı' : 'Bekleniyor'),
                                style: const TextStyle(fontSize: 10, color: Colors.white)),
                            backgroundColor: v.status == 'inside' ? Colors.green : (v.status == 'completed' ? Colors.grey : Colors.blue),
                          ),
                        ],
                      ),
                      Text('Kurum: ${v.visitorCompany} • Tel: ${v.visitorPhone}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                      Text('Ev Sahibi: ${v.hostEmployeeName} • Amaç: ${v.purpose}', style: const TextStyle(fontSize: 12)),
                      Text('🎫 QR Kod: ${v.qrPassCode}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (v.status == 'pre_registered')
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              onPressed: () => pdks.checkInVisitor(v.id),
                              child: const Text('Giriş Yaptı', style: TextStyle(fontSize: 11)),
                            ),
                          if (v.status == 'inside')
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
                              onPressed: () => pdks.checkOutVisitor(v.id),
                              child: const Text('Çıkış Yaptı', style: TextStyle(fontSize: 11)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  // ===========================================================================
  // 9. HİBRİT ÇALIŞMA & REZERVASYON (Masa, Oda, Otopark)
  // ===========================================================================
  Widget _buildHybridWorkTab() {
    final pdks = context.watch<PdksState>();
    final bookings = pdks.hybridBookings;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('🏠 Hibrit Çalışma & Masa / Oda Rezervasyonu'),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Yer Ayırt', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
              onPressed: () => _showAddBookingDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (bookings.isEmpty)
          _buildEmptyText('Aktif rezervasyon kaydı bulunmuyor.')
        else
          ...bookings.map((b) => Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: b.resourceType == 'desk' ? Colors.blue.shade100 : (b.resourceType == 'meeting_room' ? Colors.purple.shade100 : Colors.teal.shade100),
                    child: Icon(
                      b.resourceType == 'desk' ? Icons.desk : (b.resourceType == 'meeting_room' ? Icons.meeting_room : Icons.local_parking),
                      color: b.resourceType == 'desk' ? Colors.blue : (b.resourceType == 'meeting_room' ? Colors.purple : Colors.teal),
                    ),
                  ),
                  title: Text(b.resourceCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('Personel: ${b.employeeName}\nTarih: ${b.date.day}.${b.date.month}.${b.date.year} • ${b.timeSlot}'),
                  isThreeLine: true,
                  trailing: b.status == 'confirmed'
                      ? IconButton(
                          icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                          tooltip: 'Rezervasyonu İptal Et',
                          onPressed: () => pdks.cancelHybridBooking(b.id),
                        )
                      : const Text('İptal Edildi', style: TextStyle(color: Colors.red, fontSize: 11)),
                ),
              )),
      ],
    );
  }

  // ===========================================================================
  // 10. ŞUBELER & ONAY SÜREÇLERİ / VEKALET
  // ===========================================================================
  Widget _buildBranchesAndDelegationTab() {
    final pdks = context.watch<PdksState>();
    final branches = pdks.branches;
    final delegations = pdks.delegations;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('🏢 Şube, Tesis & Organizasyon Yapısı'),
        const SizedBox(height: 10),
        ...branches.map((br) => Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.corporate_fare, color: Colors.indigo, size: 30),
                title: Text(br.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('Yönetici: ${br.managerName} • ${br.city}\nDepartmanlar: ${br.departments.join(', ')}'),
                isThreeLine: true,
                trailing: Text('${br.employeeCount} Personel', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              ),
            )),
        const SizedBox(height: 20),
        _buildSectionHeader('🔄 Esnek Onay Süreçleri & Yetki Vekaleti'),
        const SizedBox(height: 10),
        ...delegations.map((del) => Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.only(bottom: 10),
              child: SwitchListTile(
                value: del.isActive,
                title: Text('${del.managerName} ➔ ${del.delegateEmployeeName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: Text('Kapsam: ${del.scope.toUpperCase()} • Bitiş: ${del.endDate.day}.${del.endDate.month}.${del.endDate.year}'),
                onChanged: (val) => pdks.toggleApprovalDelegation(del.id, val),
              ),
            )),
      ],
    );
  }

  // ===========================================================================
  // 11. ÇALIŞAN GERİ BİLDİRİMLERİ & ANKETLER
  // ===========================================================================
  Widget _buildFeedbackTab() {
    final pdks = context.watch<PdksState>();
    final feedbacks = pdks.feedbacks;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('📝 Memnuniyet Anketleri & Öneri Kutusu'),
            ElevatedButton.icon(
              icon: const Icon(Icons.rate_review, size: 16),
              label: const Text('Geri Bildirim Yap', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
              onPressed: () => _showAddFeedbackDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (feedbacks.isEmpty)
          _buildEmptyText('Henüz iletilen bir geri bildirim bulunmuyor.')
        else
          ...feedbacks.map((fb) => Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber.shade700, size: 18),
                              const SizedBox(width: 4),
                              Text('${fb.rating}/5', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Chip(label: Text(fb.category.toUpperCase(), style: const TextStyle(fontSize: 9, color: Colors.white)), backgroundColor: Colors.indigo),
                            ],
                          ),
                          Text(fb.isAnonymous ? 'Anonim' : (fb.submitterName ?? ''), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(fb.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(fb.content, style: const TextStyle(fontSize: 13)),
                      if (fb.hrResponse != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text('✅ İK Yanıtı: ${fb.hrResponse}', style: const TextStyle(fontSize: 12, color: Colors.teal)),
                        ),
                      ],
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  // ===========================================================================
  // 12. ENTEGRASYON MERKEZİ & ÇEVRİMDIŞI ÇALIŞMA
  // ===========================================================================
  Widget _buildIntegrationsTab() {
    final pdks = context.watch<PdksState>();
    final endpoints = pdks.integrations;
    final queue = pdks.offlineQueue;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('🔌 ERP, Muhasebe & Turnike Entegrasyonları'),
        const SizedBox(height: 10),
        ...endpoints.map((ep) => Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.cloud_sync, color: Colors.indigo, size: 28),
                title: Text(ep.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: Text('Endpoint: ${ep.apiEndpoint}\nSenkron: ${ep.syncedRecordsCount} kayıt • Hata: ${ep.failedRecordsCount}'),
                isThreeLine: true,
                trailing: const Chip(label: Text('Bağlı', style: TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: Colors.green),
              ),
            )),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('📴 Çevrimdışı Çalışma Kuyruğu (${queue.length})'),
            ElevatedButton.icon(
              icon: const Icon(Icons.sync, size: 16),
              label: const Text('Şimdi Eşitle', style: TextStyle(fontSize: 12)),
              onPressed: () {
                pdks.syncOfflineRecords();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Çevrimdışı kuyruktaki veriler bulutla eşitlendi.')));
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (queue.isEmpty)
          _buildEmptyText('Kuyrukta bekleyen çevrimdışı işlem yok. Tüm veriler eşitlenmiş durumda.')
        else
          ...queue.map((item) => Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.offline_pin, color: Colors.orange),
                  title: Text('İşlem: ${item.actionType.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('Kayıt: ${item.recordedAt.hour}:${item.recordedAt.minute}:${item.recordedAt.second} • Durum: ${item.syncStatus}'),
                ),
              )),
      ],
    );
  }

  // ===========================================================================
  // YARDIMCI BİLEŞENLER & DİYALOGLAR
  // ===========================================================================

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }

  Widget _buildEmptyText(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(child: Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 13))),
    );
  }

  Widget _buildMetricCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String body, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color c = Colors.green;
    String label = 'Düşük';
    if (priority == 'critical') {
      c = Colors.red;
      label = 'Kritik';
    } else if (priority == 'high') {
      c = Colors.orange;
      label = 'Yüksek';
    } else if (priority == 'medium') {
      c = Colors.blue;
      label = 'Orta';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c)),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color c = Colors.orange;
    String label = 'Açık';
    if (status == 'in_progress') {
      c = Colors.indigo;
      label = 'İşlemde';
    } else if (status == 'resolved') {
      c = Colors.green;
      label = 'Çözüldü';
    }
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 10, color: Colors.white)),
      backgroundColor: c,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  void _showAddShiftSwapDialog(BuildContext context) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vardiya Takas Talebi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Zeynep Kaya ile cuma günkü standart vardiyanızı takas etmek istiyor musunuz?'),
            const SizedBox(height: 10),
            TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Takas Nedeni')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              final pdks = context.read<PdksState>();
              pdks.addShiftSwapRequest(ShiftSwapRequest(
                id: 'swap_${DateTime.now().millisecondsSinceEpoch}',
                companyId: pdks.activeCompanyId,
                requesterEmployeeId: pdks.currentUser.id,
                requesterName: pdks.currentUser.fullName,
                targetEmployeeId: 2,
                targetName: 'Zeynep Kaya',
                shiftId: 1,
                shiftTitle: 'Standart Ofis Vardiyası',
                targetDate: DateTime.now().add(const Duration(days: 2)),
                reason: reasonCtrl.text.isNotEmpty ? reasonCtrl.text : 'Acil şahsi durum',
              ));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Takas talebiniz veritabanına iletildi.')));
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }

  void _showAddTicketDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Arıza / Bakım Bildirimi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Arıza Başlığı')),
            const SizedBox(height: 8),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Detaylı Açıklama'), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.isEmpty) return;
              final pdks = context.read<PdksState>();
              pdks.createHelpdeskTicket(HelpdeskTicket(
                id: 't_${DateTime.now().millisecondsSinceEpoch}',
                companyId: pdks.activeCompanyId,
                requesterId: pdks.currentUser.id,
                requesterName: pdks.currentUser.fullName,
                title: titleCtrl.text,
                description: descCtrl.text,
                priority: 'medium',
              ));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Arıza bildirimi kaydedildi.')));
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showAddAnnouncementDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    bool isMandatory = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Yeni Duyuru Yayınla'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Başlık')),
              const SizedBox(height: 8),
              TextField(controller: contentCtrl, decoration: const InputDecoration(labelText: 'İçerik'), maxLines: 3),
              CheckboxListTile(
                value: isMandatory,
                title: const Text('Zorunlu Okundu Onayı', style: TextStyle(fontSize: 13)),
                onChanged: (v) => setSt(() => isMandatory = v ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.isEmpty) return;
                final pdks = context.read<PdksState>();
                pdks.publishAnnouncement(CompanyAnnouncement(
                  id: 'ann_${DateTime.now().millisecondsSinceEpoch}',
                  companyId: pdks.activeCompanyId,
                  title: titleCtrl.text,
                  content: contentCtrl.text,
                  isMandatory: isMandatory,
                ));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Duyuru yayınlandı.')));
              },
              child: const Text('Yayınla'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddVisitorDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ziyaretçi Ön Kaydı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Ad Soyad')),
            const SizedBox(height: 8),
            TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: 'Ziyaretçi Şirket Adı')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty) return;
              final pdks = context.read<PdksState>();
              pdks.registerVisitor(VisitorRecord(
                id: 'vis_${DateTime.now().millisecondsSinceEpoch}',
                companyId: pdks.activeCompanyId,
                visitorFullName: nameCtrl.text,
                visitorCompany: companyCtrl.text,
                visitorPhone: '0555 000 11 22',
                hostEmployeeId: pdks.currentUser.id,
                hostEmployeeName: pdks.currentUser.fullName,
                purpose: 'Kurumsal Görüşme',
                expectedDate: DateTime.now(),
                qrPassCode: 'PASS-${DateTime.now().millisecondsSinceEpoch % 10000}',
              ));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ziyaretçi kaydedildi.')));
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showAddBookingDialog(BuildContext context) {
    String type = 'desk';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Hibrit Rezervasyon'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                value: 'desk',
                groupValue: type,
                title: const Text('Çalışma Masası (Masa B-07)'),
                onChanged: (v) => setSt(() => type = v!),
              ),
              RadioListTile<String>(
                value: 'meeting_room',
                groupValue: type,
                title: const Text('Toplantı Odası (Oda Vega - 6 Kişilik)'),
                onChanged: (v) => setSt(() => type = v!),
              ),
              RadioListTile<String>(
                value: 'parking',
                groupValue: type,
                title: const Text('Kapalı Otopark (P-12)'),
                onChanged: (v) => setSt(() => type = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () {
                final pdks = context.read<PdksState>();
                pdks.createHybridBooking(HybridBooking(
                  id: 'res_${DateTime.now().millisecondsSinceEpoch}',
                  companyId: pdks.activeCompanyId,
                  employeeId: pdks.currentUser.id,
                  employeeName: pdks.currentUser.fullName,
                  resourceType: type,
                  resourceCode: type == 'desk' ? 'Masa B-07' : (type == 'meeting_room' ? 'Oda Vega' : 'Otopark P-12'),
                  date: DateTime.now().add(const Duration(days: 1)),
                ));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rezervasyon oluşturuldu.')));
              },
              child: const Text('Onayla'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFeedbackDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    bool isAnon = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Geri Bildirim / Öneri'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Konu')),
              const SizedBox(height: 8),
              TextField(controller: contentCtrl, decoration: const InputDecoration(labelText: 'Öneri / Görüşünüz'), maxLines: 3),
              CheckboxListTile(
                value: isAnon,
                title: const Text('Anonim olarak ilet', style: TextStyle(fontSize: 13)),
                onChanged: (v) => setSt(() => isAnon = v ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.isEmpty) return;
                final pdks = context.read<PdksState>();
                pdks.submitFeedback(EmployeeFeedback(
                  id: 'fb_${DateTime.now().millisecondsSinceEpoch}',
                  companyId: pdks.activeCompanyId,
                  category: 'suggestion',
                  title: titleCtrl.text,
                  content: contentCtrl.text,
                  isAnonymous: isAnon,
                  submitterEmployeeId: isAnon ? null : pdks.currentUser.id,
                  submitterName: isAnon ? null : pdks.currentUser.fullName,
                ));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Geri bildiriminiz İK\'ya iletildi.')));
              },
              child: const Text('İlet'),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 13. KALİBRASYON VE CMMS BAKIM YÖNETİMİ (ISO 9001 / ISO 17025 UYUMLU)
  // ===========================================================================
  Widget _buildCalibrationAndCmmsTab() {
    final pdks = context.watch<PdksState>();
    final equipments = pdks.equipmentRecords;
    final workOrders = pdks.workOrders;

    final totalEq = equipments.length;
    final quarantinedCount = equipments.where((e) => e.isQuarantined).length;
    final warningCount = equipments.where((e) => e.computedStatus.startsWith('warning_')).length;
    final openOrders = workOrders.where((w) => w.status == 'open' || w.status == 'in_progress').length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.precision_manufacturing_rounded, color: Color(0xFF38BDF8), size: 28),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kalibrasyon & CMMS Bakım Portalı',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'ISO 9001:2015 & ISO 17025 Standartlarına Tam Uyumlu',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Süresi Dolanları Tara & Karantinaya Al',
                      icon: const Icon(Icons.security_update_warning_rounded, color: Color(0xFFF59E0B)),
                      onPressed: () async {
                        await pdks.checkAndQuarantineExpiredEquipments();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kalibrasyon taraması tamamlandı, süresi dolanlar karantinaya alındı.')),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('Toplam Ekipman', totalEq.toString(), Colors.white),
                    _buildStatCol('Karantinada', quarantinedCount.toString(), quarantinedCount > 0 ? const Color(0xFFEF4444) : Colors.white70),
                    _buildStatCol('Yaklaşan', warningCount.toString(), warningCount > 0 ? const Color(0xFFF59E0B) : Colors.white70),
                    _buildStatCol('Açık İş Emri', openOrders.toString(), const Color(0xFF38BDF8)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ekipman Sicil Kartları (Envanter)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_task_rounded, size: 16),
              label: const Text('Yeni İş Emri Aç', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              onPressed: () => _showCreateWorkOrderDialog(context, pdks),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...equipments.map((eq) {
          final isQuar = eq.isQuarantined;
          final status = eq.computedStatus;
          Color statusBg;
          String statusText;

          if (isQuar) {
            statusBg = const Color(0xFFEF4444);
            statusText = '🚨 KARANTİNADA / KULLANIM DIŞI';
          } else if (status == 'warning_3d') {
            statusBg = const Color(0xFFDC2626);
            statusText = '3 Gün Kaldı (Kritik)';
          } else if (status == 'warning_15d') {
            statusBg = const Color(0xFFEA580C);
            statusText = '15 Gün Kaldı';
          } else if (status == 'warning_30d') {
            statusBg = const Color(0xFFD97706);
            statusText = '30 Gün Kaldı';
          } else {
            statusBg = const Color(0xFF10B981);
            statusText = 'Kalibrasyon Geçerli';
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(6)),
                        child: Text(eq.equipmentCode, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: statusBg.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                        child: Text(statusText, style: TextStyle(color: statusBg, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(eq.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('${eq.brandModel} • ${eq.department} • ${eq.location}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Standart: ${eq.referenceStandard}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          Text('Tolerans: ${eq.toleranceLimit}', style: const TextStyle(fontSize: 11, color: Colors.black87)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Son Kalibrasyon: ${eq.lastCalibrationDate.day}.${eq.lastCalibrationDate.month}.${eq.lastCalibrationDate.year}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          Text('Gelecek: ${eq.nextCalibrationDate.day}.${eq.nextCalibrationDate.month}.${eq.nextCalibrationDate.year}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  if (eq.quarantineReason != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(6)),
                      child: Text('Gerekçe: ${eq.quarantineReason}', style: const TextStyle(color: Color(0xFF991B1B), fontSize: 11)),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        icon: Icon(isQuar ? Icons.lock_open_rounded : Icons.gavel_rounded, size: 14),
                        label: Text(isQuar ? 'Karantinayı Kaldır' : 'Karantinaya Al', style: const TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isQuar ? const Color(0xFF10B981) : const Color(0xFFDC2626),
                        ),
                        onPressed: () => pdks.toggleEquipmentQuarantine(
                          eq.id,
                          reason: isQuar ? 'Yeniden doğrulama yapıldı.' : 'Periyodik kontrol / güvenlik şüphesi.',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        const Text(
          'Periyodik Bakım ve Arıza İş Emirleri (CMMS)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...workOrders.map((wo) {
          final isUrgent = wo.isUrgent;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (isUrgent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(4)),
                              child: const Text('🚨 ACİL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                            ),
                          Text('${wo.equipmentCode} • ${wo.equipmentName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(wo.status.toUpperCase(), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(wo.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(wo.description, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                  const Divider(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Teknisyen: ${wo.assignedTechnicianName ?? "Atanmadı"}', style: const TextStyle(fontSize: 11, color: Colors.indigo, fontWeight: FontWeight.w600)),
                      if (wo.totalCost > 0)
                        Text('Maliyet: ${wo.totalCost.toStringAsFixed(0)} ₺', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // 14. 4857 MEVZUAT KURAL MOTORU VE DEĞİŞTİRİLEMEZ DENETİM (AUDIT LOG)
  // ===========================================================================
  Widget _buildLaborLawAndAuditTab() {
    final pdks = context.watch<PdksState>();
    final auditLogs = pdks.auditLogs;
    final lockedPeriods = pdks.lockedPeriods;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.gavel_rounded, color: Color(0xFFF59E0B), size: 28),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('4857 İş Kanunu Mevzuat Motoru & KVKK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Otomatik Yasal Sınır, Mola Kesintisi ve Denetim İzleri', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                  child: const Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('• Kademeli Ara Dinlenme:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          Text('≤4s: 15dk | 4-7.5s: 30dk | >7.5s: 60dk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('• Gece Çalışması Yasal Sınırı:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          Text('20:00 - 06:00 arası azami 7.5 saat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('• Günlük Azami Çalışma Sınırı:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          Text('4857 Md.63 uyarınca azami 11 saat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('• Yıllık Fazla Mesai Sınırı:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          Text('4857 Md.41 uyarınca azami 270 saat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('• Yaş/Kıdem Yıllık İzin Kuralı:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          Text('18 altı veya 50+ yaş için asgari 20 gün', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bordro Kilitli Puantaj Dönemleri:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Wrap(
                      spacing: 6,
                      children: lockedPeriods.map((p) => Chip(
                        label: Text('🔒 $p', style: const TextStyle(fontSize: 10, color: Colors.white)),
                        backgroundColor: const Color(0xFFDC2626),
                        padding: EdgeInsets.zero,
                      )).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Değiştirilemez Denetim Kayıtları (Immutable Audit Log)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...auditLogs.map((log) => Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                      child: Text(log.actionType, style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                    Text('${log.timestamp.day}.${log.timestamp.month}.${log.timestamp.year} ${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Kullanıcı: ${log.userName} (${log.userRole}) • IP: ${log.ipAddress}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                if (log.oldValue != null || log.newValue != null) ...[
                  const SizedBox(height: 4),
                  if (log.oldValue != null)
                    Text('Eski Değer: ${log.oldValue}', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                  if (log.newValue != null)
                    Text('Yeni Değer: ${log.newValue}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F766E))),
                ],
                const Divider(height: 12),
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'SHA-256 İmzası: ${log.hashSignature.substring(0, 16)}...',
                        style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  void _showCreateWorkOrderDialog(BuildContext context, PdksState pdks) {
    final equipments = pdks.equipmentRecords;
    if (equipments.isEmpty) return;

    String selectedEqId = equipments.first.id;
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String priority = 'normal';
    int? selectedTechId = pdks.employees.where((e) => e.role == UserRole.technician).firstOrNull?.id;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Yeni CMMS Bakım / Arıza İş Emri'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedEqId,
                  decoration: const InputDecoration(labelText: 'Ekipman Seçiniz'),
                  items: equipments.map((e) => DropdownMenuItem(
                    value: e.id,
                    child: Text('${e.equipmentCode} - ${e.name} ${e.isQuarantined ? "🚨(Karantina)" : ""}', overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (val) => setModalState(() => selectedEqId = val!),
                ),
                const SizedBox(height: 10),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'İş Emri Başlığı')),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Açıklama / Arıza Detayı')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Öncelik Seviyesi'),
                  items: const [
                    DropdownMenuItem(value: 'normal', child: Text('Normal Bakım')),
                    DropdownMenuItem(value: 'high', child: Text('Yüksek Öncelik')),
                    DropdownMenuItem(value: 'urgent', child: Text('🚨 ACİL ARIZA (Vardiyadaki Ekiplere Bildir)')),
                  ],
                  onChanged: (val) => setModalState(() => priority = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty) return;
                final res = await pdks.createMaintenanceWorkOrder(
                  equipmentId: selectedEqId,
                  title: titleCtrl.text,
                  description: descCtrl.text,
                  priority: priority,
                  technicianId: selectedTechId,
                );
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res.message),
                      backgroundColor: res.success ? const Color(0xFF10B981) : const Color(0xFFDC2626),
                    ),
                  );
                }
              },
              child: const Text('İş Emrini Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCol(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
      ],
    );
  }

  // ===========================================================================
  // 15. PDKS AI, 4857 MEVZUAT ASİSTANI & SAHTE GEÇİŞ (ANOMALİ) TESPİTİ
  // ===========================================================================
  Widget _buildAiAndAnomalyTab() {
    final pdks = context.watch<PdksState>();
    final anomalies = pdks.anomalies;
    final chatMessages = pdks.aiMessages;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('🤖 4857 Sayılı İş Kanunu & PDKS AI Asistanı'),
        const SizedBox(height: 6),
        Text(
          'Mevzuat kuralları (45 saat haftalık limit, 270 saat yıllık tavan, gece vardiyası 7.5 saat, 11 saat dinlenme süresi) doğrultusunda anlık yapay zeka danışmanı.',
          style: TextStyle(fontSize: 12, color: AppColors.textSub(context)),
        ),
        const SizedBox(height: 12),

        // Hızlı Soru Çipleri
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildAiQuickChip('Yıllık 270 saat fazla mesai kuralı'),
            _buildAiQuickChip('Gece vardiyasında 7.5 saati aşan çalışma'),
            _buildAiQuickChip('Vardiyalar arası 11 saat dinlenme'),
            _buildAiQuickChip('Süt ve mazeret izni hesaplama'),
          ],
        ),
        const SizedBox(height: 12),

        // Sohbet Kutusu (Chat Window)
        Container(
          height: 260,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: chatMessages.isEmpty
              ? const Center(
                  child: Text('AI Asistanına bir soru yönelterek mevzuat danışmanlığı alabilirsiniz.',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                )
              : ListView.builder(
                  itemCount: chatMessages.length,
                  itemBuilder: (ctx, idx) {
                    final msg = chatMessages[idx];
                    final isAi = !msg.isUser;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isAi
                              ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : Colors.white)
                              : const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(isAi ? Icons.psychology_rounded : Icons.person_rounded,
                                    size: 14, color: isAi ? const Color(0xFF818CF8) : Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  isAi ? 'PDKS AI Mevzuat Asistanı' : 'Siz',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isAi ? const Color(0xFF818CF8) : Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg.message,
                              style: TextStyle(
                                fontSize: 13,
                                color: isAi ? AppColors.text(context) : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 8),

        // Soru Gönderme Girişi
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _aiPromptController,
                decoration: InputDecoration(
                  hintText: '4857 İş Kanunu veya vardiya hakkında soru sorun...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  filled: true,
                  fillColor: AppColors.cardBg(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                onSubmitted: (val) => _sendAiQuery(val),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isAiResponding ? null : () => _sendAiQuery(_aiPromptController.text),
              child: _isAiResponding
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, size: 18),
            ),
          ],
        ),

        const SizedBox(height: 24),
        _buildSectionHeader('🚨 Sahte Geçiş (Anti-Buddy Punching) & Anomali Denetimi'),
        const SizedBox(height: 6),
        Text(
          'GPS Sahteciliği (Mock Location), eşzamanlı turnike kart basımı ve yüz uyuşmazlığı gibi hileli hareketler otomatik yakalanır.',
          style: TextStyle(fontSize: 12, color: AppColors.textSub(context)),
        ),
        const SizedBox(height: 12),

        if (anomalies.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Tebrikler! Tespit edilmiş herhangi bir sahte geçiş veya GPS anomalisi bulunmuyor.',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.green)),
                ),
              ],
            ),
          )
        else
          ...anomalies.map((anom) {
            final isResolved = anom.status == 'resolved' || anom.status == 'dismissed';
            final isCritical = anom.severity == 'critical';
            final badgeColor = isCritical ? Colors.red : Colors.orange;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: AppColors.cardBg(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isResolved ? Colors.grey.withOpacity(0.2) : badgeColor.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: badgeColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 14, color: badgeColor),
                              const SizedBox(width: 4),
                              Text(anom.severityLabel, style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isResolved ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isResolved ? 'Çözüldü' : 'İnceleme Bekliyor',
                            style: TextStyle(
                              color: isResolved ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      anom.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text('Personel: ${anom.employeeName}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(anom.description, style: TextStyle(fontSize: 12, color: AppColors.text(context))),
                    const SizedBox(height: 6),
                    Text(
                      'Zaman: ${anom.detectedAt.day}.${anom.detectedAt.month}.${anom.detectedAt.year} ${anom.detectedAt.hour}:${anom.detectedAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 11, color: AppColors.textSub(context)),
                    ),
                    if (anom.resolutionNote != null && anom.resolutionNote!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Yönetici Kararı: ${anom.resolutionNote}',
                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                    if (!isResolved) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.rule_folder_rounded, size: 16),
                          label: const Text('İncele & Karara Bağla', style: TextStyle(fontSize: 12)),
                          onPressed: () => _showResolveAnomalyDialog(anom),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),

        const SizedBox(height: 24),
        _buildSectionHeader('🧠 Akıllı Vardiya Optimizasyonu (AI Shift Planner)'),
        const SizedBox(height: 6),
        Text(
          'İş Kanunu 11 saatlik dinlenme periyodunu ve haftalık 45 saatlik sınırları gözeterek en verimli vardiya dağıtımını önerir.',
          style: TextStyle(fontSize: 12, color: AppColors.textSub(context)),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.auto_awesome_rounded),
          label: const Text('Yapay Zeka ile Vardiya Planını Optimize Et'),
          onPressed: () {
            final opt = pdks.generateSmartShiftPlan(department: _selectedShiftDept ?? 'Tüm Departmanlar');
            setState(() {
              _latestOptimization = opt;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Akıllı vardiya optimizasyonu tamamlandı. 4857 Sayılı Kanun kısıtları doğrulandı.'),
                backgroundColor: Color(0xFF10B981),
              ),
            );
          },
        ),
        if (_latestOptimization != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.indigo.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Departman: ${_latestOptimization!.department}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF6366F1))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Kapsama: %${_latestOptimization!.coverageScorePercent.toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Dönem: ${_latestOptimization!.weekLabel} • Toplam Vardiya: ${_latestOptimization!.totalAssignedShifts} • Tahmini İşçilik: ₺${_latestOptimization!.estimatedLaborCostTL.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
                Text('Yapay Zeka Notları:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSub(context))),
                ..._latestOptimization!.optimizationNotes.map((note) => Text('• $note', style: const TextStyle(fontSize: 11))),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAiQuickChip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 11)),
      backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
      side: BorderSide(color: const Color(0xFF6366F1).withOpacity(0.3)),
      onPressed: () => _sendAiQuery(text),
    );
  }

  Future<void> _sendAiQuery(String prompt) async {
    if (prompt.trim().isEmpty || _isAiResponding) return;
    _aiPromptController.clear();
    setState(() => _isAiResponding = true);
    final pdks = context.read<PdksState>();
    await pdks.askPdkAiAssistant(prompt);
    if (mounted) {
      setState(() => _isAiResponding = false);
    }
  }

  void _showResolveAnomalyDialog(PdkAnomalyRecord anom) {
    final noteCtrl = TextEditingController();
    bool isDismissed = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: Text('Anomaliyi Karara Bağla: ${anom.title}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Personel: ${anom.employeeName}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(anom.description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'İnceleme / Açıklama Notu',
                  hintText: 'Örn: Kamera kayıtları incelendi, teknik hata olduğu anlaşıldı...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: isDismissed,
                title: const Text('Bu uyarıyı asılsız (dismissed/göz ardı) olarak kapat', style: TextStyle(fontSize: 12)),
                onChanged: (val) => setDState(() => isDismissed = val ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
              onPressed: () async {
                final note = noteCtrl.text.trim().isEmpty ? 'Yönetici tarafından kapatıldı.' : noteCtrl.text.trim();
                final pdks = context.read<PdksState>();
                await pdks.resolveAnomaly(
                  anomalyId: anom.id,
                  resolutionNote: note,
                  isDismissed: isDismissed,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Kararı Onayla'),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 16. KİOSK TABLET YÜZ TANIMA & TURNİKE TCP/IP IOT
  // ===========================================================================
  Widget _buildKioskAndTurnstileTab() {
    final pdks = context.watch<PdksState>();
    final terminals = pdks.kioskTerminals;
    final enrollments = pdks.faceEnrollments;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('📸 Fabrika Kiosk Tableti & Turnike TCP/IP Entegrasyonu'),
        const SizedBox(height: 6),
        Text(
          'Giriş kapılarına asılan tabletler (Android/iOS/Windows) üzerinden canlı yüz tanıma, anti-spoofing ve turnike röle tetikleme altyapısı.',
          style: TextStyle(fontSize: 12, color: AppColors.textSub(context)),
        ),
        const SizedBox(height: 16),

        // Kiosk Başlatma Aksiyon Kartı
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tablet_mac_rounded, color: Colors.cyanAccent, size: 32),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Duvar Tableti / Kiosk Turnike Modu',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    SizedBox(height: 4),
                    Text('Tam ekran kamera vizörü, liveness canlılık tespiti ve sesli karşılama.',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.fullscreen_rounded),
                label: const Text('Kiosk Modunu Aç'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const KioskTerminalScreen()),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        _buildSectionHeader('🚪 Aktif Turnike Kiosklar & TCP/IP Röle Cihazları'),
        const SizedBox(height: 12),
        ...terminals.map((term) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            color: AppColors.cardBg(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: term.isOnline ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                child: Icon(Icons.sensor_door_rounded, color: term.isOnline ? Colors.green : Colors.red),
              ),
              title: Text(term.terminalName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(
                'Konum: ${term.location} • TCP/IP: ${term.ipAddress}:${term.tcpPort} • Mod: ${term.mode.toUpperCase()} • Bugün: ${term.totalScansToday} Geçiş',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: term.isOnline ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  term.isOnline ? 'Çevrimiçi' : 'Bağlantı Yok',
                  style: TextStyle(color: term.isOnline ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 24),
        _buildSectionHeader('👤 Biyometrik Yüz Kayıtları & Canlılık (Liveness) Durumu'),
        const SizedBox(height: 12),
        ...enrollments.map((enr) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.15),
                  child: const Icon(Icons.face_retouching_natural_rounded, color: Color(0xFF6366F1), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(enr.employeeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('Hash: ${enr.faceVectorHash.substring(0, 16)}... • Güven: %${(enr.confidenceScore * 100).toInt()}',
                          style: TextStyle(fontSize: 11, color: AppColors.textSub(context))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: enr.isLivenessVerified ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    enr.isLivenessVerified ? 'Canlılık Doğrulandı ✅' : 'Riskli',
                    style: TextStyle(color: enr.isLivenessVerified ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // 17. 5070 SAYILI E-İMZA & BORDRO / ERP İHRACAT MOTORU
  // ===========================================================================
  Widget _buildDigitalSignatureAndErpTab() {
    final pdks = context.watch<PdksState>();
    final signedDocs = pdks.signedDocuments;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildSectionHeader('✍️ 5070 Sayılı E-İmza & Zaman Damgalı Belgeler')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.draw_rounded, size: 16),
              label: const Text('Yeni Belge İmzala', style: TextStyle(fontSize: 12)),
              onPressed: () async {
                final signed = await DigitalSignaturePadDialog.show(
                  context: context,
                  documentType: 'payroll',
                  documentTitle: '2026/10 Bordro Tahakkuk Onayı',
                  period: '2026-10',
                );
                if (signed != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Belge başarıyla 5070 zaman damgalı imzalandı: ${signed.documentTitle}'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '5070 Sayılı Elektronik İmza Kanunu md. 5 uyarınca güvenli zaman damgası ve kriptografik SHA-256 doğrulama ile ıslak imza hükmündedir.',
          style: TextStyle(fontSize: 12, color: AppColors.textSub(context)),
        ),
        const SizedBox(height: 12),

        ...signedDocs.map((doc) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            color: AppColors.cardBg(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(doc.documentTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.greenAccent),
                        ),
                        child: const Text('5070 Uyumlu', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('İmzacı: ${doc.employeeName} • Dönem: ${doc.period} • IP: ${doc.signerIp}',
                      style: TextStyle(fontSize: 11, color: AppColors.textSub(context))),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Zaman Damgası Hash (SHA-256): ${doc.timeStampHash}',
                        style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.blueGrey)),
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 24),
        _buildSectionHeader('📊 ERP & Bordro İhracat Motoru (Logo, Mikro, SAP, SGK APHB)'),
        const SizedBox(height: 6),
        Text(
          'Aylık puantaj icmalini ve fazla mesaileri kurumsal ERP sistemlerinin doğrudan içe aktarabileceği standart formatlara dönüştürün.',
          style: TextStyle(fontSize: 12, color: AppColors.textSub(context)),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedErpFormat,
                decoration: InputDecoration(
                  labelText: 'ERP / Çıktı Formatı',
                  filled: true,
                  fillColor: AppColors.cardBg(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                items: const [
                  DropdownMenuItem(value: 'logo', child: Text('Logo Tiger XML')),
                  DropdownMenuItem(value: 'mikro', child: Text('Mikro Standart CSV')),
                  DropdownMenuItem(value: 'sap', child: Text('SAP S/4HANA JSON')),
                  DropdownMenuItem(value: 'sgk', child: Text('SGK Aylık Prim & Hizmet (APHB)')),
                ],
                onChanged: (val) => setState(() => _selectedErpFormat = val ?? 'logo'),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.file_download_rounded),
              label: const Text('Çıktı Üret'),
              onPressed: () {
                final out = pdks.exportPayrollData(format: _selectedErpFormat, period: _selectedErpPeriod);
                setState(() => _generatedErpContent = out);
              },
            ),
          ],
        ),

        if (_generatedErpContent != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Üretilen Dosya Çıktısı (${_selectedErpFormat.toUpperCase()}):',
                        style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 18),
                      tooltip: 'Panoya Kopyala',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _generatedErpContent!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ERP çıktı metni panoya kopyalandı.')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SelectableText(
                  _generatedErpContent!,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // 18. İSG, RAMAK KALA (NEAR-MISS) VE TEHLİKELİ BÖLGE GEOFENCE
  // ===========================================================================
  Widget _buildOccupationalSafetyTab() {
    final pdks = context.watch<PdksState>();
    final nearMisses = pdks.nearMissReports;
    final hazardZones = pdks.hazardZones;
    final certs = pdks.safetyCertificates;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildSectionHeader('🦺 6331 Sayılı İSG & Ramak Kala Yönetimi')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.warning_rounded, size: 16),
              label: const Text('Ramak Kala Bildir', style: TextStyle(fontSize: 12)),
              onPressed: () => _showSubmitNearMissDialog(),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'İş kazalarının önlenmesi amacıyla ramak kala olayları anında İSG uzmanına ve hekime düşer.',
          style: TextStyle(fontSize: 12, color: AppColors.textSub(context)),
        ),
        const SizedBox(height: 12),

        ...nearMisses.map((nm) {
          final isCritical = nm.riskLevel == 'critical';
          final badgeColor = isCritical ? Colors.red : Colors.orange;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            color: AppColors.cardBg(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(nm.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: badgeColor),
                        ),
                        child: Text(nm.riskLabel, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Birim: ${nm.department} • Yer: ${nm.locationDetail} • Bildiren: ${nm.reporterName}',
                      style: TextStyle(fontSize: 11, color: AppColors.textSub(context))),
                  const SizedBox(height: 6),
                  Text(nm.description, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 24),
        _buildSectionHeader('📍 Tehlikeli Bölge Geofence & Zorunlu KKD Alanları'),
        const SizedBox(height: 6),
        Text(
          'Fabrika içerisinde belirlenen tehlikeli bölgelere girildiğinde zorunlu Kişisel Koruyucu Donanım (KKD) uyarısı verilir.',
          style: TextStyle(fontSize: 12, color: AppColors.textSub(context)),
        ),
        const SizedBox(height: 12),

        ...hazardZones.map((zone) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            color: AppColors.cardBg(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(zone.zoneName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('${zone.radiusMeters.toInt()}m Yarıçap Geofence',
                          style: TextStyle(fontSize: 11, color: AppColors.textSub(context))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(zone.warningMessage, style: const TextStyle(fontSize: 12, color: Colors.orange)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: zone.requiredPPE.map((ppe) {
                      return Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: const Icon(Icons.shield_rounded, size: 14, color: Colors.blue),
                        label: Text(ppe, style: const TextStyle(fontSize: 11)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 24),
        _buildSectionHeader('📅 İSG Eğitim & Sağlık Sertifikası Takvimi'),
        const SizedBox(height: 12),
        ...certs.map((c) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  (c.daysUntilExpiry <= 30 && !c.isExpired) ? Icons.access_time_filled_rounded : Icons.verified_rounded,
                  color: c.isExpired ? Colors.red : (c.daysUntilExpiry <= 30 ? Colors.orange : Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('Personel: ${c.employeeName} • Bitiş: ${c.expiryDate.day}.${c.expiryDate.month}.${c.expiryDate.year}',
                          style: TextStyle(fontSize: 11, color: AppColors.textSub(context))),
                    ],
                  ),
                ),
                Text(
                  c.statusBadge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: c.isExpired ? Colors.red : (c.daysUntilExpiry <= 30 ? Colors.orange : Colors.green),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showSubmitNearMissDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final deptCtrl = TextEditingController(text: 'Üretim / İmalat');
    final locCtrl = TextEditingController(text: 'D Blok Pres Hattı No:3');
    String risk = 'high';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('🚨 Ramak Kala (Near-Miss) Bildir'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Olay Başlığı')),
                const SizedBox(height: 8),
                TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Konum / Hat / Bölüm')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: risk,
                  decoration: const InputDecoration(labelText: 'Risk Seviyesi'),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Düşük')),
                    DropdownMenuItem(value: 'medium', child: Text('Orta')),
                    DropdownMenuItem(value: 'high', child: Text('Yüksek Risk')),
                    DropdownMenuItem(value: 'critical', child: Text('🚨 Kritik / Acil Tehlike')),
                  ],
                  onChanged: (val) => setDState(() => risk = val ?? 'high'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Olay Açıklaması & Alınan Geçici Önlem'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final pdks = context.read<PdksState>();
                final nav = Navigator.of(ctx);
                final messenger = ScaffoldMessenger.of(context);
                await pdks.submitNearMissReport(
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  department: deptCtrl.text.trim(),
                  locationDetail: locCtrl.text.trim(),
                  riskLevel: risk,
                );
                nav.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Ramak kala olayı başarıyla bildirildi ve İSG uzmanına iletildi.')),
                );
              },
              child: const Text('Bildirimi Gönder'),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 19. SAHA TELSİZİ (PUSH-TO-TALK / PTT) & SESLİ İLETİŞİM
  // ===========================================================================
  Widget _buildPushToTalkTab() {
    final pdks = context.watch<PdksState>();
    final channels = pdks.pttChannels;
    final bursts = pdks.pttBursts.where((b) => b.channelId == _activePttChannelId).toList();
    final activeChan = channels.isEmpty
        ? PttChannel(
            id: 'ptt_01',
            companyId: 'cmp_acme',
            channelName: 'Kanal 1: Saha Güvenlik & Amirleri',
            description: 'Nizamiye, çevre güvenlik ve ziyaretçi geçiş telsiz kanalı.',
            activeParticipantsCount: 6,
          )
        : channels.firstWhere((c) => c.id == _activePttChannelId, orElse: () => channels.first);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('📻 Kurumsal Saha Telsizi (Bas-Konuş / Push-to-Talk)'),
        const SizedBox(height: 6),
        Text(
          'Fabrika, saha ve güvenlik ekipleri için anlık sesli telsiz kanalları ve otomatik ses-metin (STT) transkripsiyonu.',
          style: TextStyle(fontSize: 12, color: AppColors.textSub(context)),
        ),
        const SizedBox(height: 16),

        // Telsiz Kanal Seçicisi
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: channels.map((c) {
              final isSel = c.id == _activePttChannelId;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('${c.channelName} (${c.activeParticipantsCount} Çevrimiçi)'),
                  selected: isSel,
                  selectedColor: const Color(0xFF6366F1),
                  labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.text(context), fontWeight: FontWeight.bold),
                  onSelected: (val) {
                    if (val) setState(() => _activePttChannelId = c.id);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Büyük PTT Bas-Konuş Konsolu
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _isTransmittingVoice ? Colors.redAccent : Colors.grey.withOpacity(0.2), width: 2),
          ),
          child: Column(
            children: [
              Text(
                'Aktif Kanal: ${activeChan.channelName}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                activeChan.description,
                style: TextStyle(fontSize: 12, color: AppColors.textSub(context)),
              ),
              const SizedBox(height: 20),

              // PTT Butonu
              GestureDetector(
                onTapDown: (_) => setState(() => _isTransmittingVoice = true),
                onTapUp: (_) async {
                  setState(() => _isTransmittingVoice = false);
                  await pdks.transmitPttBurst(
                    channelId: _activePttChannelId,
                    durationSeconds: 3,
                    spokenText: 'Kanal ${activeChan.channelName} üzerinden bas-konuş ses paketi iletildi.',
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isTransmittingVoice
                          ? [Colors.redAccent, Colors.red.shade900]
                          : [const Color(0xFF6366F1), const Color(0xFF4338CA)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isTransmittingVoice ? Colors.redAccent : const Color(0xFF6366F1)).withOpacity(0.5),
                        blurRadius: _isTransmittingVoice ? 25 : 12,
                        spreadRadius: _isTransmittingVoice ? 6 : 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isTransmittingVoice ? Icons.mic_rounded : Icons.radio_button_checked_rounded,
                          color: Colors.white, size: 36),
                      const SizedBox(height: 4),
                      Text(
                        _isTransmittingVoice ? 'YAYINDA' : 'BAS-KONUŞ',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isTransmittingVoice
                    ? '🎙️ Sesiniz kanaldaki tüm telsiz cihazlarına anlık iletiliyor...'
                    : 'Konuşmak için butona basılı tutunuz veya dokununuz.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: _isTransmittingVoice ? FontWeight.bold : FontWeight.normal,
                  color: _isTransmittingVoice ? Colors.redAccent : AppColors.textSub(context),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.campaign_rounded, size: 16),
                label: const Text('Özel Sesli Anons Gönder'),
                onPressed: () => _showPttVoiceAnnouncementDialog(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        _buildSectionHeader('💬 Son Telsiz Konuşmaları ve Ses-Metin (STT) Kayıtları'),
        const SizedBox(height: 12),

        if (bursts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Bu kanalda henüz yapılmış bir telsiz anonsu bulunmuyor.', style: TextStyle(color: Colors.grey)),
          )
        else
          ...bursts.map((burst) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: AppColors.cardBg(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.15),
                  child: const Icon(Icons.volume_up_rounded, color: Color(0xFF6366F1)),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(burst.speakerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('${burst.durationSeconds} sn',
                        style: TextStyle(fontSize: 11, color: AppColors.textSub(context), fontWeight: FontWeight.bold)),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      burst.transcriptText,
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${burst.timestamp.hour.toString().padLeft(2, '0')}:${burst.timestamp.minute.toString().padLeft(2, '0')}:${burst.timestamp.second.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 10, color: AppColors.textSub(context)),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  void _showPttVoiceAnnouncementDialog() {
    final textCtrl = TextEditingController(text: 'Dikkat! 2 Nolu hatta konveyör bandı durduruldu, teknisyen yönlendirilsin.');
    const duration = 4;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('📻 Yeni Telsiz Anonsu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textCtrl,
              decoration: const InputDecoration(
                labelText: 'Anons Metni (Otomatik Seslendirilecek)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
            onPressed: () async {
              if (textCtrl.text.trim().isEmpty) return;
              final pdks = context.read<PdksState>();
              await pdks.transmitPttBurst(
                channelId: _activePttChannelId,
                durationSeconds: duration,
                spokenText: textCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Kanala Anons Et'),
          ),
        ],
      ),
    );
  }
}
