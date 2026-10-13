import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/widgets.dart';
import '../../data/documents_providers.dart';
import '../../domain/document_models.dart';

class MyContributionsScreen extends ConsumerWidget {
  const MyContributionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(myDocumentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My contributions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(myDocumentsProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: docsAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: const [
              AppSkeleton(height: 96),
              SizedBox(height: AppSpacing.md),
              AppSkeleton(height: 96),
            ],
          ),
          error: (_, __) => AppEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load your contributions',
            message: 'Please check your connection and try again.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(myDocumentsProvider),
          ),
          data: (docs) {
            if (docs.isEmpty) {
              return AppEmptyState(
                icon: Icons.folder_outlined,
                title: 'No contributions yet',
                message:
                    'Share your course notes or past papers to help other students — '
                    'and earn credits to download theirs.',
                actionLabel: 'Contribute a document',
                onAction: () => context.push('/documents/upload/file'),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(myDocumentsProvider);
                await ref.read(myDocumentsProvider.future);
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.xl),
                itemCount: docs.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (_, i) => _ContributionCard(doc: docs[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ContributionCard extends StatelessWidget {
  const _ContributionCard({required this.doc});
  final Document doc;

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
      onTap: () => context.push('/documents/progress/${doc.id}'),
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
                Icons.download_outlined,
                size: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text('${doc.downloadCount} downloads',
                  style: theme.textTheme.labelSmall),
              const SizedBox(width: AppSpacing.md),
              Text(
                DateFormat.yMMMd().format(doc.createdAt),
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
          if (doc.isRejected && doc.rejectionReason != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                doc.rejectionReason!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
