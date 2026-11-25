import 'package:flutter/material.dart';

enum AppBadgeTone { primary, success, warning, danger, info, neutral }

class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.label, this.tone = AppBadgeTone.primary});

  final String label;
  final AppBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, fg) = switch (tone) {
      AppBadgeTone.primary => (
          theme.colorScheme.primary.withValues(alpha: 0.12),
          theme.colorScheme.primary,
        ),
      AppBadgeTone.success => (const Color(0x1A10B981), const Color(0xFF10B981)),
      AppBadgeTone.warning => (const Color(0x1AF59E0B), const Color(0xFFF59E0B)),
      AppBadgeTone.danger => (const Color(0x1AEF4444), const Color(0xFFEF4444)),
      AppBadgeTone.info => (const Color(0x1A3B82F6), const Color(0xFF3B82F6)),
      AppBadgeTone.neutral => (
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
