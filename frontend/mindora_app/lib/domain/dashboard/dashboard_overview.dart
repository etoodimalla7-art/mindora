class SubjectProgress {
  const SubjectProgress({required this.subjectName, required this.masteryScore, this.lastStudiedAt});
  final String subjectName;
  final double masteryScore;
  final DateTime? lastStudiedAt;

  factory SubjectProgress.fromJson(Map<String, dynamic> json) => SubjectProgress(
        subjectName: json['subject_name'] as String,
        masteryScore: (json['mastery_score'] as num).toDouble(),
        lastStudiedAt:
            json['last_studied_at'] == null ? null : DateTime.parse(json['last_studied_at'] as String),
      );
}

class DashboardOverview {
  const DashboardOverview({
    required this.streakDays,
    required this.subjects,
    this.weakestSubject,
  });

  final int streakDays;
  final List<SubjectProgress> subjects;
  final String? weakestSubject;

  factory DashboardOverview.fromJson(Map<String, dynamic> json) => DashboardOverview(
        streakDays: json['streak_days'] as int,
        subjects: (json['subjects'] as List)
            .map((e) => SubjectProgress.fromJson(e as Map<String, dynamic>))
            .toList(),
        weakestSubject: json['weakest_subject'] as String?,
      );
}
