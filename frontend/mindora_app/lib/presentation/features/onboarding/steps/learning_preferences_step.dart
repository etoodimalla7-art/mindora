import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared_widgets/onboarding_step_scaffold.dart';
import '../../../shared_widgets/option_tile.dart';
import '../../../providers/onboarding_controller.dart';
import '../onboarding_screen.dart';

class LearningPreferencesStep extends ConsumerWidget {
  const LearningPreferencesStep({super.key});

  static const _times = ['Early morning', 'Afternoon', 'Evening', 'Late night'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = OnboardingStepContext.of(context);
    final data = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    void toggle(String time) {
      final times = List<String>.from(data.preferredStudyTimes);
      times.contains(time) ? times.remove(time) : times.add(time);
      controller.update((d) => d.copyWith(preferredStudyTimes: times));
    }

    return OnboardingStepScaffold(
      stepIndex: step.stepIndex,
      totalSteps: step.totalSteps,
      onBack: step.onBack,
      title: 'When do you study best?',
      subtitle: 'This shapes when we schedule your sessions and reminders.',
      onNext: step.onNext,
      content: ListView(
        children: [
          for (final time in _times)
            OptionTile(
              label: time,
              selected: data.preferredStudyTimes.contains(time),
              onTap: () => toggle(time),
            ),
        ],
      ),
    );
  }
}
