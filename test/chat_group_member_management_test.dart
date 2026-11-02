import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pdks_flutter/state/pdks_state.dart';
import 'package:pdks_flutter/models/employee.dart';
import 'package:pdks_flutter/views/chat/group_member_management_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mesajlaşma Grup Yeni Kişi Ekleme & Çıkarma Test Paketi', () {
    late PdksState pdks;
    late Employee adminUser;
    late Employee member1;
    late Employee member2;
    late Employee outsideEmp;

    setUp(() {
      pdks = PdksState();
      adminUser = pdks.employees.firstWhere((e) => e.role == UserRole.boss || e.role == UserRole.admin);
      pdks.switchUserForTesting(adminUser);

      final otherEmps = pdks.employees.where((e) => e.id != adminUser.id).toList();
      member1 = otherEmps[0];
      member2 = otherEmps[1];
      outsideEmp = otherEmps[2];
    });

    test('1. Yönetici Yeni Grup Kurup Katılımcı Listesini Belirleyebilmeli', () {
      final groupRes = pdks.createGroupChannel(
        title: 'Özel Proje Ekibi Alfa',
        subtitle: 'Ar-Ge ve İnovasyon Çalışma Grubu',
        participantIds: [adminUser.id, member1.id],
      );

      expect(groupRes.success, isTrue);
      expect(groupRes.channel, isNotNull);
      final channelId = groupRes.channel!.id;

      final participants = pdks.getParticipantsForChannel(channelId);
      expect(participants.length, equals(2));
      expect(participants.any((e) => e.id == member1.id), isTrue);
      expect(participants.any((e) => e.id == outsideEmp.id), isFalse);
    });

    test('2. Gruba Yeni Kişi Ekleme (addMemberToGroup) Başarıyla Çalışmalı', () async {
      final groupRes = pdks.createGroupChannel(
        title: 'Lojistik Koordinasyon',
        subtitle: 'Depo ve sevkiyat',
        participantIds: [adminUser.id, member1.id],
      );
      final channelId = groupRes.channel!.id;

      // Henüz ekli olmayan outsideEmp'i ekle
      final addRes = await pdks.addMemberToGroup(
        channelId: channelId,
        employeeId: outsideEmp.id,
      );

      expect(addRes.success, isTrue);
      expect(addRes.message, contains(outsideEmp.fullName));

      final updatedParticipants = pdks.getParticipantsForChannel(channelId);
      expect(updatedParticipants.length, equals(3));
      expect(updatedParticipants.any((e) => e.id == outsideEmp.id), isTrue);

      // Grup içinde sistem bildirim mesajı oluşmuş olmalı
      final messages = pdks.getMessagesForChannel(channelId);
      expect(messages.any((m) => m.text.contains(outsideEmp.fullName) && m.text.contains('ekledi')), isTrue);

      // Mükerrer ekleme reddedilmeli
      final duplicateRes = await pdks.addMemberToGroup(
        channelId: channelId,
        employeeId: outsideEmp.id,
      );
      expect(duplicateRes.success, isFalse);
      expect(duplicateRes.message, contains('zaten bu grupta'));
    });

    test('3. Gruba Çoklu Kişi Ekleme (addMultipleMembersToGroup) Başarıyla Çalışmalı', () async {
      final groupRes = pdks.createGroupChannel(
        title: 'Saha Denetim Ekibi',
        subtitle: 'Kalite ve İSG',
        participantIds: [adminUser.id],
      );
      final channelId = groupRes.channel!.id;

      final batchRes = await pdks.addMultipleMembersToGroup(
        channelId: channelId,
        employeeIds: [member1.id, member2.id],
      );

      expect(batchRes.success, isTrue);
      expect(batchRes.addedCount, equals(2));

      final participants = pdks.getParticipantsForChannel(channelId);
      expect(participants.length, equals(3));
      expect(participants.any((e) => e.id == member1.id), isTrue);
      expect(participants.any((e) => e.id == member2.id), isTrue);
    });

    test('4. Gruptan Kişi Çıkarma (removeMemberFromGroup) ve İzolasyon Denetimi', () async {
      final groupRes = pdks.createGroupChannel(
        title: 'İmalat Vardiya Grubu',
        subtitle: 'Vardiya amirleri',
        participantIds: [adminUser.id, member1.id, member2.id],
      );
      final channelId = groupRes.channel!.id;

      // member2'yi gruptan çıkar
      final removeRes = await pdks.removeMemberFromGroup(
        channelId: channelId,
        employeeId: member2.id,
      );

      expect(removeRes.success, isTrue);
      expect(removeRes.message, contains(member2.fullName));

      final updatedParticipants = pdks.getParticipantsForChannel(channelId);
      expect(updatedParticipants.length, equals(2));
      expect(updatedParticipants.any((e) => e.id == member2.id), isFalse);

      // Çıkarma sistem mesajı gönderilmiş olmalı
      final messages = pdks.getMessagesForChannel(channelId);
      expect(messages.any((m) => m.text.contains(member2.fullName) && m.text.contains('çıkardı')), isTrue);
    });

    test('5. Kendi İsteğiyle Gruptan Ayrılma (Self-Leave)', () async {
      final groupRes = pdks.createGroupChannel(
        title: 'Sosyal Kulüp',
        subtitle: 'Hafta sonu etkinlikleri',
        participantIds: [adminUser.id, member1.id],
      );
      final channelId = groupRes.channel!.id;

      // member1 olarak oturum aç ve gruptan ayrıl
      pdks.switchUserForTesting(member1);

      final leaveRes = await pdks.removeMemberFromGroup(
        channelId: channelId,
        employeeId: member1.id,
      );

      expect(leaveRes.success, isTrue);
      expect(leaveRes.message, contains('ayrıldınız'));

      final participants = pdks.getParticipantsForChannel(channelId);
      expect(participants.any((e) => e.id == member1.id), isFalse);
    });

    test('6. Yetkisiz Kullanıcı Başkasını Gruptan Çıkaramaz veya Ekleyemez (Yetki Sınırı)', () async {
      final groupRes = pdks.createGroupChannel(
        title: 'Yönetim Kurulu Grubu',
        subtitle: 'Üst düzey yöneticiler',
        participantIds: [adminUser.id, member1.id],
      );
      final channelId = groupRes.channel!.id;

      // Oturumu normal personele (member1) çevir
      pdks.switchUserForTesting(member1);

      // Başka birini eklemeye çalışsın
      final unauthorizedAdd = await pdks.addMemberToGroup(
        channelId: channelId,
        employeeId: outsideEmp.id,
      );
      expect(unauthorizedAdd.success, isFalse);
      expect(unauthorizedAdd.message, contains('Yetki Sınırı'));

      // Başka birini çıkarmaya çalışsın
      final unauthorizedRemove = await pdks.removeMemberFromGroup(
        channelId: channelId,
        employeeId: adminUser.id,
      );
      expect(unauthorizedRemove.success, isFalse);
      expect(unauthorizedRemove.message, contains('Yetki Sınırı'));
    });

    testWidgets('7. GroupMemberManagementSheet UI Render ve Üye Listeleme Testi', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 900));

      final groupRes = pdks.createGroupChannel(
        title: 'Finans ve Muhasebe Ekibi',
        subtitle: 'Aylık bütçe ve harcama onayları',
      );
      final channelId = groupRes.channel!.id;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<PdksState>.value(
              value: pdks,
              child: GroupMemberManagementSheet(channelId: channelId),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Finans ve Muhasebe Ekibi'), findsOneWidget);
      expect(find.text('Gruba Yeni Kişi Ekle'), findsOneWidget);
      expect(find.textContaining('GRUPTAKİ KİŞİLER'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });
  });
}
