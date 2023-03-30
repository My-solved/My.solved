import 'package:flutter/cupertino.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:my_solved/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/contest.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance =
      NotificationService._privateConstructor();

  NotificationService._privateConstructor();

  bool _disposed = false;

  factory NotificationService() {
    return _instance;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
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
  void setStreakPush(int hour, int minute) async {
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

  Future<bool> getContestPush(String contestName) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = contestName.hashCode.toString();
    return prefs.getBool(key) ?? false;
  }

  void setContestPush(String contestName, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = contestName.hashCode.toString();
    prefs.setBool(key, value);
    notifyListeners();
  }

  // 대회 알림 id: 대회 해시
  void toggleContestPush(Contest contest) async {
    final bool isPush = await getContestPush(contest.name);

    if (isPush) {
      _flutterLocalNotificationsPlugin.cancel(contest.name.hashCode);
      setContestPush(contest.name, false);
    } else {
      NotificationDetails details = NotificationDetails(
        android: AndroidNotificationDetails(
          'Contest_Notification',
          'Contest_Notification',
          channelDescription: 'Contest_Notification',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            badgeNumber: 1,
            interruptionLevel: InterruptionLevel.timeSensitive),
      );

      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

      int beforeHour = UserService().contestAlarmHour;
      int beforeMinute = UserService().contestAlarmMinute;

      tz.TZDateTime startDate = tz.TZDateTime(
        tz.local,
        contest.startTime.year,
        contest.startTime.month,
        contest.startTime.day,
        contest.startTime.hour,
        contest.startTime.minute,
      ).subtract(Duration(hours: beforeHour, minutes: beforeMinute));

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        contest.name.hashCode,
        beforeHour + beforeMinute == 0
            ? '대회 시작!'
            : ('${beforeHour == 0 ? '' : '$beforeHour시간'} ${beforeMinute == 0 ? '$beforeMinute분' : ''} 뒤 대회 시작!'),
        contest.name,
        startDate,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true,
      );
      setContestPush(contest.name, true);
    }
    notifyListeners();
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
