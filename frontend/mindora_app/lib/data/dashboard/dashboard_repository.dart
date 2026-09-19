import '../../core/network/api_client.dart';
import '../../domain/dashboard/dashboard_overview.dart';
import '../../domain/dashboard/study_session.dart';

/// Talks to /study-sessions and /progress. Kept as one small repository
/// for now since the dashboard is the only current consumer; splits into
/// separate repositories if/when planner and progress screens need their
/// own data access in later phases.
class DashboardRepository {
  DashboardRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<List<StudySessionEntity>> getTodaySessions() async {
    final response = await _apiClient.dio.get('/study-sessions/today');
    final data = (response.data as Map<String, dynamic>)['data'] as List;
    return data.map((e) => StudySessionEntity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DashboardOverview> getOverview() async {
    final response = await _apiClient.dio.get('/progress/overview');
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return DashboardOverview.fromJson(data);
  }

  Future<void> completeSession(String sessionId) async {
    await _apiClient.dio.post('/study-sessions/$sessionId/complete');
  }

  Future<void> startSession(String sessionId) async {
    await _apiClient.dio.post('/study-sessions/$sessionId/start');
  }
}
