class StudyPlanEntity {
  const StudyPlanEntity({
    required this.id,
    required this.mode,
    this.targetExamName,
    required this.subjects,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.sessionCount,
  });

  final String id;
  final String mode; // "exam" | "subject"
  final String? targetExamName;
  final List<String> subjects;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final int sessionCount;

  factory StudyPlanEntity.fromJson(Map<String, dynamic> json) => StudyPlanEntity(
        id: json['id'] as String,
        mode: json['mode'] as String,
        targetExamName: json['target_exam_name'] as String?,
        subjects: (json['subjects'] as List).cast<String>(),
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: DateTime.parse(json['end_date'] as String),
        status: json['status'] as String,
        sessionCount: json['session_count'] as int,
      );
}
