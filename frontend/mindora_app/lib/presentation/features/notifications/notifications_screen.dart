import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../domain/notifications/notification_entity.dart';
import '../../providers/notifications_providers.dart';
import '../../shared_widgets/empty_state.dart';

/// Section 47: an in-app notification center. Generation happens
/// server-side whenever this list is fetched (no push/scheduler
/// infrastructure exists yet — see ROADMAP.md), so opening this screen
/// is what surfaces due reminders.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(String type) {
    switch (type) {
      case 'session_upcoming':
        return Icons.notifications_active_outlined;
      case 'session_missed':
        return Icons.event_busy_outlined;
      case 'exam_countdown':
        return Icons.flag_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsListProvider);
    final markRead = ref.watch(markNotificationReadActionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: SafeArea(
        child: notificationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => EmptyState(
            icon: Icons.wifi_off_rounded,
            title: "Couldn't load notifications",
            message: 'Check your connection and try again.',
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return EmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'Nothing yet',
                message: "You'll see reminders here about upcoming sessions, "
                    'missed sessions, and your exam countdown.',
              );
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(notificationsListProvider),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final NotificationEntity n = notifications[index];
                  return Card(
                    color: n.isUnread ? theme.colorScheme.primary.withValues(alpha: 0.05) : null,
                    child: ListTile(
                      leading: Icon(_iconFor(n.type), color: n.isUnread ? theme.colorScheme.primary : null),
                      title: Text(n.title, style: theme.textTheme.titleLarge),
                      subtitle: Text(n.body),
                      trailing: n.isUnread
                          ? IconButton(
                              icon: const Icon(Icons.check_circle_outline_rounded),
                              tooltip: 'Mark as read',
                              onPressed: () => markRead(n.id),
                            )
                          : null,
                      onTap: n.isUnread ? () => markRead(n.id) : null,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
