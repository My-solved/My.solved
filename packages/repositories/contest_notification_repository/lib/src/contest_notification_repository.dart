import 'package:notification_api/notification_api.dart';

class ContestNotificationRepository {
  ContestNotificationRepository({
    NotificationApiClient? notificationApiClient,
  }) : _notificationApiClient =
            notificationApiClient ?? NotificationApiClient();

  final NotificationApiClient _notificationApiClient;

  Future<void> setContestNotification({
    required String title,
    required DateTime startTime,
    required int beforeMinute,
  }) async {
    _notificationApiClient.setInstanceNotification(
      id: title.hashCode,
      dateTime: DateTime(
        startTime.year,
        startTime.month,
        startTime.day,
        startTime.hour,
        startTime.minute - beforeMinute,
      ),
      title: "$beforeMinute분 뒤 대회 시작!",
      content: title,
    );
  }

  Future<void> cancelContestNotification({
    required String title,
  }) async {
    _notificationApiClient.cancelScheduledNotificationById(
      id: title.hashCode,
    );
  }
}