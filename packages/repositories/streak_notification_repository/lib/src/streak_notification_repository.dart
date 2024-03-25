import 'package:notification_api/notification_api.dart';

class StreakNotificationRepository {
  StreakNotificationRepository({
    NotificationApiClient? notificationApiClient,
  }) : _notificationApiClient =
            notificationApiClient ?? NotificationApiClient();

  final NotificationApiClient _notificationApiClient;
  final int _streakID = 2;

  Future<void> setStreakNotification({
    required int hour,
    required int minute,
  }) async {
    await _notificationApiClient.setScheduledNotification(
      id: _streakID,
      hour: hour,
      minute: minute,
      title: "오늘도 백준 한 문제, 잊지 않으셨나요?",
      content: "스트릭을 이어보세요!",
    );
  }

  Future<void> cancelStreakNotification() async {
    await _notificationApiClient.cancelScheduledNotificationById(id: _streakID);
  }
}