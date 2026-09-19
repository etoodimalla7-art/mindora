import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../domain/dashboard/study_session.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/notifications_providers.dart';
import '../../shared_widgets/empty_state.dart';
import 'widgets/streak_chip.dart';
import 'widgets/today_session_card.dart';
import 'widgets/weak_subject_banner.dart';

/// Personalized dashboard (section 13), now wired to real data from
/// /study-sessions/today and /progress/overview instead of placeholders.
/// A brand-new account with no plan yet correctly shows the "set your
/// exam goal" empty state — never fake statistics.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  /// The dashboard doesn't yet read the student's target exam from
  /// their education profile (that provider isn't wired up in the
  /// frontend yet — a follow-up once onboarding data is surfaced
  /// elsewhere in the app), so this asks directly rather than blocking
  /// the feature on that wiring.
  Future<void> _promptForExamAndViewReadiness(BuildContext context) async {
    final controller = TextEditingController();
    final examName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Which exam?'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. GCE Advanced Level'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('View'),
          ),
        ],
      ),
    );
    if (examName != null && examName.isNotEmpty && context.mounted) {
      context.push('/readiness', extra: examName);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(todaySessionsProvider);
    final overviewAsync = ref.watch(dashboardOverviewProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todaySessionsProvider);
          ref.invalidate(dashboardOverviewProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: Text('${_greeting()} 👋'),
              actions: [
                IconButton(
                  icon: Badge(
                    isLabelVisible: ref.watch(unreadNotificationCountProvider) > 0,
                    label: Text('${ref.watch(unreadNotificationCountProvider)}'),
                    child: const Icon(Icons.notifications_none_rounded),
                  ),
                  onPressed: () => context.push('/notifications'),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: sessionsAsync.when(
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.wifi_off_rounded,
                    title: "Couldn't load your dashboard",
                    message: 'Check your connection and pull down to try again.',
                  ),
                ),
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.flag_rounded,
                        title: 'No exam set yet',
                        message:
                            "Tell us what you're preparing for and we'll build "
                            'your personalized dashboard — countdown, daily '
                            'focus and readiness score.',
                        actionLabel: 'Set my exam goal',
                        onAction: () => context.push('/planner/create'),
                      ),
                    );
                  }
                  return SliverList.list(
                    children: [
                      overviewAsync.maybeWhen(
                        data: (overview) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: StreakChip(days: overview.streakDays),
                        ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                      for (final StudySessionEntity session in sessions)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: TodaySessionCard(
                            session: session,
                            onStart: () => context.push('/study-session/${session.id}', extra: session),
                          ),
                        ),
                      overviewAsync.maybeWhen(
                        data: (overview) => overview.weakestSubject != null
                            ? WeakSubjectBanner(subjectName: overview.weakestSubject!)
                            : const SizedBox.shrink(),
                        orElse: () => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.insights_outlined),
                        label: const Text('View my exam readiness'),
                        onPressed: () => _promptForExamAndViewReadiness(context),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
