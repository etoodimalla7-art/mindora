import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared_widgets/onboarding_step_scaffold.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../providers/onboarding_controller.dart';
import '../onboarding_screen.dart';

/// Section 47: notifications must be useful, not spammy — we ask
/// permission with a clear, specific reason rather than a bare OS prompt.
/// Actual OS-level permission request wiring lands in Phase 14.
class NotificationPermissionStep extends ConsumerWidget {
  const NotificationPermissionStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = OnboardingStepContext.of(context);
    final data = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final theme = Theme.of(context);

    return OnboardingStepScaffold(
      stepIndex: step.stepIndex,
      totalSteps: step.totalSteps,
      onBack: step.onBack,
      title: 'Stay on track',
      onNext: step.onNext,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notifications_active_outlined, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            "We'll remind you before study sessions, when you fall behind "
            'schedule, and as your exam date approaches — nothing else.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable study reminders'),
            value: data.notificationsEnabled,
            onChanged: (value) => controller.update((d) => d.copyWith(notificationsEnabled: value)),
          ),
        ],
      ),
    );
  }
}
