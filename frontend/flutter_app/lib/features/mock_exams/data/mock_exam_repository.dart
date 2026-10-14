import 'package:dio/dio.dart';

import '../domain/mock_exam_models.dart';

class MockExamRepository {
  MockExamRepository(this._dio);
  final Dio _dio;

  Future<MockExam> create({
    required String title,
    required String subject,
    String? academicLevel,
    int questionCount = 10,
    int durationMinutes = 30,
    String difficulty = 'medium',
    List<String> sourceDocumentIds = const [],
  }) async {
    final r = await _dio.post('/mock-exams', data: {
      'title': title,
      'subject': subject,
      'academic_level': academicLevel,
      'question_count': questionCount,
      'duration_minutes': durationMinutes,
      'difficulty': difficulty,
      'source_document_ids': sourceDocumentIds,
    });
    return MockExam.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<MockExam>> list() async {
    final r = await _dio.get('/mock-exams');
    return (r.data as List)
        .map((e) => MockExam.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MockExam> get(String id) async {
    final r = await _dio.get('/mock-exams/$id');
    return MockExam.fromJson(r.data as Map<String, dynamic>);
  }

  Future<MockExam> start(String id) async {
    final r = await _dio.post('/mock-exams/$id/start');
    return MockExam.fromJson(r.data as Map<String, dynamic>);
  }

  Future<MockExam> submitAnswer({
    required String examId,
    required String questionId,
    required String answer,
    int? timeSpentSeconds,
  }) async {
    final r = await _dio.post('/mock-exams/$examId/answer', data: {
      'question_id': questionId,
      'answer': answer,
      'time_spent_seconds': timeSpentSeconds,
    });
    return MockExam.fromJson(r.data as Map<String, dynamic>);
  }

  Future<MockExamResults> submit(String id) async {
    final r = await _dio.post('/mock-exams/$id/submit');
    return MockExamResults.fromJson(r.data as Map<String, dynamic>);
  }

  Future<MockExamResults> results(String id) async {
    final r = await _dio.get('/mock-exams/$id/results');
    return MockExamResults.fromJson(r.data as Map<String, dynamic>);
  }
}
