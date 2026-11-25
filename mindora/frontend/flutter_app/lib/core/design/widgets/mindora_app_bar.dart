import 'package:flutter/material.dart';

import 'brand_logo.dart';

/// Shared AppBar with the MINDORA logo + wordmark.
///
/// Usage:
///   MindoraAppBar(title: 'Planner')
///   MindoraAppBar(showWordmark: true)  // for home/splash
class MindoraAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MindoraAppBar({
    super.key,
    this.title,
    this.showWordmark = false,
    this.actions,
    this.leading,
    this.bottom,
    this.elevation = 0,
  });

  final String? title;
  final bool showWordmark;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final double elevation;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: elevation,
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      leading: leading,
      title: showWordmark
          ? const BrandLogo(size: 28, showWordmark: true, wordmarkSize: 18)
          : (title != null ? Text(title!) : null),
      actions: actions,
      bottom: bottom,
    );
  }
}
