import 'package:flutter/material.dart';
import 'employee.dart';

enum MessageType {
  text,
  document,
  location,
  quickTemplate,
  image,
}

class ChatMessage {
  final String id;
  final int senderId;
  final String senderName;
  final UserRole senderRole;
  final int? receiverId; // null ise grup/kanal mesajı
  final String channelId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;
  final String? attachmentName;
  final String? attachmentSize;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    this.receiverId,
    required this.channelId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
    this.attachmentName,
    this.attachmentSize,
  });

  ChatMessage copyWith({
    String? id,
    int? senderId,
    String? senderName,
    UserRole? senderRole,
    int? receiverId,
    String? channelId,
    String? text,
    DateTime? timestamp,
    bool? isRead,
    MessageType? type,
    String? attachmentName,
    String? attachmentSize,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      receiverId: receiverId ?? this.receiverId,
      channelId: channelId ?? this.channelId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      attachmentName: attachmentName ?? this.attachmentName,
      attachmentSize: attachmentSize ?? this.attachmentSize,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole.name,
      'receiverId': receiverId,
      'channelId': channelId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type.name,
      'attachmentName': attachmentName,
      'attachmentSize': attachmentSize,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    UserRole parsedRole = UserRole.employee;
    try {
      parsedRole = UserRole.values.firstWhere(
        (r) => r.name == json['senderRole'],
        orElse: () => UserRole.employee,
      );
    } catch (_) {}

    MessageType parsedType = MessageType.text;
    try {
      parsedType = MessageType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => MessageType.text,
      );
    } catch (_) {}

    return ChatMessage(
      id: json['id']?.toString() ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: json['senderId'] ?? 0,
      senderName: json['senderName'] ?? '',
      senderRole: parsedRole,
      receiverId: json['receiverId'],
      channelId: json['channelId'] ?? '',
      text: json['text'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      isRead: json['isRead'] ?? false,
      type: parsedType,
      attachmentName: json['attachmentName'],
      attachmentSize: json['attachmentSize'],
    );
  }
}

class ChatChannel {
  final String id;
  final String title;
  final String subtitle;
  final bool isDirect;
  final int? directUserId;
  final IconData icon;
  final Color iconColor;
  final List<int>? participantIds;

  const ChatChannel({
    required this.id,
    required this.title,
    required this.subtitle,
    this.isDirect = false,
    this.directUserId,
    required this.icon,
    required this.iconColor,
    this.participantIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'isDirect': isDirect,
      'directUserId': directUserId,
      'iconCode': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconColorValue': iconColor.value,
      'participantIds': participantIds,
    };
  }

  factory ChatChannel.fromJson(Map<String, dynamic> json) {
    final IconData parsedIcon = _resolveChannelIcon(json['iconCode']);

    Color parsedColor = const Color(0xFF2563EB);
    if (json['iconColorValue'] != null) {
      parsedColor = Color(json['iconColorValue'] as int);
    }

    List<int>? participants;
    if (json['participantIds'] != null) {
      participants = (json['participantIds'] as List)
          .map((e) => (e as num).toInt())
          .toList();
    }

    return ChatChannel(
      id: json['id']?.toString() ?? 'channel_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      isDirect: json['isDirect'] ?? false,
      directUserId: json['directUserId'],
      icon: parsedIcon,
      iconColor: parsedColor,
      participantIds: participants,
    );
  }

  static IconData _resolveChannelIcon(dynamic code) {
    if (code == null) return Icons.groups_rounded;
    final int val = code is int ? code : (int.tryParse(code.toString()) ?? 0);
    switch (val) {
      case 0xe2eb:
        return Icons.group_rounded;
      case 0xe2ea:
        return Icons.groups_rounded;
      case 0xe153:
        return Icons.campaign_rounded;
      case 0xe5fe:
        return Icons.support_agent_rounded;
      case 0xe19a:
        return Icons.chat_bubble_rounded;
      case 0xe253:
        return Icons.forum_rounded;
      default:
        return Icons.groups_rounded;
    }
  }
}
