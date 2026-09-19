class ReadinessEntity {
  const ReadinessEntity({
    required this.targetExamName, required this.knowledge, required this.practice,
    required this.retention, required this.pastPapers, required this.weakTopics,
    required this.consistency, required this.overall,
  });

  final String targetExamName;
  final double knowledge;
  final double practice;
  final double retention;
  final double pastPapers;
  final double weakTopics;
  final double consistency;
  final double overall;

  List<(String, double)> get dimensions => [
        ('Knowledge', knowledge),
        ('Practice', practice),
        ('Retention', retention),
        ('Past Papers', pastPapers),
        ('Weak Topics', weakTopics),
        ('Consistency', consistency),
      ];

  factory ReadinessEntity.fromJson(Map<String, dynamic> json) => ReadinessEntity(
        targetExamName: json['target_exam_name'] as String,
        knowledge: (json['knowledge'] as num).toDouble(),
        practice: (json['practice'] as num).toDouble(),
        retention: (json['retention'] as num).toDouble(),
        pastPapers: (json['past_papers'] as num).toDouble(),
        weakTopics: (json['weak_topics'] as num).toDouble(),
        consistency: (json['consistency'] as num).toDouble(),
        overall: (json['overall'] as num).toDouble(),
      );
}
