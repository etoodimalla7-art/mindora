import 'package:flutter/material.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../domain/chat_models.dart';
import 'sources_card.dart';
import 'tool_badges.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    // Split off the sources block if present.
    final (body, sources) = isUser
        ? (message.content, const <String>[])
        : SourcesCard.split(message.content);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _Avatar(isUser: false),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isUser
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                  ),
                  child: SelectableText(
                    body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isUser
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                ),
                if (!isUser && message.toolsUsed.isNotEmpty)
                  ToolBadges(tools: message.toolsUsed),
                if (!isUser && sources.isNotEmpty)
                  SourcesCard(sources: sources),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: AppSpacing.sm),
            _Avatar(isUser: true),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.isUser});
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isUser
        ? theme.colorScheme.primary.withValues(alpha: 0.15)
        : theme.colorScheme.primary;
    final fg = isUser ? theme.colorScheme.primary : theme.colorScheme.onPrimary;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(
        isUser ? Icons.person : Icons.auto_awesome,
        size: 16,
        color: fg,
      ),
    );
  }
}
