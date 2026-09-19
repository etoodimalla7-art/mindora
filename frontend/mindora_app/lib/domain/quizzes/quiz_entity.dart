class QuestionEntity {
  const QuestionEntity({required this.id, required this.qType, required this.prompt, required this.choices});
  final String id;
  final String qType;
  final String prompt;
  final List<String> choices;

  factory QuestionEntity.fromJson(Map<String, dynamic> json) => QuestionEntity(
        id: json['id'] as String,
        qType: json['q_type'] as String,
        prompt: json['prompt'] as String,
        choices: (json['choices'] as List).cast<String>(),
      );
}

class QuizEntity {
  const QuizEntity({required this.id, required this.topicTitle, required this.difficulty, required this.questions});
  final String id;
  final String topicTitle;
  final String difficulty;
  final List<QuestionEntity> questions;

  factory QuizEntity.fromJson(Map<String, dynamic> json) => QuizEntity(
        id: json['id'] as String,
        topicTitle: json['topic_title'] as String,
        difficulty: json['difficulty'] as String,
        questions: (json['questions'] as List)
            .map((e) => QuestionEntity.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class QuestionResultEntity {
  const QuestionResultEntity({
    required this.questionId, required this.prompt, this.chosenAnswer,
    required this.correctAnswer, required this.isCorrect,
  });
  final String questionId;
  final String prompt;
  final String? chosenAnswer;
  final String correctAnswer;
  final bool isCorrect;

  factory QuestionResultEntity.fromJson(Map<String, dynamic> json) => QuestionResultEntity(
        questionId: json['question_id'] as String,
        prompt: json['prompt'] as String,
        chosenAnswer: json['chosen_answer'] as String?,
        correctAnswer: json['correct_answer'] as String,
        isCorrect: json['is_correct'] as bool,
      );
}

class AttemptResultEntity {
  const AttemptResultEntity({required this.attemptId, required this.score, required this.results});
  final String attemptId;
  final double score;
  final List<QuestionResultEntity> results;

  factory AttemptResultEntity.fromJson(Map<String, dynamic> json) => AttemptResultEntity(
        attemptId: json['attempt_id'] as String,
        score: (json['score'] as num).toDouble(),
        results: (json['results'] as List)
            .map((e) => QuestionResultEntity.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
