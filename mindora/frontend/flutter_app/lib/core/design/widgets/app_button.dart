import 'package:flutter/material.dart';

import '../../audio/feedback_service.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (icon != null)
          Icon(icon, size: 18),
        if (loading || icon != null) const SizedBox(width: 8),
        if (!loading)
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );

    // Safe handler — no null-check crash, no force-unwrap.
    VoidCallback? handler;
    if (!loading && onPressed != null) {
      handler = () {
        FeedbackService.instance.tap();
        onPressed!.call();
      };
    }

    final button = switch (variant) {
      AppButtonVariant.primary =>
        FilledButton(onPressed: handler, child: child),
      AppButtonVariant.secondary =>
        OutlinedButton(onPressed: handler, child: child),
      AppButtonVariant.ghost => TextButton(onPressed: handler, child: child),
      AppButtonVariant.danger => FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: handler,
          child: child,
        ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
