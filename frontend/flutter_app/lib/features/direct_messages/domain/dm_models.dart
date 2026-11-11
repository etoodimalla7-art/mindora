import 'package:equatable/equatable.dart';

class DirectPeer extends Equatable {
  const DirectPeer({
    required this.userId,
    this.fullName,
    required this.email,
    this.avatarUrl,
  });

  final String userId;
  final String? fullName;
  final String email;
  final String? avatarUrl;

  String get displayName =>
      (fullName != null && fullName!.isNotEmpty) ? fullName! : email;

  factory DirectPeer.fromJson(Map<String, dynamic> j) => DirectPeer(
        userId: j['user_id'] as String,
        fullName: j['full_name'] as String?,
        email: j['email'] as String,
        avatarUrl: j['avatar_url'] as String?,
      );

  @override
  List<Object?> get props => [userId];
}

class DirectConversation extends Equatable {
  const DirectConversation({
    required this.id,
    required this.peer,
    this.lastMessageAt,
    this.lastMessagePreview,
    required this.unreadCount,
    required this.createdAt,
  });

  final String id;
  final DirectPeer peer;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final int unreadCount;
  final DateTime createdAt;

  factory DirectConversation.fromJson(Map<String, dynamic> j) =>
      DirectConversation(
        id: j['id'] as String,
        peer: DirectPeer.fromJson(j['peer'] as Map<String, dynamic>),
        lastMessageAt: j['last_message_at'] != null
            ? DateTime.parse(j['last_message_at'] as String)
            : null,
        lastMessagePreview: j['last_message_preview'] as String?,
        unreadCount: j['unread_count'] as int? ?? 0,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  @override
  List<Object?> get props => [id, lastMessageAt, unreadCount];
}

class DirectMessage extends Equatable {
  const DirectMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.readAt,
    this.senderName,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? senderName;

  factory DirectMessage.fromJson(Map<String, dynamic> j) => DirectMessage(
        id: j['id'] as String,
        conversationId: j['conversation_id'] as String,
        senderId: j['sender_id'] as String,
        content: j['content'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
        readAt: j['read_at'] != null
            ? DateTime.parse(j['read_at'] as String)
            : null,
        senderName: j['sender_name'] as String?,
      );

  @override
  List<Object?> get props => [id];
}
