import 'package:flutter/material.dart';

import '../../domain/chat_models.dart';

class ToolBadges extends StatelessWidget {
  const ToolBadges({super.key, required this.tools});
  final List<ToolUsage> tools;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = tools.where((t) => !t.hasError).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final t in visible)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_iconFor(t.name), size: 12,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    _labelFor(t.name),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static IconData _iconFor(String name) => switch (name) {
        'calculator' => Icons.calculate_outlined,
        'course_rag' => Icons.menu_book_outlined,
        'general_chat' => Icons.auto_awesome_outlined,
        _ => Icons.build_outlined,
      };

  static String _labelFor(String name) => switch (name) {
        'calculator' => 'calculator',
        'course_rag' => 'your documents',
        'general_chat' => 'AI',
        _ => name,
      };
}
