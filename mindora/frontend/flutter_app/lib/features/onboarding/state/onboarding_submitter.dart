import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../state/onboarding_state.dart';

final onboardingSubmitterProvider = Provider<OnboardingSubmitter>(
  (ref) => OnboardingSubmitter(ref),
);

class OnboardingSubmitter {
  OnboardingSubmitter(this.ref);
  final Ref ref;

  /// Persists the education profile to the backend.
  /// Requires an authenticated user — the wizard registers/logs in first.
  Future<void> submit(OnboardingDraft draft) async {
    final dio = ref.read(dioProvider);
    await dio.put('/users/me/education', data: {
      'education_system': draft.educationSystem,
      'level': draft.level,
      'program': draft.program,
      'subjects': draft.subjects,
      'goals': draft.goal != null ? [draft.goal] : [],
      'study_preferences': {
        'studyWindows': draft.studyWindows,
        'explanationStyle': draft.explanationStyle,
        'notifications': draft.allowNotifications,
      },
      'target_exam_date':
          draft.targetExamDate?.toIso8601String().substring(0, 10),
    });
  }
}
