import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import '../domain/admin_models.dart';

class PaperApi {
  PaperApi(this._dio);
  final Dio _dio;

  Future<List<AdminPaper>> listPapers({String? subject}) async {
    final r = await _dio.get('/admin/papers', queryParameters: {
      if (subject != null) 'subject': subject,
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
  }) async {
    final bytes = await file.readAsBytes();
    final form = FormData.fromMap({
      'title': title,
      'subject': subject,
      'exam_system': examSystem,
      'exam_level': examLevel,
      if (examYear != null) 'exam_year': examYear,
      'language': language,
      if (description != null) 'description': description,
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.name,
        contentType: DioMediaType('application', 'pdf'),
      ),
    });
    final r = await _dio.post('/admin/papers', data: form);
    return AdminPaper.fromJson(r.data);
  }

  Future<void> deletePaper(String paperId) async {
    await _dio.delete('/admin/papers/$paperId');
  }
}
