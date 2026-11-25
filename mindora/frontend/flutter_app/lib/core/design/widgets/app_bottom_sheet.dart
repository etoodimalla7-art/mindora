import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.showHandle = true,
  });

  final String? title;
  final Widget child;
  final bool showHandle;

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required Widget child,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (_) => AppBottomSheet(title: title, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showHandle)
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            if (title != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(title!, style: theme.textTheme.titleLarge),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.xxl,
                right: AppSpacing.xxl,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xxl,
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
