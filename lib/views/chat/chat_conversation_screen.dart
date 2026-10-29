import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/chat_message.dart';
import '../../models/employee.dart';
import '../../state/pdks_state.dart';
import '../../core/utils/platform_file_helper.dart';

class ChatConversationScreen extends StatefulWidget {
  final String channelId;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Employee? directUser;

  const ChatConversationScreen({
    super.key,
    required this.channelId,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.directUser,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _showQuickTemplates = false;

  final List<String> _quickTemplates = [
    '👋 Günaydın, herkese iyi çalışmalar dilerim!',
    '⏱️ Mesaimi başlattım, ofisteyim.',
    '🚗 Trafikten dolayı 15 dakika gecikeceğim.',
    '📋 İzin talebim hakkında bilgi alabilir miyim?',
    '🍽️ Yemekhane menüsü bugün harika görünüyor!',
    '✅ Tamamdır, teşekkürler.',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PdksState>().markChannelAsRead(widget.channelId);
        _scrollToBottom(animate: false);
      }
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        if (animate) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent + 80,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
        }
      }
    });
  }

  void _handleSend({
    String? customText,
    MessageType type = MessageType.text,
    String? attachmentName,
    String? attachmentSize,
  }) {
    final text = customText ?? _textCtrl.text;
    if (text.trim().isEmpty && attachmentName == null) return;

    context.read<PdksState>().sendMessage(
      channelId: widget.channelId,
      text: text,
      receiverId: widget.directUser?.id,
      type: type,
      attachmentName: attachmentName,
      attachmentSize: attachmentSize,
    );

    if (customText == null) {
      _textCtrl.clear();
    }
    _scrollToBottom();
  }

  void _showAttachmentSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.cardBorder(context)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              'Mesaja Belge, PDF veya Konum Ekle',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.file_upload_rounded, color: Color(0xFF2563EB)),
              ),
              title: Text('Telefonumdan Belge / PDF Seç', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
              subtitle: Text('Cihazınızdaki PDF, Word veya rapor dosyasını gönderin', style: TextStyle(color: AppColors.textSub(context), fontSize: 12)),
              onTap: () async {
                // iOS Safari uyumluluğu için dosya seçiciyi modal kapanmadan ÖNCE hemen tetikle
                final pickFuture = PlatformFileHelper.pickDocumentFile();
                Navigator.pop(ctx);
                final file = await pickFuture;
                if (file != null) {
                  _handleSend(
                    customText: '📄 ${file.name}',
                    type: MessageType.document,
                    attachmentName: file.name,
                    attachmentSize: file.size,
                  );
                }
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF0284C7)),
              ),
              title: Text('Kurumsal Hazır Formlar (PDF)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
              subtitle: Text('İzin formu, sağlık raporu veya masraf pusulası', style: TextStyle(color: AppColors.textSub(context), fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _showPredefinedFormsDialog(context);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on_rounded, color: Color(0xFF10B981)),
              ),
              title: Text('Ofis Konumu Paylaş', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
              subtitle: Text('Şirket geofence merkez koordinatını ilet', style: TextStyle(color: AppColors.textSub(context), fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _handleSend(
                  customText: '📍 Şirket Merkez Ofis Konumu (PDKS Geofence Noktası)',
                  type: MessageType.location,
                  attachmentName: 'Merkez Ofis Koordinatı (41.0082° N, 28.9784° E)',
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B)),
              ),
              title: Text('Hazır Mesaj Şablonları', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
              subtitle: Text('Sık kullanılan hızlı kurumsal yanıtlar', style: TextStyle(color: AppColors.textSub(context), fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _showQuickTemplates = !_showQuickTemplates);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showPredefinedFormsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Kurumsal Belge Seçin', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFormOption(
              title: 'İş Göremezlik & Sağlık Raporu (PDF)',
              size: '1.2 MB',
              onTap: () {
                Navigator.pop(ctx);
                _handleSend(
                  customText: '📄 Sağlık Raporu ektedir, bilginize sunarım.',
                  type: MessageType.document,
                  attachmentName: 'Saglik_Raporu_Ekim_2026.pdf',
                  attachmentSize: '1.2 MB',
                );
              },
            ),
            _buildFormOption(
              title: 'Yıllık İzin Talep Dilekçesi (PDF)',
              size: '480 KB',
              onTap: () {
                Navigator.pop(ctx);
                _handleSend(
                  customText: '📄 İmzalı Yıllık İzin Talep Formum ektedir.',
                  type: MessageType.document,
                  attachmentName: 'Yillik_Izin_Dilekcesi_2026.pdf',
                  attachmentSize: '480 KB',
                );
              },
            ),
            _buildFormOption(
              title: 'Personel Masraf & Harcama Pusulası (PDF)',
              size: '890 KB',
              onTap: () {
                Navigator.pop(ctx);
                _handleSend(
                  customText: '📄 Şirket Görevi Masraf ve Harcama Pusulası.',
                  type: MessageType.document,
                  attachmentName: 'Personel_Masraf_Pusulasi.pdf',
                  attachmentSize: '890 KB',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormOption({required String title, required String size, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 24),
      title: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.text(context))),
      subtitle: Text(size, style: TextStyle(fontSize: 11, color: AppColors.textSub(context))),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final messages = pdks.getMessagesForChannel(widget.channelId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    (widget.iconColor ?? AppColors.primaryOf(context)).withOpacity(0.2),
                    widget.iconColor ?? AppColors.primaryOf(context),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: widget.directUser != null
                    ? Text(
                        widget.directUser!.fullName.isNotEmpty ? widget.directUser!.fullName.substring(0, 2).toUpperCase() : 'P',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      )
                    : Icon(widget.icon ?? Icons.chat_bubble_outline_rounded, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.subtitle ?? (widget.directUser != null ? '${widget.directUser!.department} • Çevrimiçi' : 'Şirket Kanalı'),
                        style: TextStyle(fontSize: 11, color: AppColors.textSub(context)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt_rounded),
            tooltip: 'Hızlı Şablonlar',
            onPressed: () => setState(() => _showQuickTemplates = !_showQuickTemplates),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Kanal Bilgisi',
            onPressed: () => _showChannelInfo(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mesaj Listesi
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: (widget.iconColor ?? AppColors.primaryOf(context)).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.icon ?? Icons.mark_chat_unread_rounded,
                            size: 40,
                            color: widget.iconColor ?? AppColors.primaryOf(context),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Henüz mesaj bulunmuyor',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sohbeti ilk başlatan siz olun!',
                          style: TextStyle(fontSize: 12, color: AppColors.textSub(context)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == pdks.currentUser.id;
                      return _buildMessageBubble(context, msg, isMe, isDark);
                    },
                  ),
          ),

          // Hızlı Şablonlar Çubuğu (Açılıp kapanabilir)
          if (_showQuickTemplates)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: AppColors.cardBg(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '⚡ Hızlı Kurumsal Mesaj Şablonları:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSub(context)),
                      ),
                      InkWell(
                        onTap: () => setState(() => _showQuickTemplates = false),
                        child: const Icon(Icons.close_rounded, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _quickTemplates.map((template) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            backgroundColor: AppColors.subtle(context),
                            side: BorderSide(color: AppColors.cardBorder(context)),
                            label: Text(
                              template,
                              style: TextStyle(fontSize: 11, color: AppColors.text(context)),
                            ),
                            onPressed: () {
                              _handleSend(customText: template, type: MessageType.quickTemplate);
                              setState(() => _showQuickTemplates = false);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

          // Alt Mesaj Yazma Barı
          Container(
            padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              border: Border(top: BorderSide(color: AppColors.cardBorder(context))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 26),
                  color: AppColors.primaryOf(context),
                  tooltip: 'Ek Dosya / Konum / Şablon',
                  onPressed: _showAttachmentSheet,
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.subtle(context),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.cardBorder(context)),
                    ),
                    child: TextField(
                      controller: _textCtrl,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(fontSize: 14, color: AppColors.text(context)),
                      decoration: InputDecoration(
                        hintText: 'Mesajınızı yazın...',
                        hintStyle: TextStyle(fontSize: 13, color: AppColors.textSub(context).withOpacity(0.7)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryOf(context),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryOf(context).withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: () => _handleSend(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage msg, bool isMe, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: _getRoleColor(msg.senderRole).withOpacity(0.2),
              child: Text(
                msg.senderName.isNotEmpty ? msg.senderName.substring(0, 1).toUpperCase() : '?',
                style: TextStyle(
                  color: _getRoleColor(msg.senderRole),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.primaryOf(context)
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                border: isMe ? null : Border.all(color: AppColors.cardBorder(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Gönderici Başlığı (Grup kanallarında ve başkası ise)
                  if (!isMe && widget.directUser == null) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          msg.senderName,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: _getRoleColor(msg.senderRole),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: _getRoleColor(msg.senderRole).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            msg.senderRole.label,
                            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: _getRoleColor(msg.senderRole)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Belge / Ek Kartı
                  if (msg.type == MessageType.document) ...[
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          PlatformFileHelper.saveAndOpen(
                            fileName: msg.attachmentName ?? 'Belge.pdf',
                            content: 'Kurumsal PDKS Belgesi\nDosya: ${msg.attachmentName ?? "Belge.pdf"}\nGönderen: ${msg.senderName}\nTarih: ${DateFormat("dd.MM.yyyy HH:mm").format(msg.timestamp)}',
                            mimeType: 'application/pdf',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              content: Text('📄 ${msg.attachmentName ?? "Belge"} açılıyor / indiriliyor...'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.white.withOpacity(0.18) : AppColors.subtle(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isMe ? Colors.white.withOpacity(0.3) : AppColors.cardBorder(context),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.picture_as_pdf_rounded, color: isMe ? Colors.white : Colors.redAccent, size: 22),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg.attachmentName ?? 'Belge.pdf',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: isMe ? Colors.white : AppColors.text(context),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          msg.attachmentSize ?? 'PDF Belgesi',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            color: isMe ? Colors.white70 : AppColors.textSub(context),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '• Aç / İndir',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: isMe ? Colors.white : AppColors.primaryOf(context),
                                          ),
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
                    ),
                  ],

                  // Konum Kartı
                  if (msg.type == MessageType.location) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.white.withOpacity(0.15) : AppColors.subtle(context),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on_rounded, color: isMe ? Colors.white : const Color(0xFF10B981), size: 20),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              msg.attachmentName ?? 'Konum',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isMe ? Colors.white : AppColors.text(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Mesaj Metni
                  Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isMe ? Colors.white : AppColors.text(context),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 3),

                  // Zaman ve Okundu Durumu
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(msg.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white70 : AppColors.textSub(context).withOpacity(0.7),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.done_all_rounded, size: 14, color: Colors.white70),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
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

  void _showChannelInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subtitle ?? 'PDKS Şirket İçi Güvenli Mesajlaşma Hattı',
              style: TextStyle(color: AppColors.textSub(context), fontSize: 13),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.subtle(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security_rounded, color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tüm mesajlar şirket sunucularında şifreli olarak saklanır ve yalnızca yetkili çalışanlarca görüntülenir.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSub(context)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
