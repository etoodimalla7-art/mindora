import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/admin_models.dart';
import 'admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.watch(dioProvider)),
);

/// Pending moderation queue — all documents with status `under_review`.
final pendingDocumentsProvider =
    FutureProvider<List<AdminDocumentRow>>((ref) async {
  return ref.watch(adminRepositoryProvider).listDocuments(status: 'under_review');
});

/// All documents regardless of status (for history browsing).
final allDocumentsProvider = FutureProvider<List<AdminDocumentRow>>((ref) async {
  return ref.watch(adminRepositoryProvider).listDocuments();
});
