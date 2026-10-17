import 'package:flutter/services.dart';

/// Central service for haptics + sounds.
///
/// Usage:
///   FeedbackService.instance.tap();      // tiny tap (vibration + click)
///   FeedbackService.instance.success();  // success feedback
///   FeedbackService.instance.error();    // error feedback
class FeedbackService {
  FeedbackService._();
  static final FeedbackService instance = FeedbackService._();

  /// Tap feedback — short vibration + system click.
  Future<void> tap() async {
    HapticFeedback.selectionClick();
  }

  /// Light impact (e.g. toggle switch).
  Future<void> light() async {
    HapticFeedback.lightImpact();
  }

  /// Success (e.g. form submitted) — medium impact + heavy click.
  Future<void> success() async {
    HapticFeedback.mediumImpact();
  }

  /// Error (e.g. validation failed) — heavy impact (heavier than success).
  Future<void> error() async {
    HapticFeedback.heavyImpact();
  }
}
