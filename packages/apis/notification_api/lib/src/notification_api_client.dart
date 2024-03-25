import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationApiClient {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> _requestPermission() async {
    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('@android:drawable/ic_lock_idle_alarm');
    const DarwinInitializationSettings iosInitializationSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings settings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();
    await _flutterLocalNotificationsPlugin.initialize(settings);
  }

  Future<void> setScheduledNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String content,
  }) async {
    await _requestPermission();
    _flutterLocalNotificationsPlugin.cancel(id);
    NotificationDetails details = const NotificationDetails(
      android: AndroidNotificationDetails(
        'Notification_channel',
        'Notification_channel',
        channelDescription: 'Notification_channel',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      content,
      _timeZoneSetting(hour, minute),
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _timeZoneSetting(int hour, int minute) {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
    tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    return scheduledDate;
  }

  Future<void> cancelScheduledNotificationById({required int id}) async {
    await _requestPermission();
    _flutterLocalNotificationsPlugin.cancel(id);
  }
}