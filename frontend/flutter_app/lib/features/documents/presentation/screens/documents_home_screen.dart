import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/widgets.dart';
import '../../data/documents_providers.dart';
import '../../../../core/design/widgets/mindora_app_bar.dart';

class DocumentsHomeScreen extends ConsumerWidget {
  const DocumentsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final creditsAsync = ref.watch(creditBalanceProvider);

    return Scaffold(
      appBar: const MindoraAppBar(showWordmark: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            // Credits summary
            creditsAsync.when(
              loading: () => const AppSkeleton(height: 96),
              error: (_, __) => const SizedBox.shrink(),
              data: (credits) => AppSurface(
                padding: const EdgeInsets.all(AppSpacing.xl),
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${credits.balance}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Download credits',
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            'Earn ${credits.contributionReward} credits for each approved contribution.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Primary action
            AppSurface(
              padding: const EdgeInsets.all(AppSpacing.xl),
              onTap: () => context.push('/documents/upload/file'),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.upload_file,
                        color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Contribute a document',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          'Upload course notes, past papers, or study guides.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            AppSurface(
              padding: const EdgeInsets.all(AppSpacing.xl),
              onTap: () => context.push('/documents/mine'),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.folder_copy_outlined,
                        color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My contributions',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          'See the status of your submissions.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
