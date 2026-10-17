import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/design/widgets/widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/dashboard_providers.dart';
import '../domain/dashboard_models.dart';
import 'widgets/dashboard_cards.dart';
import '../../../core/design/widgets/mindora_app_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(authControllerProvider).session;
    final dashboardAsync = ref.watch(dashboardProvider);

    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 18
            ? 'Good afternoon'
            : 'Good evening';

    final displayName = session?.user.fullName?.split(' ').first ??
        session?.user.email.split('@').first ??
        'student';

    return Scaffold(
      appBar: const MindoraAppBar(showWordmark: true),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardProvider);
            await ref.read(dashboardProvider.future);
          },
          child: dashboardAsync.when(
            loading: () => _LoadingState(
              greeting: greeting,
              displayName: displayName,
            ),
            error: (err, _) => _ErrorState(
              greeting: greeting,
              displayName: displayName,
              onRetry: () => ref.invalidate(dashboardProvider),
            ),
            data: (d) => _DashboardBody(
              theme: theme,
              greeting: greeting,
              displayName: displayName,
              dashboard: d,
              isAuthenticated: session != null,
              onRefresh: () => ref.invalidate(dashboardProvider),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Loaded state
// ============================================================

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.theme,
    required this.greeting,
    required this.displayName,
    required this.dashboard,
    required this.isAuthenticated,
    required this.onRefresh,
  });

  final ThemeData theme;
  final String greeting;
  final String displayName;
  final Dashboard dashboard;
  final bool isAuthenticated;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final hasAnyData = dashboard.examCountdown != null ||
        dashboard.todayFocus != null ||
        dashboard.streakDays > 0 ||
        dashboard.recentActivity.isNotEmpty;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        _Greeting(greeting: greeting, displayName: displayName),
        const SizedBox(height: AppSpacing.xl),

        if (dashboard.examCountdown != null) ...[
          ExamCountdownCard(countdown: dashboard.examCountdown!),
          const SizedBox(height: AppSpacing.lg),
        ],

        if (!hasAnyData) ...[
          _GetStartedCard(),
          const SizedBox(height: AppSpacing.xl),
          Text("Today's focus", style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          const AppEmptyState(
            icon: Icons.event_available_outlined,
            title: 'Nothing scheduled yet',
            message:
                'Once you create a study plan, your daily sessions will appear here.',
          ),
        ] else ...[
          if (dashboard.streakDays > 0) ...[
            StreakCard(days: dashboard.streakDays),
            const SizedBox(height: AppSpacing.lg),
          ],

          if (dashboard.todayFocus != null) ...[
            Text("Today's focus", style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            TodayFocusCard(focus: dashboard.todayFocus!),
            const SizedBox(height: AppSpacing.xl),
          ],

          if (dashboard.readinessScore > 0) ...[
            ReadinessCard(
              score: dashboard.readinessScore,
              breakdown: dashboard.readinessBreakdown,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          if (dashboard.weakTopics.isNotEmpty) ...[
            WeakTopicsCard(topics: dashboard.weakTopics),
            const SizedBox(height: AppSpacing.lg),
          ],

          if (dashboard.recentActivity.isNotEmpty) ...[
            RecentActivityCard(items: dashboard.recentActivity),
            const SizedBox(height: AppSpacing.lg),
          ],

          Text('Quick actions', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          const _QuickActions(),
        ],

        const SizedBox(height: AppSpacing.massive),
      ],
    );
  }
}

// ============================================================
// Greeting row
// ============================================================

class _Greeting extends StatelessWidget {
  const _Greeting({required this.greeting, required this.displayName});
  final String greeting;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting 👋',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Welcome, $displayName',
                style: theme.textTheme.headlineSmall,
              ),
            ],
          ),
        ),
        AppAvatar(
          initials: displayName.isNotEmpty ? displayName.substring(0, 1) : '?',
        ),
      ],
    );
  }
}

// ============================================================
// Get-started (only shown when nothing exists yet)
// ============================================================

class _GetStartedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.xl),
      color: theme.colorScheme.primary.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Get started', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tell us your exam and subjects. We will build a personalized study plan.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Create my study plan',
            icon: Icons.auto_awesome,
            onPressed: () {},
            expand: false,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Quick actions
// ============================================================

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actions = <(IconData, String, VoidCallback)>[
      (Icons.auto_awesome_outlined, 'Ask AI', () {}),
      (Icons.quiz_outlined, 'Quick quiz', () {}),
      (Icons.style_outlined, 'Flashcards', () {}),
      (Icons.event_outlined, 'Open planner', () {}),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 2.4,
      children: [
        for (final (icon, label, onTap) in actions)
          AppSurface(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            onTap: onTap,
            child: Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ============================================================
// Loading state — skeleton cards
// ============================================================

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.greeting, required this.displayName});
  final String greeting;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        _Greeting(greeting: greeting, displayName: displayName),
        const SizedBox(height: AppSpacing.xl),
        const AppSkeleton(height: 92),
        const SizedBox(height: AppSpacing.lg),
        const AppSkeleton(height: 68),
        const SizedBox(height: AppSpacing.lg),
        const AppSkeleton(height: 180),
        const SizedBox(height: AppSpacing.lg),
        const AppSkeleton(height: 140),
      ],
    );
  }
}

// ============================================================
// Error state
// ============================================================

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.greeting,
    required this.displayName,
    required this.onRetry,
  });

  final String greeting;
  final String displayName;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        _Greeting(greeting: greeting, displayName: displayName),
        const SizedBox(height: AppSpacing.xxxl),
        AppEmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'We could not load your dashboard',
          message: 'Please check your connection and try again.',
          actionLabel: 'Try again',
          onAction: onRetry,
        ),
      ],
    );
  }
}
