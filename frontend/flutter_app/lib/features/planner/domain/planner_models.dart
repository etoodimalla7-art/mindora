import 'package:equatable/equatable.dart';

class StudySession extends Equatable {
  const StudySession({
    required this.id,
    this.planId,
    required this.title,
    this.subject,
    this.topic,
    this.objective,
    required this.scheduledFor,
    required this.durationMinutes,
    required this.status,
    this.startedAt,
    this.completedAt,
  });

  final String id;
  final String? planId;
  final String title;
  final String? subject;
  final String? topic;
  final String? objective;
  final DateTime scheduledFor;
  final int durationMinutes;
  final String status;
  final DateTime? startedAt;
  final DateTime? completedAt;

  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
        id: json['id'] as String,
        planId: json['plan_id'] as String?,
        title: json['title'] as String,
        subject: json['subject'] as String?,
        topic: json['topic'] as String?,
        objective: json['objective'] as String?,
        scheduledFor: DateTime.parse(json['scheduled_for'] as String),
        durationMinutes: json['duration_minutes'] as int,
        status: json['status'] as String,
        startedAt: json['started_at'] != null
            ? DateTime.parse(json['started_at'] as String)
            : null,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
      );

  @override
  List<Object?> get props => [id, status, scheduledFor];
}

class StudyPlan extends Equatable {
  const StudyPlan({
    required this.id,
    required this.planType,
    required this.title,
    this.subject,
    this.examSystem,
    this.examLevel,
    this.examName,
    required this.startDate,
    this.targetDate,
    required this.dailyMinutes,
    required this.isActive,
    required this.createdAt,
    this.sessions = const [],
  });

  final String id;
  final String planType;
  final String title;
  final String? subject;
  final String? examSystem;
  final String? examLevel;
  final String? examName;
  final DateTime startDate;
  final DateTime? targetDate;
  final int dailyMinutes;
  final bool isActive;
  final DateTime createdAt;
  final List<StudySession> sessions;

  int get daysRemaining =>
      targetDate == null ? 0 : targetDate!.difference(DateTime.now()).inDays;

  factory StudyPlan.fromJson(Map<String, dynamic> json) => StudyPlan(
        id: json['id'] as String,
        planType: json['plan_type'] as String,
        title: json['title'] as String,
        subject: json['subject'] as String?,
        examSystem: json['exam_system'] as String?,
        examLevel: json['exam_level'] as String?,
        examName: json['exam_name'] as String?,
        startDate: DateTime.parse(json['start_date'] as String),
        targetDate: json['target_date'] != null
            ? DateTime.parse(json['target_date'] as String)
            : null,
        dailyMinutes: json['daily_minutes'] as int,
        isActive: json['is_active'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
        sessions: (json['sessions'] as List<dynamic>? ?? [])
            .map((e) => StudySession.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [id, isActive, targetDate];
}
