import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/widgets.dart';
import '../../data/admin_providers.dart';
import '../../domain/admin_models.dart';

enum _Filter { pending, approved, rejected, all }

class AdminModerationScreen extends ConsumerStatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  ConsumerState<AdminModerationScreen> createState() =>
      _AdminModerationScreenState();
}

class _AdminModerationScreenState extends ConsumerState<AdminModerationScreen> {
  _Filter _filter = _Filter.pending;

  String? get _statusParam => switch (_filter) {
        _Filter.pending => 'under_review',
        _Filter.approved => 'approved',
        _Filter.rejected => 'rejected',
        _Filter.all => null,
      };

  Future<void> _reload() async {
    ref.invalidate(pendingDocumentsProvider);
    ref.invalidate(allDocumentsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(
      FutureProvider.autoDispose<List<AdminDocumentRow>>((ref) async {
        return ref.watch(adminRepositoryProvider).listDocuments(status: _statusParam);
      }),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin — Moderation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: AppTabs(
                tabs: const ['Pending', 'Approved', 'Rejected', 'All'],
                index: _filter.index,
                onChanged: (i) => setState(() => _filter = _Filter.values[i]),
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => ListView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  children: const [
                    AppSkeleton(height: 100),
                    SizedBox(height: AppSpacing.md),
                    AppSkeleton(height: 100),
                  ],
                ),
                error: (_, __) => AppEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not load moderation queue',
                  message: 'Please check your connection and try again.',
                  actionLabel: 'Retry',
                  onAction: () => ref.invalidate(pendingDocumentsProvider),
                ),
                data: (docs) {
                  if (docs.isEmpty) {
                    return AppEmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'Nothing to review',
                      message: switch (_filter) {
                        _Filter.pending =>
                          'No documents are waiting for moderation.',
                        _Filter.approved => 'No approved documents yet.',
                        _Filter.rejected => 'No rejected documents yet.',
                        _Filter.all => 'No documents in the system yet.',
                      },
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (_, i) => _ModerationCard(doc: docs[i]),
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

class _ModerationCard extends StatelessWidget {
  const _ModerationCard({required this.doc});
  final AdminDocumentRow doc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (badgeText, badgeTone) = switch (doc.status) {
      'approved' => ('APPROVED', AppBadgeTone.success),
      'under_review' => ('UNDER REVIEW', AppBadgeTone.warning),
      'rejected' => ('REJECTED', AppBadgeTone.danger),
      'uploading' => ('UPLOADING', AppBadgeTone.info),
      _ => (doc.status.toUpperCase(), AppBadgeTone.neutral),
    };

    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: () => context.push('/admin/documents/${doc.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  doc.title,
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppBadge(label: badgeText, tone: badgeTone),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [
              if (doc.category != null) doc.category,
              if (doc.academicLevel != null) doc.academicLevel,
              doc.language.toUpperCase(),
            ].whereType<String>().join(' · '),
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.insert_drive_file_outlined,
                size: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                '${(doc.sizeBytes / 1024).toStringAsFixed(1)} KB',
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(
                Icons.auto_awesome_outlined,
                size: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                '${(doc.qualityScore * 100).toStringAsFixed(0)}% quality',
                style: theme.textTheme.labelSmall,
              ),
              const Spacer(),
              Text(
                DateFormat.MMMd().format(doc.createdAt),
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
