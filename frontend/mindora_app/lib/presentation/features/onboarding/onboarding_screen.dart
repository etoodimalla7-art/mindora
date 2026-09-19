import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'steps/intro_step.dart';
import 'steps/language_step.dart';
import 'steps/country_step.dart';
import 'steps/education_system_step.dart';
import 'steps/education_level_step.dart';
import 'steps/academic_profile_step.dart';
import 'steps/study_goals_step.dart';
import 'steps/learning_preferences_step.dart';
import 'steps/notification_permission_step.dart';
import 'steps/ai_personalization_step.dart';
import 'steps/completion_step.dart';

/// Hosts the 13-screen onboarding sequence (section 10) as a PageView.
/// Each step is its own widget under steps/ and only needs to call
/// `advance()` / `goBack()` — this host owns the page controller and
/// step count so no single step file has to know its position.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();

  static const _steps = [
    IntroStep(),
    LanguageStep(),
    CountryStep(),
    EducationSystemStep(),
    EducationLevelStep(),
    AcademicProfileStep(),
    StudyGoalsStep(),
    LearningPreferencesStep(),
    NotificationPermissionStep(),
    AiPersonalizationStep(),
    CompletionStep(),
  ];

  void _advance() {
    if (_pageController.page!.round() == _steps.length - 1) {
      context.go('/home');
      return;
    }
    _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _goBack() {
    _pageController.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 0; i < _steps.length; i++)
            OnboardingStepContext(
              stepIndex: i,
              totalSteps: _steps.length,
              onNext: _advance,
              onBack: i == 0 ? null : _goBack,
              child: _steps[i],
            ),
        ],
      ),
    );
  }
}

/// InheritedWidget-style context so each step widget can read its
/// position/callbacks without threading them through constructors.
class OnboardingStepContext extends InheritedWidget {
  const OnboardingStepContext({
    super.key,
    required this.stepIndex,
    required this.totalSteps,
    required this.onNext,
    required this.onBack,
    required super.child,
  });

  final int stepIndex;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  static OnboardingStepContext of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<OnboardingStepContext>();
    assert(result != null, 'No OnboardingStepContext found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(OnboardingStepContext oldWidget) => false;
}
