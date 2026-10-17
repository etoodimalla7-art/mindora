import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/admin_models.dart';
import 'admin_api.dart';
import 'admin_repository.dart';

// ============================================================
// Legacy — Documents moderation
// ============================================================

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(dioProvider));
});

final pendingDocumentsProvider = FutureProvider<List<AdminDocumentRow>>((ref) async {
  return ref.watch(adminRepositoryProvider).listDocuments(status: 'under_review');
});

final allDocumentsProvider = FutureProvider<List<AdminDocumentRow>>((ref) async {
  return ref.watch(adminRepositoryProvider).listDocuments();
});

// ============================================================
// New — Stats, Users, Papers
// ============================================================

final adminApiProvider = Provider<AdminApi>((ref) {
  return AdminApi(ref.watch(dioProvider));
});

final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  return ref.watch(adminApiProvider).getStats();
});

final adminUsersProvider = FutureProvider.family<List<AdminUser>, String>((ref, search) async {
  return ref.watch(adminApiProvider).listUsers(search: search);
});

final adminPapersProvider = FutureProvider<List<AdminPaper>>((ref) async {
  return ref.watch(adminApiProvider).listPapers();
});
