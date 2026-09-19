import 'package:flutter/material.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../domain/quizzes/quiz_entity.dart';

/// Section 40: detailed corrections after submission — every question
/// shown with what the student chose vs. the correct answer.
class QuizResultsScreen extends StatelessWidget {
  const QuizResultsScreen({super.key, required this.result});
  final AttemptResultEntity result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = result.score >= 70 ? Colors.green.shade700 : theme.colorScheme.error;

    return Scaffold(
      appBar: AppBar(title: const Text('Results'), automaticallyImplyLeading: false),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Text('${result.score.round()}%', style: theme.textTheme.displayLarge?.copyWith(color: scoreColor, fontSize: 48)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Your score', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: result.results.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final r = result.results[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                r.isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                color: r.isCorrect ? Colors.green.shade700 : theme.colorScheme.error,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(child: Text(r.prompt, style: theme.textTheme.titleLarge)),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (!r.isCorrect) ...[
                            Text('Your answer: ${r.chosenAnswer ?? "(no answer)"}',
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
                            const SizedBox(height: 4),
                          ],
                          Text('Correct answer: ${r.correctAnswer}',
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.green.shade700)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
