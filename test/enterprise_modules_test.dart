import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdks_flutter/core/services/database_service.dart';
import 'package:pdks_flutter/models/shift_swap_request.dart';
import 'package:pdks_flutter/models/helpdesk_ticket.dart';
import 'package:pdks_flutter/models/company_announcement.dart';
import 'package:pdks_flutter/models/personnel_file.dart';
import 'package:pdks_flutter/models/training_and_skill.dart';
import 'package:pdks_flutter/models/performance_goal.dart';
import 'package:pdks_flutter/models/visitor_record.dart';
import 'package:pdks_flutter/models/hybrid_booking.dart';
import 'package:pdks_flutter/models/organization_branch.dart';
import 'package:pdks_flutter/models/integration_and_sync.dart';
import 'package:pdks_flutter/models/employee_feedback.dart';
import 'package:pdks_flutter/state/pdks_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DatabaseService.instance.init(forceReload: true);
  });

  group('15 Kurumsal Modül Veritabanı ve Kalıcılık Testleri', () {
    test('1. Tüm 15 modülün varsayılan veritabanı tohum verileri başarıyla yüklenmeli', () async {
      final db = DatabaseService.instance;

      expect(db.getAllShiftSwaps().isNotEmpty, true, reason: 'Vardiya takasları yüklenmeli');
      expect(db.getAllOpenShiftSlots().isNotEmpty, true, reason: 'Açık vardiyalar yüklenmeli');
      expect(db.getAllHelpdeskTickets().isNotEmpty, true, reason: 'Teknik destek talepleri yüklenmeli');
      expect(db.getAllAnnouncements().isNotEmpty, true, reason: 'Şirket duyuruları yüklenmeli');
      expect(db.getAllDocuments().isNotEmpty, true, reason: 'Özlük belgeleri yüklenmeli');
      expect(db.getAllOnboardingTasks().isNotEmpty, true, reason: 'Onboarding görevleri yüklenmeli');
      expect(db.getAllTrainingCourses().isNotEmpty, true, reason: 'Eğitim kursları yüklenmeli');
      expect(db.getAllTrainingRecords().isNotEmpty, true, reason: 'Eğitim kayıtları yüklenmeli');
      expect(db.getAllPerformanceGoals().isNotEmpty, true, reason: 'Performans hedefleri yüklenmeli');
      expect(db.getAllVisitorRecords().isNotEmpty, true, reason: 'Ziyaretçi kayıtları yüklenmeli');
      expect(db.getAllHybridBookings().isNotEmpty, true, reason: 'Hibrit rezervasyonlar yüklenmeli');
      expect(db.getAllCompanyBranches().isNotEmpty, true, reason: 'Şube ve tesisler yüklenmeli');
      expect(db.getAllApprovalDelegations().isNotEmpty, true, reason: 'Vekaletler yüklenmeli');
      expect(db.getAllIntegrationEndpoints().isNotEmpty, true, reason: 'Entegrasyon uç noktaları yüklenmeli');
      expect(db.getAllOfflineSyncItems().isNotEmpty, true, reason: 'Çevrimdışı senkronizasyon kuyruğu yüklenmeli');
      expect(db.getAllEmployeeFeedbacks().isNotEmpty, true, reason: 'Geri bildirim ve anketler yüklenmeli');
    });

    test('2. Vardiya Takası ve Boş Vardiya CRUD işlemleri veritabanına kaydedilmeli', () async {
      final db = DatabaseService.instance;

      final swap = ShiftSwapRequest(
        id: 'swap_test_01',
        companyId: 'cmp_acme',
        requesterEmployeeId: 1,
        requesterName: 'Ahmet Yılmaz',
        targetEmployeeId: 2,
        targetName: 'Mehmet Demir',
        shiftId: 101,
        shiftTitle: 'Sabah Vardiyası (08:00 - 16:00)',
        targetDate: DateTime.now().add(const Duration(days: 1)),
        reason: 'Sınav sebebiyle takas talebi',
      );
      await db.insertShiftSwap(swap);
      expect(db.getAllShiftSwaps().any((s) => s.id == 'swap_test_01'), true);

      await db.updateShiftSwapStatus('swap_test_01', 'approved', 'Yönetici');
      final fetched = db.getAllShiftSwaps().firstWhere((s) => s.id == 'swap_test_01');
      expect(fetched.status, 'approved');

      final openSlot = OpenShiftSlot(
        id: 'open_slot_test_01',
        companyId: 'cmp_acme',
        shiftId: 102,
        shiftTitle: 'Hafta Sonu Acil Destek Vardiyası',
        date: DateTime.now().add(const Duration(days: 3)),
        requiredHeadcount: 2,
        appliedEmployeeIds: [1],
      );
      await db.insertOpenShiftSlot(openSlot);
      expect(db.getAllOpenShiftSlots().any((o) => o.id == 'open_slot_test_01'), true);

      await db.applyToOpenShiftSlot('open_slot_test_01', 2);
      final fetchedSlot = db.getAllOpenShiftSlots().firstWhere((o) => o.id == 'open_slot_test_01');
      expect(fetchedSlot.appliedEmployeeIds.contains(2), true);
    });

    test('3. Helpdesk Arıza ve Bakım Biletleri CRUD işlemleri veritabanına kaydedilmeli', () async {
      final db = DatabaseService.instance;

      final ticket = HelpdeskTicket(
        id: 'hd_test_01',
        companyId: 'cmp_acme',
        title: 'Sunucu Odası Klima Arızası',
        description: 'Klima sıcaklık uyarı lambası kırmızı yanıyor',
        category: 'iklimlendirme',
        priority: 'high',
        requesterId: 1,
        requesterName: 'Ahmet Yılmaz',
        createdAt: DateTime.now(),
      );
      await db.insertHelpdeskTicket(ticket);
      expect(db.getAllHelpdeskTickets().any((t) => t.id == 'hd_test_01'), true);

      await db.assignTechnicianToTicket('hd_test_01', 3, 'Kemal Teknisyen');
      final inProgress = db.getAllHelpdeskTickets().firstWhere((t) => t.id == 'hd_test_01');
      expect(inProgress.status, 'in_progress');
      expect(inProgress.assignedTechnicianName, 'Kemal Teknisyen');

      await db.resolveHelpdeskTicket('hd_test_01', 'Filtreler temizlendi ve gaz basıldı.');
      final resolved = db.getAllHelpdeskTickets().firstWhere((t) => t.id == 'hd_test_01');
      expect(resolved.status, 'resolved');
      expect(resolved.solutionNotes, contains('Filtreler'));
    });

    test('4. Şirket Duyuruları ve Okundu Onayı takibi veritabanına kaydedilmeli', () async {
      final db = DatabaseService.instance;

      final announcement = CompanyAnnouncement(
        id: 'ann_test_01',
        companyId: 'cmp_acme',
        title: '2026 Yangın Tahliye Tatbikatı Prosedürü',
        content: 'Tüm personelin acil çıkış rotasını incelemesi zorunludur.',
        isMandatory: true,
        publisherName: 'İSG Kurulu',
        publishedAt: DateTime.now(),
        confirmedEmployeeIds: [],
      );
      await db.insertAnnouncement(announcement);
      expect(db.getAllAnnouncements().any((a) => a.id == 'ann_test_01'), true);

      await db.confirmAnnouncement('ann_test_01', 1);
      await db.confirmAnnouncement('ann_test_01', 2);
      final fetched = db.getAllAnnouncements().firstWhere((a) => a.id == 'ann_test_01');
      expect(fetched.confirmedEmployeeIds.contains(1), true);
      expect(fetched.confirmedEmployeeIds.contains(2), true);
      expect(fetched.confirmedEmployeeIds.contains(3), false);
    });

    test('5. Personel Özlük Dosyası ve Onboarding/Offboarding veritabanına kaydedilmeli', () async {
      final db = DatabaseService.instance;

      final doc = EmployeeDocument(
        id: 'doc_test_01',
        companyId: 'cmp_acme',
        employeeId: 1,
        title: 'Yüksekte Çalışma Sertifikası',
        documentType: 'certificate',
        fileName: 'isg_sertifikasi.pdf',
        uploadDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 365)),
        status: 'valid',
      );
      await db.insertDocument(doc);
      expect(db.getAllDocuments().any((d) => d.id == 'doc_test_01'), true);

      final task = OnboardingTask(
        id: 'task_test_01',
        companyId: 'cmp_acme',
        employeeId: 1,
        processType: 'onboarding',
        title: 'Şirket e-posta ve Slack hesabı açılması',
        category: 'it_donanim',
        isCompleted: false,
      );
      await db.insertOnboardingTask(task);
      expect(db.getAllOnboardingTasks().any((t) => t.id == 'task_test_01'), true);

      await db.toggleOnboardingTask('task_test_01', true);
      final fetchedTask = db.getAllOnboardingTasks().firstWhere((t) => t.id == 'task_test_01');
      expect(fetchedTask.isCompleted, true);
    });

    test('6. Eğitim Kursları ve Kayıtları veritabanına kaydedilmeli', () async {
      final db = DatabaseService.instance;

      final course = TrainingCourse(
        id: 'course_test_01',
        companyId: 'cmp_acme',
        title: 'KVKK ve Veri Gizliliği 2026',
        description: 'Kişisel verilerin işlenmesi ve yasal gereksinimler',
        category: 'kvkk',
        durationMinutes: 120,
      );
      await db.insertTrainingCourse(course);
      expect(db.getAllTrainingCourses().any((c) => c.id == 'course_test_01'), true);

      await db.assignTrainingCourse('course_test_01', 'KVKK ve Veri Gizliliği 2026', 1, 'cmp_acme');
      final assigned = db.getAllTrainingRecords().firstWhere((r) => r.courseId == 'course_test_01' && r.employeeId == 1);
      expect(assigned.status, 'assigned');

      await db.completeTrainingCourse(assigned.id, 95);
      final completed = db.getAllTrainingRecords().firstWhere((r) => r.id == assigned.id);
      expect(completed.status, 'completed');
      expect(completed.score, 95);
    });

    test('7. Hedef & OKR Performans Yönetimi veritabanına kaydedilmeli', () async {
      final db = DatabaseService.instance;

      final goal = PerformanceGoal(
        id: 'goal_test_01',
        companyId: 'cmp_acme',
        employeeId: 1,
        employeeName: 'Ahmet Yılmaz',
        period: '2026 Q1',
        title: 'Müşteri Memnuniyet Oranını %95 Üzerine Çıkarmak',
        description: 'SLA yanıt sürelerinin 15 dakikanın altına indirilmesi',
        currentProgress: 85,
        status: 'active',
      );
      await db.insertPerformanceGoal(goal);
      expect(db.getAllPerformanceGoals().any((g) => g.id == 'goal_test_01'), true);

      final updatedGoal = goal.copyWith(currentProgress: 100, status: 'reviewed');
      await db.updatePerformanceGoal(updatedGoal);
      final fetched = db.getAllPerformanceGoals().firstWhere((g) => g.id == 'goal_test_01');
      expect(fetched.currentProgress, 100);
      expect(fetched.status, 'reviewed');
    });

    test('8. Ziyaretçi ve Taşeron Giriş-Çıkış Kayıtları veritabanına kaydedilmeli', () async {
      final db = DatabaseService.instance;

      final visitor = VisitorRecord(
        id: 'vis_test_01',
        companyId: 'cmp_acme',
        visitorFullName: 'Murat Taşeron',
        visitorCompany: 'Akdeniz Elektrik A.Ş.',
        visitorPhone: '0555 111 22 33',
        hostEmployeeName: 'Ahmet Yılmaz',
        hostEmployeeId: 1,
        purpose: 'Trafoların Yıllık Bakımı',
        expectedDate: DateTime.now(),
        qrPassCode: 'QR_VIS_9988',
        hasSafetyBriefing: true,
        status: 'pre_registered',
      );
      await db.insertVisitorRecord(visitor);
      expect(db.getAllVisitorRecords().any((v) => v.id == 'vis_test_01'), true);

      await db.checkInVisitor('vis_test_01');
      final checkedIn = db.getAllVisitorRecords().firstWhere((v) => v.id == 'vis_test_01');
      expect(checkedIn.status, 'inside');

      await db.checkOutVisitor('vis_test_01');
      final checkedOut = db.getAllVisitorRecords().firstWhere((v) => v.id == 'vis_test_01');
      expect(checkedOut.status, 'completed');
      expect(checkedOut.checkOutTime != null, true);
    });

    test('9. Hibrit Çalışma, Masa ve Toplantı Odası Rezervasyonu veritabanına kaydedilmeli', () async {
      final db = DatabaseService.instance;

      final booking = HybridBooking(
        id: 'bk_test_01',
        companyId: 'cmp_acme',
        employeeId: 1,
        employeeName: 'Ahmet Yılmaz',
        resourceType: 'desk',
        resourceCode: 'Masa A-14',
        date: DateTime.now().add(const Duration(days: 1)),
        timeSlot: 'Tam Gün (08:30 - 18:00)',
        status: 'confirmed',
      );
      await db.insertHybridBooking(booking);
      expect(db.getAllHybridBookings().any((b) => b.id == 'bk_test_01'), true);

      await db.cancelHybridBooking('bk_test_01');
      final fetched = db.getAllHybridBookings().firstWhere((b) => b.id == 'bk_test_01');
      expect(fetched.status, 'cancelled');
    });

    test('10. Şube Organizasyonu ve Yetki Vekaleti veritabanına kaydedilmeli', () async {
      final db = DatabaseService.instance;

      final branch = CompanyBranch(
        id: 'br_test_01',
        companyId: 'cmp_acme',
        name: 'İzmir Ar-Ge Merkezi',
        code: 'IZM-02',
        city: 'İzmir',
        address: 'Urla Teknopark',
        employeeCount: 45,
        managerId: 1,
        managerName: 'Zeynep Kaya',
        departments: ['Yazılım', 'Donanım'],
      );
      await db.insertCompanyBranch(branch);
      expect(db.getAllCompanyBranches().any((b) => b.id == 'br_test_01'), true);

      final delegation = ApprovalDelegation(
        id: 'del_test_01',
        companyId: 'cmp_acme',
        managerId: 1,
        managerName: 'Ahmet Yılmaz',
        delegateEmployeeId: 2,
        delegateEmployeeName: 'Mehmet Demir',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        scope: 'leave',
        isActive: true,
      );
      await db.insertApprovalDelegation(delegation);
      expect(db.getAllApprovalDelegations().any((d) => d.id == 'del_test_01'), true);

      await db.toggleApprovalDelegation('del_test_01', false);
      final toggled = db.getAllApprovalDelegations().firstWhere((d) => d.id == 'del_test_01');
      expect(toggled.isActive, false);
    });

    test('11. Entegrasyon Merkezi ve Çevrimdışı Eşitleme Kuyruğu veritabanına kaydedilmeli', () async {
      final db = DatabaseService.instance;

      final endpoint = IntegrationEndpoint(
        id: 'int_test_01',
        companyId: 'cmp_acme',
        name: 'SAP S/4HANA Bordro Entegrasyonu',
        systemType: 'erp',
        apiEndpoint: 'https://sap.acme.com/api/v2/payroll',
        status: 'active',
        lastSyncTime: DateTime.now(),
        failedRecordsCount: 0,
      );
      await db.insertIntegrationEndpoint(endpoint);
      expect(db.getAllIntegrationEndpoints().any((i) => i.id == 'int_test_01'), true);

      final syncItem = OfflineSyncItem(
        id: 'sync_test_01',
        companyId: 'cmp_acme',
        actionType: 'checkIn',
        payload: {'employeeId': 1, 'timestamp': '2026-11-02T08:00:00Z'},
        recordedAt: DateTime.now(),
        syncStatus: 'queued',
      );
      await db.enqueueOfflineItem(syncItem);
      expect(db.getAllOfflineSyncItems().any((s) => s.id == 'sync_test_01'), true);

      await db.clearOfflineQueue();
      expect(db.getAllOfflineSyncItems().isEmpty, true);
    });

    test('12. Çalışan Geri Bildirimleri ve Anonim Öneri Kutusu veritabanına kaydedilmeli', () async {
      final db = DatabaseService.instance;

      final feedback = EmployeeFeedback(
        id: 'fb_test_01',
        companyId: 'cmp_acme',
        category: 'suggestion',
        title: 'Ofiste Bisiklet Park Yeri Talebi',
        content: 'Tesis girişine korunaklı bisiklet park yeri ve tamir kiti eklenmesi faydalı olur.',
        isAnonymous: true,
        rating: 5,
        status: 'submitted',
        createdAt: DateTime.now(),
      );
      await db.insertEmployeeFeedback(feedback);
      expect(db.getAllEmployeeFeedbacks().any((f) => f.id == 'fb_test_01'), true);

      await db.respondToFeedback('fb_test_01', 'İdari İşler ile görüşüldü, bütçe onayı alındı.');
      final fetched = db.getAllEmployeeFeedbacks().firstWhere((f) => f.id == 'fb_test_01');
      expect(fetched.status, 'resolved');
      expect(fetched.hrResponse, contains('İdari İşler'));
    });

    test('13. PdksState üzerinden 15 modülün reaktif yönetimi ve Executive Dashboard istatistikleri', () async {
      final pdks = PdksState();

      // Executive Dashboard hesaplamaları
      final stats = pdks.executiveDashboardStats;
      expect(stats.totalEmployees >= 0, true);
      expect(stats.activeBranchesCount >= 1, true);
      expect(stats.employeeSatisfactionScore >= 0.0, true);

      // Reaktif State Eylemi: Yardım masası bileti oluşturma
      final newTicket = HelpdeskTicket(
        id: 'hd_reactive_01',
        companyId: 'cmp_acme',
        requesterId: pdks.currentUser.id,
        requesterName: pdks.currentUser.fullName,
        title: 'Toplantı Odası HDMI Kablosu Kopuk',
        description: '3. Kat toplantı odasındaki projektör kablosu temassızlık yapıyor.',
        category: 'hardware',
        priority: 'medium',
      );
      pdks.createHelpdeskTicket(newTicket);
      expect(pdks.helpdeskTickets.any((t) => t.title.contains('HDMI')), true);

      // Reaktif State Eylemi: Anonim geri bildirim gönderme
      final newFb = EmployeeFeedback(
        id: 'fb_reactive_01',
        companyId: 'cmp_acme',
        title: 'Yemekhane Salata Barı Çeşitliliği',
        content: 'Salata barına zeytin ve ceviz eklenmesi çalışanlarca talep edilmektedir.',
        category: 'suggestion',
        isAnonymous: true,
        rating: 5,
      );
      pdks.submitFeedback(newFb);
      expect(pdks.feedbacks.any((f) => f.title.contains('Salata')), true);

      // Reaktif State Eylemi: Hibrit masa rezervasyonu
      final newBooking = HybridBooking(
        id: 'bk_reactive_01',
        companyId: 'cmp_acme',
        employeeId: pdks.currentUser.id,
        employeeName: pdks.currentUser.fullName,
        resourceType: 'desk',
        resourceCode: 'Masa B-07',
        date: DateTime.now().add(const Duration(days: 2)),
        timeSlot: 'Tam Gün (08:30 - 18:00)',
      );
      pdks.createHybridBooking(newBooking);
      expect(pdks.hybridBookings.any((b) => b.resourceCode == 'Masa B-07'), true);
    });
  });
}
