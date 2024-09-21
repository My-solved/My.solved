import 'package:notification_api/notification_api.dart';
import 'package:timezone/timezone.dart' as tz;

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
    tz.TZDateTime target = tz.TZDateTime(
      tz.UTC,
      startTime.year,
      startTime.month,
      startTime.day,
      startTime.hour,
      startTime.minute - beforeMinute,
    );

    await _notificationApiClient.setInstanceNotification(
      id: target.hashCode ^ title.hashCode,
      dateTime: target,
      title: "대회 알림",
      content: beforeMinute == 0
          ? "$title 대회가 시작되었습니다."
          : "$beforeMinute분 뒤 $title 대회가 시작됩니다.",
    );
  }

  Future<void> cancelContestNotification({
    required String title,
  }) async {
    await _notificationApiClient.cancelScheduledNotificationById(
      id: title.hashCode,
    );
  }
}
