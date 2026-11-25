/// Admin Security & Monitoring API client (Phase 7.1).
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

// ---------- DTOs ----------

class ServiceStatus {
  const ServiceStatus({
    required this.name,
    required this.status,
    this.latencyMs,
    this.detail,
  });

  final String name;
  final String status; // ok | degraded | down
  final double? latencyMs;
  final String? detail;

  factory ServiceStatus.fromJson(Map<String, dynamic> j) => ServiceStatus(
        name: j['name'] as String,
        status: j['status'] as String,
        latencyMs: (j['latency_ms'] as num?)?.toDouble(),
        detail: j['detail'] as String?,
      );
}

class SystemHealth {
  const SystemHealth({
    required this.overall,
    required this.timestamp,
    required this.services,
    this.uptimeSeconds,
    this.version,
    this.env,
  });

  final String overall;
  final DateTime timestamp;
  final List<ServiceStatus> services;
  final double? uptimeSeconds;
  final String? version;
  final String? env;

  factory SystemHealth.fromJson(Map<String, dynamic> j) => SystemHealth(
        overall: j['overall'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
        services: (j['services'] as List<dynamic>? ?? [])
            .map((e) => ServiceStatus.fromJson(e as Map<String, dynamic>))
            .toList(),
        uptimeSeconds: (j['uptime_seconds'] as num?)?.toDouble(),
        version: j['version'] as String?,
        env: j['env'] as String?,
      );
}

class SystemMetrics {
  const SystemMetrics({
    required this.totalUsers,
    required this.activeSessions24h,
    required this.requestsPerMinute,
    required this.failedLogins24h,
    required this.unacknowledgedAlerts,
    this.databaseSizeMb,
    required this.updatedAt,
  });

  final int totalUsers;
  final int activeSessions24h;
  final int requestsPerMinute;
  final int failedLogins24h;
  final int unacknowledgedAlerts;
  final double? databaseSizeMb;
  final DateTime updatedAt;

  factory SystemMetrics.fromJson(Map<String, dynamic> j) => SystemMetrics(
        totalUsers: j['total_users'] as int? ?? 0,
        activeSessions24h: j['active_sessions_24h'] as int? ?? 0,
        requestsPerMinute: j['requests_per_minute'] as int? ?? 0,
        failedLogins24h: j['failed_logins_24h'] as int? ?? 0,
        unacknowledgedAlerts: j['unacknowledged_alerts'] as int? ?? 0,
        databaseSizeMb: (j['database_size_mb'] as num?)?.toDouble(),
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );
}

class LoginHistoryRow {
  const LoginHistoryRow({
    required this.id,
    this.userId,
    required this.email,
    this.ip,
    this.userAgent,
    required this.success,
    this.failureReason,
    required this.createdAt,
  });

  final String id;
  final String? userId;
  final String email;
  final String? ip;
  final String? userAgent;
  final bool success;
  final String? failureReason;
  final DateTime createdAt;

