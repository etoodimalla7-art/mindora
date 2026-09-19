import 'package:flutter/material.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../domain/ai_chat/chat_message.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: isUser ? theme.colorScheme.primary : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: isUser ? null : Border.all(color: theme.dividerColor),
            ),
            child: Text(
              message.content,
              style: theme.textTheme.bodyLarge?.copyWith(color: isUser ? Colors.white : null),
            ),
          ),
          if (!isUser && message.isFromCourseMaterial)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_rounded, size: 14, color: theme.colorScheme.secondary),
                  const SizedBox(width: 4),
                  Text('From your course material', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
