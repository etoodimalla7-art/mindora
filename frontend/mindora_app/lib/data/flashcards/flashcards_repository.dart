import '../../core/network/api_client.dart';
import '../../domain/flashcards/flashcard_entity.dart';

class FlashcardsRepository {
  FlashcardsRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<List<FlashcardEntity>> generate({
    required String topicTitle, String? sourceDocumentId, int maxCards = 10,
  }) async {
    final response = await _apiClient.dio.post('/flashcards/generate', data: {
      'topic_title': topicTitle,
      if (sourceDocumentId != null) 'source_document_id': sourceDocumentId,
      'max_cards': maxCards,
    });
    final data = (response.data as Map<String, dynamic>)['data'] as List;
    return data.map((e) => FlashcardEntity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<FlashcardEntity>> listDue({String? topic}) async {
    final response = await _apiClient.dio.get('/flashcards', queryParameters: {
      if (topic != null) 'topic': topic,
    });
    final data = (response.data as Map<String, dynamic>)['data'] as List;
    return data.map((e) => FlashcardEntity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> review(String flashcardId, String state) async {
    await _apiClient.dio.post('/flashcards/$flashcardId/review', data: {'state': state});
  }
}