  factory LoginHistoryRow.fromJson(Map<String, dynamic> j) => LoginHistoryRow(
        id: j['id'] as String,
        userId: j['user_id'] as String?,
        email: j['email'] as String? ?? '',
        ip: j['ip'] as String?,
        userAgent: j['user_agent'] as String?,
        success: j['success'] as bool? ?? false,
        failureReason: j['failure_reason'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class LoginHistoryListResponse {
  const LoginHistoryListResponse({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<LoginHistoryRow> items;
  final int total;
  final int limit;
  final int offset;

  factory LoginHistoryListResponse.fromJson(Map<String, dynamic> j) =>
      LoginHistoryListResponse(
        items: (j['items'] as List<dynamic>? ?? [])
            .map((e) => LoginHistoryRow.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: j['total'] as int? ?? 0,
        limit: j['limit'] as int? ?? 50,
        offset: j['offset'] as int? ?? 0,
      );
}

class SecurityAlert {
  const SecurityAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    required this.metadata,
    required this.acknowledged,
    this.acknowledgedBy,
    this.acknowledgedAt,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String severity;
  final String message;
  final Map<String, dynamic> metadata;
  final bool acknowledged;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;
  final DateTime createdAt;

  factory SecurityAlert.fromJson(Map<String, dynamic> j) => SecurityAlert(
        id: j['id'] as String,
        type: j['type'] as String? ?? 'manual',
        severity: j['severity'] as String? ?? 'medium',
        message: j['message'] as String? ?? '',
        metadata: (j['metadata'] as Map<String, dynamic>?) ?? {},
        acknowledged: j['acknowledged'] as bool? ?? false,
        acknowledgedBy: j['acknowledged_by'] as String?,
        acknowledgedAt: j['acknowledged_at'] != null
            ? DateTime.parse(j['acknowledged_at'] as String)
            : null,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class AlertListResponse {
  const AlertListResponse({
    required this.items,
    required this.total,
    required this.unacknowledged,
  });

  final List<SecurityAlert> items;
  final int total;
  final int unacknowledged;

  factory AlertListResponse.fromJson(Map<String, dynamic> j) =>
      AlertListResponse(
        items: (j['items'] as List<dynamic>? ?? [])
            .map((e) => SecurityAlert.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: j['total'] as int? ?? 0,
        unacknowledged: j['unacknowledged'] as int? ?? 0,
      );
}

// ---------- Repository ----------

class AdminSecurityRepository {
  AdminSecurityRepository(this._dio);
  final Dio _dio;

  Future<SystemHealth> getHealth() async {
    final r = await _dio.get<Map<String, dynamic>>('/admin/system/health');
    return SystemHealth.fromJson(r.data!);
  }

  Future<SystemMetrics> getMetrics() async {
    final r = await _dio.get<Map<String, dynamic>>('/admin/system/metrics');
    return SystemMetrics.fromJson(r.data!);
  }

  Future<LoginHistoryListResponse> getLoginHistory({
    bool? success,
    String? email,
    int limit = 50,
    int offset = 0,
  }) async {
    final query = <String, dynamic>{'limit': limit, 'offset': offset};
    if (success != null) query['success'] = success;
    if (email != null && email.isNotEmpty) query['email'] = email;

    final r = await _dio.get<Map<String, dynamic>>(
      '/admin/security/login-history',
      queryParameters: query,
    );
    return LoginHistoryListResponse.fromJson(r.data!);
  }

  Future<AlertListResponse> listAlerts({
    bool? acknowledged,
    String? severity,
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    final query = <String, dynamic>{'limit': limit, 'offset': offset};
    if (acknowledged != null) query['acknowledged'] = acknowledged;
    if (severity != null && severity.isNotEmpty) query['severity'] = severity;
    if (type != null && type.isNotEmpty) query['type'] = type;

    final r = await _dio.get<Map<String, dynamic>>(
      '/admin/security/alerts',
      queryParameters: query,
    );
    return AlertListResponse.fromJson(r.data!);
  }

  Future<void> acknowledgeAlert(String alertId) async {
    await _dio.patch<void>(
      '/admin/security/alerts/$alertId/acknowledge',
    );
  }
}

// ---------- Providers ----------

final adminSecurityRepositoryProvider = Provider<AdminSecurityRepository>(
  (ref) => AdminSecurityRepository(ref.watch(dioProvider)),
);

final systemHealthProvider = FutureProvider<SystemHealth>((ref) async {
  return ref.watch(adminSecurityRepositoryProvider).getHealth();
});

final systemMetricsProvider = FutureProvider<SystemMetrics>((ref) async {
  return ref.watch(adminSecurityRepositoryProvider).getMetrics();
});

typedef LoginHistoryFilters = ({bool? success, String? email});

final loginHistoryProvider =
    FutureProvider.family<LoginHistoryListResponse, LoginHistoryFilters>(
        (ref, filters) async {
  return ref.watch(adminSecurityRepositoryProvider).getLoginHistory(
        success: filters.success,
        email: filters.email,
      );
});

typedef AlertFilters = ({bool? acknowledged, String? severity});

final securityAlertsProvider =
    FutureProvider.family<AlertListResponse, AlertFilters>((ref, filters) async {
  return ref.watch(adminSecurityRepositoryProvider).listAlerts(
        acknowledged: filters.acknowledged,
        severity: filters.severity,
      );
});
