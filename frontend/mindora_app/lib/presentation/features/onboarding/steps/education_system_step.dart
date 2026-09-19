import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared_widgets/onboarding_step_scaffold.dart';
import '../../../shared_widgets/option_tile.dart';
import '../../../providers/onboarding_controller.dart';
import '../onboarding_screen.dart';

/// Section 12: English-track and French-track systems, chosen based on
/// the language selected earlier — extensible list, not hardcoded logic.
class EducationSystemStep extends ConsumerWidget {
  const EducationSystemStep({super.key});

  static const _englishSystems = ['GCE Ordinary Level', 'GCE Advanced Level', 'HND', 'BTS', 'Licence', 'Master'];
  static const _frenchSystems = ['BEPC', 'Probatoire', 'Baccalauréat', 'BTS', 'Licence', 'Master'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = OnboardingStepContext.of(context);
    final data = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final systems = data.locale == 'fr' ? _frenchSystems : _englishSystems;

    return OnboardingStepScaffold(
      stepIndex: step.stepIndex,
      totalSteps: step.totalSteps,
      onBack: step.onBack,
      title: 'Your education system',
      onNext: data.educationSystem != null ? step.onNext : null,
      content: ListView(
        children: [
          for (final system in systems)
            OptionTile(
              label: system,
              selected: data.educationSystem == system,
              onTap: () => controller.update((d) => d.copyWith(educationSystem: system)),
            ),
        ],
      ),
    );
  }
}
