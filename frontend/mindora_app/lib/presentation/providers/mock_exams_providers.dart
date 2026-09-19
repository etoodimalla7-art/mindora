import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock_exams/mock_exams_repository.dart';
import 'core_providers.dart';

final mockExamsRepositoryProvider = Provider((ref) {
  return MockExamsRepository(ref.watch(apiClientProvider));
});
