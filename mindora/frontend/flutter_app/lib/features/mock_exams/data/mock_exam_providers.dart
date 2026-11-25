import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/mock_exam_models.dart';
import 'mock_exam_repository.dart';

final mockExamRepositoryProvider = Provider<MockExamRepository>(
  (ref) => MockExamRepository(ref.watch(dioProvider)),
);

final mockExamsListProvider = FutureProvider<List<MockExam>>((ref) async {
  return ref.watch(mockExamRepositoryProvider).list();
});

final mockExamDetailProvider =
    FutureProvider.family<MockExam, String>((ref, id) async {
  return ref.watch(mockExamRepositoryProvider).get(id);
});

final mockExamResultsProvider =
    FutureProvider.family<MockExamResults, String>((ref, id) async {
  return ref.watch(mockExamRepositoryProvider).results(id);
});
