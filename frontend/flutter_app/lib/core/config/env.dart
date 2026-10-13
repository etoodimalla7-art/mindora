import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

class Env {
  Env._();

  /// Base URL of the MINDORA backend API.
  ///
  /// Resolution order:
  ///   1. Dart-define `API_BASE_URL` (production / CI override).
  ///   2. On web: derive from the current page origin, swapping the port
  ///      for the Codespaces port 8000 suffix. Works both in Codespaces
  ///      and on a normal web deployment behind a reverse proxy.
  ///   3. Fallback to localhost for desktop / test.
  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) return override;

    if (kIsWeb) {
      try {
        final origin = web.window.location.origin;
        // Codespaces pattern: hostname is `<slug>-<port>.app.github.dev`.
        // Rewrite it to use port 8000 while keeping the same base host.
        final rewritten = _codespacesRewrite(origin);
        return '$rewritten/api/v1';
      } catch (_) {
        // Fall through to localhost.
      }
    }

    return 'http://localhost:8000/api/v1';
  }

  static String _codespacesRewrite(String origin) {
    // Replace "-3000." with "-8000." in the hostname.
    // Example:
    //   https://urban-couscous-5g7r44jqv5qphpg4v-3000.app.github.dev
    //   → https://urban-couscous-5g7r44jqv5qphpg4v-8000.app.github.dev
    return origin
        .replaceFirst('-3000.', '-8000.')
        .replaceFirst('-8080.', '-8000.')
        .replaceFirst(':3000', ':8000');
  }
}
