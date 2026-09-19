import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../domain/documents/document_entity.dart';

class DocumentsRepository {
  DocumentsRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<DocumentEntity> uploadFile({required String path, required String filename}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(path, filename: filename),
    });
    final response = await _apiClient.dio.post('/documents/upload', data: formData);
    return DocumentEntity.fromJson((response.data as Map<String, dynamic>)['data']);
  }

  Future<DocumentEntity> saveMetadata({
    required String documentId,
    required String title,
    required String description,
    required String category,
    required String level,
    required String language,
  }) async {
    final response = await _apiClient.dio.post('/documents/$documentId/metadata', data: {
      'title': title,
      'description': description,
      'category': category,
      'level': level,
      'language': language,
    });
    return DocumentEntity.fromJson((response.data as Map<String, dynamic>)['data']);
  }

  Future<void> saveExamMetadata({
    required String documentId,
    required bool isExam,
    String? examSystem,
    String? examName,
    String? examLevel,
    String? examSubject,
    int? examYear,
    String? examSession,
  }) async {
    await _apiClient.dio.post('/documents/$documentId/exam-metadata', data: {
      'is_exam': isExam,
      'exam_system': examSystem,
      'exam_name': examName,
      'exam_level': examLevel,
      'exam_subject': examSubject,
      'exam_year': examYear,
      'exam_session': examSession,
    });
  }

  /// Returns the resulting status, blocking problems, and non-blocking
  /// warnings (e.g. possible duplicate, category mismatch) that a
  /// moderator will review but don't prevent submission.
  Future<(String status, List<String> problems, List<String> warnings)> submit(String documentId) async {
    final response = await _apiClient.dio.post('/documents/$documentId/submit');
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return (
      data['status'] as String,
      (data['problems'] as List).cast<String>(),
      (data['warnings'] as List).cast<String>(),
    );
  }

  Future<List<DocumentEntity>> listMine() async {
    final response = await _apiClient.dio.get('/documents/mine');
    final data = (response.data as Map<String, dynamic>)['data'] as List;
    return data.map((e) => DocumentEntity.fromJson(e as Map<String, dynamic>)).toList();
  }
}
