import 'package:dio/dio.dart';

import '../../../core/network/token_store.dart';
import '../domain/auth_models.dart';

class AuthRepository {
  AuthRepository(this._dio);
  final Dio _dio;
  final _store = TokenStore();

  Future<AuthSession> register({
    required String email,
    required String password,
    String? fullName,
    String preferredLanguage = 'en',
    String countryCode = 'CM',
  }) async {
    final r = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'full_name': fullName,
      'preferred_language': preferredLanguage,
      'country_code': countryCode,
    });
    final session = AuthSession.fromJson(r.data as Map<String, dynamic>);
    await _store.save(
      access: session.tokens.accessToken,
      refresh: session.tokens.refreshToken,
    );
    return session;
  }

  Future<AuthSession> login({required String email, required String password}) async {
    final r = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final session = AuthSession.fromJson(r.data as Map<String, dynamic>);
    await _store.save(
      access: session.tokens.accessToken,
      refresh: session.tokens.refreshToken,
    );
    return session;
  }

  Future<void> logout() async {
    final refresh = await _store.refresh;
    if (refresh != null) {
      try {
        await _dio.post('/auth/logout', data: {'refresh_token': refresh});
      } catch (_) {}
    }
    await _store.clear();
  }

  Future<AuthUser?> currentUser() async {
    final token = await _store.access;
    if (token == null) return null;
    try {
      final r = await _dio.get('/users/me');
      return AuthUser.fromJson(r.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
