import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.leading,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.scrollable = true,
    this.backgroundColor,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final EdgeInsetsGeometry padding;
  final bool scrollable;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final body = scrollable
        ? SingleChildScrollView(padding: padding, child: child)
        : Padding(padding: padding, child: child);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: title == null && actions == null && leading == null
          ? null
          : AppBar(title: title != null ? Text(title!) : null, actions: actions, leading: leading),
      body: SafeArea(child: body),
    );
  }
}
