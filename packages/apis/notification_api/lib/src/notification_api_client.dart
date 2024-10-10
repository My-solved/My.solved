import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationApiClient {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> setScheduledNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String content,
  }) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
    NotificationDetails details = const NotificationDetails(
      android: AndroidNotificationDetails(
        'my_solved.notification_channel',
        'my_solved',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: false,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      content,
      scheduledDate,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> setInstanceNotification({
    required int id,
    required tz.TZDateTime dateTime,
    required String title,
    required String content,
  }) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
    NotificationDetails details = const NotificationDetails(
      android: AndroidNotificationDetails(
        'my_solved.notification_channel',
        'my_solved',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: false,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    tz.TZDateTime tzDateTime = tz.TZDateTime(
      tz.UTC,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      content,
      tzDateTime,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  Future<void> cancelScheduledNotificationById({required int id}) async {
    _flutterLocalNotificationsPlugin.cancel(id);
  }
}
