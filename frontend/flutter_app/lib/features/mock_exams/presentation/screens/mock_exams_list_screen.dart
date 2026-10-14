import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/widgets.dart';
import '../../data/mock_exam_providers.dart';
import '../../domain/mock_exam_models.dart';

class MockExamsListScreen extends ConsumerWidget {
  const MockExamsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(mockExamsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mock exams'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(mockExamsListProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/mock-exams/create'),
        icon: const Icon(Icons.add),
        label: const Text('New exam'),
      ),
      body: SafeArea(
        child: listAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: const [
              AppSkeleton(height: 100),
              SizedBox(height: AppSpacing.md),
              AppSkeleton(height: 100),
            ],
          ),
          error: (_, __) => AppEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load your exams',
            message: 'Please check your connection and try again.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(mockExamsListProvider),
          ),
          data: (exams) {
            if (exams.isEmpty) {
              return AppEmptyState(
                icon: Icons.quiz_outlined,
                title: 'No mock exams yet',
                message:
                    'Generate a personalized exam from your own course documents. '
                    'The AI writes questions grounded in your material.',
                actionLabel: 'Create your first exam',
                onAction: () => context.push('/mock-exams/create'),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(mockExamsListProvider);
                await ref.read(mockExamsListProvider.future);
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.xl),
                itemCount: exams.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (_, i) => _ExamCard(exam: exams[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam});
  final MockExam exam;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (badgeText, badgeTone) = switch (exam.status) {
      'graded' => ('GRADED', AppBadgeTone.success),
      'in_progress' => ('IN PROGRESS', AppBadgeTone.warning),
      'ready' => ('READY', AppBadgeTone.primary),
      _ => (exam.status.toUpperCase(), AppBadgeTone.neutral),
    };

    void open() {
      if (exam.isGraded) {
        context.push('/mock-exams/${exam.id}/results');
      } else if (exam.isInProgress) {
        context.push('/mock-exams/${exam.id}/take');
      } else {
        context.push('/mock-exams/${exam.id}');
      }
    }

    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: open,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exam.title,
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppBadge(label: badgeText, tone: badgeTone),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${exam.subject} · ${exam.questionCount} questions · ${exam.durationMinutes} min',
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (exam.isGraded && exam.score != null) ...[
                Icon(
                  Icons.grade_outlined,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${exam.score}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Text(
                DateFormat.yMMMd().format(exam.createdAt),
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
