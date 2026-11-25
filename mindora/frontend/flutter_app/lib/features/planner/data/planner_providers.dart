import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/planner_models.dart';
import 'planner_repository.dart';

final plannerRepositoryProvider = Provider<PlannerRepository>(
  (ref) => PlannerRepository(ref.watch(dioProvider)),
);

final plansListProvider = FutureProvider<List<StudyPlan>>((ref) async {
  return ref.watch(plannerRepositoryProvider).listPlans();
});

final upcomingSessionsProvider = FutureProvider<List<StudySession>>((ref) async {
  return ref.watch(plannerRepositoryProvider).upcomingSessions();
});
