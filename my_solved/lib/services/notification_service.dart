import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._privateConstructor();

  NotificationService._privateConstructor();

  factory NotificationService() {
    return _instance;
  }

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

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
    const IOSInitializationSettings iosInitializationSettings = IOSInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true);
    const AndroidInitializationSettings androidInitializationSettings = AndroidInitializationSettings('ic_notification');
    const InitializationSettings settings = InitializationSettings(android: androidInitializationSettings, iOS: iosInitializationSettings);

    _flutterLocalNotificationsPlugin.initialize(settings);
  }

  Future<void> testPush() async {
    NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails("test", "test", "test"),
      iOS: IOSNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          badgeNumber: 1
      ),
    );

    await _flutterLocalNotificationsPlugin.show(0, "test", "test push", details);
  }
}