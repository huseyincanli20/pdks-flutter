import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdks_flutter/state/pdks_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDKS Mesajlaşma Sistemi Testleri', () {
    late PdksState state;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      state = PdksState();
    });

    test('Varsayılan kurumsal kanallar yüklü olmalı', () {
      expect(state.systemChatChannels.length, greaterThanOrEqualTo(3));
      expect(state.systemChatChannels.any((c) => c.id == 'company_general'), isTrue);
      expect(state.systemChatChannels.any((c) => c.id == 'hr_support'), isTrue);
      expect(state.systemChatChannels.any((c) => c.id == 'management_announcements'), isTrue);
    });

    test('Bireysel sohbet kanal ID formatı simetrik olmalı', () {
      final id1 = state.getDirectChannelId(1, 2);
      final id2 = state.getDirectChannelId(2, 1);
      expect(id1, equals(id2));
      expect(id1, equals('dm_1_2'));
    });

    test('Kanal mesajı başarıyla gönderilmeli ve okunmalı', () {
      final initialCount = state.getMessagesForChannel('company_general').length;
      state.sendMessage(
        channelId: 'company_general',
        text: 'Test mesajı',
      );

      final updatedMsgs = state.getMessagesForChannel('company_general');
      expect(updatedMsgs.length, equals(initialCount + 1));
      expect(updatedMsgs.last.text, equals('Test mesajı'));

      state.markChannelAsRead('company_general');
      expect(state.getUnreadCountForChannel('company_general'), equals(0));
    });

    test('Yeni grup kurma yetkisi sadece Patron ve Admin için geçerli olmalı', () {
      // Normal çalışan (Ahmet Yılmaz - employee)
      state.login('personel@sirket.com', '1234');
      expect(state.canCreateGroupChat, isFalse);

      final employeeAttempt = state.createGroupChannel(
        title: 'Çalışan Grubu',
        subtitle: 'Yetkisiz deneme',
      );
      expect(employeeAttempt.success, isFalse);
      expect(employeeAttempt.message, contains('Yalnızca Şirket Patronu (CEO) veya Sistem Yöneticisi (Admin)'));

      // İK Yetkilisi (Zeynep Kaya - hr)
      state.login('ik@sirket.com', '2345');
      expect(state.canCreateGroupChat, isFalse);

      final hrAttempt = state.createGroupChannel(
        title: 'İK Ekip Grubu',
        subtitle: 'Yetkisiz deneme',
      );
      expect(hrAttempt.success, isFalse);

      // Şirket Patronu (Kemal Özdemir - boss)
      state.login('patron@sirket.com', '3456');
      expect(state.canCreateGroupChat, isTrue);

      final bossAttempt = state.createGroupChannel(
        title: 'Yönetim Kurulu & Saha',
        subtitle: 'Özel koordinasyon',
      );
      expect(bossAttempt.success, isTrue);
      expect(bossAttempt.channel, isNotNull);
      expect(state.allGroupChannels.any((c) => c.title == 'Yönetim Kurulu & Saha'), isTrue);

      // Sistem Yöneticisi (Serkan Arslan - admin)
      state.login('admin@sirket.com', '4567');
      expect(state.canCreateGroupChat, isTrue);

      final adminAttempt = state.createGroupChannel(
        title: 'IT & Sistem Destek',
        subtitle: 'Teknik operasyon grubu',
      );
      expect(adminAttempt.success, isTrue);
      expect(state.allGroupChannels.any((c) => c.title == 'IT & Sistem Destek'), isTrue);
    });
  });
}
