import 'package:flutter/material.dart';

import '../../../../l10n/app_strings.dart';

enum OnboardingStep {
  language,
  country,
  educationSystem,
  level,
  program,
  subjects,
  goal,
  examDate,
  studyTimes,
  notifications,
  personalize,
  done,
}

extension OnboardingStepX on OnboardingStep {
  String title(AppStrings s) => switch (this) {
        OnboardingStep.language => s.stepLanguage,
        OnboardingStep.country => s.stepCountry,
        OnboardingStep.educationSystem => s.stepEducationSystem,
        OnboardingStep.level => s.stepLevel,
        OnboardingStep.program => s.stepProgram,
        OnboardingStep.subjects => s.stepSubjects,
        OnboardingStep.goal => s.stepGoal,
        OnboardingStep.examDate => s.stepExamDate,
        OnboardingStep.studyTimes => s.stepStudyTimes,
        OnboardingStep.notifications => s.stepNotifications,
        OnboardingStep.personalize => s.stepPersonalize,
        OnboardingStep.done => s.stepDone,
      };

  String subtitle(AppStrings s) => switch (this) {
        OnboardingStep.language => s.stepLanguageSub,
        OnboardingStep.country => s.stepCountrySub,
        OnboardingStep.educationSystem => s.stepEducationSystemSub,
        OnboardingStep.level => s.stepLevelSub,
        OnboardingStep.program => s.stepProgramSub,
        OnboardingStep.subjects => s.stepSubjectsSub,
        OnboardingStep.goal => s.stepGoalSub,
        OnboardingStep.examDate => s.stepExamDateSub,
        OnboardingStep.studyTimes => s.stepStudyTimesSub,
        OnboardingStep.notifications => s.stepNotificationsSub,
        OnboardingStep.personalize => s.stepPersonalizeSub,
        OnboardingStep.done => s.stepDoneSub,
      };
}
