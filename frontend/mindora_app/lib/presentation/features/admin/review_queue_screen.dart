import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../domain/admin/review_item_entity.dart';
import '../../providers/admin_providers.dart';
import '../../shared_widgets/empty_state.dart';

/// Sections 64-65: the document moderation queue. An internal
/// moderator tool — functional and information-dense rather than
/// consumer-polished, since students never see this screen (the route
/// isn't linked from student navigation; an admin opens it directly).
/// A 403 here (non-admin account) surfaces the backend's own safe
/// message rather than a custom empty state.
class ReviewQueueScreen extends ConsumerWidget {
  const ReviewQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(reviewQueueProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Review Queue')),
      body: SafeArea(
        child: queueAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyState(
            icon: Icons.lock_outline_rounded,
            title: "Can't load the queue",
            message: extractApiErrorMessage(error),
          ),
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(icon: Icons.inbox_outlined, title: 'Queue is empty', message: 'Nothing waiting for review.');
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) => _ReviewCard(item: items[index]),
            );
          },
        ),
      ),
    );
  }
}

class _ReviewCard extends ConsumerStatefulWidget {
  const _ReviewCard({required this.item});
  final ReviewQueueItemEntity item;

  @override
  ConsumerState<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends ConsumerState<_ReviewCard> {
  bool _isBusy = false;

  Future<void> _approve() async {
    setState(() => _isBusy = true);
    try {
      await ref.read(adminRepositoryProvider).approve(widget.item.id);
      ref.invalidate(reviewQueueProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(extractApiErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _reject() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reason for rejection'),
        content: TextField(controller: controller, autofocus: true, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: const Text('Reject')),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    setState(() => _isBusy = true);
    try {
      await ref.read(adminRepositoryProvider).reject(widget.item.id, reason);
      ref.invalidate(reviewQueueProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(extractApiErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final hasDuplicateFlag = item.duplicateOfId != null;
    final hasMismatch = item.detectedSubject != null && item.category != null && item.detectedSubject != item.category;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(item.title ?? '(untitled)', style: theme.textTheme.titleLarge)),
                if (item.isExam) const Chip(label: Text('Exam paper'), visualDensity: VisualDensity.compact),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                if (item.category != null) Chip(label: Text(item.category!), visualDensity: VisualDensity.compact),
                if (item.level != null) Chip(label: Text(item.level!), visualDensity: VisualDensity.compact),
                Chip(label: Text(item.status), visualDensity: VisualDensity.compact),
              ],
            ),
            if (hasMismatch) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Declared "${item.category}", detected "${item.detectedSubject}"',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            if (hasDuplicateFlag) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Possible duplicate (${((item.similarityScore ?? 0) * 100).round()}% similar)',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            if (item.validationSummary.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              for (final line in item.validationSummary)
                Text('• $line', style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isBusy ? null : _reject,
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isBusy ? null : _approve,
                    child: _isBusy
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
