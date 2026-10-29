import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/app_notification.dart';
import '../../state/pdks_state.dart';
import '../cafeteria/cafeteria_menu_view_screen.dart';
import '../mobile/leave_request_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allNotifications = pdks.notifications;
    List<AppNotification> filtered = allNotifications;

    if (_selectedFilter == 'unread') {
      filtered = allNotifications.where((n) => !n.isRead).toList();
    } else if (_selectedFilter == 'cafeteria') {
      filtered = allNotifications.where((n) => n.type == NotificationType.cafeteria).toList();
    } else if (_selectedFilter == 'announcement') {
      filtered = allNotifications.where((n) => n.type == NotificationType.announcement).toList();
    } else if (_selectedFilter == 'attendance_leave') {
      filtered = allNotifications.where((n) => n.type == NotificationType.attendance || n.type == NotificationType.leave).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('Bildirimler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          if (pdks.unreadNotificationsCount > 0)
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryOf(context),
              ),
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Tümünü Okundu Say', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () {
                pdks.markAllNotificationsAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text('Tüm bildirimler okundu olarak işaretlendi.'),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Filtre Çipleri
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.cardBg(context),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'Tümü (${allNotifications.length})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('unread', 'Okunmamış (${pdks.unreadNotificationsCount})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('cafeteria', 'Yemekhane 🍽️'),
                  const SizedBox(width: 8),
                  _buildFilterChip('attendance_leave', 'Mesai & İzin'),
                  const SizedBox(width: 8),
                  _buildFilterChip('announcement', 'Şirket Duyuruları 📢'),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: AppColors.cardBorder(context)),

          // Bildirim Listesi
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOf(context).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.primaryOf(context)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Bildirim Bulunmuyor',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bu filtreye uygun herhangi bir bildiriminiz yok.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSub(context)),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      MediaQuery.of(context).padding.bottom + 20,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildNotificationCard(context, item, isDark, pdks);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipTextColor = isSelected
        ? Colors.white
        : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B));

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: chipTextColor,
        ),
      ),
      selected: isSelected,
      showCheckmark: false,
      selectedColor: AppColors.primaryOf(context),
      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: chipTextColor,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primaryOf(context) : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
      ),
      onSelected: (_) => setState(() => _selectedFilter = key),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotification item, bool isDark, PdksState pdks) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          pdks.markNotificationAsRead(item.id);
          if (item.type == NotificationType.cafeteria) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CafeteriaMenuViewScreen()));
          } else if (item.type == NotificationType.leave) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaveRequestScreen()));
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: item.isRead
                ? AppColors.cardBg(context)
                : (isDark
                    ? item.color.withOpacity(0.12)
                    : item.color.withOpacity(0.06)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: item.isRead
                  ? AppColors.cardBorder(context)
                  : item.color.withOpacity(0.4),
              width: item.isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                              color: AppColors.text(context),
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: item.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: TextStyle(
                        fontSize: 12,
                        color: item.isRead ? AppColors.textSub(context) : AppColors.text(context),
                        height: 1.35,
                      ),
                    ),
                    if (item.targetPhone != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Text(
                              'SMS & Push Gönderildi: ${item.targetPhone}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('dd MMM yyyy • HH:mm').format(item.timestamp),
                          style: TextStyle(fontSize: 10, color: AppColors.textSub(context).withOpacity(0.8)),
                        ),
                        if (item.type == NotificationType.cafeteria)
                          Text(
                            'Menüyü Gör ›',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: item.color),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
