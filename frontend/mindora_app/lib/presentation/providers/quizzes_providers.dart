import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/quizzes/quizzes_repository.dart';
import 'core_providers.dart';

final quizzesRepositoryProvider = Provider((ref) {
  return QuizzesRepository(ref.watch(apiClientProvider));
});
