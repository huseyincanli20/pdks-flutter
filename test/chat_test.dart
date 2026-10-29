import 'package:flutter_test/flutter_test.dart';
import 'package:pdks_flutter/state/pdks_state.dart';

void main() {
  group('PDKS Mesajlaşma Sistemi Testleri', () {
    late PdksState state;

    setUp(() {
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
  });
}
