import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/shift_swap_request.dart';
import '../../models/helpdesk_ticket.dart';
import '../../models/company_announcement.dart';
import '../../models/visitor_record.dart';
import '../../models/hybrid_booking.dart';
import '../../models/employee_feedback.dart';
import '../../state/pdks_state.dart';

class EnterpriseHubScreen extends StatefulWidget {
  final int initialTabIndex;
  const EnterpriseHubScreen({super.key, this.initialTabIndex = 0});

  @override
  State<EnterpriseHubScreen> createState() => _EnterpriseHubScreenState();
}

class _EnterpriseHubScreenState extends State<EnterpriseHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
            Text('15 Gelişmiş İK, Tesis & Operasyon Modülü', style: TextStyle(fontSize: 11, color: Colors.white70)),
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
}
