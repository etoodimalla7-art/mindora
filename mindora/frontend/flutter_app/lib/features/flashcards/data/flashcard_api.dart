import 'package:dio/dio.dart';
import '../domain/flashcard_models.dart';

class FlashcardApi {
  FlashcardApi(this._dio);
  final Dio _dio;

  Future<List<Deck>> listDecks() async {
    final r = await _dio.get('/flashcards/decks');
    return (r.data as List).map((e) => Deck.fromJson(e)).toList();
  }

  Future<Deck> createDeck({required String title, String? description, String? subject}) async {
    final r = await _dio.post('/flashcards/decks', data: {
      'title': title,
      'description': description,
      'subject': subject,
    });
    return Deck.fromJson(r.data);
  }

  Future<void> deleteDeck(String deckId) async {
    await _dio.delete('/flashcards/decks/$deckId');
  }

  Future<Flashcard> addCard({
    required String deckId,
    required String front,
    required String back,
  }) async {
    final r = await _dio.post('/flashcards/decks/$deckId/cards', data: {
      'front': front,
      'back': back,
    });
    return Flashcard.fromJson(r.data);
  }

  Future<List<Flashcard>> getDueCards(String deckId) async {
    final r = await _dio.get('/flashcards/decks/$deckId/cards/due');
    return (r.data as List).map((e) => Flashcard.fromJson(e)).toList();
  }

  Future<ReviewResult> reviewCard({
    required String cardId,
    required int quality,
  }) async {
    final r = await _dio.post('/flashcards/cards/$cardId/review', data: {
      'quality': quality,
    });
    return ReviewResult.fromJson(r.data);
  }
}
