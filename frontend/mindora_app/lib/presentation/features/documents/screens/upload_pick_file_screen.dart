import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../providers/documents_providers.dart';

/// Section 17-22, screen "Upload": step 1 of the contribution flow — pick
/// a file, upload it (creates a Draft document server-side), then move
/// to metadata. Never a one-click "done" — metadata is mandatory next.
class UploadPickFileScreen extends ConsumerStatefulWidget {
  const UploadPickFileScreen({super.key});

  @override
  ConsumerState<UploadPickFileScreen> createState() => _UploadPickFileScreenState();
}

class _UploadPickFileScreenState extends ConsumerState<UploadPickFileScreen> {
  PlatformFile? _picked;
  bool _isUploading = false;
  String? _error;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'docx'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _picked = result.files.single;
        _error = null;
      });
    }
  }

  Future<void> _upload() async {
    final file = _picked;
    if (file?.path == null) return;
    setState(() {
      _isUploading = true;
      _error = null;
    });
    try {
      final doc = await ref.read(documentsRepositoryProvider).uploadFile(
            path: file!.path!,
            filename: file.name,
          );
      ref.read(activeUploadDocumentIdProvider.notifier).state = doc.id;
      if (mounted) context.push('/learn/upload/metadata');
    } catch (error) {
      setState(() => _error = extractApiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Upload a document')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Share course notes, study guides or past papers with other '
                'students. PDF, Word, or image — up to 25 MB.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _picked == null ? Icons.upload_file_rounded : Icons.description_rounded,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(_picked?.name ?? 'Tap to choose a file', textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const Spacer(),
              ElevatedButton(
                onPressed: (_picked == null || _isUploading) ? null : _upload,
                child: _isUploading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
