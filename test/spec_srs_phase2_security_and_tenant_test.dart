import 'package:flutter_test/flutter_test.dart';
import 'package:pdks_flutter/state/pdks_state.dart';
import 'package:pdks_flutter/models/employee.dart';
import 'package:pdks_flutter/core/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SRS 2. SaaS Mimarisi, Şirket Kodu ve Kayıt/Onay İş Akışları', () {
    late PdksState state;

    setUp(() {
      state = PdksState();
    });

    test('2.1 Çok Kiracılı (Multi-Tenant) Yapı ve Şirket Kodu Eşleştirme', () {
      // Şirket kodu FABRIKA01 doğrulanır
      final res = state.setCompanyCode('FABRIKA01');
      expect(res.success, isTrue);
      expect(res.company, isNotNull);
      expect(res.company!.code, 'FABRIKA01');
      expect(state.savedCompanyCode, 'FABRIKA01');

      // Geçersiz şirket kodu reddedilmeli
      final invalidRes = state.setCompanyCode('GEÇERSİZ_KOD_999');
      expect(invalidRes.success, isFalse);
      expect(invalidRes.company, isNull);

      // Şirket kodu temizleme (Şirket Değiştir)
      state.clearSavedCompanyCode();
      expect(state.savedCompanyCode, isNull);

      // Başka bir şirkete geçiş (Örn: ACME)
      final acmeRes = state.setCompanyCode('ACME');
      expect(acmeRes.success, isTrue);
      expect(state.savedCompanyCode, 'ACME');
    });

    test('2.2 Kısıtlı Ön Kayıt (Açık formda Sicil, Departman, Rol seçimi yapılamaz)', () {
      final regRes = state.registerRestricted(
        companyCode: 'FABRIKA01',
        fullName: 'Mehmet Demir',
        phone: '05350001122',
        tcKimlikNo: '12345678901',
        pin: '5820',
      );

      expect(regRes.success, isTrue);
      expect(regRes.message, contains('İnsan Kaynakları'));

      // Kayıt onay bekliyor durumunda olmalı
      final pendingEmp = state.allEmployees.firstWhere((e) => e.phone == '05350001122');
      expect(pendingEmp.isApproved, isFalse);
      expect(pendingEmp.department, 'Onay Bekliyor');
      expect(pendingEmp.title, 'Personel Adayı');
      expect(pendingEmp.role, UserRole.employee);
      expect(pendingEmp.tcKimlikNo, '12345678901');

      // Onaylanmamış kullanıcı giriş yapamamalı
      final loginRes = state.login(pendingEmp.email, '5820');
      expect(loginRes.success, isFalse);
      expect(loginRes.isPendingApproval, isTrue);
    });

    test('2.2 İK / Yönetici Onay ve Atama Paneli (Sicil No, Şube, Departman ve Rol Atama)', () {
      // Önce İK rolü ile oturum açalım
      final hrEmp = state.allEmployees.firstWhere((e) => e.role == UserRole.hr);
      state.login(hrEmp.email, hrEmp.pinCode);

      final targetEmp = state.allEmployees.firstWhere((e) => e.phone == '05350001122');

      // Yönetici onay ekranında Sicil No, Departman, Şube ve Rol atar
      final approveRes = state.approveEmployeeRegistration(
        employeeId: targetEmp.id,
        department: 'Otomotiv Montaj Hattı',
        title: 'Vardiya Teknisyeni',
        sicilNo: 'SIC-2026-0881',
        branch: 'Kocaeli Fabrika Tesisleri',
        role: UserRole.technician,
        baseSalary: 64000.0,
      );

      expect(approveRes.success, isTrue);

      final updatedEmp = state.allEmployees.firstWhere((e) => e.id == targetEmp.id);
      expect(updatedEmp.isApproved, isTrue);
      expect(updatedEmp.sicilNo, 'SIC-2026-0881');
      expect(updatedEmp.displaySicilNo, 'SIC-2026-0881');
      expect(updatedEmp.branch, 'Kocaeli Fabrika Tesisleri');
      expect(updatedEmp.department, 'Otomotiv Montaj Hattı');
      expect(updatedEmp.role, UserRole.technician);
      expect(updatedEmp.baseGrossSalary, 64000.0);

      // Onay bildirimi ve SMS/E-posta içeriğinde Sicil No ve Şube doğrulanır
      expect(approveRes.dispatchedNotification, isNotNull);
      expect(approveRes.dispatchedNotification!.message, contains('SIC-2026-0881'));
      expect(approveRes.dispatchedNotification!.message, contains('Kocaeli Fabrika Tesisleri'));
    });
  });

  group('SRS 3. Güvenli Mobil Erişim, PIN Kodu ve Biyometrik Doğrulama', () {
    late PdksState state;

    setUp(() {
      state = PdksState();
      DatabaseService.instance.setFailedPinAttempts(0);
      DatabaseService.instance.setPinLockoutUntil(null);
    });

    test('3.1 4 Haneli PIN Kodu ve Brute-Force Koruması (4 Hatalı Denemede Kilit)', () {
      final emp = state.allEmployees.firstWhere((e) => e.isApproved && e.pinCode == '1234');

      // 1. Hatalı Deneme
      final try1 = state.login(emp.email, '9999');
      expect(try1.success, isFalse);
      expect(try1.message, contains('Kalan deneme hakkı: 3'));
      expect(state.isPinLockedOut, isFalse);

      // 2. Hatalı Deneme
      final try2 = state.login(emp.email, '9999');
      expect(try2.success, isFalse);
      expect(try2.message, contains('Kalan deneme hakkı: 2'));

      // 3. Hatalı Deneme
      final try3 = state.login(emp.email, '9999');
      expect(try3.success, isFalse);
      expect(try3.message, contains('Kalan deneme hakkı: 1'));

      // 4. Hatalı Deneme -> Oturum Kilitlenmeli (Brute-Force Koruması)
      final try4 = state.login(emp.email, '9999');
      expect(try4.success, isFalse);
      expect(try4.message, contains('Güvenlik Uyarısı'));
      expect(state.isPinLockedOut, isTrue);
      expect(state.lockoutSecondsRemaining, greaterThan(0));

      // Kilitliyken doğru PIN girilse dahi kilit engellemeli
      final tryLocked = state.login(emp.email, '1234');
      expect(tryLocked.success, isFalse);
      expect(tryLocked.message, contains('Güvenlik Kilidi'));
    });

    test('3.3 T.C. Kimlik ve Telefon ile SMS OTP Tabanlı PIN Sıfırlama', () {
      final emp = state.allEmployees.firstWhere((e) => e.isApproved);

      // T.C. Kimlik ve Telefon eşleştirilerek OTP talep edilir
      final otpRes = state.requestPinResetOtp(
        tcKimlikNo: emp.tcKimlikNo,
        phone: emp.phone,
      );

      expect(otpRes.success, isTrue);
      expect(otpRes.otp, isNotNull);
      expect(otpRes.otp!.length, 6);
      expect(state.lastGeneratedResetOtp, otpRes.otp);

      // Yanlış OTP ile deneme başarısız olmalı
      final wrongVerify = state.verifyOtpAndResetPin(
        phone: emp.phone,
        otpCode: '000000',
        new4DigitPin: '7788',
      );
      expect(wrongVerify.success, isFalse);

      // Doğru OTP ile yeni 4 haneli PIN belirlenir
      final correctVerify = state.verifyOtpAndResetPin(
        phone: emp.phone,
        otpCode: otpRes.otp!,
        new4DigitPin: '7788',
      );
      expect(correctVerify.success, isTrue);

      // Kilit kalkmış ve yeni PIN ile oturum açılabilmelidir
      expect(state.isPinLockedOut, isFalse);
      final loginWithNewPin = state.login(emp.email, '7788');
      expect(loginWithNewPin.success, isTrue);
      expect(state.isLoggedIn, isTrue);
    });

    test('3.2 Biyometrik Mobil Doğrulama (Touch ID / Face ID) Entegrasyonu', () async {
      // Biyometrik giriş simülasyonu
      final bioRes = await state.loginWithBiometrics();
      expect(bioRes.success, isTrue);
      expect(state.isLoggedIn, isTrue);
    });
  });
}
