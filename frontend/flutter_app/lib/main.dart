import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/notifications/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase: mobile only (Web needs firebase_options.dart from flutterfire)
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      await PushService.instance.initialize();
    } catch (e) {
      debugPrint('[MINDORA] Firebase init failed: $e');
      // Do not crash the app on push failure
    }
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const ProviderScope(child: MindoraApp()));
}
