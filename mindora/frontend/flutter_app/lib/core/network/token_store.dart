import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cross-platform token storage.
///
/// - Mobile (iOS/Android): flutter_secure_storage (encrypted)
/// - Web: shared_preferences (localStorage, persists across reloads)
/// - Desktop: flutter_secure_storage (or fallback if not supported)
class TokenStore {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  // Mobile / desktop
  static const _secure = FlutterSecureStorage();

  Future<void> save({required String access, required String refresh}) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessKey, access);
      await prefs.setString(_refreshKey, refresh);
      return;
    }
    await _secure.write(key: _accessKey, value: access);
    await _secure.write(key: _refreshKey, value: refresh);
  }

  Future<String?> get access async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessKey);
    }
    return _secure.read(key: _accessKey);
  }

  Future<String?> get refresh async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshKey);
    }
    return _secure.read(key: _refreshKey);
  }

  Future<void> clear() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessKey);
      await prefs.remove(_refreshKey);
      return;
    }
    await _secure.delete(key: _accessKey);
    await _secure.delete(key: _refreshKey);
  }
}
