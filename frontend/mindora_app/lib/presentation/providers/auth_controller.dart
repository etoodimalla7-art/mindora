import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../domain/auth/auth_repository.dart';
import 'core_providers.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({required this.status, this.errorMessage});
  final AuthStatus status;
  final String? errorMessage;

  AuthState copyWith({AuthStatus? status, String? errorMessage}) =>
      AuthState(status: status ?? this.status, errorMessage: errorMessage);
}

/// Drives the router redirect (see app_router.dart) and every auth screen.
/// Screens never call the repository directly — they call this controller
/// so there is exactly one place that owns auth state.
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState(status: AuthStatus.unknown)) {
    _restore();
  }

  final AuthRepository _repository;

  Future<void> _restore() async {
    final hasSession = await _repository.hasActiveSession();
    state = AuthState(status: hasSession ? AuthStatus.authenticated : AuthStatus.unauthenticated);
  }

  Future<bool> register({required String email, required String password, required String locale}) =>
      _guard(() => _repository.register(email: email, password: password, locale: locale));

  Future<bool> login({required String email, required String password}) =>
      _guard(() => _repository.login(email: email, password: password));

  Future<bool> forgotPassword(String email) =>
      _guard(() => _repository.forgotPassword(email), setAuthenticated: false);

  Future<bool> resetPassword({required String resetToken, required String newPassword}) =>
      _guard(
        () => _repository.resetPassword(resetToken: resetToken, newPassword: newPassword),
        setAuthenticated: false,
      );

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> _guard(Future<void> Function() action, {bool setAuthenticated = true}) async {
    try {
      await action();
      state = AuthState(
        status: setAuthenticated ? AuthStatus.authenticated : state.status,
      );
      return true;
    } catch (error) {
      state = state.copyWith(errorMessage: extractApiErrorMessage(error));
      return false;
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
