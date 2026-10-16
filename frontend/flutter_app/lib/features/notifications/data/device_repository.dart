/// Orchestrates device registration with the backend.
///
/// Best-effort: silently no-ops if the token is missing or the network fails.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../../core/notifications/push_service.dart';
import 'notification_api.dart';

class DeviceRepository {
  DeviceRepository(this._api);
  final NotificationApi _api;
  final Logger _log = Logger();

  /// Called after login/register. Non-blocking, best-effort.
  Future<void> registerCurrentDevice() async {
    final token = PushService.instance.token;
    if (token == null || token.isEmpty) {
      _log.d('No FCM token yet, skipping device registration');
      return;
    }
    final platform = _platform();
    await _api.registerDevice(
      fcmToken: token,
      platform: platform,
    );
  }

  String _platform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    if (Platform.isWindows) return 'windows';
    return 'unknown';
  }
}
