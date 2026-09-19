import 'package:flutter/material.dart';
import '../../../../core/theme/brand_config.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../onboarding_screen.dart';

class IntroStep extends StatelessWidget {
  const IntroStep({super.key});

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
            Icon(Icons.school_rounded, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.lg),
            Text("Let's set up ${BrandConfig.appName} for you",
                style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'A few quick questions so your study plan, AI tutor and '
              'recommendations actually match your exam and goals.',
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
