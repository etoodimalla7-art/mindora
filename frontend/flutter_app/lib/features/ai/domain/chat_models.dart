import 'package:equatable/equatable.dart';

class ToolUsage extends Equatable {
  const ToolUsage({required this.name, this.error, this.metadata});

  final String name;
  final String? error;
  final Map<String, dynamic>? metadata;

  bool get hasError => error != null && error!.isNotEmpty;

  factory ToolUsage.fromJson(Map<String, dynamic> j) => ToolUsage(
        name: j['name'] as String,
        error: j['error'] as String?,
        metadata: j['metadata'] as Map<String, dynamic>?,
      );

  @override
  List<Object?> get props => [name, error];
}

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.toolsUsed = const [],
    this.model,
    this.provider,
    required this.createdAt,
  });

  final String id;
  final String role; // user | assistant | system | tool
  final String content;
  final List<ToolUsage> toolsUsed;
  final String? model;
  final String? provider;
  final DateTime createdAt;

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as String,
        role: j['role'] as String,
        content: j['content'] as String,
        toolsUsed: ((j['tools_used'] as List?) ?? [])
            .map((e) => ToolUsage.fromJson(e as Map<String, dynamic>))
            .toList(),
        model: j['model'] as String?,
        provider: j['provider'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  @override
  List<Object?> get props => [id];
}

class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.title,
    this.subject,
    required this.messageCount,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? subject;
  final int messageCount;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        id: j['id'] as String,
        title: j['title'] as String,
        subject: j['subject'] as String?,
        messageCount: j['message_count'] as int? ?? 0,
        isArchived: j['is_archived'] as bool? ?? false,
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );

  @override
  List<Object?> get props => [id, messageCount, updatedAt];
}

class ConversationDetail extends Equatable {
  const ConversationDetail({
    required this.id,
    required this.title,
    this.subject,
    required this.messageCount,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  final String id;
  final String title;
  final String? subject;
  final int messageCount;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  factory ConversationDetail.fromJson(Map<String, dynamic> j) =>
      ConversationDetail(
        id: j['id'] as String,
        title: j['title'] as String,
        subject: j['subject'] as String?,
        messageCount: j['message_count'] as int? ?? 0,
        isArchived: j['is_archived'] as bool? ?? false,
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
        messages: ((j['messages'] as List?) ?? [])
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [id, messages.length];
}
