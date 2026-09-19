import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../providers/documents_providers.dart';

/// Section 19: extra metadata only when the document is an official
/// examination paper. Final screen of the flow — also triggers submit.
class UploadExamMetadataScreen extends ConsumerStatefulWidget {
  const UploadExamMetadataScreen({super.key});

  @override
  ConsumerState<UploadExamMetadataScreen> createState() => _UploadExamMetadataScreenState();
}

class _UploadExamMetadataScreenState extends ConsumerState<UploadExamMetadataScreen> {
  bool _isExam = false;
  final _systemController = TextEditingController();
  final _nameController = TextEditingController();
  final _levelController = TextEditingController();
  final _subjectController = TextEditingController();
  final _yearController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;
  List<String> _revisionProblems = [];
  List<String> _warnings = [];
  String? _finalStatus;

  @override
  void dispose() {
    _systemController.dispose();
    _nameController.dispose();
    _levelController.dispose();
    _subjectController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final documentId = ref.read(activeUploadDocumentIdProvider);
    if (documentId == null) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final repo = ref.read(documentsRepositoryProvider);
    try {
      if (_isExam) {
        await repo.saveExamMetadata(
          documentId: documentId,
          isExam: true,
          examSystem: _systemController.text.trim().isEmpty ? null : _systemController.text.trim(),
          examName: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
          examLevel: _levelController.text.trim().isEmpty ? null : _levelController.text.trim(),
          examSubject: _subjectController.text.trim().isEmpty ? null : _subjectController.text.trim(),
          examYear: int.tryParse(_yearController.text.trim()),
        );
      }
      final (status, problems, warnings) = await repo.submit(documentId);
      setState(() {
        _finalStatus = status;
        _revisionProblems = problems;
        _warnings = warnings;
      });
    } catch (error) {
      setState(() => _error = extractApiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_finalStatus != null) {
      final needsRevision = _finalStatus == 'NeedsRevision';
      return Scaffold(
        appBar: AppBar(title: const Text('Submission')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  needsRevision ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                  size: 48,
                  color: needsRevision ? theme.colorScheme.error : Colors.green.shade700,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  needsRevision ? 'A few things need fixing' : 'Submitted for review',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (needsRevision)
                  for (final problem in _revisionProblems)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Text('• $problem', style: theme.textTheme.bodyMedium),
                    )
                else
                  Text(
                    "We'll review your document and notify you once it's approved.",
                    style: theme.textTheme.bodyMedium,
                  ),
                if (_warnings.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('For the moderator\'s attention:', style: theme.textTheme.labelLarge),
                        const SizedBox(height: AppSpacing.xs),
                        for (final warning in _warnings)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                            child: Text('• $warning', style: theme.textTheme.bodyMedium),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: () => context.go('/learn'),
                  child: Text(needsRevision ? 'Back to Learn' : 'Done'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Examination details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Is this an official examination paper?'),
              value: _isExam,
              onChanged: (v) => setState(() => _isExam = v),
            ),
            if (_isExam) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(controller: _systemController, decoration: const InputDecoration(labelText: 'Examination system (e.g. GCE, Baccalauréat)')),
              const SizedBox(height: AppSpacing.md),
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Examination name')),
              const SizedBox(height: AppSpacing.md),
              TextField(controller: _levelController, decoration: const InputDecoration(labelText: 'Level (e.g. Ordinary Level, Advanced Level)')),
              const SizedBox(height: AppSpacing.md),
              TextField(controller: _subjectController, decoration: const InputDecoration(labelText: 'Subject')),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _yearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Year'),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit document'),
            ),
          ],
        ),
      ),
    );
  }
}
