import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:pdks_flutter/core/services/database_service.dart';
import 'package:pdks_flutter/models/employee.dart';
import 'package:pdks_flutter/models/vehicle_request.dart';
import 'package:pdks_flutter/state/pdks_state.dart';
import 'package:pdks_flutter/views/vehicle/vehicle_request_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. Yeni Roller ve Yetki Tanımları Testleri', () {
    test('UserRole enum değerleri ve etiketleri eksiksiz olmalı', () {
      expect(UserRole.technician.label, equals('Teknisyen'));
      expect(UserRole.technician.shortLabel, equals('Teknisyen'));

      expect(UserRole.doctor.label, equals('İşyeri Hekimi (Doktor)'));
      expect(UserRole.doctor.shortLabel, equals('Doktor'));

      expect(UserRole.serviceManager.label, equals('Servis Sorumlusu'));
      expect(UserRole.serviceManager.shortLabel, equals('Servis'));

      expect(UserRole.vehicleRentalManager.label, equals('Araç Kiralama Sorumlusu'));
      expect(UserRole.vehicleRentalManager.shortLabel, equals('Araç Kiralama'));
    });

    test('Employee.fromJson yeni rolleri doğru ayrıştırmalı', () {
      final jsonTech = {'id': 101, 'fullName': 'Teknisyen Ali', 'role': 'technician'};
      final empTech = Employee.fromJson(jsonTech);
      expect(empTech.role, equals(UserRole.technician));

      final jsonDoc = {'id': 102, 'fullName': 'Dr. Ayşe', 'role': 'doktor'};
      final empDoc = Employee.fromJson(jsonDoc);
      expect(empDoc.role, equals(UserRole.doctor));

      final jsonServis = {'id': 103, 'fullName': 'Servisçi Veli', 'role': 'servis_sorumlusu'};
      final empServis = Employee.fromJson(jsonServis);
      expect(empServis.role, equals(UserRole.serviceManager));

      final jsonArac = {'id': 104, 'fullName': 'Filocu Can', 'role': 'arackiralama'};
      final empArac = Employee.fromJson(jsonArac);
      expect(empArac.role, equals(UserRole.vehicleRentalManager));
    });

    test('Sistem rollerinde Teknisyen, Doktor, Servis ve Araç Kiralama tanımlı olmalı', () {
      final pdks = PdksState();
      addTearDown(() {
        pdks.logout();
        pdks.dispose();
      });

      final roles = pdks.roles;
      expect(roles.any((r) => r.id == 'role_technician'), isTrue);
      expect(roles.any((r) => r.id == 'role_doctor'), isTrue);
      expect(roles.any((r) => r.id == 'role_service_manager'), isTrue);
      expect(roles.any((r) => r.id == 'role_vehicle_rental_manager'), isTrue);

      // vehicle_request sayfası yetkileri tanımlı olmalı
      final techRole = roles.firstWhere((r) => r.id == 'role_technician');
      expect(techRole.canAccessPage('vehicle_request'), isTrue);

      final vehicleRole = roles.firstWhere((r) => r.id == 'role_vehicle_rental_manager');
      expect(vehicleRole.canAccessPage('vehicle_request'), isTrue);
    });

    test('Demo giriş kısayolları yeni roller için çalışmalı', () {
      final pdks = PdksState();
      addTearDown(() {
        pdks.logout();
        pdks.dispose();
      });

      // Teknisyen girişi
      final loginTech = pdks.login('teknisyen@sirket.com', '1234');
      expect(loginTech.success, isTrue);
      expect(pdks.currentUser.role, equals(UserRole.technician));

      // Doktor girişi
      final loginDoc = pdks.login('doktor@sirket.com', '1234');
      expect(loginDoc.success, isTrue);
      expect(pdks.currentUser.role, equals(UserRole.doctor));

      // Servis Sorumlusu girişi
      final loginServis = pdks.login('servis@sirket.com', '1234');
      expect(loginServis.success, isTrue);
      expect(pdks.currentUser.role, equals(UserRole.serviceManager));

      // Araç Kiralama Sorumlusu girişi
      final loginArac = pdks.login('arackiralama@sirket.com', '1234');
      expect(loginArac.success, isTrue);
      expect(pdks.currentUser.role, equals(UserRole.vehicleRentalManager));
    });
  });

  group('2. Araç Talep ve Filo Yönetimi İş Mantığı Testleri', () {
    test('Personel veya teknisyen yeni araç talebi oluşturabilmeli', () async {
      final pdks = PdksState();
      addTearDown(() {
        pdks.logout();
        pdks.dispose();
      });

      // Teknisyen olarak oturum açalım
      pdks.login('teknisyen@sirket.com', '1234');

      final start = DateTime.now().add(const Duration(hours: 1));
      final end = DateTime.now().add(const Duration(hours: 6));

      final res = await pdks.createVehicleRequest(
        vehicleType: 'Hafif Ticari / Kamyonet',
        startDate: start,
        endDate: end,
        destination: 'Ankara Ostim OSB Jeneratör Arızası',
        purpose: 'Acil yedek parça ve test cihazı transferi',
        passengerCount: 2,
        needsDriver: false,
        notes: 'Arka bagaja 2 adet takım çantası yüklenecek.',
      );

      expect(res.success, isTrue);
      expect(res.request, isNotNull);
      expect(res.request!.status, equals(VehicleRequestStatus.pending));
      expect(res.request!.employeeId, equals(pdks.currentUser.id));
      expect(res.request!.destination, contains('Ostim OSB'));

      // Kullanıcının listesinde bu talep bulunmalı
      final myRequests = pdks.vehicleRequestsForCurrentUser;
      expect(myRequests.any((r) => r.id == res.request!.id), isTrue);
    });

    test('Araç Kiralama Sorumlusu talebi onaylayabilmeli ve araç atayabilmeli', () async {
      final pdks = PdksState();
      addTearDown(() {
        pdks.logout();
        pdks.dispose();
      });

      // 1. Personel talep oluştursun
      pdks.login('personel@sirket.com', '1234');
      final createRes = await pdks.createVehicleRequest(
        vehicleType: 'Binek Otomobil (Sedan/HB)',
        startDate: DateTime.now().add(const Duration(hours: 2)),
        endDate: DateTime.now().add(const Duration(hours: 5)),
        destination: 'Bakanlık Toplantısı',
        purpose: 'Proje sunumu ve ihale evrakı teslimi',
      );
      final reqId = createRes.request!.id;

      // 2. Yetkisiz personel onaylamayı denerse engellenmeli
      final failApprove = await pdks.approveVehicleRequest(
        reqId,
        assignedVehicle: '06 ABC 123 - Megane',
      );
      expect(failApprove.success, isFalse);
      expect(failApprove.message, contains('Yetki Sınırı'));

      // 3. Araç Kiralama Sorumlusu oturum açsın ve onaylasın
      pdks.login('arackiralama@sirket.com', '1234');
      final okApprove = await pdks.approveVehicleRequest(
        reqId,
        assignedVehicle: '34 ACME 2024 - Renault Megane Sedan',
        assignedDriver: 'Personel Kendisi',
        note: 'Araç anahtarı A blok danışmadan teslim alınabilir.',
      );

      expect(okApprove.success, isTrue);

      final updatedReq = pdks.allVehicleRequests.firstWhere((r) => r.id == reqId);
      expect(updatedReq.status, equals(VehicleRequestStatus.approved));
      expect(updatedReq.assignedVehicle, contains('34 ACME 2024'));
      expect(updatedReq.approvedBy, contains('Araç Kiralama Sorumlusu'));
    });

    test('Araç Kiralama Sorumlusu veya Admin talebi reddedebilmeli', () async {
      final pdks = PdksState();
      addTearDown(() {
        pdks.logout();
        pdks.dispose();
      });

      pdks.login('personel@sirket.com', '1234');
      final createRes = await pdks.createVehicleRequest(
        vehicleType: 'SUV / 4x4 Arazi',
        startDate: DateTime.now().add(const Duration(hours: 1)),
        endDate: DateTime.now().add(const Duration(hours: 4)),
        destination: 'Özel Ziyaret',
        purpose: 'Şahsi işler',
      );
      final reqId = createRes.request!.id;

      // Filo yöneticisi reddetsin
      pdks.login('arackiralama@sirket.com', '1234');
      final rejectRes = await pdks.rejectVehicleRequest(
        reqId,
        reason: 'Şirket araçları yalnızca resmi iş seyahatlerinde tahsis edilir.',
      );

      expect(rejectRes.success, isTrue);
      final req = pdks.allVehicleRequests.firstWhere((r) => r.id == reqId);
      expect(req.status, equals(VehicleRequestStatus.rejected));
      expect(req.approvalNote, contains('resmi iş seyahatlerinde'));
    });

    test('Sefer durumu inUse ve completed olarak güncellenebilmeli', () async {
      final pdks = PdksState();
      addTearDown(() {
        pdks.logout();
        pdks.dispose();
      });

      pdks.login('arackiralama@sirket.com', '1234');
      final reqs = pdks.vehicleRequestsForCurrentUser;
      final approvedReq = reqs.firstWhere((r) => r.status == VehicleRequestStatus.approved);

      // Seferde
      final startRes = await pdks.updateVehicleRequestStatus(approvedReq.id, VehicleRequestStatus.inUse);
      expect(startRes.success, isTrue);

      // Tamamlandı
      final finishRes = await pdks.updateVehicleRequestStatus(approvedReq.id, VehicleRequestStatus.completed);
      expect(finishRes.success, isTrue);
      final check = pdks.allVehicleRequests.firstWhere((r) => r.id == approvedReq.id);
      expect(check.status, equals(VehicleRequestStatus.completed));
    });
  });

  group('3. Araç Talep Ekranı (VehicleRequestScreen) Widget Testi', () {
    testWidgets('VehicleRequestScreen açılmalı ve sekmeler render edilmeli', (tester) async {
      final pdks = PdksState();
      pdks.login('arackiralama@sirket.com', '1234');

      await tester.pumpWidget(
        ChangeNotifierProvider<PdksState>.value(
          value: pdks,
          child: const MaterialApp(
            home: VehicleRequestScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Başlık ve sekmeler kontrolü
      expect(find.text('Araç Talebi & Filo'), findsWidgets);
      expect(find.text('Yeni Araç Talebi'), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(TabBarView), findsOneWidget);

      // Yeni Araç Talebi sekmesine geçiş
      await tester.tap(find.text('Yeni Araç Talebi'));
      await tester.pumpAndSettle();

      expect(find.text('Kurumsal Araç Talebi'), findsOneWidget);
      expect(find.text('Araç Tipi Seçimi *'), findsOneWidget);
      expect(find.text('Gidilecek Güzergah / Varış Noktası *'), findsOneWidget);
      expect(find.text('Talep Nedeni & Saha Görevi *'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      pdks.logout();
      pdks.dispose();
    });
  });
}
