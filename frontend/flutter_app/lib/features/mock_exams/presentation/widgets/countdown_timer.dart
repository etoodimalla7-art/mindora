import 'dart:async';

import 'package:flutter/material.dart';

class CountdownTimer extends StatefulWidget {
  const CountdownTimer({
    super.key,
    required this.durationSeconds,
    required this.onExpired,
    this.onTick,
  });

  final int durationSeconds;
  final VoidCallback onExpired;
  final void Function(int remaining)? onTick;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late int _remaining;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _remaining = widget.durationSeconds;
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining--);
      widget.onTick?.call(_remaining);
      if (_remaining <= 0) {
        _t?.cancel();
        widget.onExpired();
      }
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = _remaining ~/ 60;
    final seconds = _remaining % 60;
    final isWarning = _remaining <= 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isWarning
            ? const Color(0xFFEF4444).withValues(alpha: 0.15)
            : theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 16,
            color: isWarning
                ? const Color(0xFFEF4444)
                : theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: isWarning
                  ? const Color(0xFFEF4444)
                  : theme.colorScheme.primary,
              fontFeatures: const [FontFeature.tabularFigures()],
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
