import 'package:dio/dio.dart';

import '../domain/document_models.dart';

class DocumentsRepository {
  DocumentsRepository(this._dio);
  final Dio _dio;

  /// Upload a file with metadata. Returns the created document (status=uploading).
  ///
  /// Accepts either a `filePath` (mobile/desktop) OR `bytes` (web), because
  /// Flutter Web does not expose a filesystem path.
  Future<Document> upload({
    String? filePath,
    List<int>? bytes,
    required String filename,
    required String mimeType,
    required String title,
    required String description,
    void Function(int sent, int total)? onProgress,
  }) async {
    MultipartFile multipartFile;
    if (bytes != null && bytes.isNotEmpty) {
      multipartFile = MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: DioMediaType.parse(mimeType),
      );
    } else if (filePath != null && filePath.isNotEmpty) {
      multipartFile = await MultipartFile.fromFile(
        filePath,
        filename: filename,
        contentType: DioMediaType.parse(mimeType),
      );
    } else {
      throw ArgumentError('Either filePath or bytes must be provided.');
    }

    final formData = FormData.fromMap({
      'title': title,
      'description': description,
      'file': multipartFile,
    });

    final r = await _dio.post(
      '/documents/upload',
      data: formData,
      onSendProgress: onProgress,
    );
    return Document.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Document> submit({
    required String id,
    required String category,
    required String academicLevel,
    required String language,
    bool isExamRelated = false,
    String? examSystem,
    String? examName,
    int? examYear,
    String? examSession,
    String? documentType,
  }) async {
    final r = await _dio.post('/documents/$id/submit', data: {
      'category': category,
      'academic_level': academicLevel,
      'language': language,
      'is_exam_related': isExamRelated,
      'exam_system': examSystem,
      'exam_name': examName,
      'exam_year': examYear,
      'exam_session': examSession,
      'document_type': documentType,
    });
    return Document.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Document> get(String id) async {
    final r = await _dio.get('/documents/$id');
    return Document.fromJson(r.data as Map<String, dynamic>);
  }

  Future<DocumentStatus> getStatus(String id) async {
    final r = await _dio.get('/documents/$id/status');
    return DocumentStatus.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<Document>> listMine() async {
    final r = await _dio.get('/documents');
    return (r.data as List)
        .map((e) => Document.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CreditBalance> credits() async {
    final r = await _dio.get('/credits');
    return CreditBalance.fromJson(r.data as Map<String, dynamic>);
  }
}
