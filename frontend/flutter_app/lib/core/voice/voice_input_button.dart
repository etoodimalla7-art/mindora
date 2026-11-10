import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Microphone button that transcribes speech to text.
///
/// Usage:
///   VoiceInputButton(onTranscribed: (text) => controller.text = text)
class VoiceInputButton extends StatefulWidget {
  const VoiceInputButton({
    super.key,
    required this.onTranscribed,
    this.iconSize = 24,
  });

  final void Function(String text) onTranscribed;
  final double iconSize;

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  final _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _available = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _available = await _speech.initialize(
        onError: (e) => debugPrint('[STT] error: $e'),
        onStatus: (s) {
          if (s == 'done' || s == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('[STT] init failed: $e');
    }
  }

  Future<void> _toggleListening() async {
    if (!_available) {
      await _initSpeech();
    }

    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    setState(() => _isListening = true);

    // Use the new SpeechListenOptions (non-deprecated in v7+)
    final options = stt.SpeechListenOptions(
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'en_US',
    );

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          widget.onTranscribed(result.recognizedWords);
          if (mounted) setState(() => _isListening = false);
        }
      },
      listenOptions: options,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_available) {
      return IconButton(
        icon: const Icon(Icons.mic_off, color: Colors.grey),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Micro non disponible sur cet appareil')),
          );
        },
      );
    }

    return IconButton(
      icon: Icon(
        _isListening ? Icons.stop_circle : Icons.mic,
        color: _isListening ? Colors.red : theme.colorScheme.primary,
        size: widget.iconSize,
      ),
      tooltip: _isListening ? 'Arrêter' : 'Dictée vocale',
      onPressed: _toggleListening,
    );
  }
}
