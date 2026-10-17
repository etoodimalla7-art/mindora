import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../domain/chat_models.dart';
import 'sse_parser.dart';

class ChatSendResult {
  const ChatSendResult({
    required this.conversationId,
    required this.message,
    this.usage = const {},
  });

  final String conversationId;
  final ChatMessage message;
  final Map<String, dynamic> usage;
}

/// Events emitted by the streaming endpoint.
sealed class ChatStreamEvent {}

class ChatMeta extends ChatStreamEvent {
  ChatMeta(this.conversationId);
  final String conversationId;
}

class ChatToken extends ChatStreamEvent {
  ChatToken(this.text);
  final String text;
}

class ChatDone extends ChatStreamEvent {
  ChatDone({
    required this.messageId,
    required this.toolsUsed,
    required this.model,
    required this.provider,
  });
  final String messageId;
  final List<ToolUsage> toolsUsed;
  final String? model;
  final String? provider;
}

class ChatErrorEvent extends ChatStreamEvent {
  ChatErrorEvent(this.message);
  final String message;
}

class ChatRepository {
  ChatRepository(this._dio);
  final Dio _dio;

  Future<ChatSendResult> sendMessage({
    required String message,
    String? conversationId,
    String? subject,
  }) async {
    final body = <String, dynamic>{'message': message};
    if (conversationId != null) body['conversation_id'] = conversationId;
    if (subject != null) body['subject'] = subject;

    final r = await _dio.post('/ai/chat', data: body);
    final data = r.data as Map<String, dynamic>;
    return ChatSendResult(
      conversationId: data['conversation_id'] as String,
      message: ChatMessage.fromJson(data['message'] as Map<String, dynamic>),
      usage: (data['usage'] as Map<String, dynamic>?) ?? const {},
    );
  }

  /// Stream a chat message as SSE events.
  Stream<ChatStreamEvent> streamMessage({
    required String message,
    String? conversationId,
    String? subject,
  }) async* {
    final body = <String, dynamic>{'message': message};
    if (conversationId != null) body['conversation_id'] = conversationId;
    if (subject != null) body['subject'] = subject;

    // Timeout global (aligné sur le backend : 90s + marge 15s)
    const overallTimeout = Duration(seconds: 105);

    final controller = StreamController<ChatStreamEvent>();
    StreamSubscription? sub;

    final timer = Timer(overallTimeout, () {
      if (!controller.isClosed) {
        controller.add(ChatErrorEvent(
          'The response took too long. Please try again.',
        ));
        controller.close();
        sub?.cancel();
      }
    });

    try {
      final response = await _dio.post<ResponseBody>(
        '/ai/chat/stream',
        data: body,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

      final byteStream = response.data!.stream;
      final parser = SseParser();

      sub = byteStream.listen(
        (chunk) {
          for (final sse in parser.feed(chunk)) {
            final parsed = _parseEvent(sse);
            if (parsed != null && !controller.isClosed) {
              controller.add(parsed);
            }
          }
        },
        onError: (e) {
          if (!controller.isClosed) {
            controller.add(ChatErrorEvent('Connection error: $e'));
            controller.close();
          }
          timer.cancel();
        },
        onDone: () {
          for (final sse in parser.close()) {
            final parsed = _parseEvent(sse);
            if (parsed != null && !controller.isClosed) {
              controller.add(parsed);
            }
          }
          if (!controller.isClosed) controller.close();
          timer.cancel();
        },
        cancelOnError: true,
      );

      yield* controller.stream;
    } catch (e) {
      timer.cancel();
      if (!controller.isClosed) {
        controller.add(ChatErrorEvent('Failed to connect: $e'));
        controller.close();
      }
      rethrow;
    } finally {
      timer.cancel();
    }
  }

  ChatStreamEvent? _parseEvent(SseEvent sse) {
    try {
      final json = jsonDecode(sse.data) as Map<String, dynamic>;
      switch (sse.event) {
        case 'meta':
          return ChatMeta(json['conversation_id'] as String? ?? '');
        case 'token':
          return ChatToken(json['text'] as String? ?? '');
        case 'done':
          final tools = ((json['tools_used'] as List?) ?? [])
              .map((e) => ToolUsage.fromJson(e as Map<String, dynamic>))
              .toList();
          return ChatDone(
            messageId: json['message_id'] as String? ?? '',
            toolsUsed: tools,
            model: json['model'] as String?,
            provider: json['provider'] as String?,
          );
        case 'error':
          return ChatErrorEvent(json['message'] as String? ?? 'Unknown error');
      }
    } catch (_) {
      return null;
    }
    return null;
  }


  Future<List<Conversation>> listConversations() async {
    final r = await _dio.get('/ai/conversations');
    return (r.data as List)
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ConversationDetail> getConversation(String id) async {
    final r = await _dio.get('/ai/conversations/$id');
    return ConversationDetail.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> deleteConversation(String id) async {
    await _dio.delete('/ai/conversations/$id');
  }
}
