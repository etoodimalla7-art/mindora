import 'package:dio/dio.dart';
import '../domain/paper_models.dart';

class PublicPaperApi {
  PublicPaperApi(this._dio);
  final Dio _dio;

  Future<List<Paper>> listPapers({
    String? subject,
    String? examSystem,
    String? examLevel,
  }) async {
    final r = await _dio.get('/papers', queryParameters: {
      if (subject != null && subject.isNotEmpty) 'subject': subject,
      if (examSystem != null && examSystem.isNotEmpty) 'exam_system': examSystem,
      if (examLevel != null && examLevel.isNotEmpty) 'exam_level': examLevel,
    });
    return (r.data as List).map((e) => Paper.fromJson(e)).toList();
  }

  /// Returns the full download URL for a paper.
  String downloadUrl(String paperId) {
    final base = _dio.options.baseUrl.replaceAll(RegExp(r'/$'), '');
    return '$base/papers/$paperId/download';
  }
}
