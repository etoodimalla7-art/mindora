/// Listens to push events and routes the user accordingly.
///
/// Wraps the whole app and subscribes to:
/// - onOpenedApp  → navigate to the mapped route (tray tap / cold start)
/// - onForeground → (optionally) show an in-app banner
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import 'notification_models.dart';
import 'push_providers.dart';

class PushListener extends ConsumerStatefulWidget {
  const PushListener({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<PushListener> createState() => _PushListenerState();
}

class _PushListenerState extends ConsumerState<PushListener> {
  final Logger _log = Logger();
  StreamSubscription<PushPayload>? _openedSub;
  StreamSubscription<PushPayload>? _foregroundSub;

  @override
  void initState() {
    super.initState();
    // Listeners are wired in didChangeDependencies because we need context.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _openedSub ??= ref
        .read(pushServiceProvider)
        .onOpenedApp
        .listen(_handleOpenedFromTray);
    _foregroundSub ??= ref
        .read(pushServiceProvider)
        .onForeground
        .listen(_handleForeground);
  }

  void _handleOpenedFromTray(PushPayload payload) {
    final route = ref.read(deepLinkHandlerProvider).routeFor(payload);
    if (route == null) return;
    _log.i('Push → navigating to $route');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        GoRouter.of(context).go(route);
      } catch (e) {
        _log.w('Navigation failed: $e');
      }
    });
  }

  void _handleForeground(PushPayload payload) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final title = payload.title ?? 'MINDORA';
    final body = payload.body ?? '';
    messenger.showSnackBar(
      SnackBar(
        content: Text(body.isEmpty ? title : '$title — $body'),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _openedSub?.cancel();
    _foregroundSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
