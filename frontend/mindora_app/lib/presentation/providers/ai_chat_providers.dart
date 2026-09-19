import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/network/api_client.dart';
import '../../data/ai_chat/ai_chat_repository.dart';
import '../../domain/ai_chat/chat_message.dart';
import 'core_providers.dart';

final aiChatRepositoryProvider = Provider((ref) {
  return AiChatRepository(ref.watch(apiClientProvider));
});

/// Set by the study-session screen right before handing off to the AI
/// tutor tab, so the chat can auto-send a topic-specific opener without
/// route params (same pattern as activePlanIdProvider in Phase 7).
final pendingTutorPromptProvider = StateProvider.autoDispose<String?>((ref) => null);

class ChatState {
  const ChatState({
    this.messages = const [], this.conversationId, this.isSending = false,
    this.error, this.socraticMode = false,
  });
  final List<ChatMessage> messages;
  final String? conversationId;
  final bool isSending;
  final String? error;
  final bool socraticMode;

  ChatState copyWith({
    List<ChatMessage>? messages, String? conversationId, bool? isSending,
    String? error, bool clearError = false, bool? socraticMode,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      conversationId: conversationId ?? this.conversationId,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
      socraticMode: socraticMode ?? this.socraticMode,
    );
  }
}

/// Owns the current chat screen's transcript. A fresh conversation
/// starts with no id — the backend creates one on the first message and
/// this controller remembers it for every follow-up in the same session.
class ChatController extends StateNotifier<ChatState> {
  ChatController(this._ref) : super(const ChatState());

  final Ref _ref;
  bool _overridePendingForNextSend = false;
  final _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  /// Section 43: plays the synthesized reply when a real TTS provider
  /// is configured. The current dev MockSpeechProvider always returns
  /// null here, so this path is exercised once a real provider is
  /// wired up — the plumbing is ready ahead of that.
  Future<void> _playAudioReplyIfPresent(String? base64Audio) async {
    if (base64Audio == null || base64Audio.isEmpty) return;
    try {
      final bytes = base64Decode(base64Audio);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/tutor_reply_${DateTime.now().millisecondsSinceEpoch}.mp3');
      await file.writeAsBytes(bytes);
      await _audioPlayer.play(DeviceFileSource(file.path));
    } catch (_) {
      // Non-fatal: the text reply is already shown regardless.
    }
  }

  /// Section 37: toggling this flags an explicit override to send with
  /// the *next* message only — after that, the backend's persisted
  /// preference (Conversation.style_preferences) carries it forward,
  /// so we don't need to keep resending it every turn.
  void setSocraticMode(bool enabled) {
    _overridePendingForNextSend = true;
    state = state.copyWith(socraticMode: enabled);
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isSending) return;

    final sendOverride = _overridePendingForNextSend;
    _overridePendingForNextSend = false;

    state = state.copyWith(
      messages: [...state.messages, ChatMessage(role: 'user', content: trimmed)],
      isSending: true,
      clearError: true,
    );

    try {
      final repo = _ref.read(aiChatRepositoryProvider);
      final result = await repo.sendMessage(
        message: trimmed,
        conversationId: state.conversationId,
        socraticOverride: sendOverride ? state.socraticMode : null,
      );
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            role: 'assistant', content: result.reply,
            toolsUsed: result.toolsUsed, sourceDocumentId: result.sourceDocumentId,
          ),
        ],
        conversationId: result.conversationId,
        isSending: false,
        socraticMode: result.stylePreferences['socratic'] == true,
      );
    } catch (error) {
      state = state.copyWith(isSending: false, error: extractApiErrorMessage(error));
    }
  }

  /// Section 43: sends a recorded audio clip. The transcript is shown
  /// as the user's message (so the student can see what was heard),
  /// then the reply arrives exactly like a typed message.
  Future<void> sendVoice(String filePath) async {
    if (state.isSending) return;
    state = state.copyWith(isSending: true, clearError: true);
    try {
      final repo = _ref.read(aiChatRepositoryProvider);
      final result = await repo.sendVoiceMessage(filePath: filePath, conversationId: state.conversationId);
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(role: 'user', content: result.transcript),
          ChatMessage(role: 'assistant', content: result.reply, toolsUsed: result.toolsUsed, sourceDocumentId: result.sourceDocumentId),
        ],
        conversationId: result.conversationId,
        isSending: false,
      );
      unawaited(_playAudioReplyIfPresent(result.audioReplyBase64));
    } catch (error) {
      state = state.copyWith(isSending: false, error: extractApiErrorMessage(error));
    }
  }

  /// Section 44: sends a photo of a question. The extracted question
  /// text is shown as the user's message, so the student can confirm
  /// it was read correctly.
  Future<void> sendImage(String filePath) async {
    if (state.isSending) return;
    state = state.copyWith(isSending: true, clearError: true);
    try {
      final repo = _ref.read(aiChatRepositoryProvider);
      final result = await repo.sendVisionMessage(filePath: filePath, conversationId: state.conversationId);
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(role: 'user', content: result.extractedQuestion),
          ChatMessage(role: 'assistant', content: result.reply, toolsUsed: result.toolsUsed, sourceDocumentId: result.sourceDocumentId),
        ],
        conversationId: result.conversationId,
        isSending: false,
      );
    } catch (error) {
      state = state.copyWith(isSending: false, error: extractApiErrorMessage(error));
    }
  }
}

final chatControllerProvider = StateNotifierProvider.autoDispose<ChatController, ChatState>((ref) {
  return ChatController(ref);
});
