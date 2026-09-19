import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../domain/past_papers/past_paper_entity.dart';
import '../../../providers/credits_providers.dart';

class PastPaperCard extends ConsumerStatefulWidget {
  const PastPaperCard({super.key, required this.paper, required this.onToggleBookmark});
  final PastPaperEntity paper;
  final VoidCallback onToggleBookmark;

  @override
  ConsumerState<PastPaperCard> createState() => _PastPaperCardState();
}

class _PastPaperCardState extends ConsumerState<PastPaperCard> {
  bool _isDownloading = false;

  Future<void> _download() async {
    setState(() => _isDownloading = true);
    try {
      final available = await ref.read(creditsRepositoryProvider).downloadPastPaper(widget.paper.id);
      ref.invalidate(creditBalanceProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
          available
              ? 'Downloaded — check your downloads.'
              : "Credit used, but this paper's file isn't uploaded yet.",
        )));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(extractApiErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        title: Text(widget.paper.title, style: theme.textTheme.titleLarge),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Wrap(
            spacing: AppSpacing.xs,
            children: [
              Chip(label: Text(widget.paper.subjectName), visualDensity: VisualDensity.compact),
              Chip(label: Text(widget.paper.level), visualDensity: VisualDensity.compact),
              Chip(label: Text('${widget.paper.year}${widget.paper.session != null ? ' • ${widget.paper.session}' : ''}'), visualDensity: VisualDensity.compact),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                widget.paper.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: widget.paper.isBookmarked ? theme.colorScheme.primary : null,
              ),
              onPressed: widget.onToggleBookmark,
            ),
            IconButton(
              icon: _isDownloading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download_rounded),
              onPressed: _isDownloading ? null : _download,
            ),
          ],
        ),
      ),
    );
  }
}
