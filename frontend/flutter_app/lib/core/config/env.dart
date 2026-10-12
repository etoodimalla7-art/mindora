import 'package:flutter/foundation.dart';

class Env {
  Env._();

  /// In Codespaces, the backend is reachable on the same host at port 8000.
  /// Web preview will proxy through the forwarded port.
  static const String _fallback = 'http://localhost:8000/api/v1';

  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return _fallback;
    return _fallback;
  }
}
