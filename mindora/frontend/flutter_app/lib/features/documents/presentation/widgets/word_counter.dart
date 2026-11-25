import 'package:flutter/material.dart';

import '../../../../core/design/tokens/app_spacing.dart';

class WordCounter extends StatelessWidget {
  const WordCounter({
    super.key,
    required this.text,
    this.minWords = 20,
    this.minUniqueWords = 8,
  });

  final String text;
  final int minWords;
  final int minUniqueWords;

  static int _wordCount(String text) {
    final t = text.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  static int _uniqueCount(String text) {
    final t = text.toLowerCase();
    final tokens = RegExp(r"[\wÀ-ÿ'-]+").allMatches(t).map((m) => m.group(0)!);
    return tokens.toSet().length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final words = _wordCount(text);
    final unique = _uniqueCount(text);
    final wordsOk = words >= minWords;
    final uniqueOk = unique >= minUniqueWords;
    final progress = (words / minWords).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                wordsOk ? Icons.check_circle : Icons.edit_note,
                size: 18,
                color: wordsOk
                    ? const Color(0xFF10B981)
                    : theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                wordsOk
                    ? '$words words — minimum reached'
                    : '$words / $minWords words',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: wordsOk ? const Color(0xFF10B981) : null,
                ),
              ),
              const Spacer(),
              Text(
                '$unique unique',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: uniqueOk
                      ? const Color(0xFF10B981)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surface,
              valueColor: AlwaysStoppedAnimation(
                wordsOk ? const Color(0xFF10B981) : theme.colorScheme.primary,
              ),
            ),
          ),
          if (!wordsOk) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Write at least $minWords words to describe the document.',
              style: theme.textTheme.labelSmall,
            ),
          ] else if (!uniqueOk) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add a bit more variety to increase the unique word count.',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
}
