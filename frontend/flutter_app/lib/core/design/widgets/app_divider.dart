import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

class AppDivider extends StatelessWidget {
  const AppDivider({super.key, this.label, this.spacing = AppSpacing.lg});

  final String? label;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (label == null) {
      return Divider(height: spacing * 2, color: theme.colorScheme.outline.withValues(alpha: 0.5));
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing),
      child: Row(
        children: [
          Expanded(child: Divider(color: theme.colorScheme.outline.withValues(alpha: 0.5))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(label!, style: theme.textTheme.labelSmall),
          ),
          Expanded(child: Divider(color: theme.colorScheme.outline.withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}
