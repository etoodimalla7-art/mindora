import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../admin/data/web_download_stub.dart'
    if (dart.library.js_interop) '../../admin/data/web_download_web.dart';
import '../domain/document_models.dart';

abstract class LocalDownloadsStore {
  Future<List<LocalDownloadedDocument>> list();
  Future<LocalDownloadedDocument> save({
    required Document document,
    required List<int> bytes,
  });
  Future<void> remove(String documentId);
}

class PrefsLocalDownloadsStore implements LocalDownloadsStore {
  static const String _prefsKey = 'mindora_local_downloads_v1';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<List<LocalDownloadedDocument>> list() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_prefsKey) ?? const [];
    final items = <LocalDownloadedDocument>[];
    for (final entry in raw) {
      try {
        items.add(
          LocalDownloadedDocument.fromJson(
            jsonDecode(entry) as Map<String, dynamic>,
          ),
        );
      } catch (_) {
        // Skip malformed entries
      }
    }
    items.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
    return items;
  }

  @override
  Future<LocalDownloadedDocument> save({
    required Document document,
    required List<int> bytes,
  }) async {
    String? localPath;
    if (kIsWeb) {
      if (bytes.isNotEmpty) {
        triggerWebDownload(
          bytes,
          document.originalFilename,
          document.mimeType,
        );
      }
    } else {
      final baseDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${baseDir.path}/mindora_downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      final safeName = document.originalFilename.replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      );
      final target = File('${downloadsDir.path}/${document.id}_$safeName');
      await target.writeAsBytes(bytes, flush: true);
      localPath = target.path;
    }

    final entry = LocalDownloadedDocument(
      documentId: document.id,
      title: document.title,
      originalFilename: document.originalFilename,
      mimeType: document.mimeType,
      sizeBytes: bytes.isNotEmpty ? bytes.length : document.sizeBytes,
      language: document.language,
      category: document.category,
      academicLevel: document.academicLevel,
      localPath: localPath,
      downloadedAt: DateTime.now().toUtc(),
    );

    final existing = await list();
    final updated = [
      entry,
      ...existing.where((d) => d.documentId != document.id),
    ];
    final prefs = await _prefs;
    await prefs.setStringList(
      _prefsKey,
      updated.map((e) => jsonEncode(e.toJson())).toList(),
    );
    return entry;
  }

  @override
  Future<void> remove(String documentId) async {
    final existing = await list();
    final removed = existing.where((d) => d.documentId == documentId).toList();
    for (final item in removed) {
      if (!kIsWeb && item.localPath != null && item.localPath!.isNotEmpty) {
        final f = File(item.localPath!);
        if (await f.exists()) {
          await f.delete();
        }
      }
    }
    final remaining = existing.where((d) => d.documentId != documentId).toList();
    final prefs = await _prefs;
    await prefs.setStringList(
      _prefsKey,
      remaining.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}
