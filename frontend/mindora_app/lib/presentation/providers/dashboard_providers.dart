import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dashboard/dashboard_repository.dart';
import '../../domain/dashboard/dashboard_overview.dart';
import '../../domain/dashboard/study_session.dart';
import 'core_providers.dart';

final dashboardRepositoryProvider = Provider((ref) {
  return DashboardRepository(ref.watch(apiClientProvider));
});

final todaySessionsProvider = FutureProvider.autoDispose<List<StudySessionEntity>>((ref) {
  return ref.watch(dashboardRepositoryProvider).getTodaySessions();
});

final dashboardOverviewProvider = FutureProvider.autoDispose<DashboardOverview>((ref) {
  return ref.watch(dashboardRepositoryProvider).getOverview();
});

/// Marks a session complete, then invalidates the two providers above so
/// the dashboard refetches — screens never manage refresh state manually.
final completeSessionActionProvider = Provider((ref) {
  return (String sessionId) async {
    await ref.read(dashboardRepositoryProvider).completeSession(sessionId);
    ref.invalidate(todaySessionsProvider);
    ref.invalidate(dashboardOverviewProvider);
  };
});
