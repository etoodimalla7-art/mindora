import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/widgets.dart';
import '../../data/planner_providers.dart';
import '../../domain/planner_models.dart';

final planDetailProvider =
    FutureProvider.family<StudyPlan, String>((ref, planId) async {
  return ref.watch(plannerRepositoryProvider).getPlan(planId);
});

class PlanDetailScreen extends ConsumerWidget {
  const PlanDetailScreen({super.key, required this.planId});
  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(planDetailProvider(planId));
    return Scaffold(
      appBar: AppBar(title: const Text('Plan')),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => AppEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load this plan',
            message: 'Try again in a moment.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(planDetailProvider(planId)),
          ),
          data: (plan) => _Body(plan: plan),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.plan});
  final StudyPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final upcoming = plan.sessions
        .where((s) => s.status != 'completed')
        .take(20)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Text(plan.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          plan.targetDate != null
              ? '${plan.daysRemaining} days remaining · '
                  '${DateFormat.yMMMd().format(plan.targetDate!)}'
              : '${plan.sessions.length} sessions',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Roadmap', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        for (final s in upcoming) ...[
          _SessionRow(session: s),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (upcoming.isEmpty)
          const AppEmptyState(
            icon: Icons.check_circle_outline,
            title: 'All sessions complete',
            message: 'Great work. Add a new plan to keep going.',
          ),
      ],
    );
  }
}

class _SessionRow extends ConsumerStatefulWidget {
  const _SessionRow({required this.session});
  final StudySession session;

  @override
  ConsumerState<_SessionRow> createState() => _SessionRowState();
}

class _SessionRowState extends ConsumerState<_SessionRow> {
  bool _busy = false;

  Future<void> _complete() async {
    setState(() => _busy = true);
    try {
      await ref.read(plannerRepositoryProvider).completeSession(
            id: widget.session.id,
            confidenceAfter: 0.7,
          );
      ref.invalidate(planDetailProvider(widget.session.planId ?? ''));
      ref.invalidate(upcomingSessionsProvider);
      ref.invalidate(plansListProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.session;
    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat.MMMd().format(s.scheduledFor),
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat.Hm().format(s.scheduledFor),
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.title, style: theme.textTheme.bodyMedium),
                if (s.subject != null)
                  Text(s.subject!, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Mark completed',
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            onPressed: _busy ? null : _complete,
          ),
        ],
      ),
    );
  }
}
