import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/widgets.dart';
import '../../../../core/router/routes.dart';
import '../../../../l10n/app_strings.dart';
import '../../data/documents_providers.dart';
import '../../domain/document_models.dart';

class DocumentsLibraryScreen extends ConsumerStatefulWidget {
  const DocumentsLibraryScreen({super.key});

  @override
  ConsumerState<DocumentsLibraryScreen> createState() =>
      _DocumentsLibraryScreenState();
}

class _DocumentsLibraryScreenState
    extends ConsumerState<DocumentsLibraryScreen> {
  late final TextEditingController _searchCtrl;

  static const _subjects = <String>[
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'Computer Science',
    'Literature',
    'History',
  ];

  static const _levels = <String>[
    'High School',
    'Terminale',
    'Premiere',
    'Undergraduate',
    'Baccalaureat',
  ];

  static const _languages = <String>['fr', 'en'];

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(
      text: ref.read(libraryFilterProvider).search,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _updateFilter(LibraryFilter next) {
    ref.read(libraryFilterProvider.notifier).state = next;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final filter = ref.watch(libraryFilterProvider);
    final docsAsync = ref.watch(libraryDocumentsProvider);
    final creditsAsync = ref.watch(creditBalanceProvider);
    final localDownloadsAsync = ref.watch(localDownloadsProvider);
    final downloadedIds = (localDownloadsAsync.valueOrNull ?? const [])
        .map((d) => d.documentId)
        .toSet();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.libraryTitle),
        actions: [
          creditsAsync.maybeWhen(
            data: (c) => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: Center(
                child: Semantics(
                  label: '${c.balance} credits',
                  child: AppBadge(
                    label: '${c.balance} cr',
                    tone: AppBadgeTone.primary,
                  ),
                ),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            tooltip: s.myDownloadsTitle,
            icon: const Icon(Icons.download_done_outlined),
            onPressed: () => context.push(AppRoutes.myDownloads),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                onSubmitted: (val) => _updateFilter(
                  filter.copyWith(search: val),
                ),
                onChanged: (val) => _updateFilter(
                  filter.copyWith(search: val),
                ),
                decoration: InputDecoration(
                  hintText: s.searchDocumentsHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          tooltip: s.resetFilters,
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            _updateFilter(filter.copyWith(search: ''));
                          },
                        )
                      : null,
                ),
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                children: [
                  _FilterDropdownChip(
                    label: filter.category ?? s.allSubjects,
                    selected: filter.category != null,
                    options: _subjects,
                    allLabel: s.allSubjects,
                    onSelected: (val) => _updateFilter(
                      val == null
                          ? filter.copyWith(clearCategory: true)
                          : filter.copyWith(category: val),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterDropdownChip(
                    label: filter.academicLevel ?? s.allLevels,
                    selected: filter.academicLevel != null,
                    options: _levels,
                    allLabel: s.allLevels,
                    onSelected: (val) => _updateFilter(
                      val == null
                          ? filter.copyWith(clearLevel: true)
                          : filter.copyWith(academicLevel: val),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterDropdownChip(
                    label: filter.language?.toUpperCase() ?? s.allLanguages,
                    selected: filter.language != null,
                    options: _languages,
                    allLabel: s.allLanguages,
                    displayTransform: (v) => v.toUpperCase(),
                    onSelected: (val) => _updateFilter(
                      val == null
                          ? filter.copyWith(clearLanguage: true)
                          : filter.copyWith(language: val),
                    ),
                  ),
                  if (filter.hasActiveFilters) ...[
                    const SizedBox(width: AppSpacing.sm),
                    ActionChip(
                      label: Text(s.resetFilters),
                      onPressed: () {
                        _searchCtrl.clear();
                        _updateFilter(const LibraryFilter());
                      },
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: docsAsync.when(
                loading: () => ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: 5,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (_, __) => const AppSkeleton(height: 112),
                ),
                error: (err, _) => AppEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: s.noDocumentsTitle,
                  message: err.toString(),
                  actionLabel: s.retry,
                  onAction: () => ref.invalidate(libraryDocumentsProvider),
                ),
                data: (docs) {
                  if (docs.isEmpty) {
                    return AppEmptyState(
                      icon: Icons.menu_book_outlined,
                      title: s.noDocumentsTitle,
                      message: s.noDocumentsBody,
                      actionLabel: filter.hasActiveFilters
                          ? s.resetFilters
                          : null,
                      onAction: filter.hasActiveFilters
                          ? () {
                              _searchCtrl.clear();
                              _updateFilter(const LibraryFilter());
                            }
                          : null,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(libraryDocumentsProvider);
                      await ref.read(libraryDocumentsProvider.future);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (_, i) {
                        final doc = docs[i];
                        final isDownloaded = downloadedIds.contains(doc.id);
                        return _LibraryDocumentCard(
                          document: doc,
                          formattedSize: _formatSize(doc.sizeBytes),
                          isDownloaded: isDownloaded,
                          downloadedLabel: s.downloadedBadge,
                          theme: theme,
                          onTap: () => context.push('/documents/${doc.id}'),
                        );
                      },
                    ),
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

class _FilterDropdownChip extends StatelessWidget {
  const _FilterDropdownChip({
    required this.label,
    required this.selected,
    required this.options,
    required this.allLabel,
    required this.onSelected,
    this.displayTransform,
  });

  final String label;
  final bool selected;
  final List<String> options;
  final String allLabel;
  final ValueChanged<String?> onSelected;
  final String Function(String)? displayTransform;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      tooltip: label,
      onSelected: (value) => onSelected(value == '__ALL__' ? null : value),
      itemBuilder: (_) => [
        PopupMenuItem<String>(value: '__ALL__', child: Text(allLabel)),
        for (final opt in options)
          PopupMenuItem<String>(
            value: opt,
            child: Text(displayTransform?.call(opt) ?? opt),
          ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.14)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 18,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryDocumentCard extends StatelessWidget {
  const _LibraryDocumentCard({
    required this.document,
    required this.formattedSize,
    required this.isDownloaded,
    required this.downloadedLabel,
    required this.theme,
    required this.onTap,
  });

  final Document document;
  final String formattedSize;
  final bool isDownloaded;
  final String downloadedLabel;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: document.title,
      child: AppSurface(
        padding: const EdgeInsets.all(AppSpacing.lg),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.description_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.title,
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        document.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isDownloaded) ...[
                  const SizedBox(width: AppSpacing.sm),
                  AppBadge(
                    label: downloadedLabel,
                    tone: AppBadgeTone.success,
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                if (document.category != null && document.category!.isNotEmpty)
                  AppBadge(
                    label: document.category!,
                    tone: AppBadgeTone.primary,
                  ),
                if (document.academicLevel != null &&
                    document.academicLevel!.isNotEmpty)
                  AppBadge(
                    label: document.academicLevel!,
                    tone: AppBadgeTone.neutral,
                  ),
                AppBadge(
                  label: document.language.toUpperCase(),
                  tone: AppBadgeTone.info,
                ),
                AppBadge(
                  label: formattedSize,
                  tone: AppBadgeTone.neutral,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
