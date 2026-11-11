import 'dart:async';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// ignore: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/widgets.dart';

const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB
const int _chunkSizeBytes = 1 * 1024 * 1024;    // 1 MB chunks
const Duration _readTimeout = Duration(seconds: 120);

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
  bool _busy = false;
  int _readBytes = 0;
  int _totalBytes = 0;

  Future<void> _pick() async {
    if (_busy) return;
    debugPrint('[UPLOAD_PICK] start');
    const typeGroup = XTypeGroup(
      label: 'Documents',
      extensions: ['pdf', 'txt', 'md', 'docx', 'png', 'jpg', 'jpeg'],
    );

    setState(() {
      _busy = true;
      _readBytes = 0;
      _totalBytes = 0;
    });

    try {
      debugPrint('[UPLOAD_PICK] calling openFile...');
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) {
        debugPrint('[UPLOAD_PICK] user cancelled');
        return;
      }
      debugPrint('[UPLOAD_PICK] openFile returned: ${file.name}');

      // --- Get file size early (native length is instant; web goes through blob) ---
      int totalSize = 0;
      try {
        totalSize = await file.length();
      } catch (_) {
        totalSize = 0;
      }
      debugPrint('[UPLOAD_PICK] total size: $totalSize bytes');
      setState(() => _totalBytes = totalSize);

      // --- Size check BEFORE reading bytes (avoid loading huge file) ---
      if (totalSize > _maxFileSizeBytes) {
        throw 'Ce fichier est trop lourd (${_fmtMb(totalSize)}). '
            'Max 10 MB. Compresse-le avec Adobe Scan ou Smallpdf, '
            'ou divise-le en plusieurs parties.';
      }

      // --- Read bytes: web uses Blob.slice(), native uses readAsBytes ---
      Uint8List bytes;
      if (kIsWeb) {
        debugPrint('[UPLOAD_PICK] reading via Blob.slice (web)...');
        bytes = await _readBytesWeb(file, totalSize);
      } else {
        debugPrint('[UPLOAD_PICK] reading via readAsBytes (native)...');
        bytes = await file.readAsBytes().timeout(_readTimeout);
      }

      final size = bytes.length;
      debugPrint('[UPLOAD_PICK] bytes read: $size bytes');

      if (size == 0) throw 'Fichier vide.';
      if (size > _maxFileSizeBytes) {
        throw 'Fichier trop lourd (${_fmtMb(size)}). Max 10 MB.';
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
      debugPrint('[UPLOAD_PICK] picked OK: ${file.name}');
    } catch (e) {
      debugPrint('[UPLOAD_PICK] ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          duration: const Duration(seconds: 8),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _readBytes = 0;
          _totalBytes = 0;
        });
      }
    }
  }

  /// Web-specific read using Blob.slice to avoid loading the whole file at once.
  Future<Uint8List> _readBytesWeb(XFile file, int totalSize) async {
    // XFile on web exposes its JS blob via `XFile.blob`? Not directly — we
    // recreate it via readAsBytes for browsers that expose it, OR use the
    // stream API which internally uses Blob.stream().
    //
    // The most reliable cross-platform approach: use `file.openRead()` which
    // returns a Stream<Uint8List>. On web, `file_selector_web` implements
    // openRead via Blob.slice internally.
    final builder = BytesBuilder(copy: false);
    int received = 0;
    final completer = Completer<Uint8List>();

    final sub = file.openRead().listen(
      (chunk) {
        builder.add(chunk);
        received += chunk.length;
        if (mounted && totalSize > 0) {
          setState(() => _readBytes = received);
        }
      },
      onError: (Object e) {
        if (!completer.isCompleted) {
          completer.completeError('Erreur de lecture : $e');
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(builder.takeBytes());
        }
      },
      cancelOnError: true,
    );

    try {
      return await completer.future.timeout(_readTimeout);
    } finally {
      await sub.cancel();
    }
  }

  String _fmtMb(int bytes) =>
      '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';

  void _continue() {
    if (_picked == null) return;
    context.push('/documents/upload/metadata', extra: _picked);
  }

  String _formatSize(int bytes) {
    if (bytes == 0) return '—';
    if (bytes > 1024 * 1024) return _fmtMb(bytes);
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFile = _picked != null;
    final progressText = _busy && _totalBytes > 0
        ? 'Lecture : ${_fmtMb(_readBytes)} / ${_fmtMb(_totalBytes)}'
        : (_busy ? 'Lecture du fichier...' : null);

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
                onTap: _busy ? null : _pick,
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
                      if (_busy)
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            value: _totalBytes > 0
                                ? (_readBytes / _totalBytes).clamp(0.0, 1.0)
                                : null,
                          ),
                        )
                      else
                        Icon(
                          hasFile ? Icons.description : Icons.upload_file,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        _busy
                            ? (progressText ?? 'Lecture...')
                            : (hasFile
                                ? _picked!.name
                                : 'Tap to choose a file'),
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      if (hasFile && !_busy) ...[
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
                onPressed: hasFile && !_busy ? _continue : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
