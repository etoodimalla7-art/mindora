import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tokens are the only thing sensitive enough to need secure storage;
/// everything else (locale, onboarding flags) can use plain prefs later.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessKey = 'mindora_access_token';
  static const _refreshKey = 'mindora_refresh_token';

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  Future<String?> readAccessToken() => _storage.read(key: _accessKey);
  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  Future<bool> hasSession() async => (await readAccessToken()) != null;

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
