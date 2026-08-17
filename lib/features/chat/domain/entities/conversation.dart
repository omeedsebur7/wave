import 'package:equatable/equatable.dart';

class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.participantIds,
    required this.otherUserName,
    required this.updatedAt,
    this.otherUserAvatarUrl,
    this.lastMessage,
    this.unreadCount = 0,
    this.aboutProductId,
  });

  final String id;
  final List<String> participantIds;
  final String otherUserName;
  final String? otherUserAvatarUrl;
  final DateTime updatedAt;
  final String? lastMessage;
  final int unreadCount;

  /// Most chats in a marketplace start from a listing. Carrying the product id
  /// lets the thread show what it's about, which saves the "which item?"
  /// exchange that otherwise opens every conversation.
  final String? aboutProductId;

  @override
  List<Object?> get props => [id, updatedAt, unreadCount, lastMessage];
}

class Message extends Equatable {
  const Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
    this.status = MessageStatus.sent,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final MessageStatus status;

  @override
  List<Object?> get props => [id, status, text];
}

/// `sending` and `failed` exist for the offline queue (§6): a message written
/// without a connection is shown immediately in a pending state and retried,
/// rather than silently disappearing.
enum MessageStatus { sending, sent, failed }
