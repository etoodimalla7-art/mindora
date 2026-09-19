import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/past_papers/past_papers_repository.dart';
import '../../domain/past_papers/past_paper_entity.dart';
import 'core_providers.dart';

final pastPapersRepositoryProvider = Provider((ref) {
  return PastPapersRepository(ref.watch(apiClientProvider));
});

final pastPaperFilterSelectionProvider =
    StateProvider.autoDispose<PastPaperFilterSelection>((ref) => const PastPaperFilterSelection());

final pastPaperFiltersProvider = FutureProvider.autoDispose<PastPaperFilters>((ref) {
  return ref.watch(pastPapersRepositoryProvider).getFilters();
});

final pastPaperSearchResultsProvider = FutureProvider.autoDispose<List<PastPaperEntity>>((ref) {
  final selection = ref.watch(pastPaperFilterSelectionProvider);
  return ref.watch(pastPapersRepositoryProvider).search(selection);
});

/// Toggles a bookmark and invalidates the search results so the star
/// icon updates immediately — same invalidate-after-mutation pattern as
/// completeSessionActionProvider in Phase 3.
final toggleBookmarkActionProvider = Provider((ref) {
  return (String pastPaperId, bool currentlyBookmarked) async {
    final repo = ref.read(pastPapersRepositoryProvider);
    if (currentlyBookmarked) {
      await repo.unbookmark(pastPaperId);
    } else {
      await repo.bookmark(pastPaperId);
    }
    ref.invalidate(pastPaperSearchResultsProvider);
  };
});
