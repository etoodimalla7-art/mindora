/// Riverpod providers for push notifications.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/notifications/data/device_repository.dart';
import '../../features/notifications/data/notification_api.dart';
import '../network/api_client.dart';
import 'deep_link_handler.dart';
import 'push_service.dart';

final pushServiceProvider = Provider<PushService>((ref) {
  return PushService.instance;
});

final deepLinkHandlerProvider = Provider<DeepLinkHandler>((ref) {
  return const DeepLinkHandler();
});

final notificationApiProvider = Provider<NotificationApi>((ref) {
  return NotificationApi(ref.watch(dioProvider));
});

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(ref.watch(notificationApiProvider));
});
