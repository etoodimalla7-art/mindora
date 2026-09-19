import '../../core/network/api_client.dart';
import '../../domain/notifications/notification_entity.dart';

class NotificationsRepository {
  NotificationsRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<List<NotificationEntity>> list() async {
    final response = await _apiClient.dio.get('/notifications');
    final data = (response.data as Map<String, dynamic>)['data'] as List;
    return data.map((e) => NotificationEntity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markRead(String notificationId) async {
    await _apiClient.dio.patch('/notifications/$notificationId/read');
  }

  Future<Map<String, dynamic>> getPreferences() async {
    final response = await _apiClient.dio.get('/notifications/preferences');
    return (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }

  Future<void> updatePreferences({
    bool? enabled, int? quietHoursStart, int? quietHoursEnd, List<String>? preferredStudyTimes,
  }) async {
    await _apiClient.dio.put('/notifications/preferences', data: {
      if (enabled != null) 'enabled': enabled,
      if (quietHoursStart != null) 'quiet_hours_start': quietHoursStart,
      if (quietHoursEnd != null) 'quiet_hours_end': quietHoursEnd,
      if (preferredStudyTimes != null) 'preferred_study_times': preferredStudyTimes,
    });
  }
}
