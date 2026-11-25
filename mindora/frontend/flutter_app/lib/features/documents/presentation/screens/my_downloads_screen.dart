import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/widgets.dart';
import '../../../../core/router/routes.dart';
import '../../../../l10n/app_strings.dart';
import '../../data/documents_providers.dart';
import '../../domain/document_models.dart';

class MyDownloadsScreen extends ConsumerWidget {
  const MyDownloadsScreen({super.key});

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d/$m/${local.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final downloadsAsync = ref.watch(localDownloadsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.myDownloadsTitle)),
      body: SafeArea(
        child: downloadsAsync.when(
          loading: () => ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, __) => const AppSkeleton(height: 88),
          ),
          error: (err, _) => AppEmptyState(
            icon: Icons.error_outline,
            title: s.noDownloadsTitle,
            message: err.toString(),
            actionLabel: s.retry,
            onAction: () => ref.invalidate(localDownloadsProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return AppEmptyState(
                icon: Icons.download_for_offline_outlined,
                title: s.noDownloadsTitle,
                message: s.noDownloadsBody,
                actionLabel: s.libraryTitle,
                onAction: () => context.push(AppRoutes.documentsLibrary),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) {
                final item = items[i];
                return _LocalDownloadTile(
                  item: item,
                  subtitle:
                      '${_formatSize(item.sizeBytes)} • ${_formatDate(item.downloadedAt)}',
                  theme: theme,
                  removeLabel: s.removeLocalDownload,
                  onOpen: () => context.push('/documents/${item.documentId}'),
                  onRemove: () async {
                    await ref
                        .read(localDownloadsStoreProvider)
                        .remove(item.documentId);
                    ref.invalidate(localDownloadsProvider);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _LocalDownloadTile extends StatelessWidget {
  const _LocalDownloadTile({
    required this.item,
    required this.subtitle,
    required this.theme,
    required this.removeLabel,
    required this.onOpen,
    required this.onRemove,
  });

  final LocalDownloadedDocument item;
  final String subtitle;
  final ThemeData theme;
  final String removeLabel;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: onOpen,
      child: Row(
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
              Icons.offline_pin_outlined,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.originalFilename,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: removeLabel,
            icon: Icon(
              Icons.delete_outline,
              color: theme.colorScheme.error,
            ),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
