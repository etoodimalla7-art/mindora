import 'package:dio/dio.dart';

import '../domain/planner_models.dart';

class PlannerRepository {
  PlannerRepository(this._dio);
  final Dio _dio;

  Future<StudyPlan> createExamPlan({
    required String examSystem,
    required String examLevel,
    required String examName,
    required List<String> subjects,
    required DateTime targetDate,
    required int dailyMinutes,
  }) async {
    final r = await _dio.post('/planner/exam', data: {
      'exam_system': examSystem,
      'exam_level': examLevel,
      'exam_name': examName,
      'subjects': subjects,
      'target_date': _dateOnly(targetDate),
      'daily_minutes': dailyMinutes,
    });
    return StudyPlan.fromJson(r.data as Map<String, dynamic>);
  }

  Future<StudyPlan> createSubjectPlan({
    required String subject,
    String? topic,
    required int durationDays,
    required int dailyMinutes,
  }) async {
    final r = await _dio.post('/planner/subject', data: {
      'subject': subject,
      'topic': topic,
      'duration_days': durationDays,
      'daily_minutes': dailyMinutes,
    });
    return StudyPlan.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<StudyPlan>> listPlans() async {
    final r = await _dio.get('/planner/plans');
    return (r.data as List<dynamic>)
        .map((e) => StudyPlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StudyPlan> getPlan(String id) async {
    final r = await _dio.get('/planner/plans/$id');
    return StudyPlan.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<StudySession>> upcomingSessions() async {
    final r = await _dio.get('/planner/sessions');
    return (r.data as List<dynamic>)
        .map((e) => StudySession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StudySession> startSession(String id) async {
    final r = await _dio.post('/planner/sessions/$id/start');
    return StudySession.fromJson(r.data as Map<String, dynamic>);
  }

  Future<StudySession> completeSession({
    required String id,
    double? confidenceAfter,
    String? notes,
  }) async {
    final r = await _dio.post('/planner/sessions/$id/complete', data: {
      'confidence_after': confidenceAfter,
      'notes': notes,
    });
    return StudySession.fromJson(r.data as Map<String, dynamic>);
  }

  String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
