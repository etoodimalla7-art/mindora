import 'package:equatable/equatable.dart';

class StudyGroup extends Equatable {
  const StudyGroup({
    required this.id,
    required this.name,
    this.description,
    this.examSystem,
    this.examLevel,
    this.subject,
    required this.creatorId,
    required this.isPrivate,
    required this.memberCount,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? description;
  final String? examSystem;
  final String? examLevel;
  final String? subject;
  final String creatorId;
  final bool isPrivate;
  final int memberCount;
  final DateTime createdAt;

  factory StudyGroup.fromJson(Map<String, dynamic> j) => StudyGroup(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        examSystem: j['exam_system'] as String?,
        examLevel: j['exam_level'] as String?,
        subject: j['subject'] as String?,
        creatorId: j['creator_id'] as String,
        isPrivate: j['is_private'] as bool? ?? false,
        memberCount: j['member_count'] as int? ?? 0,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  @override
  List<Object?> get props => [id, memberCount, createdAt];
}

class GroupMessage extends Equatable {
  const GroupMessage({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.userName,
  });

  final String id;
  final String groupId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String? userName;

  factory GroupMessage.fromJson(Map<String, dynamic> j) => GroupMessage(
        id: j['id'] as String,
        groupId: j['group_id'] as String,
        userId: j['user_id'] as String,
        content: j['content'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
        userName: j['user_name'] as String?,
      );

  @override
  List<Object?> get props => [id];
}
