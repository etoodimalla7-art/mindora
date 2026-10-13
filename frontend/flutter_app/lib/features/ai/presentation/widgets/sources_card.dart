import 'package:flutter/material.dart';

import '../../../../core/design/tokens/app_spacing.dart';

/// Parses a sources block from an assistant message and renders it as a
/// small card. Matches the "**Sources**" section produced by course_rag.
class SourcesCard extends StatelessWidget {
  const SourcesCard({super.key, required this.sources});
  final List<String> sources;

  static const _marker = '**Sources**';

  /// Split the message content into (body, sources list).
  /// Returns an empty sources list if no `**Sources**` marker is found.
  static (String, List<String>) split(String content) {
    final idx = content.indexOf(_marker);
    if (idx == -1) return (content, const []);

    final body = content.substring(0, idx).trimRight();
    final tail = content.substring(idx + _marker.length).trim();

    final sources = tail
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.startsWith('-'))
        .map((l) => l.replaceFirst(RegExp(r'^-\s*'), ''))
        .toList();

    return (body, sources);
  }

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.library_books_outlined,
                    size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Sources from your documents',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (final s in sources)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: theme.textTheme.bodySmall),
                    Expanded(
                      child: Text(
                        s.replaceAll('*', ''),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
