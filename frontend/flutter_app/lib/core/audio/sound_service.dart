import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Lightweight sound service using Flutter's built-in system sounds.
///
/// No external .mp3 files needed — uses SystemSound (Android/iOS native)
/// or HapticFeedback (silent fallback on Web/Desktop).
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  /// Subtle tap click — best for buttons.
  Future<void> tap() async {
    if (kIsWeb) return; // SystemSound.click not supported on Web
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {
      // Silent fail
    }
  }

  /// Alert sound — error / warning.
  Future<void> alert() async {
    if (kIsWeb) return;
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }
}
