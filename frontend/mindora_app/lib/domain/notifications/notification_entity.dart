class NotificationEntity {
  const NotificationEntity({
    required this.id, required this.type, required this.title, required this.body,
    required this.scheduledFor, this.readAt,
  });
  final String id;
  final String type;
  final String title;
  final String body;
  final DateTime scheduledFor;
  final DateTime? readAt;

  bool get isUnread => readAt == null;

  factory NotificationEntity.fromJson(Map<String, dynamic> json) => NotificationEntity(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        scheduledFor: DateTime.parse(json['scheduled_for'] as String),
        readAt: json['read_at'] == null ? null : DateTime.parse(json['read_at'] as String),
      );
}
