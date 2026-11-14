/// Admin Users API client + Riverpod providers (Phase 2).
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

// ---------- DTOs ----------

class AdminUserDetail {
  const AdminUserDetail({
    required this.id,
    required this.email,
    this.fullName,
    required this.preferredLanguage,
    required this.countryCode,
    required this.isActive,
    required this.isVerified,
    required this.isAdmin,
    this.suspendedAt,
    this.suspendedBy,
    this.suspensionReason,
    required this.createdAt,
    this.lastLoginAt,
    required this.documentsCount,
    required this.papersCount,
    required this.sessionsCount,
    required this.roles,
    this.educationSystem,
    this.educationLevel,
    this.educationProgram,
    required this.subjects,
  });

  final String id;
  final String email;
  final String? fullName;
  final String preferredLanguage;
  final String countryCode;
  final bool isActive;
  final bool isVerified;
  final bool isAdmin;
  final DateTime? suspendedAt;
  final String? suspendedBy;
  final String? suspensionReason;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final int documentsCount;
  final int papersCount;
  final int sessionsCount;
  final List<String> roles;
  final String? educationSystem;
  final String? educationLevel;
  final String? educationProgram;
  final List<String> subjects;

  bool get isSuspended => suspendedAt != null;

  String get statusLabel {
    if (isSuspended) return 'Suspendu';
    if (!isActive) return 'Inactif';
    return 'Actif';
  }

  factory AdminUserDetail.fromJson(Map<String, dynamic> j) => AdminUserDetail(
        id: j['id'] as String,
        email: j['email'] as String,
        fullName: j['full_name'] as String?,
        preferredLanguage: j['preferred_language'] as String? ?? 'en',
        countryCode: j['country_code'] as String? ?? 'CM',
        isActive: j['is_active'] as bool? ?? true,
        isVerified: j['is_verified'] as bool? ?? false,
        isAdmin: j['is_admin'] as bool? ?? false,
        suspendedAt: j['suspended_at'] != null
            ? DateTime.tryParse(j['suspended_at'] as String)
            : null,
        suspendedBy: j['suspended_by'] as String?,
        suspensionReason: j['suspension_reason'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
        lastLoginAt: j['last_login_at'] != null
            ? DateTime.tryParse(j['last_login_at'] as String)
            : null,
        documentsCount: (j['documents_count'] as int?) ?? 0,
        papersCount: (j['papers_count'] as int?) ?? 0,
        sessionsCount: (j['sessions_count'] as int?) ?? 0,
        roles: List<String>.from(j['roles'] as List? ?? []),
        educationSystem: j['education_system'] as String?,
        educationLevel: j['education_level'] as String?,
        educationProgram: j['education_program'] as String?,
        subjects: List<String>.from(j['subjects'] as List? ?? []),
      );
}

// ---------- Repository ----------

class AdminUsersRepository {
  AdminUsersRepository(this._dio);
  final Dio _dio;

  Future<AdminUserDetail> getDetail(String userId) async {
    final r = await _dio.get('/admin/users/$userId');
    return AdminUserDetail.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> suspend(String userId, String reason) async {
    final r = await _dio.post(
      '/admin/users/$userId/suspend',
      data: {'reason': reason},
    );
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> revokeSessions(String userId) async {
    final r = await _dio.post('/admin/users/$userId/revoke-sessions');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> toggleActive(String userId) async {
    final r = await _dio.post('/admin/users/$userId/toggle-active');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> promote(String userId) async {
    final r = await _dio.post('/admin/users/$userId/promote');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> bulkSuspend(
      List<String> userIds, String reason) async {
    final r = await _dio.post(
      '/admin/users/bulk-suspend',
      data: {'user_ids': userIds, 'reason': reason},
    );
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> bulkPromote(List<String> userIds) async {
    final r = await _dio.post(
      '/admin/users/bulk-promote',
      data: {'user_ids': userIds},
    );
    return r.data as Map<String, dynamic>;
  }
}

// ---------- Riverpod ----------

final adminUsersRepositoryProvider = Provider<AdminUsersRepository>(
  (ref) => AdminUsersRepository(ref.watch(dioProvider)),
);

final adminUserDetailProvider =
    FutureProvider.family<AdminUserDetail, String>((ref, id) async {
  return ref.watch(adminUsersRepositoryProvider).getDetail(id);
});
