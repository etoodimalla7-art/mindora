import 'package:flutter/material.dart';
import '../../core/theme/spacing_tokens.dart';

/// A single selectable row used throughout onboarding (language, level,
/// goals, etc.) — consistent selection affordance everywhere instead of
/// each step inventing its own.
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? theme.colorScheme.primary : theme.dividerColor,
              width: selected ? 2 : 1,
            ),
            color: selected ? theme.colorScheme.primary.withValues(alpha: 0.06) : null,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: selected ? theme.colorScheme.primary : null),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
              if (selected) Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
