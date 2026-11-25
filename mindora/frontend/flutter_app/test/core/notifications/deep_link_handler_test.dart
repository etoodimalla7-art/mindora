import 'package:flutter_test/flutter_test.dart';
import 'package:mindora_app/core/notifications/deep_link_handler.dart';
import 'package:mindora_app/core/notifications/notification_models.dart';

void main() {
  const handler = DeepLinkHandler();

  group('DeepLinkHandler', () {
    test('prefers explicit deep_link', () {
      const p = PushPayload(
        notificationId: 'n1',
        templateKey: 'session_reminder',
        deepLink: '/planner/sessions/42',
      );
      expect(handler.routeFor(p), '/planner/sessions/42');
    });

    test('maps session_reminder to /planner', () {
      const p = PushPayload(
        notificationId: 'n1',
        templateKey: 'session_reminder',
      );
      expect(handler.routeFor(p), '/planner');
    });

    test('maps streak to /home', () {
      const p = PushPayload(notificationId: 'n1', templateKey: 'streak');
      expect(handler.routeFor(p), '/home');
    });

    test('maps document_ready to /documents', () {
      const p = PushPayload(notificationId: 'n1', templateKey: 'document_ready');
      expect(handler.routeFor(p), '/documents');
    });

    test('maps subscription_expiring to /subscription', () {
      const p = PushPayload(
        notificationId: 'n1',
        templateKey: 'subscription_expiring',
      );
      expect(handler.routeFor(p), '/subscription');
    });

    test('maps milestone to /mock-exams', () {
      const p = PushPayload(notificationId: 'n1', templateKey: 'milestone');
      expect(handler.routeFor(p), '/mock-exams');
    });

    test('returns null for unknown template', () {
      const p = PushPayload(notificationId: 'n1', templateKey: 'unknown_xyz');
      expect(handler.routeFor(p), isNull);
    });

    test('ignores empty deep_link', () {
      const p = PushPayload(
        notificationId: 'n1',
        templateKey: 'streak',
        deepLink: '',
      );
      expect(handler.routeFor(p), '/home');
    });
  });
}
