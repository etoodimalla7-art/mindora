import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindora_app/core/design/theme/app_theme.dart';
import 'package:mindora_app/features/ai/data/chat_providers.dart';
import 'package:mindora_app/features/ai/data/chat_repository.dart';
import 'package:mindora_app/features/ai/domain/chat_models.dart';
import 'package:mindora_app/features/ai/presentation/screens/chat_screen.dart';
import 'package:mindora_app/l10n/app_strings.dart';

class _FakeChatRepository extends ChatRepository {
  _FakeChatRepository() : super(Dio());

  StreamController<ChatStreamEvent>? activeController;
  String? reportedMessageId;
  String? reportedReason;
  String? loadedConversationId;

  final List<Conversation> conversations = [
    Conversation(
      id: 'conv-1',
      title: 'Calculus Integrals Help',
      subject: 'Mathematics',
      messageCount: 2,
      isArchived: false,
      createdAt: DateTime.utc(2026, 11, 18),
      updatedAt: DateTime.utc(2026, 11, 19),
    ),
  ];

  @override
  Stream<ChatStreamEvent> streamMessage({
    required String message,
    String? conversationId,
    String? subject,
    String? imageBase64,
    String? imageMimeType,
  }) {
    activeController = StreamController<ChatStreamEvent>();
    return activeController!.stream;
  }

  @override
  Future<List<Conversation>> listConversations() async => conversations;

  @override
  Future<ConversationDetail> getConversation(String id) async {
    loadedConversationId = id;
    return ConversationDetail(
      id: id,
      title: 'Calculus Integrals Help',
      subject: 'Mathematics',
      messageCount: 2,
      isArchived: false,
      createdAt: DateTime.utc(2026, 11, 18),
      updatedAt: DateTime.utc(2026, 11, 19),
      messages: [
        ChatMessage(
          id: 'hist-u-1',
          role: 'user',
          content: 'What is an antiderivative?',
          createdAt: DateTime.utc(2026, 11, 19),
        ),
        ChatMessage(
          id: 'hist-a-1',
          role: 'assistant',
          content: 'An antiderivative reverses differentiation.',
          createdAt: DateTime.utc(2026, 11, 19),
        ),
      ],
    );
  }

  @override
  Future<void> reportMessage({
    required String messageId,
    String? conversationId,
    required String reason,
    String? details,
    required String excerpt,
  }) async {
    reportedMessageId = messageId;
    reportedReason = reason;
  }
}

Widget _wrapChatTest(_FakeChatRepository repo) {
  return ProviderScope(
    overrides: [
      chatRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [AppStrings.delegate],
      home: const ChatScreen(),
    ),
  );
}

void main() {
  testWidgets('C2 streams SSE tokens progressively, displays RAG sources, and reports issue',
      (tester) async {
    final repo = _FakeChatRepository();
    await tester.pumpWidget(_wrapChatTest(repo));
    await tester.pumpAndSettle();

    // Send a prompt
    await tester.enterText(
      find.byType(TextField),
      'Explain derivative of x squared',
    );
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    // Emit meta + first token chunk (progressive rendering check)
    repo.activeController!.add(ChatMeta('conv-live'));
    repo.activeController!.add(ChatToken('The derivative '));
    await tester.pump();

    expect(find.textContaining('The derivative '), findsOneWidget);

    // Emit second chunk with RAG sources and close stream
    repo.activeController!.add(
      ChatToken('of x² is 2x.\n\n**Sources**\n- Calculus Notes Ch. 2'),
    );
    repo.activeController!.add(
      ChatDone(
        messageId: 'msg-assistant-99',
        toolsUsed: const [
          ToolUsage(
            name: 'course_rag',
            metadata: {
              'sources': ['Limits & Derivatives Guide'],
            },
          ),
        ],
        model: 'gemini-2.5-flash',
        provider: 'gemini',
      ),
    );
    await repo.activeController!.close();
    await tester.pumpAndSettle();

    expect(find.textContaining('of x² is 2x.'), findsOneWidget);
    expect(find.text('Sources from your documents'), findsOneWidget);
    expect(find.text('Calculus Notes Ch. 2'), findsOneWidget);
    expect(find.text('Limits & Derivatives Guide'), findsOneWidget);

    // Tap Report issue on the assistant message
    await tester.tap(find.text('Report issue'));
    await tester.pumpAndSettle();

    expect(find.text('Report an AI response'), findsOneWidget);
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();

    expect(repo.reportedMessageId, 'msg-assistant-99');
    expect(repo.reportedReason, 'Inaccurate answer');
    expect(find.text('Report sent. Thank you!'), findsOneWidget);
  });

  testWidgets('C2 drawer loads conversation history and supports new conversation',
      (tester) async {
    final repo = _FakeChatRepository();
    await tester.pumpWidget(_wrapChatTest(repo));
    await tester.pumpAndSettle();

    // Open drawer
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.text('Calculus Integrals Help'), findsOneWidget);

    // Select past conversation
    await tester.tap(find.text('Calculus Integrals Help'));
    await tester.pumpAndSettle();

    expect(repo.loadedConversationId, 'conv-1');
    expect(find.text('What is an antiderivative?'), findsOneWidget);
    expect(
      find.text('An antiderivative reverses differentiation.'),
      findsOneWidget,
    );

    // Start new conversation via AppBar action
    await tester.tap(find.byTooltip('New conversation'));
    await tester.pumpAndSettle();

    expect(find.text('What is an antiderivative?'), findsNothing);
    expect(find.text('Ask me anything'), findsOneWidget);
  });
}
