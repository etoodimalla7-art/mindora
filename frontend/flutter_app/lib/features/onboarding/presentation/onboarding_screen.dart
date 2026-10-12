import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/design/widgets/widgets.dart';
import '../../../core/locale/locale_provider.dart';
import '../../../core/router/routes.dart';
import '../../../l10n/app_strings.dart';
import '../state/onboarding_state.dart';
import '../state/onboarding_submitter.dart';
import 'steps/step_catalogue.dart';
import 'steps/step_country.dart';
import 'steps/step_education_system.dart';
import 'steps/step_exam_date.dart';
import 'steps/step_goal.dart';
import 'steps/step_language.dart';
import 'steps/step_level.dart';
import 'steps/step_notifications.dart';
import 'steps/step_personalize.dart';
import 'steps/step_program.dart';
import 'steps/step_study_times.dart';
import 'steps/step_subjects.dart';
import 'steps/step_welcome_done.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _steps = const [
    OnboardingStep.language,
    OnboardingStep.country,
    OnboardingStep.educationSystem,
    OnboardingStep.level,
    OnboardingStep.program,
    OnboardingStep.subjects,
    OnboardingStep.goal,
    OnboardingStep.examDate,
    OnboardingStep.studyTimes,
    OnboardingStep.notifications,
    OnboardingStep.personalize,
    OnboardingStep.done,
  ];

  int _index = 0;
  bool _submitting = false;

  void _next() async {
    if (_index < _steps.length - 1) {
      setState(() => _index++);
      return;
    }
    // Finish
    setState(() => _submitting = true);
    try {
      final draft = ref.read(onboardingProvider);
      await ref.read(onboardingSubmitterProvider).submit(draft);
      if (!mounted) return;
      context.go(AppRoutes.home);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _back() {
    if (_index > 0) setState(() => _index--);
  }

  Widget _buildStep(OnboardingStep step) => switch (step) {
        OnboardingStep.language => const StepLanguage(),
        OnboardingStep.country => const StepCountry(),
        OnboardingStep.educationSystem => const StepEducationSystem(),
        OnboardingStep.level => const StepLevel(),
        OnboardingStep.program => const StepProgram(),
        OnboardingStep.subjects => const StepSubjects(),
        OnboardingStep.goal => const StepGoal(),
        OnboardingStep.examDate => const StepExamDate(),
        OnboardingStep.studyTimes => const StepStudyTimes(),
        OnboardingStep.notifications => const StepNotifications(),
        OnboardingStep.personalize => const StepPersonalize(),
        OnboardingStep.done => const StepWelcomeDone(),
      };

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final step = _steps[_index];
    final progress = (_index + 1) / _steps.length;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress bar + skip
              Row(
                children: [
                  if (_index > 0)
                    IconButton(
                      onPressed: _back,
                      icon: const Icon(Icons.arrow_back),
                      tooltip: s.back,
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 240),
                        builder: (_, v, __) => LinearProgressIndicator(
                          value: v,
                          minHeight: 6,
                          backgroundColor:
                              Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.home),
                    child: Text(s.skip),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxxl),

              Text(step.title(s), style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                step.subtitle(s),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.65),
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),

              Expanded(child: _buildStep(step)),

              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: _index == _steps.length - 1 ? s.finish : s.continueLabel,
                loading: _submitting,
                onPressed: _submitting ? null : _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
