import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/documents/documents_repository.dart';
import '../../domain/documents/document_entity.dart';
import 'core_providers.dart';

final documentsRepositoryProvider = Provider((ref) {
  return DocumentsRepository(ref.watch(apiClientProvider));
});

final myDocumentsProvider = FutureProvider.autoDispose<List<DocumentEntity>>((ref) {
  return ref.watch(documentsRepositoryProvider).listMine();
});

/// Holds the in-progress upload's document id across the 3-screen flow
/// (pick file -> metadata -> exam metadata/submit) so each screen doesn't
/// have to pass it through constructor args and route params.
final activeUploadDocumentIdProvider = StateProvider.autoDispose<String?>((ref) => null);
