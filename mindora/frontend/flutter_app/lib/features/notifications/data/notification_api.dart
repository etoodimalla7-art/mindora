/// HTTP client for the notification endpoints.
///
/// Endpoints used:
/// - POST   /notifications/devices         (register)
/// - DELETE /notifications/devices/{id}    (unregister)
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class NotificationApi {
  NotificationApi(this._dio);
  final Dio _dio;
  final Logger _log = Logger();

  Future<String?> registerDevice({
    required String fcmToken,
    required String platform,
    String? deviceModel,
    String? osVersion,
    String? appVersion,
  }) async {
    try {
      final r = await _dio.post(
        '/notifications/devices',
        data: {
          'fcm_token': fcmToken,
          'platform': platform,
          if (deviceModel != null) 'device_model': deviceModel,
          if (osVersion != null) 'os_version': osVersion,
          if (appVersion != null) 'app_version': appVersion,
        },
      );
      final id = (r.data as Map<String, dynamic>)['id']?.toString();
      _log.i('Device registered: $id');
      return id;
    } on DioException catch (e) {
      _log.w('registerDevice failed: ${e.response?.statusCode} ${e.message}');
      return null;
    } catch (e) {
      _log.w('registerDevice unexpected: $e');
      return null;
    }
  }

  Future<bool> unregisterDevice(String deviceId) async {
    try {
      await _dio.delete('/notifications/devices/$deviceId');
      return true;
    } catch (e) {
      if (kDebugMode) _log.w('unregisterDevice failed: $e');
      return false;
    }
  }
}
