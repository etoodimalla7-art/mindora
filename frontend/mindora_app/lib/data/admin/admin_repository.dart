import '../../core/network/api_client.dart';
import '../../domain/admin/review_item_entity.dart';

class AdminRepository {
  AdminRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<List<ReviewQueueItemEntity>> getReviewQueue() async {
    final response = await _apiClient.dio.get('/admin/documents/queue');
    final data = (response.data as Map<String, dynamic>)['data'] as List;
    return data.map((e) => ReviewQueueItemEntity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> approve(String documentId) async {
    await _apiClient.dio.post('/admin/documents/$documentId/approve');
  }

  Future<void> reject(String documentId, String reason) async {
    await _apiClient.dio.post('/admin/documents/$documentId/reject', data: {'reason': reason});
  }
}
