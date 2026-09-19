import 'package:flutter/material.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../onboarding_screen.dart';

class AiPersonalizationStep extends StatelessWidget {
  const AiPersonalizationStep({super.key});

  @override
  Widget build(BuildContext context) {
    final step = OnboardingStepContext.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Icon(Icons.psychology_alt_outlined, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.lg),
            Text('Your AI tutor is ready', style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "It already knows your exam, level and goals — it'll get "
              'sharper as you study, ask questions, and upload courses.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            ElevatedButton(onPressed: step.onNext, child: const Text('Continue')),
          ],
        ),
      ),
    );
  }
}
