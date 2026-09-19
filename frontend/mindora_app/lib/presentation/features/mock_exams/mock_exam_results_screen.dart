import 'package:flutter/material.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../domain/mock_exams/mock_exam_entity.dart';

/// Section 40-42: overall score, a per-subject breakdown (so a student
/// sees which subject dragged the score down, not just one number),
/// then detailed per-question corrections.
class MockExamResultsScreen extends StatelessWidget {
  const MockExamResultsScreen({super.key, required this.result});
  final MockExamResultEntity result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = result.score >= 70 ? Colors.green.shade700 : theme.colorScheme.error;

    return Scaffold(
      appBar: AppBar(title: const Text('Exam Results'), automaticallyImplyLeading: false),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Center(
              child: Column(
                children: [
                  Text('${result.score.round()}%', style: theme.textTheme.displayLarge?.copyWith(color: scoreColor, fontSize: 48)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Overall score', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('By subject', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            for (final entry in result.sectionScores.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.key, style: theme.textTheme.bodyLarge)),
                    Text('${entry.value.round()}%',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: entry.value >= 70 ? Colors.green.shade700 : theme.colorScheme.error,
                        )),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            Text('Question corrections', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            for (final r in result.results)
              Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                      if (!r.isCorrect)
                        Text('Your answer: ${r.chosenAnswer ?? "(no answer)"}',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
                      Text('Correct answer: ${r.correctAnswer}',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.green.shade700)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
