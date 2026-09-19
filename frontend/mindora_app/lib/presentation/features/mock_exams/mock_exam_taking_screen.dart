import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../domain/mock_exams/mock_exam_entity.dart';
import '../../providers/mock_exams_providers.dart';
import 'mock_exam_results_screen.dart';

/// Section 40: countdown timer, question navigation across ALL
/// sections combined (subject boundaries shown via a header, not a
/// hard barrier), and auto-submit when time runs out.
class MockExamTakingScreen extends ConsumerStatefulWidget {
  const MockExamTakingScreen({super.key, required this.exam});
  final MockExamEntity exam;

  @override
  ConsumerState<MockExamTakingScreen> createState() => _MockExamTakingScreenState();
}

class _MockExamTakingScreenState extends ConsumerState<MockExamTakingScreen> {
  late int _remainingSeconds;
  Timer? _timer;
  int _index = 0;
  final Map<String, String> _answers = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.exam.durationMinutes * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _submit(auto: true);
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Which section a flat question index falls into, for the subject
  /// header shown above each question.
  String _sectionForIndex(int flatIndex) {
    var count = 0;
    for (final section in widget.exam.sections) {
      if (flatIndex < count + section.questions.length) return section.subjectName;
      count += section.questions.length;
    }
    return '';
  }

  Future<void> _submit({bool auto = false}) async {
    if (_isSubmitting) return;
    _timer?.cancel();
    setState(() => _isSubmitting = true);
    try {
      final result = await ref.read(mockExamsRepositoryProvider).submit(widget.exam.id, _answers);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MockExamResultsScreen(result: result)),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't submit your exam. Please try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final questions = widget.exam.allQuestions;
    final question = questions[_index];
    final selected = _answers[question.id];
    final isLast = _index == questions.length - 1;
    final isLowTime = _remainingSeconds < 300;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Mock Exam — ${_sectionForIndex(_index)}'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Center(
                child: Text(
                  _formatTime(_remainingSeconds),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: isLowTime ? theme.colorScheme.error : null,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(value: (_index + 1) / questions.length),
                const SizedBox(height: AppSpacing.sm),
                Text('Question ${_index + 1} of ${questions.length}', style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.lg),
                Text(question.prompt, style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: ListView(
                    children: [
                      for (final choice in question.choices)
                        RadioListTile<String>(
                          title: Text(choice),
                          value: choice,
                          groupValue: selected,
                          onChanged: (value) => setState(() => _answers[question.id] = value!),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (_index > 0)
                      Expanded(
                        child: OutlinedButton(onPressed: () => setState(() => _index--), child: const Text('Back')),
                      ),
                    if (_index > 0) const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : isLast
                                ? () => _submit()
                                : () => setState(() => _index++),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(isLast ? 'Submit Exam' : 'Next'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
