import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindora_app/domain/ai_chat/chat_message.dart';
import 'package:mindora_app/presentation/features/ai_assistant/widgets/chat_bubble.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders message content', (tester) async {
    await tester.pumpWidget(wrap(
      const ChatBubble(message: ChatMessage(role: 'user', content: 'What is a derivative?')),
    ));
    expect(find.text('What is a derivative?'), findsOneWidget);
  });

  testWidgets('shows "From your course material" tag when the assistant used course_retriever', (tester) async {
    await tester.pumpWidget(wrap(
      const ChatBubble(
        message: ChatMessage(
          role: 'assistant', content: 'A derivative is the rate of change...',
          toolsUsed: ['course_retriever'], sourceDocumentId: 'doc-123',
        ),
      ),
    ));
    expect(find.text('From your course material'), findsOneWidget);
  });

  testWidgets('does NOT show the course-material tag for a general-knowledge reply', (tester) async {
    await tester.pumpWidget(wrap(
      const ChatBubble(
        message: ChatMessage(role: 'assistant', content: 'General answer.', toolsUsed: ['general_knowledge']),
      ),
    ));
    expect(find.text('From your course material'), findsNothing);
  });

  testWidgets('does NOT show the course-material tag on a user message even with tools set', (tester) async {
    // Guards against a copy-paste bug where isFromCourseMaterial ignores role.
    await tester.pumpWidget(wrap(
      const ChatBubble(
        message: ChatMessage(role: 'user', content: 'question', toolsUsed: ['course_retriever']),
      ),
    ));
    expect(find.text('From your course material'), findsNothing);
  });
}
