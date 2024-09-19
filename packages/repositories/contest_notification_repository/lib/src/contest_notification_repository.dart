import 'package:notification_api/notification_api.dart';
import 'package:timezone/timezone.dart' as tz;

class ContestNotificationRepository {
  ContestNotificationRepository({
    NotificationApiClient? notificationApiClient,
  }) : _notificationApiClient =
            notificationApiClient ?? NotificationApiClient();

  final NotificationApiClient _notificationApiClient;

  Future<void> setTestNotification() async {
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime target = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );

    await _notificationApiClient.setInstanceNotification(
      id: 404,
      dateTime: target,
      title: "대회 테스트",
      content: "특정 날짜 푸시 알림 테스트",
    );
  }

  Future<void> setContestNotification({
    required String title,
    required DateTime startTime,
    required int beforeMinute,
  }) async {
    tz.TZDateTime target = tz.TZDateTime(
        tz.local,
        startTime.year,
        startTime.month,
        startTime.day,
        startTime.hour,
        startTime.minute - beforeMinute,
        startTime.second,
        tz.local.currentTimeZone.offset);

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
