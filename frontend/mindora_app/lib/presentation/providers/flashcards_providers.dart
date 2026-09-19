import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/flashcards/flashcards_repository.dart';
import 'core_providers.dart';

final flashcardsRepositoryProvider = Provider((ref) {
  return FlashcardsRepository(ref.watch(apiClientProvider));
});
