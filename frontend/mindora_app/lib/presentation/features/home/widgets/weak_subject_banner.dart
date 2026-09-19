import 'package:flutter/material.dart';
import '../../../../core/theme/spacing_tokens.dart';

class WeakSubjectBanner extends StatelessWidget {
  const WeakSubjectBanner({super.key, required this.subjectName});
  final String subjectName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_down_rounded, color: theme.colorScheme.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Your weakest subject right now is $subjectName. Consider adding it to today\'s plan.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
