import 'package:flutter/material.dart';

enum AppChipTone { neutral, primary, success, warning, danger, info }

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.tone = AppChipTone.neutral,
    this.selected = false,
    this.onTap,
    this.onDelete,
  });

  final String label;
  final IconData? icon;
  final AppChipTone tone;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _paletteFor(tone, theme);

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? palette.fg.withValues(alpha: 0.14) : palette.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? palette.fg : theme.colorScheme.outline.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: palette.fg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected ? palette.fg : theme.colorScheme.onSurface,
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDelete,
              child: Icon(Icons.close, size: 14, color: palette.fg),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return chip;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: BorderRadius.circular(999), onTap: onTap, child: chip),
    );
  }

  _ChipPalette _paletteFor(AppChipTone tone, ThemeData theme) {
    final scheme = theme.colorScheme;
    return switch (tone) {
      AppChipTone.neutral => _ChipPalette(
          bg: scheme.surfaceContainerHighest,
          fg: scheme.onSurface.withValues(alpha: 0.75),
        ),
      AppChipTone.primary => _ChipPalette(
          bg: scheme.primary.withValues(alpha: 0.10),
          fg: scheme.primary,
        ),
      AppChipTone.success => const _ChipPalette(
          bg: Color(0x1A10B981),
          fg: Color(0xFF10B981),
        ),
      AppChipTone.warning => const _ChipPalette(
          bg: Color(0x1AF59E0B),
          fg: Color(0xFFF59E0B),
        ),
      AppChipTone.danger => _ChipPalette(
          bg: scheme.error.withValues(alpha: 0.10),
          fg: scheme.error,
        ),
      AppChipTone.info => const _ChipPalette(
          bg: Color(0x1A3B82F6),
          fg: Color(0xFF3B82F6),
        ),
    };
  }
}

class _ChipPalette {
  const _ChipPalette({required this.bg, required this.fg});
  final Color bg;
  final Color fg;
}
