import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../domain/auth/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._apiClient, this._tokenStorage);

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<void> _persistTokensFrom(Map<String, dynamic> envelope) async {
    final data = envelope['data'] as Map<String, dynamic>;
    await _tokenStorage.saveTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String locale,
  }) async {
    final response = await _apiClient.dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'locale': locale,
    });
    await _persistTokensFrom(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> login({required String email, required String password}) async {
    final response = await _apiClient.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    await _persistTokensFrom(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/auth/logout');
    } finally {
      await _tokenStorage.clear();
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    await _apiClient.dio.post('/auth/password/forgot', data: {'email': email});
  }

  @override
  Future<void> resetPassword({required String resetToken, required String newPassword}) async {
    await _apiClient.dio.post('/auth/password/reset', data: {
      'reset_token': resetToken,
      'new_password': newPassword,
    });
  }

  @override
  Future<bool> hasActiveSession() => _tokenStorage.hasSession();
}
