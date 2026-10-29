import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/chat_message.dart';
import '../../models/employee.dart';
import '../../models/page_customization.dart';
import '../../state/pdks_state.dart';
import '../common/admin_edit_mode_bar.dart';
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
    final channels = pdks.allGroupChannels;
    final canCreateGroup = pdks.canCreateGroupChat;

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
          if (canCreateGroup)
            IconButton(
              icon: const Icon(Icons.group_add_rounded),
              tooltip: 'Yeni Grup Kur (Yönetici)',
              onPressed: () => _openCreateGroupModal(context, pdks),
            ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Yeni Bireysel Sohbet',
            onPressed: () => _openNewChatModal(context, pdks),
          ),
        ],
      ),
      body: Column(
        children: [
          // Yönetici & Admin Düzenleme Çubuğu
          const AdminEditModeBar(
            pageId: 'chat_list',
            pageTitle: 'Mesajlaşma Ekranı',
            editableSections: [
              PageSectionItem(id: 'search_filter', title: 'Arama & Filtre Çubuğu'),
              PageSectionItem(id: 'channels_section', title: 'Kurumsal Grup Kanalları'),
              PageSectionItem(id: 'direct_chats_section', title: 'Bireysel Sohbetler (1-e-1)'),
            ],
          ),

          // Arama Çubuğu & Filtre Kapsülleri
          AdminEditableSection(
            pageId: 'chat_list',
            sectionId: 'search_filter',
            sectionTitle: 'Arama & Filtre Çubuğu',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                  AdminEditableSection(
                    pageId: 'chat_list',
                    sectionId: 'channels_section',
                    sectionTitle: 'Kurumsal Grup Kanalları',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
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
                            if (canCreateGroup)
                              InkWell(
                                onTap: () => _openCreateGroupModal(context, pdks),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Icon(Icons.add_circle_outline_rounded, size: 14, color: AppColors.primaryOf(context)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '+ Yeni Grup Kur (Yönetim)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryOf(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.textSub(context)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Grup Yetkisi: Patron & Admin',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSub(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // 2. BİREYSEL DİREKT MESAJLAR BÖLÜMÜ
                if (_selectedFilter != 'channels') ...[
                  AdminEditableSection(
                    pageId: 'chat_list',
                    sectionId: 'direct_chats_section',
                    sectionTitle: 'Bireysel Sohbetler (1-e-1)',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryOf(context),
        foregroundColor: Colors.white,
        icon: Icon(canCreateGroup ? Icons.add_comment_rounded : Icons.chat_rounded),
        label: Text(
          canCreateGroup ? 'Yeni Mesaj / Grup' : 'Yeni Mesaj',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          if (canCreateGroup) {
            _showNewMessageOptionsSheet(context, pdks);
          } else {
            _openNewChatModal(context, pdks);
          }
        },
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

  void _showNewMessageOptionsSheet(BuildContext context, PdksState pdks) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.cardBorder(context)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              'Mesajlaşma İşlemi Seçin',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.text(context)),
            ),
            Text(
              'Yetkiniz dahilinde yeni bir grup kanalı veya bireysel sohbet başlatabilirsiniz.',
              style: TextStyle(fontSize: 12, color: AppColors.textSub(context)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.group_add_rounded, color: Color(0xFFD97706)),
              ),
              title: Text('Yeni Grup Kanalı Kur (Yönetim Yetkisi)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
              subtitle: Text('Şirket içi departman veya proje koordinasyon grubu oluşturun', style: TextStyle(color: AppColors.textSub(context), fontSize: 11.5)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                _openCreateGroupModal(context, pdks);
              },
            ),
            const SizedBox(height: 6),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF2563EB)),
              ),
              title: Text('Bireysel Sohbet Başlat (1-e-1)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
              subtitle: Text('Rehberden bir çalışma arkadaşınızla özel birebir yazışma başlatın', style: TextStyle(color: AppColors.textSub(context), fontSize: 11.5)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                _openNewChatModal(context, pdks);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openCreateGroupModal(BuildContext context, PdksState pdks) {
    if (!pdks.canCreateGroupChat) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yetki Sınırı: Yalnızca Şirket Patronu (CEO) veya Sistem Yöneticisi (Admin) yeni grup kurabilir.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleCtrl = TextEditingController();
    final subtitleCtrl = TextEditingController();
    final otherEmployees = pdks.employees.where((e) => e.id != pdks.currentUser.id).toList();
    final Set<int> selectedEmployeeIds = otherEmployees.map((e) => e.id).toSet();

    final availableIcons = [
      Icons.groups_rounded,
      Icons.campaign_rounded,
      Icons.rocket_launch_rounded,
      Icons.bolt_rounded,
      Icons.business_center_rounded,
      Icons.analytics_rounded,
      Icons.support_agent_rounded,
      Icons.code_rounded,
      Icons.terminal_rounded,
      Icons.security_rounded,
    ];

    final availableColors = [
      const Color(0xFF2563EB), // Mavi
      const Color(0xFF10B981), // Zümrüt Yeşili
      const Color(0xFF9333EA), // Mor
      const Color(0xFFD97706), // Kehribar Altın
      const Color(0xFF0284C7), // Gök Mavisi
      const Color(0xFFEF4444), // Kırmızı
      const Color(0xFF4F46E5), // İndigo
    ];

    IconData selectedIcon = Icons.groups_rounded;
    Color selectedColor = availableColors.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: AppColors.cardBorder(context)),
            ),
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFD97706), size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yeni Grup Kanalı Kur',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.text(context)),
                            ),
                            Text(
                              '👑 Yönetici Yetkisi: ${pdks.currentUser.roleDisplayName} (${pdks.currentUser.fullName})',
                              style: const TextStyle(fontSize: 11, color: Color(0xFFD97706), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Grup Adı
                  Text('Grup Adı *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleCtrl,
                    style: TextStyle(fontSize: 14, color: AppColors.text(context)),
                    decoration: InputDecoration(
                      hintText: 'örn: Saha & Operasyon Ekibi',
                      hintStyle: TextStyle(fontSize: 13, color: AppColors.textSub(context).withOpacity(0.6)),
                      filled: true,
                      fillColor: AppColors.subtle(context),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.cardBorder(context))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.cardBorder(context))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Grup Açıklaması
                  Text('Kanal Konusu / Açıklama', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: subtitleCtrl,
                    style: TextStyle(fontSize: 14, color: AppColors.text(context)),
                    decoration: InputDecoration(
                      hintText: 'örn: Günlük saha durum raporları ve lojistik bildirimleri',
                      hintStyle: TextStyle(fontSize: 13, color: AppColors.textSub(context).withOpacity(0.6)),
                      filled: true,
                      fillColor: AppColors.subtle(context),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.cardBorder(context))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.cardBorder(context))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // İkon Seçimi
                  Text('Kanal İkonu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: availableIcons.map((ic) {
                        final isSel = selectedIcon == ic;
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedIcon = ic),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSel ? selectedColor : AppColors.subtle(context),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSel ? selectedColor : AppColors.cardBorder(context), width: isSel ? 2 : 1),
                            ),
                            child: Icon(ic, color: isSel ? Colors.white : AppColors.text(context), size: 20),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Renk Seçimi
                  Text('Tema Rengi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: availableColors.map((col) {
                        final isSel = selectedColor == col;
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedColor = col),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: col,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSel ? Colors.white : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: isSel
                                  ? [BoxShadow(color: col.withOpacity(0.5), blurRadius: 6, spreadRadius: 1)]
                                  : null,
                            ),
                            child: isSel ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Katılımcılar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Katılımcılar (${selectedEmployeeIds.length} / ${otherEmployees.length})',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            if (selectedEmployeeIds.length == otherEmployees.length) {
                              selectedEmployeeIds.clear();
                            } else {
                              selectedEmployeeIds.addAll(otherEmployees.map((e) => e.id));
                            }
                          });
                        },
                        child: Text(
                          selectedEmployeeIds.length == otherEmployees.length ? 'Tümünü Kaldır' : 'Tümünü Ekle',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryOf(context)),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.subtle(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder(context)),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: otherEmployees.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.cardBorder(context).withOpacity(0.5)),
                      itemBuilder: (ctx, idx) {
                        final emp = otherEmployees[idx];
                        final isChecked = selectedEmployeeIds.contains(emp.id);
                        return CheckboxListTile(
                          dense: true,
                          value: isChecked,
                          title: Text(emp.fullName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                          subtitle: Text('${emp.department} • ${emp.title}', style: TextStyle(fontSize: 11, color: AppColors.textSub(context))),
                          activeColor: AppColors.primaryOf(context),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) {
                                selectedEmployeeIds.add(emp.id);
                              } else {
                                selectedEmployeeIds.remove(emp.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Grubu Kur Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOf(context),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: const Text('Grubu Oluştur & Mesajlaşmayı Başlat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      onPressed: () {
                        if (titleCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Lütfen grup için bir başlık giriniz.'), backgroundColor: Colors.red),
                          );
                          return;
                        }
                        final participantList = [pdks.currentUser.id, ...selectedEmployeeIds];
                        final result = pdks.createGroupChannel(
                          title: titleCtrl.text.trim(),
                          subtitle: subtitleCtrl.text.trim().isEmpty ? 'Grup Sohbeti' : subtitleCtrl.text.trim(),
                          icon: selectedIcon,
                          iconColor: selectedColor,
                          participantIds: participantList,
                        );

                        if (result.success && result.channel != null) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('🎉 ${result.message}'), backgroundColor: AppColors.success),
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatConversationScreen(
                                channelId: result.channel!.id,
                                title: result.channel!.title,
                                subtitle: result.channel!.subtitle,
                                icon: result.channel!.icon,
                                iconColor: result.channel!.iconColor,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result.message), backgroundColor: Colors.red),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
