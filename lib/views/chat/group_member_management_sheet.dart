import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/chat_message.dart';
import '../../models/employee.dart';
import '../../state/pdks_state.dart';

/// Grup Üyeleri Yönetim Paneli (Kişi Ekleme / Çıkarma)
class GroupMemberManagementSheet extends StatefulWidget {
  final String channelId;

  const GroupMemberManagementSheet({
    super.key,
    required this.channelId,
  });

  static Future<void> show(BuildContext context, String channelId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GroupMemberManagementSheet(channelId: channelId),
    );
  }

  @override
  State<GroupMemberManagementSheet> createState() => _GroupMemberManagementSheetState();
}

class _GroupMemberManagementSheetState extends State<GroupMemberManagementSheet> {
  String _searchFilter = '';

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final channel = pdks.getChannelById(widget.channelId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (channel == null) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text('Grup kanalı bulunamadı.', style: TextStyle(color: AppColors.text(context))),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
          ],
        ),
      );
    }

    final canManage = pdks.canManageGroupMembers(channel.id);
    final allParticipants = pdks.getParticipantsForChannel(channel.id);
    final filteredParticipants = allParticipants.where((e) {
      if (_searchFilter.isEmpty) return true;
      final q = _searchFilter.toLowerCase();
      return e.fullName.toLowerCase().contains(q) ||
          e.department.toLowerCase().contains(q) ||
          e.title.toLowerCase().contains(q);
    }).toList();

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Çekmece Tutamacı
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Başlık ve Kanal Bilgisi
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: channel.iconColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(channel.icon, color: channel.iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${allParticipants.length} Katılımcı',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (canManage)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '👑 Yönetici Yetkisi',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Yönetici Hızlı Eylem Butonu: Yeni Kişi Ekle
          if (canManage) ...[
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOf(context),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Gruba Yeni Kişi Ekle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () => _openAddMemberDialog(context, pdks, channel),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Arama Çubuğu
          Container(
            decoration: BoxDecoration(
              color: AppColors.subtle(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder(context)),
            ),
            child: TextField(
              style: TextStyle(fontSize: 13, color: AppColors.text(context)),
              decoration: InputDecoration(
                hintText: 'Gruptaki üyelerde ara...',
                hintStyle: TextStyle(fontSize: 12, color: AppColors.textSub(context).withOpacity(0.6)),
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                suffixIcon: _searchFilter.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () => setState(() => _searchFilter = ''),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (val) => setState(() => _searchFilter = val.trim()),
            ),
          ),
          const SizedBox(height: 12),

          // Üye Listesi Başlığı
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GRUPTAKİ KİŞİLER (${filteredParticipants.length})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textSub(context),
                  letterSpacing: 0.6,
                ),
              ),
              if (!canManage)
                Text(
                  'Yalnızca Yöneticiler Üye Çıkarabilir',
                  style: TextStyle(fontSize: 10, color: AppColors.textSub(context)),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Üye Listesi
          Expanded(
            child: filteredParticipants.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        _searchFilter.isEmpty ? 'Grupta henüz üye bulunmuyor.' : 'Arama kriterine uygun üye bulunamadı.',
                        style: TextStyle(color: AppColors.textSub(context), fontSize: 13),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredParticipants.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.cardBorder(context).withOpacity(0.5)),
                    itemBuilder: (ctx, idx) {
                      final emp = filteredParticipants[idx];
                      final isCurrentUser = emp.id == pdks.currentUser.id;

                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: _getRoleColor(emp.role).withOpacity(0.18),
                          child: Text(
                            emp.fullName.isNotEmpty ? emp.fullName.substring(0, 1).toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _getRoleColor(emp.role),
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                emp.fullName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text(context),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCurrentUser) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Siz',
                                  style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          '${emp.department} • ${emp.roleDisplayName}',
                          style: TextStyle(fontSize: 11, color: AppColors.textSub(context)),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Yönetici ise kişiyi gruptan çıkarma butonu
                            if (canManage && !isCurrentUser)
                              IconButton(
                                icon: const Icon(Icons.person_remove_rounded, color: Colors.redAccent, size: 20),
                                tooltip: 'Gruptan Çıkar',
                                onPressed: () => _confirmRemoveMember(context, pdks, channel, emp),
                              ),
                            // Kişi kendisi ise gruptan ayrılma butonu
                            if (isCurrentUser && allParticipants.length > 1)
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(color: Colors.redAccent),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.logout_rounded, size: 14),
                                label: const Text('Ayrıl', style: TextStyle(fontSize: 11)),
                                onPressed: () => _confirmLeaveGroup(context, pdks, channel),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Gruba Yeni Kişi Ekleme Modalı
  void _openAddMemberDialog(BuildContext context, PdksState pdks, ChatChannel channel) {
    final nonParticipants = pdks.getNonParticipantsForChannel(channel.id);
    final Set<int> selectedIds = {};
    String addSearch = '';

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (dlgCtx, setDlgState) {
          final filteredCandidates = nonParticipants.where((e) {
            if (addSearch.isEmpty) return true;
            final q = addSearch.toLowerCase();
            return e.fullName.toLowerCase().contains(q) ||
                e.department.toLowerCase().contains(q) ||
                e.title.toLowerCase().contains(q);
          }).toList();

          return AlertDialog(
            backgroundColor: AppColors.cardBg(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOf(context).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.person_add_alt_1_rounded, color: AppColors.primaryOf(context), size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gruba Kişi Ekle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context))),
                      Text(channel.title, style: TextStyle(fontSize: 11, color: AppColors.textSub(context))),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (nonParticipants.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Şirketteki tüm çalışma arkadaşlarınız zaten bu grupta yer alıyor.',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Arama Kutusu
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.subtle(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder(context)),
                      ),
                      child: TextField(
                        style: TextStyle(fontSize: 13, color: AppColors.text(context)),
                        decoration: InputDecoration(
                          hintText: 'Personel adı veya departman ara...',
                          hintStyle: TextStyle(fontSize: 12, color: AppColors.textSub(context).withOpacity(0.6)),
                          prefixIcon: const Icon(Icons.search_rounded, size: 18),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onChanged: (val) => setDlgState(() => addSearch = val.trim()),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Tümünü Seç / Kaldır
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Eklenebilir Kişiler (${filteredCandidates.length})',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSub(context)),
                        ),
                        TextButton(
                          onPressed: () {
                            setDlgState(() {
                              if (selectedIds.length == filteredCandidates.length) {
                                selectedIds.clear();
                              } else {
                                selectedIds.addAll(filteredCandidates.map((e) => e.id));
                              }
                            });
                          },
                          child: Text(
                            selectedIds.length == filteredCandidates.length ? 'Seçimi Temizle' : 'Tümünü Seç',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryOf(context)),
                          ),
                        ),
                      ],
                    ),

                    // Aday Personel Listesi
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: AppColors.subtle(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder(context)),
                      ),
                      child: filteredCandidates.isEmpty
                          ? Center(
                              child: Text('Kişi bulunamadı.', style: TextStyle(color: AppColors.textSub(context), fontSize: 12)),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: filteredCandidates.length,
                              separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.cardBorder(context).withOpacity(0.5)),
                              itemBuilder: (c, i) {
                                final candidate = filteredCandidates[i];
                                final isSelected = selectedIds.contains(candidate.id);

                                return CheckboxListTile(
                                  dense: true,
                                  value: isSelected,
                                  activeColor: AppColors.primaryOf(context),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  title: Text(
                                    candidate.fullName,
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                                  ),
                                  subtitle: Text(
                                    '${candidate.department} • ${candidate.roleDisplayName}',
                                    style: TextStyle(fontSize: 10.5, color: AppColors.textSub(context)),
                                  ),
                                  onChanged: (val) {
                                    setDlgState(() {
                                      if (val == true) {
                                        selectedIds.add(candidate.id);
                                      } else {
                                        selectedIds.remove(candidate.id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dlgCtx),
                child: const Text('Vazgeç'),
              ),
              if (nonParticipants.isNotEmpty)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOf(context),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text(
                    selectedIds.isEmpty
                        ? 'Kişi Seçiniz'
                        : 'Seçilenleri Ekle (${selectedIds.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: selectedIds.isEmpty
                      ? null
                      : () async {
                          Navigator.pop(dlgCtx);
                          final result = await pdks.addMultipleMembersToGroup(
                            channelId: channel.id,
                            employeeIds: selectedIds.toList(),
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🎉 ${result.message}'),
                                backgroundColor: result.success ? AppColors.success : Colors.red,
                              ),
                            );
                            setState(() {}); // Modal içeriğini tazele
                          }
                        },
                ),
            ],
          );
        },
      ),
    );
  }

  /// Personeli Gruptan Çıkarma Onayı
  void _confirmRemoveMember(BuildContext context, PdksState pdks, ChatChannel channel, Employee targetEmp) {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: AppColors.cardBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
            SizedBox(width: 8),
            Text('Kişiyi Gruptan Çıkar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          '${targetEmp.fullName} kişisini "${channel.title}" grubundan çıkarmak istediğinize emin misiniz?\n\n'
          '⚠️ Personel bu grubun geçmiş mesajlarını ve yeni iletilerini artık göremeyecektir.',
          style: TextStyle(fontSize: 13, color: AppColors.text(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(dlgCtx);
              final res = await pdks.removeMemberFromGroup(
                channelId: channel.id,
                employeeId: targetEmp.id,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res.message),
                    backgroundColor: res.success ? Colors.green : Colors.red,
                  ),
                );
                setState(() {});
              }
            },
            child: const Text('Gruptan Çıkar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Gruptan Kendi İsteğiyle Ayrılma Onayı
  void _confirmLeaveGroup(BuildContext context, PdksState pdks, ChatChannel channel) {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: AppColors.cardBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.orangeAccent, size: 24),
            SizedBox(width: 8),
            Text('Gruptan Ayrıl', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          '"${channel.title}" grubundan ayrılmak istediğinize emin misiniz?\n\n'
          'Gruptan ayrıldığınızda bu grubun mesajlarını artık göremeyeceksiniz.',
          style: TextStyle(fontSize: 13, color: AppColors.text(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(dlgCtx);
              final res = await pdks.removeMemberFromGroup(
                channelId: channel.id,
                employeeId: pdks.currentUser.id,
              );
              if (context.mounted) {
                Navigator.pop(context); // bottom sheet'i de kapat
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res.message),
                    backgroundColor: res.success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Gruptan Ayrıl', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.boss:
        return const Color(0xFFD97706); // Altın
      case UserRole.admin:
        return const Color(0xFFDC2626); // Kırmızı
      case UserRole.hr:
        return const Color(0xFF9333EA); // Mor
      case UserRole.technician:
        return const Color(0xFF0284C7); // Gök Mavisi
      case UserRole.doctor:
        return const Color(0xFF059669); // Yeşil
      default:
        return const Color(0xFF2563EB); // Mavi
    }
  }
}
