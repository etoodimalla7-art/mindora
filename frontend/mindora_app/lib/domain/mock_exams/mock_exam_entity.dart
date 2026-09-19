import '../quizzes/quiz_entity.dart';

class MockExamSectionEntity {
  const MockExamSectionEntity({required this.subjectName, required this.quizId, required this.questions});
  final String subjectName;
  final String quizId;
  final List<QuestionEntity> questions;

  factory MockExamSectionEntity.fromJson(Map<String, dynamic> json) => MockExamSectionEntity(
        subjectName: json['subject_name'] as String,
        quizId: json['quiz_id'] as String,
        questions: (json['questions'] as List).map((e) => QuestionEntity.fromJson(e as Map<String, dynamic>)).toList(),
      );

  List<QuestionEntity> get allQuestions => questions;
}

class MockExamEntity {
  const MockExamEntity({
    required this.id, required this.subjectNames, required this.difficulty,
    required this.durationMinutes, required this.status, required this.sections,
  });
  final String id;
  final List<String> subjectNames;
  final String difficulty;
  final int durationMinutes;
  final String status;
  final List<MockExamSectionEntity> sections;

  List<QuestionEntity> get allQuestions => sections.expand((s) => s.questions).toList();

  factory MockExamEntity.fromJson(Map<String, dynamic> json) => MockExamEntity(
        id: json['id'] as String,
        subjectNames: (json['subject_names'] as List).cast<String>(),
        difficulty: json['difficulty'] as String,
        durationMinutes: json['duration_minutes'] as int,
        status: json['status'] as String,
        sections: (json['sections'] as List)
            .map((e) => MockExamSectionEntity.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class MockExamResultEntity {
  const MockExamResultEntity({
    required this.attemptId, required this.score, required this.sectionScores, required this.results,
  });
  final String attemptId;
  final double score;
  final Map<String, double> sectionScores;
  final List<QuestionResultEntity> results;

  factory MockExamResultEntity.fromJson(Map<String, dynamic> json) => MockExamResultEntity(
        attemptId: json['attempt_id'] as String,
        score: (json['score'] as num).toDouble(),
        sectionScores: (json['section_scores'] as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble())),
        results: (json['results'] as List)
            .map((e) => QuestionResultEntity.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
