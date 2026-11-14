/// Admin Sessions API client (Phase 7.3).
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

// ---------- DTOs ----------

class SessionRow {
  const SessionRow({
    required this.id,
    required this.userId,
    this.userEmail,
    required this.isAdmin,
    required this.isExpired,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String? userEmail;
  final bool isAdmin;
  final bool isExpired;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SessionRow.fromJson(Map<String, dynamic> j) => SessionRow(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        userEmail: j['user_email'] as String?,
        isAdmin: j['is_admin'] as bool? ?? false,
        isExpired: j['is_expired'] as bool? ?? false,
        expiresAt: DateTime.parse(j['expires_at'] as String),
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );
}

class SessionListResponse {
  const SessionListResponse({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<SessionRow> items;
  final int total;
  final int limit;
  final int offset;

  factory SessionListResponse.fromJson(Map<String, dynamic> j) =>
      SessionListResponse(
        items: (j['items'] as List<dynamic>? ?? [])
            .map((e) => SessionRow.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: j['total'] as int? ?? 0,
        limit: j['limit'] as int? ?? 50,
        offset: j['offset'] as int? ?? 0,
      );
}

class RevokeResult {
  const RevokeResult({required this.revokedCount, required this.message});
  final int revokedCount;
  final String message;

  factory RevokeResult.fromJson(Map<String, dynamic> j) => RevokeResult(
        revokedCount: j['revoked_count'] as int? ?? 0,
        message: j['message'] as String? ?? '',
      );
}

class CleanupResult {
  const CleanupResult({required this.deletedCount, required this.message});
  final int deletedCount;
  final String message;

  factory CleanupResult.fromJson(Map<String, dynamic> j) => CleanupResult(
        deletedCount: j['deleted_count'] as int? ?? 0,
        message: j['message'] as String? ?? '',
      );
}

// ---------- Repository ----------

class AdminSessionsRepository {
  AdminSessionsRepository(this._dio);
  final Dio _dio;

  Future<SessionListResponse> listSessions({
    String? email,
    bool adminOnly = false,
    bool includeExpired = false,
    int limit = 50,
    int offset = 0,
  }) async {
    final query = <String, dynamic>{
      'admin_only': adminOnly,
      'include_expired': includeExpired,
      'limit': limit,
      'offset': offset,
    };
    if (email != null && email.isNotEmpty) query['email'] = email;

    final r = await _dio.get<Map<String, dynamic>>(
      '/admin/sessions',
      queryParameters: query,
    );
    return SessionListResponse.fromJson(r.data!);
  }

  Future<RevokeResult> revokeSession(String sessionId) async {
    final r = await _dio.delete<Map<String, dynamic>>(
      '/admin/sessions/$sessionId',
    );
    return RevokeResult.fromJson(r.data!);
  }

  Future<RevokeResult> revokeUserSessions(String userId) async {
    final r = await _dio.delete<Map<String, dynamic>>(
      '/admin/sessions/users/$userId',
    );
    return RevokeResult.fromJson(r.data!);
  }

  Future<CleanupResult> cleanupExpired() async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/admin/sessions/cleanup',
    );
    return CleanupResult.fromJson(r.data!);
  }
}

// ---------- Providers ----------

final adminSessionsRepositoryProvider = Provider<AdminSessionsRepository>(
  (ref) => AdminSessionsRepository(ref.watch(dioProvider)),
);

typedef SessionsFilters = ({String? email, bool adminOnly});

final sessionsListProvider =
    FutureProvider.family<SessionListResponse, SessionsFilters>(
        (ref, filters) async {
  return ref.watch(adminSessionsRepositoryProvider).listSessions(
        email: filters.email,
        adminOnly: filters.adminOnly,
        includeExpired: false,
        limit: 100,
      );
});
