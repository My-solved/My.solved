import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_solved/app/screen/app_screen.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

  await _initLocalNotification();
  await initializeDateFormatting();

  runApp(AppScreen());
}

Future<void> _initLocalNotification() async {
  FlutterLocalNotificationsPlugin localNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  AndroidInitializationSettings androidInitializationSettings =
  const AndroidInitializationSettings("mipmap/ic_launcher");
  DarwinInitializationSettings iosInitializationSettings =
  const DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings, iOS: iosInitializationSettings);
  await localNotificationsPlugin.initialize(initializationSettings);
}
