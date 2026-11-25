import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/widgets.dart';
import '../../data/documents_providers.dart';
import '../../domain/document_models.dart';

class UploadProgressScreen extends ConsumerWidget {
  const UploadProgressScreen({super.key, required this.documentId});
  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusAsync = ref.watch(documentStatusProvider(documentId));
    final docAsync = ref.watch(
      FutureProvider.family<Document, String>((ref, id) async {
        return ref.watch(documentsRepositoryProvider).get(id);
      })(documentId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Submission status')),
      body: SafeArea(
        child: statusAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => AppEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not fetch status',
            message: 'Please try again.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(documentStatusProvider(documentId)),
          ),
          data: (status) => ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              _StatusBanner(status: status),
              const SizedBox(height: AppSpacing.xxl),
              Text('Analysis pipeline', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              for (final entry in status.steps.entries)
                _StepRow(label: _humanize(entry.key), state: entry.value),
              const SizedBox(height: AppSpacing.xxl),
              docAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (doc) {
                  if (doc.analysis == null) return const SizedBox.shrink();
                  final a = doc.analysis!;
                  return AppSurface(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Detected metadata',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.md),
                        _kv('Language', a.detectedLanguage ?? '—'),
                        _kv('Subject', a.detectedSubject ?? '—'),
                        _kv('Level', a.detectedLevel ?? '—'),
                        _kv('Type', a.detectedDocType ?? '—'),
                        _kv(
                          'Quality score',
                          '${(a.qualityScore * 100).toStringAsFixed(0)}%',
                        ),
                        if (a.keywords.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text('Keywords', style: theme.textTheme.labelMedium),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final k in a.keywords.take(10))
                                AppChip(label: k, tone: AppChipTone.neutral),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: 'Back to My Contributions',
                icon: Icons.folder_open,
                variant: AppButtonVariant.secondary,
                onPressed: () => context.go('/documents/mine'),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Contribute another',
                onPressed: () => context.go('/documents/upload/file'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _humanize(String key) {
    return key.replaceAll('_', ' ').replaceFirstMapped(
          RegExp(r'^\w'),
          (m) => m.group(0)!.toUpperCase(),
        );
  }

  static Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(k),
            ),
            Text(
              v,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});
  final DocumentStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, fg, icon, text) = switch (status.status) {
      'under_review' => (
          theme.colorScheme.primary.withValues(alpha: 0.10),
          theme.colorScheme.primary,
          Icons.hourglass_top,
          'Your document is under review.',
        ),
      'approved' => (
          const Color(0x1A10B981),
          const Color(0xFF10B981),
          Icons.check_circle,
          'Your document is live and available to other students.',
        ),
      'rejected' => (
          const Color(0x1AEF4444),
          const Color(0xFFEF4444),
          Icons.cancel,
          status.rejectionReason ?? 'Your document was rejected.',
        ),
      _ => (
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurface,
          Icons.info,
          'Status: ${status.status}',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: fg),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.titleMedium?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.state});
  final String label;
  final String state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = switch (state) {
      'done' => (Icons.check_circle, const Color(0xFF10B981)),
      'in_progress' => (Icons.pending, theme.colorScheme.primary),
      'failed' => (Icons.cancel, const Color(0xFFEF4444)),
      _ => (Icons.radio_button_unchecked, theme.colorScheme.outline),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            state.replaceAll('_', ' '),
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
