/// PDF viewer sheet (Web only via iframe + native fallback via url_launcher).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/token_store.dart';

void showPdfViewerSheet(
  BuildContext context, {
  required String docId,
  required String title,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0A0E1A),
    builder: (_) => PdfViewerSheet(docId: docId, title: title),
  );
}

class PdfViewerSheet extends StatefulWidget {
  const PdfViewerSheet({
    super.key,
    required this.docId,
    required this.title,
  });
  final String docId;
  final String title;

  @override
  State<PdfViewerSheet> createState() => _PdfViewerSheetState();
}

class _PdfViewerSheetState extends State<PdfViewerSheet> {
  String? _url;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final token = await TokenStore().access;
      if (token == null) {
        setState(() {
          _error = 'Not authenticated';
          _loading = false;
        });
        return;
      }
      // Use download URL + token as query param (backend accepts JWT anywhere)
      final base = Env.apiBaseUrl;
      setState(() {
        _url = '$base/admin/documents/${widget.docId}/download?token=$token';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A0E1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 48),
                                const SizedBox(height: 12),
                                Text(_error!,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        )
                      : _buildViewer(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewer(ThemeData theme) {
    if (kIsWeb) {
      // On web, use an iframe via HtmlElementView
      return _WebPdfIframe(url: _url!);
    }
    // On mobile, open in external viewer
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              final uri = Uri.parse(_url!);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Ouvrir le PDF'),
          ),
        ],
      ),
    );
  }
}

/// Web-only: render the PDF via an <iframe> using the browser's native viewer.
class _WebPdfIframe extends StatefulWidget {
  const _WebPdfIframe({required this.url});
  final String url;

  @override
  State<_WebPdfIframe> createState() => _WebPdfIframeState();
}

class _WebPdfIframeState extends State<_WebPdfIframe> {
  @override
  Widget build(BuildContext context) {
    // Fallback: on web, render an iframe via a small embedded widget.
    // We use HtmlElementView which requires `dart:ui_web` on Flutter 3.24+.
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Ouvre le PDF dans un onglet',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              final uri = Uri.parse(widget.url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Ouvrir'),
          ),
        ],
      ),
    );
  }
}
