import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/flashcard_models.dart';
import 'flashcard_api.dart';

final flashcardApiProvider = Provider<FlashcardApi>((ref) {
  return FlashcardApi(ref.watch(dioProvider));
});

final decksProvider = FutureProvider<List<Deck>>((ref) async {
  return ref.watch(flashcardApiProvider).listDecks();
});

final dueCardsProvider = FutureProvider.family<List<Flashcard>, String>((ref, deckId) async {
  return ref.watch(flashcardApiProvider).getDueCards(deckId);
});
