import '../../core/network/api_client.dart';
import '../../domain/progress/readiness_entity.dart';

class ProgressRepository {
  ProgressRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<ReadinessEntity> getReadiness(String targetExamName) async {
    final response = await _apiClient.dio.get('/progress/readiness/$targetExamName');
    return ReadinessEntity.fromJson((response.data as Map<String, dynamic>)['data']);
  }
}
