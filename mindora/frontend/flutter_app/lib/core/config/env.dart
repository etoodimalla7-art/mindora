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

  static const String _defaultProdApiUrl = 'https://api.mindora.dev/api/v1';

  static String get apiBaseUrl {
    // 1. Explicit override from --dart-define=API_BASE_URL=...
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }

    // 2. Web: derive from current page origin (same-origin gateway proxies /api/v1)
    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        if (origin.isNotEmpty && origin != 'null') {
          return '${_rewriteWebOrigin(origin)}/api/v1';
        }
      } catch (_) {
        // fall through
      }
    }

    // 3. Production release builds without --dart-define use the production API host
    if (isProduction || kReleaseMode) {
      return _defaultProdApiUrl;
    }

    // 4. Local development / test harness fallback (never compiled into prod path)
    return 'http://127.0.0.1:8001/api/v1';
  }

  /// On GitHub Codespaces or local unified gateway (:3000 / :8080),
  /// route `/api/v1` through the same origin when served by the gateway,
  /// or rewrite Codespaces preview ports when needed.
  static String _rewriteWebOrigin(String origin) {
    return origin
        .replaceFirst('-3000.', '-8001.')
        .replaceFirst('-3001.', '-8001.');
  }
}
