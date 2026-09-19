import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/onboarding/onboarding_local_flags.dart';
import '../../domain/onboarding/onboarding_data.dart';
import 'core_providers.dart';

final onboardingLocalFlagsProvider = Provider((ref) => OnboardingLocalFlags());

final onboardingCompleteProvider = FutureProvider<bool>((ref) {
  return ref.watch(onboardingLocalFlagsProvider).isComplete();
});

class OnboardingController extends StateNotifier<OnboardingData> {
  OnboardingController(this._ref) : super(const OnboardingData());

  final Ref _ref;

  void update(OnboardingData Function(OnboardingData) transform) {
    state = transform(state);
  }

  /// Called from the final onboarding screen. Sends the collected
  /// education profile AND notification preferences (section 47 —
  /// previously collected in the notification-permission step but
  /// never actually sent anywhere) to the backend, then marks
  /// onboarding done locally so the router stops sending the user
  /// back through it.
  Future<bool> submit() async {
    if (!state.isReadyToSubmit) return false;
    final apiClient = _ref.read(apiClientProvider);
    try {
      await apiClient.dio.put('/users/me/education-profile', data: {
        'country': state.country,
        'education_system': state.educationSystem,
        'level': state.educationLevel,
        'program': state.program,
        'target_exam': state.targetExam,
        'target_exam_date': state.targetExamDate?.toIso8601String().split('T').first,
      });
      try {
        await apiClient.dio.put('/notifications/preferences', data: {
          'enabled': state.notificationsEnabled,
          'preferred_study_times': state.preferredStudyTimes,
        });
      } catch (_) {
        // Non-fatal: the education profile (required) saved fine;
        // notification preferences default sensibly server-side and
        // can be changed later in Settings if this call fails.
      }
      await _ref.read(onboardingLocalFlagsProvider).markComplete();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingData>((ref) {
  return OnboardingController(ref);
});
