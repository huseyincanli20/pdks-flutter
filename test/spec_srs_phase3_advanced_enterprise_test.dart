import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pdks_flutter/state/pdks_state.dart';
import 'package:pdks_flutter/views/kiosk/kiosk_terminal_screen.dart';
import 'package:pdks_flutter/views/enterprise/enterprise_hub_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDKS Faz 3 İleri Düzey Kurumsal Yetkinlikler Test Paketi', () {
    late PdksState pdks;

    setUp(() {
      pdks = PdksState();
    });

    test('1.1. AI PDKS 4857 Mevzuat Asistanı Hukuki Soruları Yanıtlamalı', () async {
      // Fazla mesai 270 saat sorusu
      await pdks.askPdkAiAssistant('Yıllık 270 saat fazla mesai sınırı hakkında bilgi verir misiniz?');
      expect(pdks.aiMessages.isNotEmpty, isTrue);
      final lastMsg = pdks.aiMessages.last;
      expect(lastMsg.isUser, isFalse);
      expect(lastMsg.message, contains('270'));
      expect(lastMsg.message, contains('4857'));

      // Gece vardiyası 7.5 saat kuralı
      await pdks.askPdkAiAssistant('Gece vardiyasında en fazla kaç saat çalışılabilir?');
      final nightMsg = pdks.aiMessages.last;
      expect(nightMsg.message, contains('7.5'));
    });

    test('1.2. Sahte Geçiş (Anti-Buddy Punching) Anomali Tespiti ve Çözümleme', () async {
      final initialCount = pdks.anomalies.length;
      expect(initialCount, greaterThan(0));

      final firstAnomaly = pdks.anomalies.first;
      expect(firstAnomaly.status, isNot('resolved'));

      // Yönetici anomaliyi inceler ve karara bağlar
      await pdks.resolveAnomaly(
        anomalyId: firstAnomaly.id,
        resolutionNote: 'Kamera kayıtları incelendi, teknik IP arızası nedeniyle mükerrer kayıt oluştuğu doğrulandı.',
        isDismissed: false,
      );

      final updatedAnomaly = pdks.anomalies.firstWhere((a) => a.id == firstAnomaly.id);
      expect(updatedAnomaly.status, equals('resolved'));
      expect(updatedAnomaly.resolutionNote, contains('Kamera kayıtları incelendi'));
    });

    test('1.3. Akıllı Vardiya Optimizasyonu 4857 Sayılı Kanun Kısıtlarıyla Üretilmeli', () {
      final plan = pdks.generateSmartShiftPlan(department: 'Üretim / İmalat');
      expect(plan.department, equals('Üretim / İmalat'));
      expect(plan.coverageScorePercent, greaterThan(90.0));
      expect(plan.adheresToLaborLaw4857, isTrue);
      expect(plan.optimizationNotes.isNotEmpty, isTrue);
      expect(plan.totalAssignedShifts, greaterThan(0));
    });

    test('2.1. Kiosk Yüz Tanıma: Canlılık (Liveness) Doğrulanınca Turnike Açılmalı', () async {
      final emps = pdks.employees;
      expect(emps.isNotEmpty, isTrue);
      final targetEmp = emps.first;

      final result = await pdks.processKioskFaceScan(
        terminalId: 'KIOSK-GATE-A1',
        rawFaceVectorOrName: targetEmp.fullName,
        isBlinkDetected: true,
      );

      expect(result.success, isTrue);
      expect(result.employeeName, equals(targetEmp.fullName));
      expect(result.message, contains('Turnike kilidi açıldı'));
    });

    test('2.2. Kiosk Yüz Tanıma: Fotoğraftan Sahte Geçiş (Spoofing) Reddedilmeli ve Anomali Açılmalı', () async {
      final anomaliesBefore = pdks.anomalies.length;

      final result = await pdks.processKioskFaceScan(
        terminalId: 'KIOSK-GATE-A1',
        rawFaceVectorOrName: 'Ahmet Yılmaz',
        isBlinkDetected: false, // Canlılık yok (fotoğraf/ekran)
      );

      expect(result.success, isFalse);
      expect(result.message, contains('Sahte Geçiş'));
      expect(pdks.anomalies.length, equals(anomaliesBefore + 1));
      expect(pdks.anomalies.first.severity, equals('critical'));
    });

    test('3.1. 5070 Sayılı E-İmza SHA-256 Zaman Damgası ile Belgeyi İmzalamalı', () async {
      final doc = await pdks.signDocumentWith5070Timestamp(
        documentType: 'payroll',
        documentTitle: '2026/10 Dönemi Bordro Tahakkuku',
        period: '2026-10',
        signaturePoints: 'SVG_POINTS_TEST_123',
      );

      expect(doc.id.startsWith('sig_'), isTrue);
      expect(doc.isVerified5070, isTrue);
      expect(doc.timeStampHash.length, equals(64)); // SHA-256 hash length is 64 hex chars
      expect(pdks.signedDocuments.any((d) => d.id == doc.id), isTrue);
    });

    test('3.2. ERP İhracat Motoru Logo, Mikro, SAP ve SGK Çıktıları Üretmeli', () {
      final logoXml = pdks.exportPayrollData(format: 'logo', period: '2026-10');
      expect(logoXml, contains('<?xml version="1.0"'));
      expect(logoXml, contains('<PDKS_EXPORT TIGER_VERSION="3.0"'));

      final mikroCsv = pdks.exportPayrollData(format: 'mikro', period: '2026-10');
      expect(mikroCsv, contains('SicilNo;TCKimlik;PersonelAdSoyad;CalismaGun;FazlaMesaiSaat;HaftaTatili;BrutUcret'));

      final sapJson = pdks.exportPayrollData(format: 'sap', period: '2026-10');
      expect(sapJson, contains('"system": "SAP_S4HANA_HCM"'));

      final sgkAphb = pdks.exportPayrollData(format: 'sgk', period: '2026-10');
      expect(sgkAphb, contains('AYLIK PRİM VE HİZMET BELGESİ'));
    });

    test('4.1. 6331 İSG Ramak Kala (Near-Miss) Olay Bildirimi ve Acil Bildirim Tetikleme', () async {
      final notifCountBefore = pdks.notifications.length;

      await pdks.submitNearMissReport(
        title: 'Pres Hattında Yağ Sızıntısı & Kayma Tehlikesi',
        description: '3 nolu pres tezgahından hidrolik yağ damlıyor, çalışanlar kayma tehlikesi geçirdi.',
        department: 'Preshane',
        locationDetail: 'Hat 3 / Zemin',
        riskLevel: 'high',
      );

      expect(pdks.nearMissReports.isNotEmpty, isTrue);
      final lastReport = pdks.nearMissReports.first;
      expect(lastReport.title, contains('Pres Hattında'));
      expect(lastReport.riskLabel, contains('Yüksek Risk'));

      // İSG hekimine ve uzmanına acil bildirim gitmiş olmalı
      expect(pdks.notifications.length, equals(notifCountBefore + 1));
      expect(pdks.notifications.first.title, contains('Acil İSG'));
    });

    test('4.2. Tehlikeli Bölge Geofence & Zorunlu KKD Denetimi', () {
      final zones = pdks.hazardZones;
      expect(zones.isNotEmpty, isTrue);
      final firstZone = zones.first;

      // Tam merkezin koordinatında geofence denetimi
      final checkInside = pdks.checkHazardZoneGeofence(firstZone.centerLat, firstZone.centerLng);
      expect(checkInside.isInsideHazard, isTrue);
      expect(checkInside.requiredPPE.isNotEmpty, isTrue);
      expect(checkInside.warning, isNotNull);

      // Çok uzaktaki bir koordinatta denetim
      final checkOutside = pdks.checkHazardZoneGeofence(35.0, 30.0);
      expect(checkOutside.isInsideHazard, isFalse);
    });

    test('5.1. Kurumsal Bas-Konuş Saha Telsizi (PTT) Ses Paketi Gönderimi', () async {
      final channels = pdks.pttChannels;
      expect(channels.isNotEmpty, isTrue);
      final activeChan = channels.first;
      final burstsBefore = pdks.pttBursts.length;

      await pdks.transmitPttBurst(
        channelId: activeChan.id,
        spokenText: 'Acil müdahale ekibi 2 nolu yangın çıkışına yönlensin.',
        durationSeconds: 4,
      );

      expect(pdks.pttBursts.length, equals(burstsBefore + 1));
      final lastBurst = pdks.pttBursts.first;
      expect(lastBurst.channelId, equals(activeChan.id));
      expect(lastBurst.durationSeconds, equals(4));
      expect(lastBurst.transcriptText, contains('Acil müdahale'));
    });

    testWidgets('6.1. KioskTerminalScreen Tam Ekran UI Widget Render Testi', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<PdksState>.value(
            value: pdks,
            child: const KioskTerminalScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('TURNİKE BAĞLI'), findsOneWidget);
      expect(find.text('Yüzünüzü Çerçeveye\nHizalayınız'), findsOneWidget);
      expect(find.text('Hızlı Biyometrik Test & Geçiş'), findsOneWidget);
      expect(find.text('Turnike Rölesini Manuel Aç (3 sn)', skipOffstage: false), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('6.2. EnterpriseHubScreen 19 Sekmeli Hub & Gelişmiş Modüller Render Testi', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<PdksState>.value(
            value: pdks,
            child: const EnterpriseHubScreen(initialTabIndex: 14), // Tab 15: AI & Anomali
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Kurumsal Modüller'), findsOneWidget);
      expect(find.text('19 Gelişmiş İK, Tesis, Güvenlik & Operasyon Modülü'), findsOneWidget);
      expect(find.text('PDKS AI & Anomali'), findsWidgets);
      expect(find.text('Kiosk Yüz & Turnike'), findsWidgets);
      expect(find.text('5070 E-İmza & ERP'), findsWidgets);
      expect(find.text('İSG & Ramak Kala'), findsWidgets);
      expect(find.text('Saha Telsizi (PTT)'), findsWidgets);

      await tester.binding.setSurfaceSize(null);
    });
  });
}
