class StudySessionEntity {
  const StudySessionEntity({
    required this.id,
    required this.subjectName,
    required this.topicTitle,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.status,
  });

  final String id;
  final String subjectName;
  final String topicTitle;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String status;

  factory StudySessionEntity.fromJson(Map<String, dynamic> json) => StudySessionEntity(
        id: json['id'] as String,
        subjectName: json['subject_name'] as String,
        topicTitle: json['topic_title'] as String,
        scheduledAt: DateTime.parse(json['scheduled_at'] as String),
        durationMinutes: json['duration_minutes'] as int,
        status: json['status'] as String,
      );
}
