import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/widgets.dart';

/// A picked file, normalized across platforms.
class PickedFile {
  const PickedFile({
    required this.name,
    required this.path,
    required this.bytes,
    required this.size,
  });

  final String name;
  final String? path;
  final Uint8List? bytes;
  final int size;
}

class UploadFileScreen extends StatefulWidget {
  const UploadFileScreen({super.key});

  @override
  State<UploadFileScreen> createState() => _UploadFileScreenState();
}

class _UploadFileScreenState extends State<UploadFileScreen> {
  PickedFile? _picked;

  Future<void> _pick() async {
    const typeGroup = XTypeGroup(
      label: 'Documents',
      extensions: ['pdf', 'txt', 'md', 'docx', 'png', 'jpg', 'jpeg'],
    );

    try {
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return;

      Uint8List? bytes;
      int size = 0;

      if (kIsWeb) {
        bytes = await file.readAsBytes();
        size = bytes.length;
      } else {
        size = await file.length();
      }

      if (!mounted) return;
      setState(() {
        _picked = PickedFile(
          name: file.name,
          path: kIsWeb ? null : file.path,
          bytes: bytes,
          size: size,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We could not open the file picker.')),
      );
    }
  }

  void _continue() {
    if (_picked == null) return;
    context.push('/documents/upload/metadata', extra: _picked);
  }

  String _formatSize(int bytes) {
    if (bytes == 0) return '—';
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFile = _picked != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Select file')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose a document to contribute.',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'PDF, DOCX, images, or plain text — max 10 MB.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xxl),

              GestureDetector(
                onTap: _pick,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: hasFile
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.5),
                      width: hasFile ? 1.5 : 1,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        hasFile ? Icons.description : Icons.upload_file,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        hasFile ? _picked!.name : 'Tap to choose a file',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      if (hasFile) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatSize(_picked!.size),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const Spacer(),
              AppButton(
                label: 'Continue',
                icon: Icons.arrow_forward,
                onPressed: hasFile ? _continue : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
