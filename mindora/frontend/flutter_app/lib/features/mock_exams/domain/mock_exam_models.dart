import 'package:equatable/equatable.dart';

class MockQuestionOption extends Equatable {
  const MockQuestionOption({required this.label, required this.text});

  final String label;
  final String text;

  factory MockQuestionOption.fromJson(Map<String, dynamic> j) =>
      MockQuestionOption(
        label: j['label'] as String? ?? '',
        text: j['text'] as String? ?? '',
      );

  @override
  List<Object?> get props => [label, text];
}

class MockQuestion extends Equatable {
  const MockQuestion({
    required this.id,
    required this.position,
    required this.questionType,
    required this.prompt,
    this.options = const [],
    required this.difficulty,
    required this.points,
    this.correctAnswer,
    this.explanation,
  });

  final String id;
  final int position;
  final String questionType; // mcq | true_false | short_answer
  final String prompt;
  final List<MockQuestionOption> options;
  final String difficulty;
  final int points;
  final String? correctAnswer;
  final String? explanation;

  bool get hasAnswer => correctAnswer != null && correctAnswer!.isNotEmpty;

  factory MockQuestion.fromJson(Map<String, dynamic> j) => MockQuestion(
        id: j['id'] as String,
        position: j['position'] as int,
        questionType: j['question_type'] as String,
        prompt: j['prompt'] as String,
        options: ((j['options'] as List?) ?? [])
            .map((e) => MockQuestionOption.fromJson(e as Map<String, dynamic>))
            .toList(),
        difficulty: j['difficulty'] as String? ?? 'medium',
        points: j['points'] as int? ?? 1,
        correctAnswer: j['correct_answer'] as String?,
        explanation: j['explanation'] as String?,
      );

  @override
  List<Object?> get props => [id, correctAnswer];
}

class MockExam extends Equatable {
  const MockExam({
    required this.id,
    required this.title,
    required this.subject,
    this.academicLevel,
    required this.questionCount,
    required this.durationMinutes,
    required this.difficulty,
    required this.status,
    this.startedAt,
    this.submittedAt,
    this.gradedAt,
    this.score,
    this.correctCount,
    this.wrongCount,
    this.skippedCount,
    required this.createdAt,
    this.questions = const [],
  });

  final String id;
  final String title;
  final String subject;
  final String? academicLevel;
  final int questionCount;
  final int durationMinutes;
  final String difficulty;
  final String status;
  final DateTime? startedAt;
  final DateTime? submittedAt;
  final DateTime? gradedAt;
  final double? score;
  final int? correctCount;
  final int? wrongCount;
  final int? skippedCount;
  final DateTime createdAt;
  final List<MockQuestion> questions;

  bool get isReady => status == 'ready' || status == 'draft';
  bool get isInProgress => status == 'in_progress';
  bool get isGraded => status == 'graded';

  factory MockExam.fromJson(Map<String, dynamic> j) => MockExam(
        id: j['id'] as String,
        title: j['title'] as String,
        subject: j['subject'] as String,
        academicLevel: j['academic_level'] as String?,
        questionCount: j['question_count'] as int,
        durationMinutes: j['duration_minutes'] as int,
        difficulty: j['difficulty'] as String,
        status: j['status'] as String,
        startedAt: j['started_at'] != null
            ? DateTime.parse(j['started_at'] as String)
            : null,
        submittedAt: j['submitted_at'] != null
            ? DateTime.parse(j['submitted_at'] as String)
            : null,
        gradedAt: j['graded_at'] != null
            ? DateTime.parse(j['graded_at'] as String)
            : null,
        score: (j['score'] as num?)?.toDouble(),
        correctCount: j['correct_count'] as int?,
        wrongCount: j['wrong_count'] as int?,
        skippedCount: j['skipped_count'] as int?,
        createdAt: DateTime.parse(j['created_at'] as String),
        questions: ((j['questions'] as List?) ?? [])
            .map((e) => MockQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [id, status, score];
}

class AnswerResult extends Equatable {
  const AnswerResult({
    required this.questionId,
    this.userAnswer,
    this.isCorrect,
    required this.pointsAwarded,
    required this.correctAnswer,
    this.explanation,
    this.aiFeedback,
  });

  final String questionId;
  final String? userAnswer;
  final bool? isCorrect;
  final int pointsAwarded;
  final String correctAnswer;
  final String? explanation;
  final String? aiFeedback;

  factory AnswerResult.fromJson(Map<String, dynamic> j) => AnswerResult(
        questionId: j['question_id'] as String,
        userAnswer: j['user_answer'] as String?,
        isCorrect: j['is_correct'] as bool?,
        pointsAwarded: j['points_awarded'] as int? ?? 0,
        correctAnswer: j['correct_answer'] as String? ?? '',
        explanation: j['explanation'] as String?,
        aiFeedback: j['ai_feedback'] as String?,
      );

  @override
  List<Object?> get props => [questionId, isCorrect];
}

class MockExamResults extends Equatable {
  const MockExamResults({
    required this.exam,
    required this.answers,
    this.feedbackSummary,
    this.topicBreakdown = const {},
  });

  final MockExam exam;
  final List<AnswerResult> answers;
  final String? feedbackSummary;
  final Map<String, Map<String, int>> topicBreakdown;

  factory MockExamResults.fromJson(Map<String, dynamic> j) {
    final exam = MockExam.fromJson(j);
    return MockExamResults(
      exam: exam,
      answers: ((j['answers'] as List?) ?? [])
          .map((e) => AnswerResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      feedbackSummary: j['feedback_summary'] as String?,
      topicBreakdown: ((j['topic_breakdown'] as Map?) ?? {}).map(
        (k, v) => MapEntry(
          k.toString(),
          (v as Map).map((k2, v2) => MapEntry(k2.toString(), (v2 as num).toInt())),
        ),
      ),
    );
  }

  @override
  List<Object?> get props => [exam.id, answers.length];
}
