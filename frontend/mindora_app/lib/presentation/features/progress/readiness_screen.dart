import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../domain/progress/readiness_entity.dart';
import '../../providers/progress_providers.dart';
import '../../shared_widgets/empty_state.dart';

/// Section 42: the exam readiness score across 6 dimensions. The
/// "estimate, not a guarantee" disclaimer is a spec requirement, not
/// an afterthought — shown prominently, not buried in fine print.
class ReadinessScreen extends ConsumerWidget {
  const ReadinessScreen({super.key, required this.targetExamName});
  final String targetExamName;

  Color _colorFor(double value, ThemeData theme) {
    if (value >= 70) return Colors.green.shade700;
    if (value >= 40) return Colors.orange.shade800;
    return theme.colorScheme.error;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final readinessAsync = ref.watch(_readinessProvider(targetExamName));

    return Scaffold(
      appBar: AppBar(title: const Text('Exam Readiness')),
      body: SafeArea(
        child: readinessAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyState(
            icon: Icons.insights_outlined,
            title: 'Not enough data yet',
            message: 'Study, practice with flashcards, and take a few quizzes '
                'or a mock exam — your readiness score will appear once there\'s '
                'enough activity to estimate from.',
          ),
          data: (readiness) => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(readiness.targetExamName, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text(
                  '${readiness.overall.round()}%',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 56, color: _colorFor(readiness.overall, theme),
                  ),
                ),
              ),
              Center(child: Text('Overall readiness', style: theme.textTheme.bodyMedium)),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: theme.colorScheme.secondary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'This is an estimate based on your activity, not a guarantee '
                        'of your exam result.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              for (final (label, value) in readiness.dimensions)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(label, style: theme.textTheme.bodyLarge),
                          Text('${value.round()}%',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600, color: _colorFor(value, theme),
                              )),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: value / 100,
                          minHeight: 8,
                          backgroundColor: theme.dividerColor,
                          color: _colorFor(value, theme),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final _readinessProvider = FutureProvider.autoDispose.family<ReadinessEntity, String>((ref, examName) {
  return ref.watch(progressRepositoryProvider).getReadiness(examName);
});
