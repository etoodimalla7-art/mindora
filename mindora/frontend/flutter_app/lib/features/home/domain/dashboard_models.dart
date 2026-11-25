import 'package:equatable/equatable.dart';

class ExamCountdown extends Equatable {
  const ExamCountdown({
    required this.examName,
    required this.targetDate,
    required this.daysRemaining,
  });

  final String examName;
  final DateTime targetDate;
  final int daysRemaining;

  factory ExamCountdown.fromJson(Map<String, dynamic> json) => ExamCountdown(
        examName: json['exam_name'] as String,
        targetDate: DateTime.parse(json['target_date'] as String),
        daysRemaining: json['days_remaining'] as int,
      );

  @override
  List<Object?> get props => [examName, targetDate, daysRemaining];
}

class TodayFocus extends Equatable {
  const TodayFocus({
    this.sessionId,
    this.title,
    this.subject,
    this.topic,
    this.objective,
    this.durationMinutes,
    this.scheduledFor,
  });

  final String? sessionId;
  final String? title;
  final String? subject;
  final String? topic;
  final String? objective;
  final int? durationMinutes;
  final DateTime? scheduledFor;

  factory TodayFocus.fromJson(Map<String, dynamic> json) => TodayFocus(
        sessionId: json['session_id'] as String?,
        title: json['title'] as String?,
        subject: json['subject'] as String?,
        topic: json['topic'] as String?,
        objective: json['objective'] as String?,
        durationMinutes: json['duration_minutes'] as int?,
        scheduledFor: json['scheduled_for'] != null
            ? DateTime.parse(json['scheduled_for'] as String)
            : null,
      );

  @override
  List<Object?> get props =>
      [sessionId, title, subject, topic, objective, durationMinutes, scheduledFor];
}

class ReadinessBreakdown extends Equatable {
  const ReadinessBreakdown({
    this.knowledge = 0,
    this.practice = 0,
    this.retention = 0,
    this.consistency = 0,
    this.weakTopics = 0,
  });

  final double knowledge;
  final double practice;
  final double retention;
  final double consistency;
  final double weakTopics;

  factory ReadinessBreakdown.fromJson(Map<String, dynamic> json) =>
      ReadinessBreakdown(
        knowledge: (json['knowledge'] as num?)?.toDouble() ?? 0,
        practice: (json['practice'] as num?)?.toDouble() ?? 0,
        retention: (json['retention'] as num?)?.toDouble() ?? 0,
        consistency: (json['consistency'] as num?)?.toDouble() ?? 0,
        weakTopics: (json['weak_topics'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object?> get props =>
      [knowledge, practice, retention, consistency, weakTopics];
}

class WeakTopic extends Equatable {
  const WeakTopic({
    required this.subject,
    required this.topic,
    required this.mastery,
  });

  final String subject;
  final String topic;
  final double mastery;

  factory WeakTopic.fromJson(Map<String, dynamic> json) => WeakTopic(
        subject: json['subject'] as String,
        topic: json['topic'] as String,
        mastery: (json['mastery'] as num).toDouble(),
      );

  @override
  List<Object?> get props => [subject, topic, mastery];
}

class RecentActivity extends Equatable {
  const RecentActivity({
    required this.sessionId,
    required this.title,
    this.subject,
    this.completedAt,
    required this.durationMinutes,
  });

  final String sessionId;
  final String title;
  final String? subject;
  final DateTime? completedAt;
  final int durationMinutes;

  factory RecentActivity.fromJson(Map<String, dynamic> json) => RecentActivity(
        sessionId: json['session_id'] as String,
        title: json['title'] as String,
        subject: json['subject'] as String?,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
        durationMinutes: json['duration_minutes'] as int,
      );

  @override
  List<Object?> get props =>
      [sessionId, title, subject, completedAt, durationMinutes];
}

class Dashboard extends Equatable {
  const Dashboard({
    this.greetingName,
    this.streakDays = 0,
    this.examCountdown,
    this.todayFocus,
    this.readinessScore = 0,
    this.readinessBreakdown = const ReadinessBreakdown(),
    this.weakTopics = const [],
    this.recentActivity = const [],
  });

  final String? greetingName;
  final int streakDays;
  final ExamCountdown? examCountdown;
  final TodayFocus? todayFocus;
  final int readinessScore;
  final ReadinessBreakdown readinessBreakdown;
  final List<WeakTopic> weakTopics;
  final List<RecentActivity> recentActivity;

  factory Dashboard.fromJson(Map<String, dynamic> json) => Dashboard(
        greetingName: json['greeting_name'] as String?,
        streakDays: json['streak_days'] as int? ?? 0,
        examCountdown: json['exam_countdown'] != null
            ? ExamCountdown.fromJson(json['exam_countdown'] as Map<String, dynamic>)
            : null,
        todayFocus: json['today_focus'] != null
            ? TodayFocus.fromJson(json['today_focus'] as Map<String, dynamic>)
            : null,
        readinessScore: json['readiness_score'] as int? ?? 0,
        readinessBreakdown: json['readiness_breakdown'] != null
            ? ReadinessBreakdown.fromJson(
                json['readiness_breakdown'] as Map<String, dynamic>)
            : const ReadinessBreakdown(),
        weakTopics: (json['weak_topics'] as List<dynamic>? ?? [])
            .map((e) => WeakTopic.fromJson(e as Map<String, dynamic>))
            .toList(),
        recentActivity: (json['recent_activity'] as List<dynamic>? ?? [])
            .map((e) => RecentActivity.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [
        greetingName,
        streakDays,
        examCountdown,
        todayFocus,
        readinessScore,
        readinessBreakdown,
        weakTopics,
        recentActivity,
      ];
}
