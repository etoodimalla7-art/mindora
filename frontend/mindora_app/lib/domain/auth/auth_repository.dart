/// Pure-Dart contract — no Flutter, no Dio types leak in here. The
/// presentation layer depends on this interface, not on the concrete
/// Dio-backed implementation in data/auth/.
abstract class AuthRepository {
  Future<void> register({required String email, required String password, required String locale});
  Future<void> login({required String email, required String password});
  Future<void> logout();
  Future<void> forgotPassword(String email);
  Future<void> resetPassword({required String resetToken, required String newPassword});
  Future<bool> hasActiveSession();
}
