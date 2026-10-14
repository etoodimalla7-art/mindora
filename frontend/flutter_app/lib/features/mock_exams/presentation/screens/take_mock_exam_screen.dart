import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/widgets.dart';
import '../../data/mock_exam_providers.dart';
import '../../domain/mock_exam_models.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/question_card.dart';

class TakeMockExamScreen extends ConsumerStatefulWidget {
  const TakeMockExamScreen({super.key, required this.examId});
  final String examId;

  @override
  ConsumerState<TakeMockExamScreen> createState() =>
      _TakeMockExamScreenState();
}

class _TakeMockExamScreenState extends ConsumerState<TakeMockExamScreen> {
  int _index = 0;
  MockExam? _exam;
  final Map<String, String> _answers = {};
  final Map<String, int> _timeSpent = {};
  DateTime? _questionStartedAt;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(mockExamRepositoryProvider);
      var exam = await repo.get(widget.examId);
      if (exam.isReady) {
        exam = await repo.start(widget.examId);
      }
      if (mounted) {
        setState(() {
          _exam = exam;
          _questionStartedAt = DateTime.now();
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load the exam.')),
        );
      }
    }
  }

  void _onOptionSelected(String label) {
    if (_exam == null) return;
    final q = _exam!.questions[_index];
    _recordTime();
    setState(() => _answers[q.id] = label);
  }

  void _onShortAnswerChanged(String text) {
    if (_exam == null) return;
    final q = _exam!.questions[_index];
    _answers[q.id] = text;
  }

  void _recordTime() {
    if (_exam == null || _questionStartedAt == null) return;
    final q = _exam!.questions[_index];
    final spent = DateTime.now().difference(_questionStartedAt!).inSeconds;
    _timeSpent[q.id] = (_timeSpent[q.id] ?? 0) + spent;
    _questionStartedAt = DateTime.now();
  }

  Future<void> _saveCurrentAnswer() async {
    if (_exam == null) return;
    final q = _exam!.questions[_index];
    final ans = _answers[q.id];
    if (ans == null || ans.isEmpty) return;
    try {
      await ref.read(mockExamRepositoryProvider).submitAnswer(
            examId: widget.examId,
            questionId: q.id,
            answer: ans,
            timeSpentSeconds: _timeSpent[q.id],
          );
    } catch (_) {
      // Ignore — we'll re-submit at the end anyway.
    }
  }

  Future<void> _next() async {
    await _saveCurrentAnswer();
    _recordTime();
    if (_index < (_exam?.questions.length ?? 0) - 1) {
      setState(() => _index++);
    } else {
      await _finalize();
    }
  }

  Future<void> _previous() async {
    await _saveCurrentAnswer();
    _recordTime();
    if (_index > 0) {
      setState(() => _index--);
    }
  }

  Future<void> _finalize() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    // Ensure the last answer is saved.
    await _saveCurrentAnswer();

    try {
      await ref.read(mockExamRepositoryProvider).submit(widget.examId);
      if (!mounted) return;
      ref.invalidate(mockExamsListProvider);
      context.go('/mock-exams/${widget.examId}/results');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not submit the exam.')),
      );
      setState(() => _submitting = false);
    }
  }

  Future<void> _confirmFinish() async {
    final confirmed = await AppDialog.show(
      context,
      title: 'Finish exam?',
      message: 'You will not be able to change your answers after this.',
      confirmLabel: 'Finish',
    );
    if (confirmed) await _finalize();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_exam == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final q = _exam!.questions[_index];
    final total = _exam!.questions.length;
    final isLast = _index == total - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(_exam!.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: Center(
              child: CountdownTimer(
                durationSeconds: _exam!.durationMinutes * 60,
                onExpired: _finalize,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_index + 1) / total,
              minHeight: 3,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
            Expanded(
              child: QuestionCard(
                question: q,
                currentIndex: _index,
                totalCount: total,
                selectedOption: _answers[q.id],
                shortAnswer: _answers[q.id],
                onOptionSelected: _onOptionSelected,
                onShortAnswerChanged: _onShortAnswerChanged,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Previous',
                      variant: AppButtonVariant.secondary,
                      onPressed: _index > 0 ? _previous : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: isLast
                        ? AppButton(
                            label: 'Finish',
                            icon: Icons.check,
                            loading: _submitting,
                            onPressed: _submitting ? null : _confirmFinish,
                          )
                        : AppButton(
                            label: 'Next',
                            icon: Icons.arrow_forward,
                            onPressed: _next,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
