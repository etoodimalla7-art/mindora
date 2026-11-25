import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/app_colors.dart';
import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/widgets.dart';
import '../../../../l10n/app_strings.dart';
import '../../data/mock_exam_providers.dart';
import '../../domain/mock_exam_models.dart';

class MockExamResultsScreen extends ConsumerWidget {
  const MockExamResultsScreen({super.key, required this.examId});
  final String examId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(mockExamResultsProvider(examId));
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.resultsTitle),
        actions: [
          IconButton(
            tooltip: s.backToExams,
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
            title: s.isFr
                ? 'Impossible de charger les résultats'
                : 'Could not load results',
            message: s.isFr ? 'Veuillez réessayer.' : 'Please try again.',
            actionLabel: s.retry,
            onAction: () => ref.invalidate(mockExamResultsProvider(examId)),
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
    final s = AppStrings.of(context);
    final exam = results.exam;
    final score = exam.score ?? 0;
    final isGood = score >= 60;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        AppSurface(
          padding: const EdgeInsets.all(AppSpacing.xl),
          color: (isGood ? AppPalette.success : theme.colorScheme.primary)
              .withValues(alpha: 0.08),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppProgressRing(
                    value: score / 100,
                    size: 88,
                    strokeWidth: 8,
                    centerLabel: Text(
                      '${score.toStringAsFixed(0)}%',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.title,
                          style: theme.textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${exam.subject} · ${exam.difficulty}',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _stat(
                    context,
                    s.isFr
                        ? '✓ ${exam.correctCount ?? 0} correctes'
                        : '✓ ${exam.correctCount ?? 0} correct',
                    AppPalette.success,
                  ),
                  _stat(
                    context,
                    s.isFr
                        ? '✗ ${exam.wrongCount ?? 0} incorrectes'
                        : '✗ ${exam.wrongCount ?? 0} wrong',
                    theme.colorScheme.error,
                  ),
                  if ((exam.skippedCount ?? 0) > 0)
                    _stat(
                      context,
                      s.isFr
                          ? '— ${exam.skippedCount} ignorées'
                          : '— ${exam.skippedCount} skipped',
                      theme.colorScheme.outline,
                    ),
                ],
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

        if (results.topicBreakdown.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Text(s.performanceByTopic, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          for (final entry in results.topicBreakdown.entries) ...[
            _topicRow(context, entry.key, entry.value),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],

        const SizedBox(height: AppSpacing.xl),
        Text(s.detailedCorrections, style: theme.textTheme.titleMedium),
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
                label: s.backToExams,
                variant: AppButtonVariant.secondary,
                icon: Icons.arrow_back,
                onPressed: () => context.go('/mock-exams'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                label: s.newExamLabel,
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

  Widget _stat(BuildContext context, String label, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
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
              child: Text(
                topic,
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text('$correct / $total', style: theme.textTheme.labelSmall),
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
                  ? AppPalette.success
                  : pct >= 0.3
                      ? AppPalette.warning
                      : theme.colorScheme.error,
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
    final s = AppStrings.of(context);
    final isCorrect = answer.isCorrect == true;
    final isSkipped = answer.userAnswer == null || answer.userAnswer!.isEmpty;

    final (icon, color) = isSkipped
        ? (Icons.remove_circle_outline, theme.colorScheme.outline)
        : isCorrect
            ? (Icons.check_circle, AppPalette.success)
            : (Icons.cancel, theme.colorScheme.error);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppSurface(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
            _answerLine(
              context,
              label: s.yourAnswerLabel,
              value: answer.userAnswer?.isNotEmpty == true
                  ? answer.userAnswer!
                  : s.skippedLabel,
              color: isCorrect
                  ? AppPalette.success
                  : (isSkipped
                      ? theme.colorScheme.outline
                      : theme.colorScheme.error),
            ),
            if (!isCorrect) ...[
              const SizedBox(height: 4),
              _answerLine(
                context,
                label: s.correctLabel,
                value: answer.correctAnswer,
                color: AppPalette.success,
                bold: true,
              ),
            ],
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

  Widget _answerLine(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    bool bold = false,
  }) {
    final theme = Theme.of(context);
    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodySmall,
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: color,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
