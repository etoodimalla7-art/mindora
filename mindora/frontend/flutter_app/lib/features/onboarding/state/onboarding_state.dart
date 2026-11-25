import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingDraft {
  const OnboardingDraft({
    this.languageCode = 'en',
    this.countryCode = 'CM',
    this.educationSystem,
    this.level,
    this.program,
    this.subjects = const [],
    this.goal,
    this.targetExamDate,
    this.studyWindows = const [],
    this.explanationStyle,
    this.allowNotifications = true,
  });

  final String languageCode;
  final String countryCode;
  final String? educationSystem;
  final String? level;
  final String? program;
  final List<String> subjects;
  final String? goal;
  final DateTime? targetExamDate;
  final List<String> studyWindows;
  final String? explanationStyle;
  final bool allowNotifications;

  OnboardingDraft copyWith({
    String? languageCode,
    String? countryCode,
    String? educationSystem,
    String? level,
    String? program,
    List<String>? subjects,
    String? goal,
    DateTime? targetExamDate,
    List<String>? studyWindows,
    String? explanationStyle,
    bool? allowNotifications,
  }) =>
      OnboardingDraft(
        languageCode: languageCode ?? this.languageCode,
        countryCode: countryCode ?? this.countryCode,
        educationSystem: educationSystem ?? this.educationSystem,
        level: level ?? this.level,
        program: program ?? this.program,
        subjects: subjects ?? this.subjects,
        goal: goal ?? this.goal,
        targetExamDate: targetExamDate ?? this.targetExamDate,
        studyWindows: studyWindows ?? this.studyWindows,
        explanationStyle: explanationStyle ?? this.explanationStyle,
        allowNotifications: allowNotifications ?? this.allowNotifications,
      );
}

class OnboardingController extends StateNotifier<OnboardingDraft> {
  OnboardingController() : super(const OnboardingDraft());
  void update(OnboardingDraft draft) => state = draft;
}

final onboardingProvider =
    StateNotifierProvider<OnboardingController, OnboardingDraft>(
  (ref) => OnboardingController(),
);
