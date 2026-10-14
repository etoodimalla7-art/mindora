import 'package:dio/dio.dart';

import '../domain/admin_models.dart';

class AdminRepository {
  AdminRepository(this._dio);
  final Dio _dio;

  Future<List<AdminDocumentRow>> listDocuments({String? status}) async {
    final r = await _dio.get(
      '/admin/documents',
      queryParameters: status != null ? {'status': status} : null,
    );
    return (r.data as List)
        .map((e) => AdminDocumentRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ApproveResult> approve(String docId) async {
    final r = await _dio.post('/admin/documents/$docId/approve');
    return ApproveResult.fromJson(r.data as Map<String, dynamic>);
  }

  Future<RejectResult> reject(String docId, String reason) async {
    final r = await _dio.post(
      '/admin/documents/$docId/reject',
      data: {'reason': reason},
    );
    return RejectResult.fromJson(r.data as Map<String, dynamic>);
  }
}
