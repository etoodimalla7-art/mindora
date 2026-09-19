import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../providers/dashboard_providers.dart';
import '../../../providers/planner_providers.dart';
import '../../../shared_widgets/empty_state.dart';

/// Shown right after plan creation: the generated roadmap, grouped by
/// day, so the student can see exactly what they're committing to.
class PlanSummaryScreen extends ConsumerWidget {
  const PlanSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planId = ref.watch(activePlanIdProvider);
    final theme = Theme.of(context);

    if (planId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your plan')),
        body: EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'No plan to show',
          message: 'Create a study plan first.',
        ),
      );
    }

    final sessionsAsync = ref.watch(_planSessionsProvider(planId));

    return Scaffold(
      appBar: AppBar(title: const Text('Your plan')),
      body: SafeArea(
        child: sessionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => EmptyState(
            icon: Icons.wifi_off_rounded,
            title: "Couldn't load your plan",
            message: 'Check your connection and try again.',
          ),
          data: (sessions) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green.shade700),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '${sessions.length} sessions scheduled',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${index + 1}')),
                        title: Text(session.subjectName),
                        subtitle: Text(session.topicTitle),
                        trailing: Text(
                          '${session.scheduledAt.month}/${session.scheduledAt.day}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ElevatedButton(
                  onPressed: () {
                    ref.invalidate(todaySessionsProvider);
                    ref.invalidate(dashboardOverviewProvider);
                    context.go('/home');
                  },
                  child: const Text('Go to my dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _planSessionsProvider = FutureProvider.autoDispose.family((ref, String planId) {
  return ref.watch(plannerRepositoryProvider).getSessions(planId);
});
