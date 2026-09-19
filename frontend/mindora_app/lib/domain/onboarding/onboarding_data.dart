/// Everything collected across the onboarding screens (sections 10-12).
/// Immutable — each screen calls `copyWith` on the controller's state.
class OnboardingData {
  const OnboardingData({
    this.locale,
    this.country,
    this.educationSystem,
    this.educationLevel,
    this.program,
    this.targetExam,
    this.targetExamDate,
    this.studyGoals = const [],
    this.preferredStudyTimes = const [],
    this.notificationsEnabled = false,
  });

  final String? locale;
  final String? country;
  final String? educationSystem;
  final String? educationLevel;
  final String? program;
  final String? targetExam;
  final DateTime? targetExamDate;
  final List<String> studyGoals;
  final List<String> preferredStudyTimes;
  final bool notificationsEnabled;

  bool get isReadyToSubmit =>
      country != null && educationSystem != null && educationLevel != null;

  OnboardingData copyWith({
    String? locale,
    String? country,
    String? educationSystem,
    String? educationLevel,
    String? program,
    String? targetExam,
    DateTime? targetExamDate,
    List<String>? studyGoals,
    List<String>? preferredStudyTimes,
    bool? notificationsEnabled,
  }) {
    return OnboardingData(
      locale: locale ?? this.locale,
      country: country ?? this.country,
      educationSystem: educationSystem ?? this.educationSystem,
      educationLevel: educationLevel ?? this.educationLevel,
      program: program ?? this.program,
      targetExam: targetExam ?? this.targetExam,
      targetExamDate: targetExamDate ?? this.targetExamDate,
      studyGoals: studyGoals ?? this.studyGoals,
      preferredStudyTimes: preferredStudyTimes ?? this.preferredStudyTimes,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
