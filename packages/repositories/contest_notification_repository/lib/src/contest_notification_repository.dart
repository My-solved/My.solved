import 'dart:convert';

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
      id: _notificationId(title: title, startTime: startTime),
      dateTime: target,
      title: "대회 알림",
      content: beforeMinute == 0
          ? "$title 대회가 시작되었습니다."
          : "$beforeMinute분 뒤 $title 대회가 시작됩니다.",
    );
  }

  Future<void> cancelContestNotification({
    required String title,
    required DateTime startTime,
  }) async {
    await _notificationApiClient.cancelScheduledNotificationById(
      id: _notificationId(title: title, startTime: startTime),
    );
  }

  int _notificationId({
    required String title,
    required DateTime startTime,
  }) {
    const offsetBasis = 0x811c9dc5;
    final value = '$title\n${startTime.toUtc().millisecondsSinceEpoch}';
    var hash = offsetBasis;

    for (final byte in utf8.encode(value)) {
      hash ^= byte;
      // 0x01000193 multiplication expressed as shifts keeps the 32-bit result
      // identical on native Dart and JavaScript runtimes.
      hash = (hash +
              (hash << 1) +
              (hash << 4) +
              (hash << 7) +
              (hash << 8) +
              (hash << 24)) &
          0xffffffff;
    }

    // Keep contest notifications in the positive upper quarter of the signed
    // 32-bit range so they cannot collide with fixed low IDs such as streak.
    return (hash & 0x3fffffff) | 0x40000000;
  }
}
