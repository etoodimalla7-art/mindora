import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/network/token_store.dart';
import '../../../core/notifications/push_service.dart';
import '../../../features/notifications/data/device_repository.dart';
import '../../../features/notifications/data/notification_api.dart';
import '../../../core/network/api_client.dart';

class PushDebugScreen extends ConsumerStatefulWidget {
  const PushDebugScreen({super.key});

  @override
  ConsumerState<PushDebugScreen> createState() => _PushDebugScreenState();
}

class _PushDebugScreenState extends ConsumerState<PushDebugScreen> {
  final List<String> _logs = [];
  bool _testing = false;

  void _log(String msg) {
    final ts = DateTime.now().toIso8601String().substring(11, 19);
    setState(() => _logs.insert(0, '[$ts] $msg'));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runDiagnostics());
  }

  Future<void> _runDiagnostics() async {
    _log('═══════ DIAGNOSTIC START ═══════');

    // 1. API base URL
    _log('API_BASE_URL = ${Env.apiBaseUrl}');

    // 2. Firebase
    try {
      final apps = Firebase.apps;
      _log('Firebase.apps = ${apps.length} app(s)');
      if (apps.isNotEmpty) {
        _log('  projectId = ${apps.first.options.projectId}');
        _log('  appId = ${apps.first.options.appId}');
      } else {
        _log('❌ FIREBASE NOT INITIALIZED');
      }
    } catch (e) {
      _log('❌ Firebase.apps error: $e');
    }

    // 3. FCM permission
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      _log('FCM permission = ${settings.authorizationStatus}');
    } catch (e) {
      _log('❌ Permission error: $e');
    }

    // 4. FCM token
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        _log('❌ FCM token = NULL');
      } else {
        _log('✅ FCM token = ${token.substring(0, 30)}...');
        _log('   (full length = ${token.length})');
      }
    } catch (e) {
      _log('❌ getToken error: $e');
    }

    // 5. PushService singleton
    _log('PushService.token = ${PushService.instance.token ?? "NULL"}');

    // 6. Auth token
    try {
      final authToken = await TokenStore().access;
      if (authToken == null) {
        _log('❌ No JWT (not logged in?)');
      } else {
        _log('✅ JWT present (${authToken.substring(0, 20)}...)');
      }
    } catch (e) {
      _log('❌ TokenStore error: $e');
    }

    _log('═══════ MANUAL TEST AVAILABLE ═══════');
  }

  Future<void> _testRegisterDevice() async {
    setState(() => _testing = true);
    _log('--- Attempting device registration ---');

    try {
      final api = NotificationApi(ref.read(dioProvider));
      final repo = DeviceRepository(api);
      await repo.registerCurrentDevice();
      _log('✅ registerCurrentDevice() called (check backend)');
    } catch (e) {
      _log('❌ register error: $e');
    } finally {
      setState(() => _testing = false);
    }
  }

  Future<void> _testDirectPost() async {
    setState(() => _testing = true);
    _log('--- Direct POST /notifications/devices ---');

    try {
      final token = PushService.instance.token ??
          await FirebaseMessaging.instance.getToken();
      if (token == null) {
        _log('❌ No token to send');
        return;
      }
      final api = NotificationApi(ref.read(dioProvider));
      final id = await api.registerDevice(
        fcmToken: token,
        platform: 'android',
        deviceModel: 'debug-screen',
      );
      if (id == null) {
        _log('❌ registerDevice returned null (see logs)');
      } else {
        _log('✅ Device registered with id = $id');
      }
    } catch (e) {
      _log('❌ Direct POST error: $e');
    } finally {
      setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Push Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _logs.clear());
              _runDiagnostics();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testing ? null : _testRegisterDevice,
                    child: const Text('Register Device'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testing ? null : _testDirectPost,
                    child: const Text('Direct POST'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.black87,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _logs.length,
                itemBuilder: (context, i) {
                  final line = _logs[i];
                  final isError = line.contains('❌');
                  final isSuccess = line.contains('✅');
                  return Text(
                    line,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: isError
                          ? Colors.redAccent
                          : isSuccess
                              ? Colors.greenAccent
                              : Colors.white70,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
