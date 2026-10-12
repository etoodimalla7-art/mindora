import 'package:flutter/material.dart';

class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.label,
    this.showPercent = true,
  });

  final double value; // 0.0 to 1.0
  final String? label;
  final bool showPercent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = value.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null || showPercent)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                if (label != null)
                  Expanded(child: Text(label!, style: theme.textTheme.labelMedium)),
                if (showPercent)
                  Text(
                    '${(clamped * 100).round()}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}

class AppProgressRing extends StatelessWidget {
  const AppProgressRing({
    super.key,
    required this.value,
    this.size = 64,
    this.strokeWidth = 6,
    this.centerLabel,
  });

  final double value;
  final double size;
  final double strokeWidth;
  final Widget? centerLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: value.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              strokeCap: StrokeCap.round,
            ),
          ),
          if (centerLabel != null) centerLabel!,
        ],
      ),
    );
  }
}
