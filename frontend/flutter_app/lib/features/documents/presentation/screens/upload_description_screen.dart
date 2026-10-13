import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/widgets.dart';
import '../../data/documents_providers.dart';
import '../widgets/word_counter.dart';

class UploadDescriptionScreen extends ConsumerStatefulWidget {
  const UploadDescriptionScreen({super.key, required this.payload});
  final Map<String, dynamic> payload;

  @override
  ConsumerState<UploadDescriptionScreen> createState() =>
      _UploadDescriptionScreenState();
}

class _UploadDescriptionScreenState
    extends ConsumerState<UploadDescriptionScreen> {
  final _description = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final words = _description.text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    if (words < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Need $words/20 words before submitting.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final file = widget.payload['file'] as PlatformFile;
      final repo = ref.read(documentsRepositoryProvider);

      // 1. Upload — prefer bytes (works on web), fall back to path.
      final doc = await repo.upload(
        bytes: file.bytes,
        filePath: file.path,
        filename: file.name,
        mimeType: _mimeFor(file.name),
        title: widget.payload['title'] as String,
        description: _description.text,
      );

      // 2. Submit for analysis.
      await repo.submit(
        id: doc.id,
        category: widget.payload['category'] as String,
        academicLevel: widget.payload['level'] as String,
        language: widget.payload['language'] as String,
        isExamRelated: widget.payload['isExam'] as bool? ?? false,
        examSystem: widget.payload['examSystem'] as String?,
        examName: widget.payload['examName'] as String?,
        examYear: widget.payload['examYear'] as int?,
        documentType: widget.payload['docType'] as String?,
      );

      // 3. Refresh caches.
      ref.invalidate(myDocumentsProvider);
      ref.invalidate(creditBalanceProvider);

      if (!mounted) return;
      context.go('/documents/progress/${doc.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'We could not submit your document. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _mimeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.txt')) return 'text/plain';
    if (lower.endsWith('.md')) return 'text/markdown';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    return 'application/octet-stream';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Describe the document')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Text('Write a short description.',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Explain what the document covers and who it is for. '
              'Minimum 20 words. Keep it meaningful — spam text will be rejected.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xl),

            WordCounter(text: _description.text),

            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _description,
              minLines: 6,
              maxLines: 20,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText:
                    'Example: Course notes on differential equations with worked '
                    'examples, aimed at advanced-level students preparing for exams.',
                alignLabelWithHint: true,
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              label: 'Submit for review',
              icon: Icons.check,
              loading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
