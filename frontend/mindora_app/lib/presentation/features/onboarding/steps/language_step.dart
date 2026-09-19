import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../presentation/shared_widgets/onboarding_step_scaffold.dart';
import '../../../../presentation/shared_widgets/option_tile.dart';
import '../../../providers/onboarding_controller.dart';
import '../onboarding_screen.dart';

class LanguageStep extends ConsumerWidget {
  const LanguageStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = OnboardingStepContext.of(context);
    final data = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return OnboardingStepScaffold(
      stepIndex: step.stepIndex,
      totalSteps: step.totalSteps,
      onBack: step.onBack,
      title: 'Choose your language',
      subtitle: 'This sets your app language — you can change it later in Settings.',
      onNext: data.locale != null ? step.onNext : null,
      content: Column(
        children: [
          OptionTile(
            label: 'English',
            selected: data.locale == 'en',
            onTap: () => controller.update((d) => d.copyWith(locale: 'en')),
          ),
          OptionTile(
            label: 'Français',
            selected: data.locale == 'fr',
            onTap: () => controller.update((d) => d.copyWith(locale: 'fr')),
          ),
        ],
      ),
    );
  }
}
