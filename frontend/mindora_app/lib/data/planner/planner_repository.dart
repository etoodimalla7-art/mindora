import '../../core/network/api_client.dart';
import '../../domain/dashboard/study_session.dart';
import '../../domain/planner/study_plan_entity.dart';

class PlannerRepository {
  PlannerRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<StudyPlanEntity> createExamPlan({
    required String targetExamName,
    required List<String> subjectNames,
    required DateTime examDate,
    int minutesPerSession = 45,
  }) async {
    final response = await _apiClient.dio.post('/planner/exam-plan', data: {
      'target_exam_name': targetExamName,
      'subject_names': subjectNames,
      'exam_date': examDate.toIso8601String().split('T').first,
      'minutes_per_session': minutesPerSession,
    });
    return StudyPlanEntity.fromJson((response.data as Map<String, dynamic>)['data']);
  }

  Future<StudyPlanEntity> createSubjectPlan({
    required String subjectName,
    String? topicTitle,
    required int durationDays,
    int minutesPerSession = 45,
  }) async {
    final response = await _apiClient.dio.post('/planner/subject-plan', data: {
      'subject_name': subjectName,
      'topic_title': topicTitle,
      'duration_days': durationDays,
      'minutes_per_session': minutesPerSession,
    });
    return StudyPlanEntity.fromJson((response.data as Map<String, dynamic>)['data']);
  }

  Future<List<StudySessionEntity>> getSessions(String planId) async {
    final response = await _apiClient.dio.get('/planner/plans/$planId/sessions');
    final data = (response.data as Map<String, dynamic>)['data'] as List;
    return data.map((e) => StudySessionEntity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> reschedule(String planId) async {
    final response = await _apiClient.dio.patch('/planner/plans/$planId/reschedule');
    return (response.data as Map<String, dynamic>)['data']['rescheduled_count'] as int;
  }
}
