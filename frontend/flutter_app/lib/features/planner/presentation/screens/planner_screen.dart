import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/widgets.dart';
import '../../data/planner_providers.dart';
import '../../domain/planner_models.dart';
import '../../../../core/design/widgets/mindora_app_bar.dart';
import '../../../../core/design/widgets/skeleton_loader.dart';

class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansListProvider);

    return Scaffold(
      appBar: MindoraAppBar(
        showWordmark: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(plansListProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/planner/create'),
        icon: const Icon(Icons.add),
        label: const Text('New plan'),
      ),
      body: SafeArea(
        child: plansAsync.when(          loading: () => ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              SkeletonLoader.card(height: 100),
              const SizedBox(height: 12),
              SkeletonLoader.card(height: 100),
              const SizedBox(height: 12),
              SkeletonLoader.card(height: 100),
            ],
          ),
          error: (err, _) => AppEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'We could not load your plans',
            message: 'Check your connection and try again.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(plansListProvider),
          ),
          data: (plans) {
            if (plans.isEmpty) {
              return AppEmptyState(
                icon: Icons.calendar_today_outlined,
                title: 'No study plan yet',
                message:
                    'Tell us what examination you are preparing for and we will build your first personalized plan.',
                actionLabel: 'Create study plan',
                onAction: () => context.push('/planner/create'),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(plansListProvider);
                await ref.read(plansListProvider.future);
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.xl),
                itemCount: plans.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (_, i) => _PlanCard(plan: plans[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});
  final StudyPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExam = plan.planType == 'exam';
    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.xl),
      onTap: () => context.push('/planner/plans/${plan.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isExam ? Icons.event_outlined : Icons.menu_book_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      isExam ? 'Exam plan' : 'Subject plan',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              AppBadge(
                label: isExam ? 'EXAM' : 'SUBJECT',
                tone: isExam ? AppBadgeTone.primary : AppBadgeTone.info,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              if (plan.targetDate != null) ...[
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  '${plan.daysRemaining} days left · '
                  '${DateFormat.yMMMd().format(plan.targetDate!)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
