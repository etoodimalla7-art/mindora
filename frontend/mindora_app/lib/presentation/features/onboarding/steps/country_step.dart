import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared_widgets/onboarding_step_scaffold.dart';
import '../../../shared_widgets/option_tile.dart';
import '../../../providers/onboarding_controller.dart';
import '../onboarding_screen.dart';

/// Section 12: architecture must remain extensible to other countries —
/// Cameroon is first, the list is not hardcoded logic elsewhere.
class CountryStep extends ConsumerWidget {
  const CountryStep({super.key});

  static const _countries = ['Cameroon', 'Other'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = OnboardingStepContext.of(context);
    final data = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return OnboardingStepScaffold(
      stepIndex: step.stepIndex,
      totalSteps: step.totalSteps,
      onBack: step.onBack,
      title: 'Where are you studying?',
      onNext: data.country != null ? step.onNext : null,
      content: ListView(
        children: [
          for (final country in _countries)
            OptionTile(
              label: country,
              selected: data.country == country,
              onTap: () => controller.update((d) => d.copyWith(country: country)),
            ),
        ],
      ),
    );
  }
}
