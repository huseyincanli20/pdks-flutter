import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdks_flutter/core/services/database_service.dart';
import 'package:pdks_flutter/state/pdks_state.dart';

void main() {
  group('Veritabanı Kalıcılığı & Kayıt Mükerrer Kontrolü Testleri', () {
    late DatabaseService db;
    late PdksState state;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db = DatabaseService();
      await db.init();
      state = PdksState();
    });

    test('Veritabanı varsayılan kurumsal personellerle başlatılmalı', () {
      expect(db.getAllEmployees().length, greaterThanOrEqualTo(5));
      final ahmet = db.getEmployeeByEmail('personel@sirket.com');
      expect(ahmet, isNotNull);
      expect(ahmet!.fullName, equals('Ahmet Yılmaz'));
    });

    test('Yeni kayıt veritabanına kaydedilmeli', () {
      final regResult = state.register(
        companyCode: 'ACME',
        fullName: 'Yeni Çalışan',
        email: 'yeni.calisan@acmeteknoloji.com',
        phone: '05559876543',
        pin: '9876',
      );

      expect(regResult.success, isTrue);

      // Veritabanında kontrol et
      final fromDb = db.getEmployeeByEmail('yeni.calisan@acmeteknoloji.com');
      expect(fromDb, isNotNull);
      expect(fromDb!.fullName, equals('Yeni Çalışan'));
      expect(fromDb.isApproved, isFalse); // İK onayı beklemeli
    });

    test('Mükerrer kayıt denendiğinde veritabanı tarafından KABUL EDİLMEMELİ', () {
      // 1. İlk kayıt başarıyla yapılmalı
      final firstAttempt = state.register(
        companyCode: 'ACME',
        fullName: 'Test Personel',
        email: 'mukerrer.test@sirket.com',
        phone: '05551112233',
        pin: '1122',
      );
      expect(firstAttempt.success, isTrue);

      // 2. Aynı e-posta ile ikinci kayıt denenmeli -> KABUL EDİLMEMELİ
      final duplicateEmailAttempt = state.register(
        companyCode: 'ACME',
        fullName: 'Farklı İsim Aynı Eposta',
        email: 'mukerrer.test@sirket.com',
        phone: '05559998877',
        pin: '3344',
      );
      expect(duplicateEmailAttempt.success, isFalse);
      expect(duplicateEmailAttempt.message, contains('zaten kayıtlıdır'));

      // 3. Aynı telefon numarası ile kayıt denenmeli -> KABUL EDİLMEMELİ
      final duplicatePhoneAttempt = state.register(
        companyCode: 'ACME',
        fullName: 'Farklı Eposta Aynı Telefon',
        email: 'farkli.eposta@sirket.com',
        phone: '05551112233',
        pin: '5566',
      );
      expect(duplicatePhoneAttempt.success, isFalse);
      expect(duplicatePhoneAttempt.message, contains('zaten kayıtlıdır'));
    });

    test('Kayıtsız e-posta ile giriş yapılmak istendiğinde reddedilmeli', () {
      final loginResult = state.login('kayitsiz.kullanici@bilinmeyen.com', '1234');
      expect(loginResult.success, isFalse);
      expect(loginResult.message, contains('Veritabanında'));
    });

    test('Veritabanından çekilip İK onaylandıktan sonra PIN ile giriş yapılabilmeli', () {
      // 1. Kayıt ol
      state.register(
        companyCode: 'ACME',
        fullName: 'Cemre Deniz',
        email: 'cemre.deniz@sirket.com',
        phone: '05554443322',
        pin: '4455',
      );

      final user = db.getEmployeeByEmail('cemre.deniz@sirket.com')!;

      // 2. Onaysızken giriş denenmeli -> İK onayı uyarısı vermeli
      final preApprovalLogin = state.login('cemre.deniz@sirket.com', '4455');
      expect(preApprovalLogin.success, isFalse);
      expect(preApprovalLogin.isPendingApproval, isTrue);

      // 3. İK yetkilisi olarak sisteme girip onayla
      state.login('ik@sirket.com', '2345');
      final approveResult = state.approveEmployeeRegistration(
        employeeId: user.id,
        department: 'Yazılım',
        title: 'Frontend Geliştirici',
      );
      expect(approveResult.success, isTrue);

      // 4. Artık Cemre Deniz veritabanından çekilip oturum açabilmeli
      state.logout();
      final postApprovalLogin = state.login('cemre.deniz@sirket.com', '4455');
      expect(postApprovalLogin.success, isTrue);
      expect(state.isLoggedIn, isTrue);
      expect(state.currentUser.fullName, equals('Cemre Deniz'));
      expect(state.currentUser.department, equals('Yazılım'));
    });
  });
}
