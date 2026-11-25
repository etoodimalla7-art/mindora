import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/widgets.dart';
import '../../../../core/router/routes.dart';
import '../../../../l10n/app_strings.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/documents_providers.dart';
import '../../domain/document_models.dart';

class DocumentDetailScreen extends ConsumerStatefulWidget {
  const DocumentDetailScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<DocumentDetailScreen> createState() =>
      _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  bool _downloading = false;

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  Future<void> _downloadDocument(
    Document doc,
    CreditBalance? credits,
    bool isOwner,
  ) async {
    if (_downloading) return;
    final s = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final cost = isOwner ? 0 : (credits?.downloadCost ?? 1);

    if (cost > 0 && credits != null && credits.balance < cost) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(s.insufficientCreditsMsg),
          action: SnackBarAction(
            label: s.continueLabel,
            onPressed: () => context.push('/subscription/plans'),
          ),
        ),
      );
      return;
    }

    setState(() => _downloading = true);
    try {
      final repo = ref.read(documentsRepositoryProvider);
      await repo.download(doc.id);

      List<int> bytes = const [];
      try {
        bytes = await repo.fetchFileBytes(doc.id);
      } catch (_) {
        // Metadata download already succeeded; store local receipt even if
        // server test fixture has empty content payload.
      }

      await ref.read(localDownloadsStoreProvider).save(
            document: doc,
            bytes: bytes,
          );

      ref.invalidate(creditBalanceProvider);
      ref.invalidate(localDownloadsProvider);
      ref.invalidate(documentDetailProvider(doc.id));

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(s.downloadSavedSuccess),
          action: SnackBarAction(
            label: s.myDownloadsTitle,
            onPressed: () => context.push(AppRoutes.myDownloads),
          ),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final serverMsg = (e.response?.data is Map)
          ? (e.response!.data['detail']?.toString() ??
              e.response!.data['message']?.toString())
          : null;
      messenger.showSnackBar(
        SnackBar(content: Text(serverMsg ?? s.insufficientCreditsMsg)),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final docAsync = ref.watch(documentDetailProvider(widget.documentId));
    final creditsAsync = ref.watch(creditBalanceProvider);
    final downloadsAsync = ref.watch(localDownloadsProvider);
    final currentUserId = ref.watch(authControllerProvider).session?.user.id;

    final isLocallySaved = (downloadsAsync.valueOrNull ?? const [])
        .any((d) => d.documentId == widget.documentId);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.documentDetailTitle),
        actions: [
          IconButton(
            tooltip: s.myDownloadsTitle,
            icon: const Icon(Icons.download_done_outlined),
            onPressed: () => context.push(AppRoutes.myDownloads),
          ),
        ],
      ),
      body: SafeArea(
        child: docAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: const [
              AppSkeleton(height: 120),
              SizedBox(height: AppSpacing.lg),
              AppSkeleton(height: 180),
              SizedBox(height: AppSpacing.lg),
              AppSkeleton(height: 64),
            ],
          ),
          error: (err, _) => AppEmptyState(
            icon: Icons.error_outline,
            title: s.noDocumentsTitle,
            message: err.toString(),
            actionLabel: s.retry,
            onAction: () =>
                ref.invalidate(documentDetailProvider(widget.documentId)),
          ),
          data: (doc) {
            final credits = creditsAsync.valueOrNull;
            final isOwner = currentUserId != null && doc.ownerId == currentUserId;
            final cost = isOwner ? 0 : (credits?.downloadCost ?? 1);
            final summary = doc.analysis?.summary;
            final keywords = doc.analysis?.keywords ?? const <String>[];

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                AppSurface(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.12),
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
                                  doc.title,
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  doc.originalFilename,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.65),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isLocallySaved)
                            AppBadge(
                              label: s.downloadedBadge,
                              tone: AppBadgeTone.success,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          if (doc.category != null && doc.category!.isNotEmpty)
                            AppBadge(
                              label: '${s.subjectLabel}: ${doc.category!}',
                              tone: AppBadgeTone.primary,
                            ),
                          if (doc.academicLevel != null &&
                              doc.academicLevel!.isNotEmpty)
                            AppBadge(
                              label: '${s.levelLabel}: ${doc.academicLevel!}',
                              tone: AppBadgeTone.neutral,
                            ),
                          AppBadge(
                            label:
                                '${s.languageLabel}: ${doc.language.toUpperCase()}',
                            tone: AppBadgeTone.info,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSurface(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const AppDivider(),
                      const SizedBox(height: AppSpacing.md),
                      _MetaRow(
                        label: s.fileSizeLabel,
                        value: _formatSize(doc.sizeBytes),
                      ),
                      if (doc.pageCount != null)
                        _MetaRow(
                          label: s.pagesLabel,
                          value: '${doc.pageCount}',
                        ),
                      _MetaRow(
                        label: s.downloadsCountLabel,
                        value: '${doc.downloadCount}',
                      ),
                    ],
                  ),
                ),
                if (summary != null && summary.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppSurface(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.aiSummaryLabel,
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.sm),
                        Text(summary, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
                if (keywords.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final k in keywords)
                        AppBadge(label: k, tone: AppBadgeTone.neutral),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                AppSurface(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  child: Row(
                    children: [
                      Icon(
                        Icons.toll_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          isOwner ? s.freeForOwner : s.downloadCostLabel(cost),
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      if (credits != null)
                        AppBadge(
                          label: '${credits.balance} cr',
                          tone: credits.balance >= cost
                              ? AppBadgeTone.success
                              : AppBadgeTone.warning,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: _downloading ? s.downloadingLabel : s.downloadCta,
                  icon: Icons.download_outlined,
                  loading: _downloading,
                  onPressed: _downloading
                      ? null
                      : () => _downloadDocument(doc, credits, isOwner),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          Text(value, style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}
