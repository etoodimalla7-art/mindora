import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';
import '../domain/auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);

class AuthState {
  const AuthState({this.session, this.loading = false, this.error});
  final AuthSession? session;
  final bool loading;
  final String? error;

  AuthState copyWith({AuthSession? session, bool? loading, String? error, bool clear = false}) =>
      AuthState(
        session: clear ? null : (session ?? this.session),
        loading: loading ?? this.loading,
        error: error,
      );

  bool get isAuthenticated => session != null;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo) : super(const AuthState());
  final AuthRepository _repo;

  Future<bool> register({
    required String email,
    required String password,
    String? fullName,
    String preferredLanguage = 'en',
    String countryCode = 'CM',
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final s = await _repo.register(
        email: email,
        password: password,
        fullName: fullName,
        preferredLanguage: preferredLanguage,
        countryCode: countryCode,
      );
      state = AuthState(session: s);
      return true;
    } catch (e) {
      state = AuthState(error: _friendly(e));
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final s = await _repo.login(email: email, password: password);
      state = AuthState(session: s);
      return true;
    } catch (e) {
      state = AuthState(error: _friendly(e));
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = state.copyWith(clear: true);
  }

  String _friendly(Object e) {
    // Never leak technical errors to users (Section 60).
    final msg = e.toString();
    if (msg.contains('409')) return 'An account with this email already exists.';
    if (msg.contains('401')) return 'Invalid email or password.';
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return 'We could not reach the server. Please check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref.watch(authRepositoryProvider)),
);
