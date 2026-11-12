/// FCM + local notifications service.
library;

import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

import 'notification_models.dart';

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final Logger _log = Logger();
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _token;

  final StreamController<PushPayload> _onForegroundController =
      StreamController<PushPayload>.broadcast();
  final StreamController<PushPayload> _onOpenedAppController =
      StreamController<PushPayload>.broadcast();

  String? get token => _token;
  Stream<PushPayload> get onForeground => _onForegroundController.stream;
  Stream<PushPayload> get onOpenedApp => _onOpenedAppController.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();

      // ---- v22: initialize now takes `settings:` (named), not positional
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      await _local.initialize(
        settings: const InitializationSettings(
          android: androidInit,
          iOS: iosInit,
        ),
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            try {
              final data = jsonDecode(payload) as Map<String, dynamic>;
              _onOpenedAppController
                  .add(PushPayload.fromData(Map<String, dynamic>.from(data)));
            } catch (_) {}
          }
        },
      );

      // Android 8+ channel
      const channel = AndroidNotificationChannel(
        'mindora_default',
        'MINDORA',
        description: 'Notifications MINDORA',
        importance: Importance.high,
        playSound: true,
      );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // iOS foreground presentation
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Permissions
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // FCM token
      try {
        _token = await FirebaseMessaging.instance.getToken();
        if (kDebugMode) {
          _log.i('FCM token: ${_token != null ? "OK" : "null"}');
        }
      } catch (e) {
        if (kDebugMode) _log.w('FCM getToken failed: $e');
      }

      // Foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) _log.i('FCM foreground: ${message.messageId}');
        final payload = PushPayload.fromData(Map<String, dynamic>.from(message.data));
        _onForegroundController.add(payload);

        final title = message.notification?.title ?? payload.title ?? 'MINDORA';
        final body = message.notification?.body ?? payload.body ?? '';
        if (body.isNotEmpty) {
          showLocal(title: title, body: body, payload: jsonEncode(message.data));
        }
      });

      // Opened from tray
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) _log.i('FCM onMessageOpenedApp: ${message.messageId}');
        final payload = PushPayload.fromData(Map<String, dynamic>.from(message.data));
        _onOpenedAppController.add(payload);
      });

      // Cold-start
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        final payload = PushPayload.fromData(Map<String, dynamic>.from(initial.data));
        Future.delayed(const Duration(milliseconds: 800), () {
          _onOpenedAppController.add(payload);
        });
      }

      // Token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _token = newToken;
        if (kDebugMode) _log.i('FCM token refreshed');
      });

      _initialized = true;
      if (kDebugMode) _log.i('PushService initialized');
    } catch (e) {
      if (kDebugMode) _log.e('PushService init failed: $e');
    }
  }

  Future<void> showLocal({
    required String title,
    required String body,
    int? id,
    String? payload,
  }) async {
    const android = AndroidNotificationDetails(
      'mindora_default',
      'MINDORA',
      channelDescription: 'Notifications MINDORA',
      importance: Importance.high,
      priority: Priority.high,
    );
    // DarwinNotificationDetails in v22 has NO required params — defaults are fine
    const ios = DarwinNotificationDetails();
    const details = NotificationDetails(android: android, iOS: ios);

    try {
      // v22: show uses named params `id:`, `title:`, `body:`, `notificationDetails:`
      await _local.show(
        id: id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) _log.w('showLocal failed: $e');
    }
  }

  Future<void> dispose() async {
    await _onForegroundController.close();
    await _onOpenedAppController.close();
  }
}
