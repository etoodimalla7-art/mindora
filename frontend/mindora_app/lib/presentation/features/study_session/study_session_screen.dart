import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../domain/dashboard/study_session.dart';
import '../../providers/ai_chat_providers.dart';
import '../../providers/dashboard_providers.dart';

/// Section 49: a focused environment for one study session — subject,
/// topic, objective, timer, and AI assistance, with distractions
/// minimized. Pushed as a full-screen route outside the bottom-nav
/// shell (see app_router.dart) rather than living inside a tab.
class StudySessionScreen extends ConsumerStatefulWidget {
  const StudySessionScreen({super.key, required this.session});
  final StudySessionEntity session;

  @override
  ConsumerState<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends ConsumerState<StudySessionScreen> {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.session.durationMinutes * 60;
    _startTimer();
    // Fire-and-forget: tells the backend this session has begun
    // (section 32's session lifecycle). Not critical to the timer UI,
    // so a failure here doesn't block studying.
    ref.read(dashboardRepositoryProvider).startSession(widget.session.id).catchError((_) {});
  }

  void _startTimer() {
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        setState(() => _isRunning = false);
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resumeTimer() {
    if (_remainingSeconds > 0) _startTimer();
  }

  Future<void> _markComplete() async {
    setState(() => _isCompleting = true);
    _timer?.cancel();
    try {
      await ref.read(completeSessionActionProvider)(widget.session.id);
    } catch (_) {
      // Non-fatal: the dashboard will just show it as still pending;
      // the student can retry marking it complete from Home.
    }
    if (mounted) context.pop();
  }

  void _askTutor() {
    final prompt = "I'm studying ${widget.session.topicTitle} in ${widget.session.subjectName}. "
        "Can you help me understand it?";
    ref.read(pendingTutorPromptProvider.notifier).state = prompt;
    context.go('/ai');
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = _remainingSeconds <= 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Session'),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              Text(widget.session.subjectName, style: theme.textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(widget.session.topicTitle, style: theme.textTheme.displayLarge, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xl),
              Text(
                _formatTime(_remainingSeconds),
                style: theme.textTheme.displayLarge?.copyWith(fontSize: 56, fontFeatures: [const FontFeature.tabularFigures()]),
              ),
              const SizedBox(height: AppSpacing.md),
              if (isDone)
                Text("Time's up — nice work.", style: theme.textTheme.bodyMedium)
              else
                IconButton.filledTonal(
                  iconSize: 32,
                  icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  onPressed: _isRunning ? _pauseTimer : _resumeTimer,
                ),
              const Spacer(),
              OutlinedButton.icon(
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Ask AI Tutor about this topic'),
                onPressed: _askTutor,
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                icon: const Icon(Icons.style_rounded),
                label: const Text('Review flashcards for this topic'),
                onPressed: () => context.push('/flashcards', extra: {'topicTitle': widget.session.topicTitle}),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCompleting ? null : _markComplete,
                  child: _isCompleting
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Mark session complete'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
