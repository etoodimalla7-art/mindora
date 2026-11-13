import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';

import '../domain/admin_models.dart';

class PaperApi {
  PaperApi(this._dio);
  final Dio _dio;

  Future<List<AdminPaper>> listPapers({
    String? subject,
    String? examSystem,
    String? examLevel,
    int? examYear,
    String? search,
  }) async {
    final r = await _dio.get('/admin/papers', queryParameters: {
      if (subject != null && subject.isNotEmpty) 'subject': subject,
      if (examSystem != null && examSystem.isNotEmpty) 'exam_system': examSystem,
      if (examLevel != null && examLevel.isNotEmpty) 'exam_level': examLevel,
      if (examYear != null) 'exam_year': examYear,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return (r.data as List).map((e) => AdminPaper.fromJson(e)).toList();
  }

  Future<AdminPaper> uploadPaper({
    required String title,
    required String subject,
    required String examSystem,
    required String examLevel,
    int? examYear,
    String language = 'fr',
    String? description,
    required XFile file,
    void Function(int sent, int total)? onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    final form = FormData.fromMap({
      'title': title,
      'subject': subject,
      'exam_system': examSystem,
      'exam_level': examLevel,
      if (examYear != null) 'exam_year': examYear,
      'language': language,
      if (description != null && description.isNotEmpty)
        'description': description,
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.name,
        contentType: DioMediaType('application', 'pdf'),
      ),
    });
    final r = await _dio.post(
      '/admin/papers',
      data: form,
      onSendProgress: onProgress,
    );
    return AdminPaper.fromJson(r.data);
  }

  /// Upload multiple PDFs in parallel. Returns (successes, failures).
  Future<({List<AdminPaper> successes, List<({XFile file, String error})> failures})>
      uploadMultiple({
    required List<XFile> files,
    required String subject,
    required String examSystem,
    required String examLevel,
    int? examYear,
    String language = 'fr',
    void Function(int done, int total)? onOverallProgress,
    void Function(XFile file, AdminPaper paper)? onSuccess,
    void Function(XFile file, String error)? onFailure,
  }) async {
    final successes = <AdminPaper>[];
    final failures = <({XFile file, String error})>[];
    int done = 0;

    for (final file in files) {
      try {
        // Derive title from filename (without extension)
        final baseName = file.name.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
        final paper = await uploadPaper(
          title: baseName.isEmpty ? file.name : baseName,
          subject: subject,
          examSystem: examSystem,
          examLevel: examLevel,
          examYear: examYear,
          language: language,
          file: file,
        );
        successes.add(paper);
        onSuccess?.call(file, paper);
      } catch (e) {
        failures.add((file: file, error: e.toString()));
        onFailure?.call(file, e.toString());
      } finally {
        done++;
        onOverallProgress?.call(done, files.length);
      }
    }

    return (successes: successes, failures: failures);
  }

  Future<AdminPaper> updatePaper({
    required String id,
    String? title,
    String? subject,
    String? examSystem,
    String? examLevel,
    int? examYear,
    String? language,
    String? status,
  }) async {
    final r = await _dio.patch('/admin/papers/$id', data: {
      if (title != null) 'title': title,
      if (subject != null) 'subject': subject,
      if (examSystem != null) 'exam_system': examSystem,
      if (examLevel != null) 'exam_level': examLevel,
      if (examYear != null) 'exam_year': examYear,
      if (language != null) 'language': language,
      if (status != null) 'status': status,
    });
    return AdminPaper.fromJson(r.data);
  }

  Future<void> deletePaper(String paperId) async {
    await _dio.delete('/admin/papers/$paperId');
  }
}
