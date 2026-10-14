import 'package:flutter/foundation.dart';

class Env {
  Env._();

  /// Base URL of the MINDORA backend API.
  ///
  /// Resolution order:
  ///   1. Dart-define `API_BASE_URL` (production / CI override).
  ///   2. On web: derive from the current page origin.
  ///   3. On Android: use the Codespaces public URL (set at build time).
  ///   4. Fallback: localhost (desktop / emulator).
  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) return override;

    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        return '${_codespacesRewrite(origin)}/api/v1';
      } catch (_) {
        // Fall through.
      }
    }

    // Android / Desktop default: point to the Codespaces public backend.
    // Override this at build time with:
    //   flutter build apk --dart-define=API_BASE_URL=https://xxx-8000.app.github.dev/api/v1
    return 'http://localhost:8000/api/v1';
  }

  static String _codespacesRewrite(String origin) {
    return origin
        .replaceFirst('-3000.', '-8000.')
        .replaceFirst('-8080.', '-8000.')
        .replaceFirst(':3000', ':8000');
  }
}
