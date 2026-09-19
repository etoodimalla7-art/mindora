import 'package:flutter/material.dart';
import '../../../../core/theme/spacing_tokens.dart';

class StreakChip extends StatelessWidget {
  const StreakChip({super.key, required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    if (days <= 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded, size: 18, color: Colors.deepOrange),
          const SizedBox(width: AppSpacing.xs),
          Text('$days-day streak', style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}
