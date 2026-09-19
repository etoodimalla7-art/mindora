import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared_widgets/onboarding_step_scaffold.dart';
import '../../../shared_widgets/option_tile.dart';
import '../../../providers/onboarding_controller.dart';
import '../onboarding_screen.dart';

class StudyGoalsStep extends ConsumerWidget {
  const StudyGoalsStep({super.key});

  static const _goals = [
    'Pass my upcoming exam',
    'Understand my courses better',
    'Build consistent study habits',
    'Catch up on topics I missed',
    'Get ahead of the syllabus',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = OnboardingStepContext.of(context);
    final data = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    void toggle(String goal) {
      final goals = List<String>.from(data.studyGoals);
      goals.contains(goal) ? goals.remove(goal) : goals.add(goal);
      controller.update((d) => d.copyWith(studyGoals: goals));
    }

    return OnboardingStepScaffold(
      stepIndex: step.stepIndex,
      totalSteps: step.totalSteps,
      onBack: step.onBack,
      title: 'What are your study goals?',
      subtitle: 'Choose as many as apply.',
      onNext: step.onNext,
      content: ListView(
        children: [
          for (final goal in _goals)
            OptionTile(
              label: goal,
              selected: data.studyGoals.contains(goal),
              onTap: () => toggle(goal),
            ),
        ],
      ),
    );
  }
}
