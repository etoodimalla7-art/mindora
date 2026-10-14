import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/document_models.dart';
import 'documents_repository.dart';

final documentsRepositoryProvider = Provider<DocumentsRepository>(
  (ref) => DocumentsRepository(ref.watch(dioProvider)),
);

final myDocumentsProvider = FutureProvider<List<Document>>((ref) async {
  return ref.watch(documentsRepositoryProvider).listMine();
});

final creditBalanceProvider = FutureProvider<CreditBalance>((ref) async {
  return ref.watch(documentsRepositoryProvider).credits();
});

final documentStatusProvider =
    FutureProvider.family<DocumentStatus, String>((ref, id) async {
  return ref.watch(documentsRepositoryProvider).getStatus(id);
});
