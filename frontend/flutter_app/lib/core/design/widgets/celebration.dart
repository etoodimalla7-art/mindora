import 'package:flutter/material.dart';

import 'confetti.dart';

/// Show confetti overlay on top of the current screen for ~3 seconds.
///
/// Usage:
///   showCelebration(context);
Future<void> showCelebration(BuildContext context) async {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => const ConfettiOverlay(),
  );
  overlay.insert(entry);
  await Future.delayed(const Duration(milliseconds: 3200));
  entry.remove();
}
