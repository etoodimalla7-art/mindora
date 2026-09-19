import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive local flag — separate from TokenStorage (which is
/// reserved for secure secrets). Just tracks whether the onboarding
/// flow has been completed on this device.
class OnboardingLocalFlags {
  static const _key = 'mindora_onboarding_complete';

  Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
