import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/widgets.dart';
import '../../data/mock_exam_providers.dart';
import '../../domain/mock_exam_models.dart';

class MockExamResultsScreen extends ConsumerWidget {
  const MockExamResultsScreen({super.key, required this.examId});
  final String examId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(mockExamResultsProvider(examId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        actions: [
          IconButton(
            tooltip: 'Back to exams',
            icon: const Icon(Icons.list),
            onPressed: () => context.go('/mock-exams'),
          ),
        ],
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => AppEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load results',
            message: 'Please try again.',
            actionLabel: 'Retry',
            onAction: () =>
                ref.invalidate(mockExamResultsProvider(examId)),
          ),
          data: (results) => _Body(results: results),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.results});
  final MockExamResults results;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exam = results.exam;
    final score = exam.score ?? 0;
    final isGood = score >= 60;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        // Score card
        AppSurface(
          padding: const EdgeInsets.all(AppSpacing.xl),
          color: (isGood
                  ? const Color(0xFF10B981)
                  : theme.colorScheme.primary)
              .withValues(alpha: 0.08),
          child: Row(
            children: [
              AppProgressRing(
                value: score / 100,
                size: 96,
                strokeWidth: 8,
                centerLabel: Text(
                  '${score.toStringAsFixed(0)}%',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exam.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${exam.subject} · ${exam.difficulty}',
                      style: theme.textTheme.labelSmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(children: [
                      _stat('✓', '${exam.correctCount ?? 0} correct',
                          const Color(0xFF10B981)),
                      const SizedBox(width: 12),
                      _stat('✗', '${exam.wrongCount ?? 0} wrong',
                          const Color(0xFFEF4444)),
                      if ((exam.skippedCount ?? 0) > 0) ...[
                        const SizedBox(width: 12),
                        _stat('—', '${exam.skippedCount} skipped',
                            theme.colorScheme.outline),
                      ],
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (results.feedbackSummary != null) ...[
          const SizedBox(height: AppSpacing.xl),
          AppSurface(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              results.feedbackSummary!,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],

        // Topic breakdown
        if (results.topicBreakdown.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Text('Performance by topic', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          for (final entry in results.topicBreakdown.entries) ...[
            _topicRow(context, entry.key, entry.value),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],

        const SizedBox(height: AppSpacing.xl),
        Text('Detailed corrections', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),

        for (var i = 0; i < exam.questions.length; i++)
          _CorrectionCard(
            index: i,
            question: exam.questions[i],
            answer: results.answers.firstWhere(
              (a) => a.questionId == exam.questions[i].id,
              orElse: () => AnswerResult(
                questionId: exam.questions[i].id,
                pointsAwarded: 0,
                correctAnswer: exam.questions[i].correctAnswer ?? '',
              ),
            ),
          ),

        const SizedBox(height: AppSpacing.xxl),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Back to exams',
                variant: AppButtonVariant.secondary,
                icon: Icons.arrow_back,
                onPressed: () => context.go('/mock-exams'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                label: 'New exam',
                icon: Icons.add,
                onPressed: () => context.go('/mock-exams/create'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.massive),
      ],
    );
  }

  Widget _stat(String icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  Widget _topicRow(BuildContext context, String topic, Map<String, int> data) {
    final theme = Theme.of(context);
    final total = data['total'] ?? 0;
    final correct = data['correct'] ?? 0;
    final pct = total == 0 ? 0.0 : correct / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(topic, style: theme.textTheme.bodyMedium),
            ),
            Text(
              '$correct / $total',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 4,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(
              pct >= 0.6
                  ? const Color(0xFF10B981)
                  : pct >= 0.3
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFFEF4444),
            ),
          ),
        ),
      ],
    );
  }
}

class _CorrectionCard extends StatelessWidget {
  const _CorrectionCard({
    required this.index,
    required this.question,
    required this.answer,
  });

  final int index;
  final MockQuestion question;
  final AnswerResult answer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCorrect = answer.isCorrect == true;
    final isSkipped = answer.userAnswer == null || answer.userAnswer!.isEmpty;

    final (icon, color) = isSkipped
        ? (Icons.remove_circle_outline, theme.colorScheme.outline)
        : isCorrect
            ? (Icons.check_circle, const Color(0xFF10B981))
            : (Icons.cancel, const Color(0xFFEF4444));

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppSurface(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Q${index + 1}. ${question.prompt}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Your answer: ${answer.userAnswer ?? '(skipped)'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isCorrect
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                ),
                if (!isCorrect)
                  Expanded(
                    child: Text(
                      'Correct: ${answer.correctAnswer}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (answer.explanation != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  answer.explanation!,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
