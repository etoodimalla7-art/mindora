/// Maps a push payload to an in-app route for go_router.
///
/// Prefers the explicit `deep_link` field from the backend (already a valid
/// route). Falls back to a route derived from `template_key`.
library;

import 'notification_models.dart';

class DeepLinkHandler {
  const DeepLinkHandler();

  /// Returns a route path (starting with "/") or null if nothing should happen.
  String? routeFor(PushPayload payload) {
    if (payload.deepLink != null && payload.deepLink!.isNotEmpty) {
      return payload.deepLink;
    }

    switch (payload.templateKey) {
      case 'session_reminder':
      case 'session_completed':
        return '/planner';
      case 'streak':
        return '/home';
      case 'exam_countdown':
        return '/planner';
      case 'inactivity':
        return '/planner';
      case 'document_ready':
        return '/documents';
      case 'subscription_expiring':
        return '/subscription';
      case 'milestone':
        return '/mock-exams';
      case 'system':
      default:
        return null;
    }
  }
}
