import 'package:contest_notification_repository/contest_notification_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notification_api/notification_api.dart';
import 'package:timezone/timezone.dart' as tz;

class RecordingNotificationApiClient extends NotificationApiClient {
  int? scheduledId;
  int? cancelledId;
  tz.TZDateTime? scheduledDateTime;
  String? scheduledTitle;
  String? scheduledContent;

  @override
  Future<void> setInstanceNotification({
    required int id,
    required tz.TZDateTime dateTime,
    required String title,
    required String content,
  }) async {
    scheduledId = id;
    scheduledDateTime = dateTime;
    scheduledTitle = title;
    scheduledContent = content;
  }

  @override
  Future<void> cancelScheduledNotificationById({required int id}) async {
    cancelledId = id;
  }
}

void main() {
  group('ContestNotificationRepository', () {
    late RecordingNotificationApiClient notificationApiClient;
    late ContestNotificationRepository repository;

    setUp(() {
      notificationApiClient = RecordingNotificationApiClient();
      repository = ContestNotificationRepository(
        notificationApiClient: notificationApiClient,
      );
    });

    test('uses the same stable ID when scheduling and cancelling', () async {
      final startTime = DateTime.utc(2026, 11, 20, 12, 30);

      await repository.setContestNotification(
        title: 'Friday Contest',
        startTime: startTime,
        beforeMinute: 60,
      );
      final scheduledId = notificationApiClient.scheduledId;

      expect(scheduledId, 1408510251);

      repository = ContestNotificationRepository(
        notificationApiClient: notificationApiClient,
      );
      await repository.cancelContestNotification(
        title: 'Friday Contest',
        startTime: startTime,
      );

      expect(notificationApiClient.cancelledId, scheduledId);
    });

    test('schedules the notification at the requested lead time', () async {
      final startTime = DateTime.utc(2026, 11, 20, 12, 30);

      await repository.setContestNotification(
        title: 'Friday Contest',
        startTime: startTime,
        beforeMinute: 90,
      );

      expect(
        notificationApiClient.scheduledDateTime,
        tz.TZDateTime(tz.UTC, 2026, 11, 20, 11),
      );
      expect(notificationApiClient.scheduledTitle, '대회 알림');
      expect(
        notificationApiClient.scheduledContent,
        '90분 뒤 Friday Contest 대회가 시작됩니다.',
      );
    });

    test('uses different IDs for repeated contest titles', () async {
      await repository.setContestNotification(
        title: 'Weekly Contest',
        startTime: DateTime.utc(2026, 11, 20, 12),
        beforeMinute: 0,
      );
      final firstId = notificationApiClient.scheduledId;

      await repository.setContestNotification(
        title: 'Weekly Contest',
        startTime: DateTime.utc(2026, 11, 27, 12),
        beforeMinute: 0,
      );

      expect(notificationApiClient.scheduledId, isNot(firstId));
      expect(
        notificationApiClient.scheduledId,
        inInclusiveRange(0x40000000, 0x7fffffff),
      );
    });
  });
}
