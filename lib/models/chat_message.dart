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
}
