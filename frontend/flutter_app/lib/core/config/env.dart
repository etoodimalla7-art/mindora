import 'package:flutter/foundation.dart';

/// Centralized environment configuration.
///
/// URL resolution order:
///   1. `--dart-define=API_BASE_URL=...` at build time (CI / production).
///   2. On web: derive from the current page origin.
///   3. Fallback: localhost (dev / emulator only).
class Env {
  Env._();

  /// Compile-time override. Must be a class-level `const` so that
  /// `--dart-define` is honored at build time.
  static const String _apiBaseUrlOverride =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static const String _appEnv =
      String.fromEnvironment('APP_ENV', defaultValue: 'development');

  static bool get isProduction => _appEnv == 'production';

  static String get apiBaseUrl {
    // 1. Explicit override from --dart-define
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }

    // 2. Web: derive from origin
    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        return '${_codespacesRewrite(origin)}/api/v1';
      } catch (_) {
        // fall through
      }
    }

    // 3. Dev fallback (desktop / emulator)
    return 'http://localhost:8000/api/v1';
  }

  static String _codespacesRewrite(String origin) {
    return origin
        .replaceFirst('-3000.', '-8000.')
        .replaceFirst('-8080.', '-8000.')
        .replaceFirst(':3000', ':8000');
  }
}
