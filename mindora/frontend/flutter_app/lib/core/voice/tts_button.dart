/// Small icon button to speak a text via TTS (Phase 11D).
library;
import 'dart:async';

import 'package:flutter/material.dart';

import 'tts_service.dart';

class TtsButton extends StatefulWidget {
  const TtsButton({
    super.key,
    required this.text,
    this.iconSize = 20,
    this.language,
    this.color,
  });

  final String text;
  final double iconSize;
  final String? language;
  final Color? color;

  @override
  State<TtsButton> createState() => _TtsButtonState();
}

class _TtsButtonState extends State<TtsButton> {
  StreamSubscription<bool>? _sub;
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _sub = TtsService.instance.isSpeakingStream.listen((speaking) {
      if (!mounted) return;
      setState(() => _speaking = speaking);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_speaking) {
      await TtsService.instance.stop();
    } else {
      await TtsService.instance.speak(
        widget.text,
        language: widget.language,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = widget.color ?? theme.colorScheme.primary;
    return IconButton(
      iconSize: widget.iconSize,
      visualDensity: VisualDensity.compact,
      tooltip: _speaking ? 'Arrêter la lecture' : 'Lire à voix haute',
      icon: Icon(
        _speaking ? Icons.stop_circle : Icons.volume_up_outlined,
        color: _speaking ? active : theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      onPressed: _toggle,
    );
  }
}
