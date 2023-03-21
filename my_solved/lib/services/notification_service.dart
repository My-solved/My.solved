import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance =
      NotificationService._privateConstructor();

  NotificationService._privateConstructor();

  factory NotificationService() {
    return _instance;
  }

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void removeBadge() {
    FlutterAppBadger.removeBadge();
  }

  Future<void> init() async {
    await _configureLocalTimeZone();
    await _initializeNotification();
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  Future<void> _initializeNotification() async {
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

    _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();
    _flutterLocalNotificationsPlugin.initialize(settings);
  }

  // 스트릭 알림 id: 2
  Future<void> setStreakPush(int hour, int minute) async {
    NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'Notification_channel',
        'Notification_channel',
        // color: const Color(0xFF11CE3C),
        channelDescription: 'Notification_channel',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: 1,
      ),
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      2,
      '오늘도 백준 한 문제, 잊지 않으셨나요?',
      '스트릭을 이어보세요!',
      _timeZoneSetting(hour, minute),
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelStreakPush() async {
    _flutterLocalNotificationsPlugin.cancel(2);
  }

  tz.TZDateTime _timeZoneSetting(int hour, int minute) {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    return scheduledDate;
  }
}
