import '../../core/network/api_client.dart';
import '../../domain/quizzes/quiz_entity.dart';

class QuizzesRepository {
  QuizzesRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<QuizEntity> generate({
    required String topicTitle, String? sourceDocumentId, int numQuestions = 5, String difficulty = 'medium',
  }) async {
    final response = await _apiClient.dio.post('/quizzes/generate', data: {
      'topic_title': topicTitle,
      if (sourceDocumentId != null) 'source_document_id': sourceDocumentId,
      'num_questions': numQuestions,
      'difficulty': difficulty,
    });
    return QuizEntity.fromJson((response.data as Map<String, dynamic>)['data']);
  }

  Future<AttemptResultEntity> submitAttempt(String quizId, Map<String, String> answers) async {
    final response = await _apiClient.dio.post('/quizzes/$quizId/attempt', data: {'answers': answers});
    return AttemptResultEntity.fromJson((response.data as Map<String, dynamic>)['data']);
  }
}
