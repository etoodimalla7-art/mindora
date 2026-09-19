import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared_widgets/onboarding_step_scaffold.dart';
import '../../../shared_widgets/option_tile.dart';
import '../../../providers/onboarding_controller.dart';
import '../onboarding_screen.dart';

/// For most systems selected above the "level" is the system itself
/// (e.g. GCE Advanced Level); for broader ones (Licence/Master/HND/BTS)
/// this step narrows to year/class. Kept simple for Phase 2 — a real
/// per-system level catalog is a Phase 4 (course/document architecture) task.
class EducationLevelStep extends ConsumerWidget {
  const EducationLevelStep({super.key});

  static const _years = ['Year 1', 'Year 2', 'Year 3', 'Final Year'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = OnboardingStepContext.of(context);
    final data = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final needsYear = data.educationSystem != null &&
        ['HND', 'BTS', 'Licence', 'Master'].contains(data.educationSystem);

    return OnboardingStepScaffold(
      stepIndex: step.stepIndex,
      totalSteps: step.totalSteps,
      onBack: step.onBack,
      title: needsYear ? 'Which year are you in?' : 'Confirm your level',
      onNext: data.educationLevel != null ? step.onNext : null,
      content: needsYear
          ? ListView(
              children: [
                for (final year in _years)
                  OptionTile(
                    label: year,
                    selected: data.educationLevel == year,
                    onTap: () => controller.update((d) => d.copyWith(educationLevel: year)),
                  ),
              ],
            )
          : OptionTile(
              label: data.educationSystem ?? '',
              selected: data.educationLevel == data.educationSystem,
              onTap: () => controller.update((d) => d.copyWith(educationLevel: data.educationSystem)),
            ),
    );
  }
}
