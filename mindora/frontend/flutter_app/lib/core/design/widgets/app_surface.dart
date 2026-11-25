import 'package:flutter/material.dart';

import '../tokens/app_elevation.dart';
import '../tokens/app_radius.dart';

class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = AppRadius.lgAll,
    this.elevated = true,
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final bool elevated;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surface,
        borderRadius: borderRadius,
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.6)),
        boxShadow: elevated ? AppElevation.sm : AppElevation.none,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return box;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: box,
      ),
    );
  }
}
