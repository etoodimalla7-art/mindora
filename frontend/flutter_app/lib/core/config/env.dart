import 'package:flutter/foundation.dart';

class Env {
  Env._();

  /// Base URL of the MINDORA backend API.
  ///
  /// Resolution order:
  ///   1. Dart-define `API_BASE_URL` (production / CI override).
  ///   2. On web: derive from `Uri.base` — the browser's current URL.
  ///   3. Fallback to localhost for desktop / test.
  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) return override;

    if (kIsWeb) {
      try {
        final origin = Uri.base.origin; // e.g. "https://xxx-3000.app.github.dev"
        return '${_codespacesRewrite(origin)}/api/v1';
      } catch (_) {
        // Fall through.
      }
    }

    return 'http://localhost:8000/api/v1';
  }

  /// Rewrite the Codespaces port in the origin.
  ///   https://slug-3000.app.github.dev → https://slug-8000.app.github.dev
  static String _codespacesRewrite(String origin) {
    return origin
        .replaceFirst('-3000.', '-8000.')
        .replaceFirst('-8080.', '-8000.')
        .replaceFirst(':3000', ':8000');
  }
}