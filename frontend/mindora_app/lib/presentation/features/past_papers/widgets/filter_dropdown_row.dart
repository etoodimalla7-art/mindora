import 'package:flutter/material.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// Section 30's browse hierarchy (country -> system -> level -> subject
/// -> year), rendered as a horizontally scrolling row of dropdown chips
/// rather than 5 stacked full-width dropdowns — keeps the result list
/// visible above the fold on mobile.
class FilterDropdownRow extends StatelessWidget {
  const FilterDropdownRow({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          hint: Text(label, style: theme.textTheme.bodyMedium),
          borderRadius: BorderRadius.circular(AppRadius.md),
          items: [
            DropdownMenuItem<String?>(value: null, child: Text('All $label')),
            for (final option in options) DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
