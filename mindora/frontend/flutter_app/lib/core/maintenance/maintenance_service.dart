/// Maintenance service — checks if the backend is in maintenance mode.
///
/// Called at boot (main.dart) to decide whether to block the app.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';

class MaintenanceStatus {
  const MaintenanceStatus({
    required this.enabled,
    this.message = '',
    this.eta,
  });

  final bool enabled;
  final String message;
  final DateTime? eta;

  factory MaintenanceStatus.fromJson(Map<String, dynamic> j) => MaintenanceStatus(
        enabled: j['enabled'] as bool? ?? false,
        message: j['message'] as String? ?? '',
        eta: j['eta'] != null ? DateTime.parse(j['eta'] as String) : null,
      );

  static const MaintenanceStatus off = MaintenanceStatus(enabled: false);
}

class MaintenanceService {
  MaintenanceService(this._dio);
  final Dio _dio;

  Future<MaintenanceStatus> check() async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
        '/settings/maintenance',
        options: Options(
          // Ne bloque pas si erreur réseau → fail-open (app continue)
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      if (r.statusCode == 200 && r.data != null) {
        return MaintenanceStatus.fromJson(r.data!);
      }
      return MaintenanceStatus.off;
    } catch (_) {
      // Fail-open : si le check échoue, on laisse passer
      return MaintenanceStatus.off;
    }
  }
}

final maintenanceServiceProvider = Provider<MaintenanceService>(
  (ref) => MaintenanceService(ref.watch(dioProvider)),
);

final maintenanceCheckProvider = FutureProvider<MaintenanceStatus>((ref) async {
  return ref.watch(maintenanceServiceProvider).check();
});
