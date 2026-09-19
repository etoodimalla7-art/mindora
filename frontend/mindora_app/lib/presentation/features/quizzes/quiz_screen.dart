import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../domain/quizzes/quiz_entity.dart';
import '../../providers/quizzes_providers.dart';
import '../../shared_widgets/empty_state.dart';
import 'quiz_results_screen.dart';

/// Sections 39-40: multiple-choice/true-false quiz with question
/// navigation, then detailed corrections on submission.
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.topicTitle, this.sourceDocumentId, this.difficulty = 'medium'});
  final String topicTitle;
  final String? sourceDocumentId;
  final String difficulty;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  QuizEntity? _quiz;
  int _index = 0;
  final Map<String, String> _answers = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final quiz = await ref.read(quizzesRepositoryProvider).generate(
            topicTitle: widget.topicTitle,
            sourceDocumentId: widget.sourceDocumentId,
            difficulty: widget.difficulty,
          );
      setState(() {
        _quiz = quiz;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _error = "We couldn't generate a quiz right now. Please try again.";
      });
    }
  }

  Future<void> _submit() async {
    if (_quiz == null) return;
    setState(() => _isSubmitting = true);
    try {
      final result = await ref.read(quizzesRepositoryProvider).submitAttempt(_quiz!.id, _answers);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => QuizResultsScreen(result: result)),
        );
      }
    } catch (_) {
      setState(() {
        _isSubmitting = false;
        _error = "We couldn't submit your quiz. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(appBar: AppBar(title: const Text('Quiz')), body: const Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _quiz == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: EmptyState(icon: Icons.wifi_off_rounded, title: 'Something went wrong', message: _error ?? '', actionLabel: 'Retry', onAction: _load),
      );
    }

    final question = _quiz!.questions[_index];
    final selected = _answers[question.id];
    final isLast = _index == _quiz!.questions.length - 1;

    return Scaffold(
      appBar: AppBar(title: Text('Quiz — ${_quiz!.topicTitle}')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(value: (_index + 1) / _quiz!.questions.length),
              const SizedBox(height: AppSpacing.sm),
              Text('Question ${_index + 1} of ${_quiz!.questions.length}', style: theme.textTheme.bodyMedium),
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
                      child: OutlinedButton(
                        onPressed: () => setState(() => _index--),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_index > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selected == null
                          ? null
                          : isLast
                              ? (_isSubmitting ? null : _submit)
                              : () => setState(() => _index++),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isLast ? 'Submit' : 'Next'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
