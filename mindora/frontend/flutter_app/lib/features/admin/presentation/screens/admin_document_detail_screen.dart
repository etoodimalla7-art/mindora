import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/widgets.dart';
import '../../../documents/data/documents_providers.dart';
import '../../../documents/domain/document_models.dart';
import '../../data/admin_providers.dart';

final _adminDocProvider =
    FutureProvider.family<Document, String>((ref, id) async {
  return ref.watch(documentsRepositoryProvider).get(id);
});

class AdminDocumentDetailScreen extends ConsumerStatefulWidget {
  const AdminDocumentDetailScreen({super.key, required this.documentId});
  final String documentId;

  @override
  ConsumerState<AdminDocumentDetailScreen> createState() =>
      _AdminDocumentDetailScreenState();
}

class _AdminDocumentDetailScreenState
    extends ConsumerState<AdminDocumentDetailScreen> {
  bool _busy = false;

  Future<void> _approve() async {
    setState(() => _busy = true);
    try {
      await ref.read(adminRepositoryProvider).approve(widget.documentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document approved. Contributor rewarded +5 credits.'),
        ),
      );
      ref.invalidate(pendingDocumentsProvider);
      ref.invalidate(allDocumentsProvider);
      ref.invalidate(_adminDocProvider(widget.documentId));
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We could not approve this document.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final reason = await _promptReason();
    if (reason == null || reason.trim().length < 3) return;

    setState(() => _busy = true);
    try {
      await ref.read(adminRepositoryProvider).reject(widget.documentId, reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document rejected.')),
      );
      ref.invalidate(pendingDocumentsProvider);
      ref.invalidate(allDocumentsProvider);
      ref.invalidate(_adminDocProvider(widget.documentId));
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We could not reject this document.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _promptReason() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reason for rejection'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Explain what needs to change.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(_adminDocProvider(widget.documentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Moderate document')),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => AppEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load this document',
            message: 'Please try again.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(_adminDocProvider(widget.documentId)),
          ),
          data: (doc) => ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              Text(doc.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                doc.originalFilename,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (doc.category != null)
                    AppChip(label: doc.category!, tone: AppChipTone.primary),
                  if (doc.academicLevel != null)
                    AppChip(label: doc.academicLevel!, tone: AppChipTone.info),
                  AppChip(label: doc.language.toUpperCase()),
                  if (doc.documentType != null)
                    AppChip(label: doc.documentType!.replaceAll('_', ' ')),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              Text('Description', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              AppSurface(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  doc.description,
                  style: theme.textTheme.bodyMedium,
                ),
              ),

              if (doc.analysis != null) ...[
                const SizedBox(height: AppSpacing.xl),
                Text('AI analysis', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                AppSurface(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      _kv('Detected language', doc.analysis!.detectedLanguage ?? '—'),
                      _kv('Detected subject', doc.analysis!.detectedSubject ?? '—'),
                      _kv('Detected level', doc.analysis!.detectedLevel ?? '—'),
                      _kv('Detected type', doc.analysis!.detectedDocType ?? '—'),
                      _kv(
                        'Quality score',
                        '${(doc.analysis!.qualityScore * 100).toStringAsFixed(0)}%',
                      ),
                      _kv('Flagged spam', doc.analysis!.isSpam ? 'Yes' : 'No'),
                      _kv('Contains PII', doc.analysis!.containsPii ? 'Yes' : 'No'),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),
              Text('Metadata', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              AppSurface(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    _kv('Status', doc.status),
                    _kv(
                      'Size',
                      '${(doc.sizeBytes / 1024).toStringAsFixed(1)} KB',
                    ),
                    _kv('Mime type', doc.mimeType),
                    _kv(
                      'Created',
                      DateFormat.yMMMd().add_Hm().format(doc.createdAt),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxxl),
              if (doc.status == 'under_review') ...[
                AppButton(
                  label: 'Approve',
                  icon: Icons.check_circle_outline,
                  loading: _busy,
                  onPressed: _busy ? null : _approve,
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Reject',
                  icon: Icons.cancel_outlined,
                  variant: AppButtonVariant.danger,
                  loading: _busy,
                  onPressed: _busy ? null : _reject,
                ),
              ] else
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'This document is already ${doc.status.replaceAll("_", " ")}.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                k,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
            Flexible(
              child: Text(
                v,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}
