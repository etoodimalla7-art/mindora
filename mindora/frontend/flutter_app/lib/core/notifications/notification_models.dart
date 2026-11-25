/// Data models for push notification payloads.
///
/// Backend sends `data` maps with these keys (see hooks.py / jobs.py):
/// - notification_id   UUID of the Notification row
/// - template_key      "session_reminder" | "streak" | "exam_countdown" | ...
/// - deep_link         optional in-app route (e.g. "/planner/sessions/abc")
library;

class PushPayload {
  const PushPayload({
    required this.notificationId,
    required this.templateKey,
    this.deepLink,
    this.title,
    this.body,
  });

  final String? notificationId;
  final String templateKey;
  final String? deepLink;
  final String? title;
  final String? body;

  factory PushPayload.fromData(Map<String, dynamic> data) {
    return PushPayload(
      notificationId: data['notification_id']?.toString(),
      templateKey: (data['template_key'] ?? 'system').toString(),
      deepLink: data['deep_link']?.toString(),
      title: data['title']?.toString(),
      body: data['body']?.toString(),
    );
  }

  @override
  String toString() =>
      'PushPayload(templateKey=$templateKey, notificationId=$notificationId)';
}
