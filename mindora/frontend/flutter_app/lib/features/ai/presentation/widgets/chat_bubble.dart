import 'package:flutter/material.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/voice/tts_button.dart';
import '../../../../l10n/app_strings.dart';
import '../../domain/chat_models.dart';
import 'sources_card.dart';
import 'tool_badges.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    this.onReport,
  });

  final ChatMessage message;
  final void Function(ChatMessage message)? onReport;

  List<String> _extractToolSources() {
    final result = <String>[];
    for (final tool in message.toolsUsed) {
      final meta = tool.metadata;
      if (meta == null) continue;
      final raw = meta['sources'] ?? meta['titles'] ?? meta['documents'];
      if (raw is List) {
        for (final item in raw) {
          final text = item.toString().trim();
          if (text.isNotEmpty) result.add(text);
        }
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final isUser = message.isUser;

    final (body, inlineSources) = isUser
        ? (message.content, const <String>[])
        : SourcesCard.split(message.content);

    final mergedSources = <String>{
      ...inlineSources,
      if (!isUser) ..._extractToolSources(),
    }.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const _Avatar(isUser: false),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isUser
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                          height: 1.5,
                        ),
                      ),
                      if (!isUser && body.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TtsButton(text: body),
                            if (onReport != null) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Semantics(
                                button: true,
                                label: s.reportIssue,
                                child: TextButton.icon(
                                  onPressed: () => onReport!(message),
                                  icon: Icon(
                                    Icons.flag_outlined,
                                    size: 16,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.65),
                                  ),
                                  label: Text(
                                    s.reportIssue,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isUser && message.toolsUsed.isNotEmpty)
                  ToolBadges(tools: message.toolsUsed),
                if (!isUser && mergedSources.isNotEmpty)
                  SourcesCard(sources: mergedSources),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: AppSpacing.sm),
            const _Avatar(isUser: true),
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
