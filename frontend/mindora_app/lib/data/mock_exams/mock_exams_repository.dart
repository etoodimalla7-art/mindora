import '../../core/network/api_client.dart';
import '../../domain/mock_exams/mock_exam_entity.dart';

class MockExamsRepository {
  MockExamsRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<MockExamEntity> create({
    required List<String> subjectNames, int numQuestionsPerSubject = 5,
    String difficulty = 'medium', int durationMinutes = 60,
  }) async {
    final response = await _apiClient.dio.post('/mock-exams', data: {
      'subject_names': subjectNames,
      'num_questions_per_subject': numQuestionsPerSubject,
      'difficulty': difficulty,
      'duration_minutes': durationMinutes,
    });
    return MockExamEntity.fromJson((response.data as Map<String, dynamic>)['data']);
  }

  Future<MockExamResultEntity> submit(String mockExamId, Map<String, String> answers) async {
    final response = await _apiClient.dio.post('/mock-exams/$mockExamId/submit', data: {'answers': answers});
    return MockExamResultEntity.fromJson((response.data as Map<String, dynamic>)['data']);
  }
}
