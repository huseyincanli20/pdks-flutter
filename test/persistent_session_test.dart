import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdks_flutter/core/services/database_service.dart';
import 'package:pdks_flutter/state/pdks_state.dart';
import 'package:pdks_flutter/models/employee.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Kalıcı Oturum Yönetimi (Persistent User Session) Test Paketi', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await DatabaseService().init(forceReload: true);
      await DatabaseService().clearUserSession();
    });

    test('1. Başlangıçta oturum kapalı olmalı', () {
      final state = PdksState();
      expect(state.isLoggedIn, isFalse);
      expect(DatabaseService().isSessionActive(), isFalse);
      expect(DatabaseService().getLoggedInUserEmail(), isNull);
    });

    test('2. Giriş yapıldığında oturum hafızaya ve diske kalıcı olarak kaydedilmeli', () {
      final state = PdksState();
      final res = state.login('personel@sirket.com', '1234');
      expect(res.success, isTrue);
      expect(state.isLoggedIn, isTrue);
      expect(state.currentUser.email, 'personel@sirket.com');

      // DatabaseService kontrolü
      expect(DatabaseService().isSessionActive(), isTrue);
      expect(DatabaseService().getLoggedInUserEmail(), 'personel@sirket.com');
    });

    test('3. Uygulamadan çıkılıp tekrar girildiğinde (App Restart) kullanıcı oturumu açık kalmalı', () {
      final state1 = PdksState();
      final res1 = state1.login('ik@sirket.com', '2345');
      expect(res1.success, isTrue);
      expect(state1.isLoggedIn, isTrue);
      expect(state1.currentUser.role, UserRole.hr);

      // Uygulama kapatıldı ve yeniden başlatıldı simülasyonu
      final state2 = PdksState();
      expect(state2.isLoggedIn, isTrue);
      expect(state2.currentUser.email, 'ik@sirket.com');
      expect(state2.currentUser.role, UserRole.hr);
    });

    test('4. Kullanıcı bizzat "Oturumu Kapat" yapana kadar çıkış yapılmamalı, kapatınca oturum silinmeli', () {
      final state = PdksState();
      final res = state.login('patron@sirket.com', '3456');
      expect(res.success, isTrue);
      expect(state.isLoggedIn, isTrue);

      // Kullanıcı oturumu kapatıyor
      state.logout();
      expect(state.isLoggedIn, isFalse);
      expect(DatabaseService().isSessionActive(), isFalse);
      expect(DatabaseService().getLoggedInUserEmail(), isNull);

      // Oturum kapatıldıktan sonra uygulama yeniden açıldığında giriş ekranında kalmalı
      final stateRestart = PdksState();
      expect(stateRestart.isLoggedIn, isFalse);
    });

    test('5. Biyometrik veya test kullanıcısı değişiminde de kalıcı oturum güncellenmeli', () {
      final state = PdksState();
      final emp = state.employees.firstWhere((e) => e.email == 'admin@sirket.com');
      state.switchUserForTesting(emp);

      expect(state.isLoggedIn, isTrue);
      expect(DatabaseService().getLoggedInUserEmail(), 'admin@sirket.com');

      // Restart
      final stateRestart = PdksState();
      expect(stateRestart.isLoggedIn, isTrue);
      expect(stateRestart.currentUser.email, 'admin@sirket.com');
    });
  });
}
