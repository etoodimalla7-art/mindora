import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/chat_models.dart';
import 'chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(dioProvider)),
);

final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  return ref.watch(chatRepositoryProvider).listConversations();
});

final conversationDetailProvider =
    FutureProvider.family<ConversationDetail, String>((ref, id) async {
  return ref.watch(chatRepositoryProvider).getConversation(id);
});

class ChatState {
  const ChatState({
    this.conversationId,
    this.messages = const [],
    this.sending = false,
    this.error,
  });

  final String? conversationId;
  final List<ChatMessage> messages;
  final bool sending;
  final String? error;

  ChatState copyWith({
    String? conversationId,
    List<ChatMessage>? messages,
    bool? sending,
    String? error,
    bool clearError = false,
    bool clearConversation = false,
  }) =>
      ChatState(
        conversationId:
            clearConversation ? null : (conversationId ?? this.conversationId),
        messages: clearConversation ? const [] : (messages ?? this.messages),
        sending: sending ?? this.sending,
        error: clearError ? null : (error ?? this.error),
      );
}

class ChatController extends StateNotifier<ChatState> {
  ChatController(this._repo, this._ref) : super(const ChatState());

  final ChatRepository _repo;
  final Ref _ref;
  StreamSubscription<ChatStreamEvent>? _sub;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> loadConversation(String id) async {
    await _sub?.cancel();
    state = state.copyWith(
      conversationId: id,
      messages: const [],
      clearError: true,
    );
    try {
      final detail = await _ref.read(conversationDetailProvider(id).future);
      state = state.copyWith(
        conversationId: detail.id,
        messages: detail.messages,
      );
    } catch (_) {
      state = state.copyWith(error: 'We could not load this conversation.');
    }
  }

  void startNew() {
    _sub?.cancel();
    state = state.copyWith(clearConversation: true, clearError: true);
  }

  /// Send a message using the streaming endpoint.
  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return;

    final localUserId = 'local-user-${DateTime.now().microsecondsSinceEpoch}';
    final localAssistantId = 'local-assistant-${DateTime.now().microsecondsSinceEpoch}';

    // Optimistic user message + an empty assistant message we'll grow.
    final userMsg = ChatMessage(
      id: localUserId,
      role: 'user',
      content: trimmed,
      createdAt: DateTime.now(),
    );
    final assistantMsg = ChatMessage(
      id: localAssistantId,
      role: 'assistant',
      content: '',
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, assistantMsg],
      sending: true,
      clearError: true,
    );

    final completer = Completer<void>();

    _sub = _repo
        .streamMessage(
      message: trimmed,
      conversationId: state.conversationId,
    )
        .listen(
      (event) {
        if (event is ChatMeta) {
          state = state.copyWith(conversationId: event.conversationId);
        } else if (event is ChatToken) {
          final updated = state.messages.map((m) {
            if (m.id == localAssistantId) {
              return ChatMessage(
                id: m.id,
                role: m.role,
                content: m.content + event.text,
                toolsUsed: m.toolsUsed,
                model: m.model,
                provider: m.provider,
                createdAt: m.createdAt,
              );
            }
            return m;
          }).toList();
          state = state.copyWith(messages: updated);
        } else if (event is ChatDone) {
          final updated = state.messages.map((m) {
            if (m.id == localAssistantId) {
              return ChatMessage(
                id: event.messageId.isNotEmpty ? event.messageId : m.id,
                role: m.role,
                content: m.content,
                toolsUsed: event.toolsUsed,
                model: event.model,
                provider: event.provider,
                createdAt: m.createdAt,
              );
            }
            return m;
          }).toList();
          state = state.copyWith(messages: updated, sending: false);
          _ref.invalidate(conversationsProvider);
          completer.complete();
        } else if (event is ChatErrorEvent) {
          state = state.copyWith(
            messages: state.messages
                .where((m) => m.id != localAssistantId)
                .toList(),
            sending: false,
            error: event.message,
          );
          completer.complete();
        }
      },
      onError: (e) {
        if (!completer.isCompleted) {
          state = state.copyWith(
            messages: state.messages
                .where((m) => m.id != localAssistantId)
                .toList(),
            sending: false,
            error: 'Connection lost.',
          );
          completer.complete();
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          state = state.copyWith(sending: false);
          completer.complete();
        }
      },
      cancelOnError: true,
    );

    await completer.future;
  }

  void cancelStream() {
    _sub?.cancel();
    _sub = null;
    if (state.sending) {
      state = state.copyWith(sending: false);
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final chatControllerProvider =
    StateNotifierProvider<ChatController, ChatState>((ref) {
  return ChatController(ref.watch(chatRepositoryProvider), ref);
});
