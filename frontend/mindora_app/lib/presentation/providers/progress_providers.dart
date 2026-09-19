import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/progress/progress_repository.dart';
import 'core_providers.dart';

final progressRepositoryProvider = Provider((ref) {
  return ProgressRepository(ref.watch(apiClientProvider));
});
