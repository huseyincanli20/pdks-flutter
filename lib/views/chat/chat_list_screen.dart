import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/chat_message.dart';
import '../../models/employee.dart';
import '../../state/pdks_state.dart';
import 'chat_conversation_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String _selectedFilter = 'all'; // 'all', 'channels', 'direct'
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final currentUser = pdks.currentUser;
    final otherEmployees = pdks.employees.where((e) => e.id != currentUser.id).toList();

    // Kanallar
    final channels = pdks.systemChatChannels;

    // Aktif Bireysel Sohbetler
    final List<({Employee employee, String channelId, ChatMessage? lastMsg, int unreadCount})> directChats = [];
    for (final emp in otherEmployees) {
      final chId = pdks.getDirectChannelId(currentUser.id, emp.id);
      final msgs = pdks.getMessagesForChannel(chId);
      final unread = pdks.getUnreadCountForChannel(chId);
      // Mesaj varsa veya arama yapılıyorsa listeye al
      if (msgs.isNotEmpty || _searchQuery.isNotEmpty) {
        directChats.add((
          employee: emp,
          channelId: chId,
          lastMsg: msgs.isNotEmpty ? msgs.last : null,
          unreadCount: unread,
        ));
      }
    }

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Şirket İçi Mesajlar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (pdks.unreadChatCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryOf(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${pdks.unreadChatCount} Yeni',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Yeni Sohbet Başlat',
            onPressed: () => _openNewChatModal(context, pdks),
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama Çubuğu
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder(context)),
              ),
              child: TextField(
                style: TextStyle(fontSize: 14, color: AppColors.text(context)),
                decoration: InputDecoration(
                  hintText: 'Kanal veya çalışma arkadaşı ara...',
                  hintStyle: TextStyle(fontSize: 13, color: AppColors.textSub(context).withOpacity(0.6)),
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.primaryOf(context), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              ),
            ),
          ),

          // Filtre Butonları
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _buildFilterChip('all', 'Tümü Sohbetler'),
                const SizedBox(width: 8),
                _buildFilterChip('channels', 'Şirket Kanalları (${channels.length})'),
                const SizedBox(width: 8),
                _buildFilterChip('direct', 'Bireysel (${directChats.length})'),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.cardBorder(context)),

          // Liste
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 80),
              children: [
                // 1. ŞİRKET KANALLARI BÖLÜMÜ
                if (_selectedFilter != 'direct') ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'KURUMSAL GRUP KANALLARI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryOf(context),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  ...channels
                      .where((ch) => _searchQuery.isEmpty || ch.title.toLowerCase().contains(_searchQuery) || ch.subtitle.toLowerCase().contains(_searchQuery))
                      .map((ch) {
                    final lastMsg = pdks.getLastMessageForChannel(ch.id);
                    final unreadCount = pdks.getUnreadCountForChannel(ch.id);

                    return _buildChannelTile(
                      context: context,
                      title: ch.title,
                      subtitle: lastMsg != null
                          ? '${lastMsg.senderName.split(' ').first}: ${lastMsg.text}'
                          : ch.subtitle,
                      icon: ch.icon,
                      iconColor: ch.iconColor,
                      time: lastMsg?.timestamp,
                      unreadCount: unreadCount,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatConversationScreen(
                              channelId: ch.id,
                              title: ch.title,
                              subtitle: ch.subtitle,
                              icon: ch.icon,
                              iconColor: ch.iconColor,
                            ),
                          ),
                        );
                      },
                    );
                  }),
                  const SizedBox(height: 18),
                ],

                // 2. BİREYSEL DİREKT MESAJLAR BÖLÜMÜ
                if (_selectedFilter != 'channels') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'BİREYSEL MESAJLAR (1-E-1)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textSub(context),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _openNewChatModal(context, pdks),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '+ Yeni Sohbet',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryOf(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (directChats.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.cardBorder(context)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.mark_chat_unread_outlined, size: 36, color: AppColors.primaryOf(context).withOpacity(0.5)),
                          const SizedBox(height: 10),
                          Text(
                            'Henüz bireysel mesajlaşmanız yok',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text(context)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rehberden bir çalışma arkadaşı seçerek hemen 1-e-1 sohbet başlatabilirsiniz.',
                            style: TextStyle(fontSize: 11, color: AppColors.textSub(context)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.person_add_alt_rounded, size: 16),
                            label: const Text('Kişi Seç & Sohbet Başlat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () => _openNewChatModal(context, pdks),
                          ),
                        ],
                      ),
                    )
                  else
                    ...directChats
                        .where((d) => _searchQuery.isEmpty || d.employee.fullName.toLowerCase().contains(_searchQuery) || d.employee.department.toLowerCase().contains(_searchQuery))
                        .map((d) {
                      return _buildDirectChatTile(
                        context: context,
                        item: d,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatConversationScreen(
                                channelId: d.channelId,
                                title: d.employee.fullName,
                                subtitle: '${d.employee.department} • ${d.employee.title}',
                                directUser: d.employee,
                              ),
                            ),
                          );
                        },
                      );
                    }),
                ],
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryOf(context),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.chat_rounded),
        label: const Text('Yeni Mesaj', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _openNewChatModal(context, pdks),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.text(context),
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primaryOf(context),
      backgroundColor: AppColors.cardBg(context),
      side: BorderSide(color: isSelected ? AppColors.primaryOf(context) : AppColors.cardBorder(context)),
      onSelected: (_) => setState(() => _selectedFilter = key),
    );
  }

  Widget _buildChannelTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required DateTime? time,
    required int unreadCount,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: unreadCount > 0 ? FontWeight.w900 : FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.text(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (time != null)
              Text(
                DateFormat('HH:mm').format(time),
                style: TextStyle(fontSize: 11, color: unreadCount > 0 ? AppColors.primaryOf(context) : AppColors.textSub(context)),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: unreadCount > 0 ? AppColors.text(context) : AppColors.textSub(context),
                    fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unreadCount > 0)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOf(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirectChatTile({
    required BuildContext context,
    required ({Employee employee, String channelId, ChatMessage? lastMsg, int unreadCount}) item,
    required VoidCallback onTap,
  }) {
    final emp = item.employee;
    final roleColor = _getRoleBadgeColor(emp.role);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: onTap,
        leading: Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: roleColor.withOpacity(0.18),
              child: Text(
                emp.fullName.isNotEmpty ? emp.fullName.substring(0, 2).toUpperCase() : 'P',
                style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBg(context), width: 2),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      emp.fullName,
                      style: TextStyle(
                        fontWeight: item.unreadCount > 0 ? FontWeight.w900 : FontWeight.bold,
                        fontSize: 13.5,
                        color: AppColors.text(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      emp.roleDisplayName,
                      style: TextStyle(color: roleColor, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            if (item.lastMsg != null)
              Text(
                DateFormat('HH:mm').format(item.lastMsg!.timestamp),
                style: TextStyle(fontSize: 11, color: item.unreadCount > 0 ? AppColors.primaryOf(context) : AppColors.textSub(context)),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item.lastMsg != null
                      ? item.lastMsg!.text
                      : '${emp.department} • ${emp.title}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: item.unreadCount > 0 ? AppColors.text(context) : AppColors.textSub(context),
                    fontWeight: item.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.unreadCount > 0)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOf(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${item.unreadCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleBadgeColor(UserRole role) {
    switch (role) {
      case UserRole.boss:
        return const Color(0xFFD97706);
      case UserRole.admin:
        return const Color(0xFF9333EA);
      case UserRole.hr:
        return const Color(0xFF0284C7);
      case UserRole.cafeteria:
        return const Color(0xFFEA580C);
      case UserRole.employee:
      default:
        return const Color(0xFF2563EB);
    }
  }

  void _openNewChatModal(BuildContext context, PdksState pdks) {
    final employees = pdks.employees.where((e) => e.id != pdks.currentUser.id).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: AppColors.cardBorder(context)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Yeni Sohbet Başlat',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.text(context)),
                ),
                Text(
                  'Mesajlaşmak istediğiniz çalışma arkadaşınızı seçin:',
                  style: TextStyle(fontSize: 12, color: AppColors.textSub(context)),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    itemCount: employees.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.cardBorder(context)),
                    itemBuilder: (context, idx) {
                      final emp = employees[idx];
                      final roleColor = _getRoleBadgeColor(emp.role);
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: roleColor.withOpacity(0.18),
                          child: Text(
                            emp.fullName.isNotEmpty ? emp.fullName.substring(0, 2).toUpperCase() : 'P',
                            style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        title: Text(
                          emp.fullName,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text(context)),
                        ),
                        subtitle: Text(
                          '${emp.department} • ${emp.title}',
                          style: TextStyle(color: AppColors.textSub(context), fontSize: 11.5),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSub(context)),
                        onTap: () {
                          Navigator.pop(ctx);
                          final chId = pdks.getDirectChannelId(pdks.currentUser.id, emp.id);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatConversationScreen(
                                channelId: chId,
                                title: emp.fullName,
                                subtitle: '${emp.department} • ${emp.title}',
                                directUser: emp,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
