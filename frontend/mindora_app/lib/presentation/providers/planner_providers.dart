import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/planner/planner_repository.dart';
import 'core_providers.dart';

final plannerRepositoryProvider = Provider((ref) {
  return PlannerRepository(ref.watch(apiClientProvider));
});

/// Holds the id of the plan just created so the summary screen (and the
/// dashboard, after invalidation) can fetch its sessions without
/// threading it through route params.
final activePlanIdProvider = StateProvider.autoDispose<String?>((ref) => null);
