import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/document_models.dart';
import 'documents_repository.dart';
import 'local_downloads_store.dart';

class LibraryFilter extends Equatable {
  const LibraryFilter({
    this.category,
    this.academicLevel,
    this.language,
    this.search = '',
  });

  final String? category;
  final String? academicLevel;
  final String? language;
  final String search;

  LibraryFilter copyWith({
    String? category,
    bool clearCategory = false,
    String? academicLevel,
    bool clearLevel = false,
    String? language,
    bool clearLanguage = false,
    String? search,
  }) =>
      LibraryFilter(
        category: clearCategory ? null : (category ?? this.category),
        academicLevel: clearLevel ? null : (academicLevel ?? this.academicLevel),
        language: clearLanguage ? null : (language ?? this.language),
        search: search ?? this.search,
      );

  bool get hasActiveFilters =>
      category != null ||
      academicLevel != null ||
      language != null ||
      search.trim().isNotEmpty;

  @override
  List<Object?> get props => [category, academicLevel, language, search];
}

final documentsRepositoryProvider = Provider<DocumentsRepository>(
  (ref) => DocumentsRepository(ref.watch(dioProvider)),
);

final localDownloadsStoreProvider = Provider<LocalDownloadsStore>(
  (ref) => PrefsLocalDownloadsStore(),
);

final libraryFilterProvider = StateProvider<LibraryFilter>(
  (ref) => const LibraryFilter(),
);

final libraryDocumentsProvider = FutureProvider<List<Document>>((ref) async {
  final filter = ref.watch(libraryFilterProvider);
  return ref.watch(documentsRepositoryProvider).listLibrary(
        category: filter.category,
        academicLevel: filter.academicLevel,
        language: filter.language,
        search: filter.search,
      );
});

final documentDetailProvider =
    FutureProvider.family<Document, String>((ref, id) async {
  return ref.watch(documentsRepositoryProvider).get(id);
});

final localDownloadsProvider =
    FutureProvider<List<LocalDownloadedDocument>>((ref) async {
  return ref.watch(localDownloadsStoreProvider).list();
});

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
