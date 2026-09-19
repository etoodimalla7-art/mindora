import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../providers/documents_providers.dart';

const _minWords = 500;
const _categories = [
  'Mathematics', 'Physics', 'Chemistry', 'Biology', 'Computer Science',
  'Economics', 'Accounting', 'English', 'French', 'History', 'Geography',
];
const _levels = ['Primary', 'Secondary', 'University', 'HND', 'BTS', 'Licence', 'Master'];
const _languages = [('en', 'English'), ('fr', 'Français')];

int _wordCount(String text) => text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

/// Section 17-18: structured metadata + a real (client-side mirrored)
/// 500-word description requirement with a live counter, so the user
/// finds out *while typing*, not after a rejected submission.
class UploadMetadataScreen extends ConsumerStatefulWidget {
  const UploadMetadataScreen({super.key});

  @override
  ConsumerState<UploadMetadataScreen> createState() => _UploadMetadataScreenState();
}

class _UploadMetadataScreenState extends ConsumerState<UploadMetadataScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _category;
  String? _level;
  String _language = 'en';
  bool _isSubmitting = false;
  String? _error;
  int _words = 0;

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(() {
      setState(() => _words = _wordCount(_descriptionController.text));
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _titleController.text.trim().length >= 3 &&
      _words >= _minWords &&
      _category != null &&
      _level != null;

  Future<void> _submit() async {
    final documentId = ref.read(activeUploadDocumentIdProvider);
    if (documentId == null || !_canContinue) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ref.read(documentsRepositoryProvider).saveMetadata(
            documentId: documentId,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _category!,
            level: _level!,
            language: _language,
          );
      if (mounted) context.push('/learn/upload/exam-metadata');
    } catch (error) {
      setState(() => _error = extractApiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wordsOk = _words >= _minWords;
    return Scaffold(
      appBar: AppBar(title: const Text('Document details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TextField(
              controller: _titleController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Document title'),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category / subject'),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              value: _level,
              decoration: const InputDecoration(labelText: 'Academic level'),
              items: _levels.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (v) => setState(() => _level = v),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              value: _language,
              decoration: const InputDecoration(labelText: 'Language'),
              items: _languages
                  .map((l) => DropdownMenuItem(value: l.$1, child: Text(l.$2)))
                  .toList(),
              onChanged: (v) => setState(() => _language = v ?? 'en'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _descriptionController,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
                hintText: 'Describe what this document covers, who it helps, and why it '
                    'was made — at least 500 words.',
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$_words / $_minWords words',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: wordsOk ? Colors.green.shade700 : theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: (_canContinue && !_isSubmitting) ? _submit : null,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
