/// Centralized push notification service.
///
/// Responsibilities:
/// - Init Firebase Messaging + local notifications channel (Android).
/// - Request user permission (iOS + Android 13+).
/// - Fetch + expose the FCM token (for backend registration).
/// - Listen for token refresh.
/// - Dispatch incoming messages (foreground / tapped) to callbacks.
///
/// Backend registration is done elsewhere (see ApiClient) via
/// POST /api/v1/notifications/devices.
library;

import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

import 'notification_models.dart';

/// Top-level background handler (must be a top-level function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Required so the app is initialized before handling background messages.
  await Firebase.initializeApp();
  Logger().i('[FCM/bg] ${message.messageId} data=${message.data}');
}

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final Logger _log = Logger();
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _token;
  String? _lastHandledMessageId;

  final StreamController<PushPayload> _foreground =
      StreamController<PushPayload>.broadcast();
  final StreamController<PushPayload> _openedApp =
      StreamController<PushPayload>.broadcast();

  /// Incoming messages while the app is in foreground.
  Stream<PushPayload> get onForeground => _foreground.stream;

  /// Messages that opened the app (tapped from tray, terminated state).
  Stream<PushPayload> get onOpenedApp => _openedApp.stream;

  String? get token => _token;

  /// Call once, early in main().
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Local notifications (Android channel required for FCM display).
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _local.initialize(initSettings);

    // Android 8+ notification channel
    const channel = AndroidNotificationChannel(
      'mindora_default',
      'MINDORA',
      description: 'Notifications MINDORA',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission (Android 13+ / iOS)
    await _requestPermission();

    // Fetch token
    try {
      _token = await FirebaseMessaging.instance.getToken();
      _log.i('FCM token: ${_token?.substring(0, 12)}…');
    } catch (e) {
      _log.w('getToken failed: $e');
    }

    // Token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _log.i('FCM token refreshed');
      _token = newToken;
    });

    // Foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // Opened app handler (background → foreground via tap)
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      _log.i('App opened from notification: ${msg.messageId}');
      _emit(_openedApp, msg);
    });

    // Cold start: app was terminated and launched by a notification
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _log.i('Cold start from notification: ${initial.messageId}');
      // Slight delay so the router is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        _emit(_openedApp, initial);
      });
    }

    _log.i('PushService initialized (platform=${Platform.operatingSystem})');
  }

  Future<void> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    _log.i('Permission: ${settings.authorizationStatus}');
  }

  void _handleForeground(RemoteMessage msg) {
    _log.i('[FCM/fg] ${msg.messageId}');
    if (msg.messageId != null && msg.messageId == _lastHandledMessageId) {
      return; // dedupe
    }
    _lastHandledMessageId = msg.messageId;
    _emit(_foreground, msg);

    // Also show a local notification (so the user sees it)
    final notification = msg.notification;
    if (notification != null) {
      _showLocal(notification.title ?? 'MINDORA', notification.body ?? '');
    }
  }

  void _emit(StreamController<PushPayload> ctrl, RemoteMessage msg) {
    try {
      ctrl.add(PushPayload.fromData(msg.data));
    } catch (e) {
      _log.w('emit failed: $e');
    }
  }

  Future<void> _showLocal(String title, String body) async {
    if (!Platform.isAndroid) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'mindora_default',
        'MINDORA',
        channelDescription: 'Notifications MINDORA',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    try {
      await _local.show(0, title, body, details);
    } catch (e) {
      if (kDebugMode) _log.w('showLocal failed: $e');
    }
  }
}
