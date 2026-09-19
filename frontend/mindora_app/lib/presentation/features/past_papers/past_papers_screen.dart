import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../providers/past_papers_providers.dart';
import '../../shared_widgets/empty_state.dart';
import 'widgets/filter_dropdown_row.dart';
import 'widgets/past_paper_card.dart';

/// Section 30: browse by country -> system -> level -> subject -> year,
/// with search, filtering, and bookmarking. Reached from Learn (section
/// 71: contextual navigation, not a 6th bottom-nav tab).
class PastPapersScreen extends ConsumerStatefulWidget {
  const PastPapersScreen({super.key});

  @override
  ConsumerState<PastPapersScreen> createState() => _PastPapersScreenState();
}

class _PastPapersScreenState extends ConsumerState<PastPapersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtersAsync = ref.watch(pastPaperFiltersProvider);
    final selection = ref.watch(pastPaperFilterSelectionProvider);
    final resultsAsync = ref.watch(pastPaperSearchResultsProvider);
    final toggleBookmark = ref.watch(toggleBookmarkActionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Past Papers')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search past papers...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                ),
                onSubmitted: (value) {
                  ref.read(pastPaperFilterSelectionProvider.notifier).state =
                      selection.copyWith(query: value);
                },
              ),
            ),
            filtersAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: LinearProgressIndicator(),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (filters) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterDropdownRow(
                        label: 'Country', value: selection.country, options: filters.countries,
                        onChanged: (v) => ref.read(pastPaperFilterSelectionProvider.notifier).state =
                            v == null ? selection.copyWith(clearCountry: true) : selection.copyWith(country: v),
                      ),
                      FilterDropdownRow(
                        label: 'System', value: selection.system, options: filters.systems,
                        onChanged: (v) => ref.read(pastPaperFilterSelectionProvider.notifier).state =
                            v == null ? selection.copyWith(clearSystem: true) : selection.copyWith(system: v),
                      ),
                      FilterDropdownRow(
                        label: 'Level', value: selection.level, options: filters.levels,
                        onChanged: (v) => ref.read(pastPaperFilterSelectionProvider.notifier).state =
                            v == null ? selection.copyWith(clearLevel: true) : selection.copyWith(level: v),
                      ),
                      FilterDropdownRow(
                        label: 'Subject', value: selection.subject, options: filters.subjects,
                        onChanged: (v) => ref.read(pastPaperFilterSelectionProvider.notifier).state =
                            v == null ? selection.copyWith(clearSubject: true) : selection.copyWith(subject: v),
                      ),
                      FilterDropdownRow(
                        label: 'Year', value: selection.year?.toString(),
                        options: filters.years.map((y) => y.toString()).toList(),
                        onChanged: (v) => ref.read(pastPaperFilterSelectionProvider.notifier).state =
                            v == null ? selection.copyWith(clearYear: true) : selection.copyWith(year: int.parse(v)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: resultsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => EmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: "Couldn't load past papers",
                  message: 'Check your connection and try again.',
                ),
                data: (papers) {
                  if (papers.isEmpty) {
                    return EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No past papers found',
                      message: 'Try adjusting your filters or search terms.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: papers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final paper = papers[index];
                      return PastPaperCard(
                        paper: paper,
                        onToggleBookmark: () => toggleBookmark(paper.id, paper.isBookmarked),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
