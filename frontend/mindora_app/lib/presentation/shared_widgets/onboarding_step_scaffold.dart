import 'package:flutter/material.dart';
import '../../core/theme/spacing_tokens.dart';

/// Shared layout for every onboarding step (section 10): progress bar,
/// title/subtitle, scrollable content, and a bottom primary action.
/// Individual steps only provide `content` and decide when `onNext`
/// is enabled — they never re-implement this chrome.
class OnboardingStepScaffold extends StatelessWidget {
  const OnboardingStepScaffold({
    super.key,
    required this.stepIndex,
    required this.totalSteps,
    required this.title,
    this.subtitle,
    required this.content,
    required this.onNext,
    this.nextLabel = 'Continue',
    this.onBack,
  });

  final int stepIndex;
  final int totalSteps;
  final String title;
  final String? subtitle;
  final Widget content;
  final VoidCallback? onNext;
  final String nextLabel;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (onBack != null)
                  IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: (stepIndex + 1) / totalSteps,
                      minHeight: 6,
                      backgroundColor: theme.dividerColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(title, style: theme.textTheme.headlineMedium),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(subtitle!, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: AppSpacing.lg),
            Expanded(child: content),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: onNext, child: Text(nextLabel)),
            ),
          ],
        ),
      ),
    );
  }
}
