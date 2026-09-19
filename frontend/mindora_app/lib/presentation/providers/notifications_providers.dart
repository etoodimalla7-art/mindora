import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/notifications/notifications_repository.dart';
import '../../domain/notifications/notification_entity.dart';
import 'core_providers.dart';

final notificationsRepositoryProvider = Provider((ref) {
  return NotificationsRepository(ref.watch(apiClientProvider));
});

final notificationsListProvider = FutureProvider.autoDispose<List<NotificationEntity>>((ref) {
  return ref.watch(notificationsRepositoryProvider).list();
});

final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(notificationsListProvider).maybeWhen(
        data: (list) => list.where((n) => n.isUnread).length,
        orElse: () => 0,
      );
});

final markNotificationReadActionProvider = Provider((ref) {
  return (String notificationId) async {
    await ref.read(notificationsRepositoryProvider).markRead(notificationId);
    ref.invalidate(notificationsListProvider);
  };
});
