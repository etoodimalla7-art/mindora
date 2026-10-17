import 'dart:io';
import 'package:dio/dio.dart';
import '../domain/admin_models.dart';

class AdminApi {
  AdminApi(this._dio);
  final Dio _dio;

  Future<AdminStats> getStats() async {
    final r = await _dio.get('/admin/stats');
    return AdminStats.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<AdminUser>> listUsers({String? search, int limit = 50, int offset = 0}) async {
    final r = await _dio.get('/admin/users', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      'limit': limit,
      'offset': offset,
    });
    return (r.data as List)
        .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<bool> toggleActive(String userId) async {
    final r = await _dio.post('/admin/users/$userId/toggle-active');
    return (r.data as Map<String, dynamic>)['is_active'] as bool;
  }

  Future<bool> promote(String userId) async {
    final r = await _dio.post('/admin/users/$userId/promote');
    return (r.data as Map<String, dynamic>)['is_admin'] as bool;
  }

  Future<List<AdminPaper>> listPapers({String? subject, int limit = 50}) async {
    final r = await _dio.get('/admin/papers', queryParameters: {
      if (subject != null) 'subject': subject,
      'limit': limit,
    });
    return (r.data as List)
        .map((e) => AdminPaper.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminPaper> uploadPaper({
    required String title,
    required String subject,
    required String examSystem,
    required String examLevel,
    int? examYear,
    String language = 'fr',
    String? description,
    required File file,
  }) async {
    final form = FormData.fromMap({
      'title': title,
      'subject': subject,
      'exam_system': examSystem,
      'exam_level': examLevel,
      if (examYear != null) 'exam_year': examYear,
      'language': language,
      if (description != null) 'description': description,
      'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
    });
    final r = await _dio.post('/admin/papers', data: form);
    return AdminPaper.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> deletePaper(String paperId) async {
    await _dio.delete('/admin/papers/$paperId');
  }
}
