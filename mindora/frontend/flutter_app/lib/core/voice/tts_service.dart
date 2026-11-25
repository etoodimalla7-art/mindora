/// Singleton TTS service wrapping flutter_tts (Phase 11D).
///
/// Usage:
///   await TtsService.instance.speak("Hello world");
///   TtsService.instance.stop();
///   TtsService.instance.isSpeakingStream.listen((b) => print(b));
library;
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool _speaking = false;
  final StreamController<bool> _speakingController =
      StreamController<bool>.broadcast();

  /// Emits true when speaking starts, false when it stops.
  Stream<bool> get isSpeakingStream => _speakingController.stream;
  bool get isSpeaking => _speaking;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    try {
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);

      _tts.setStartHandler(() {
        _speaking = true;
        _speakingController.add(true);
      });
      _tts.setCompletionHandler(() {
        _speaking = false;
        _speakingController.add(false);
      });
      _tts.setCancelHandler(() {
        _speaking = false;
        _speakingController.add(false);
      });
      _tts.setErrorHandler((msg) {
        debugPrint('[TTS] error: $msg');
        _speaking = false;
        _speakingController.add(false);
      });
      _initialized = true;
    } catch (e) {
      debugPrint('[TTS] init failed: $e');
    }
  }

  /// Speak the given text. Automatically stops any ongoing speech.
  Future<void> speak(String text, {String? language}) async {
    await _ensureInit();
    if (text.trim().isEmpty) return;
    await _tts.stop();
    if (language != null) {
      try {
        await _tts.setLanguage(language);
      } catch (_) {}
    }
    // Strip Markdown-ish artifacts that sound bad when spoken.
    final cleaned = text
        .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
        .replaceAll(RegExp(r'`[^`]*`'), ' ')
        .replaceAll(RegExp(r'\*\*?([^*]+)\*\*?'), r'$1')
        .replaceAll(RegExp(r'#+\s'), '')
        .replaceAll(RegExp(r'\[(.*?)\]\(.*?\)'), r'$1');
    await _tts.speak(cleaned);
  }

  Future<void> stop() async {
    await _tts.stop();
    _speaking = false;
    _speakingController.add(false);
  }

  void dispose() {
    _speakingController.close();
    _tts.stop();
  }
}
