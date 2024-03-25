import 'package:shared_preferences_api/shared_preferences_api.dart';

class SharedPreferencesRepository {
  SharedPreferencesRepository({
    SharedPreferencesApiClient? sharedPreferencesApiClient,
  }) : _sharedPreferencesApiClient =
            sharedPreferencesApiClient ?? SharedPreferencesApiClient();

  final SharedPreferencesApiClient _sharedPreferencesApiClient;
  final String _handleKey = "handle";
  final String _isOnStreakNotificationKey = "is_on_streak_notification";
  final String _streakNotificationHourKey = "streak_notification_hour";
  final String _streakNotificationMinuteKey = "streak_notification_minute";
  final String _contestNotificationMinuteKey = "contest_notification_minute";
  final String _isOnIllustBackgroundKey = "is_on_illust_background";

  Future<String?> requestHandle() async {
    await Future.delayed(const Duration(seconds: 1));
    return await _sharedPreferencesApiClient.getString(key: _handleKey);
  }

  Future<void> login({required String handle}) async {
    await Future.delayed(const Duration(seconds: 1));
    await _sharedPreferencesApiClient.setString(key: _handleKey, value: handle);
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(seconds: 1));
    await _sharedPreferencesApiClient.removeByKey(key: _handleKey);
  }

  Future<bool> getIsOnStreakNotification() async {
    return await _sharedPreferencesApiClient.getBool(
          key: _isOnStreakNotificationKey,
        ) ??
        false;
  }

  Future<void> setIsOnStreakNotification({required bool isOn}) async {
    await _sharedPreferencesApiClient.setBool(
      key: _isOnStreakNotificationKey,
      value: isOn,
    );
  }

  Future<int?> getStreakNotificationHour() async {
    return await _sharedPreferencesApiClient.getInt(
      key: _streakNotificationHourKey,
    );
  }

  Future<void> setStreakNotificationHour({required int hour}) async {
    await _sharedPreferencesApiClient.setInt(
      key: _streakNotificationHourKey,
      value: hour,
    );
  }

  Future<int?> getStreakNotificationMinute() async {
    return await _sharedPreferencesApiClient.getInt(
      key: _streakNotificationMinuteKey,
    );
  }

  Future<void> setStreakNotificationMinute({required int minute}) async {
    await _sharedPreferencesApiClient.setInt(
      key: _streakNotificationMinuteKey,
      value: minute,
    );
  }

  Future<int> getContestNotificationMinute() async {
    return await _sharedPreferencesApiClient.getInt(
          key: _contestNotificationMinuteKey,
        ) ??
        60;
  }

  Future<void> setContestNotificationMinute({required int minute}) async {
    await _sharedPreferencesApiClient.setInt(
      key: _contestNotificationMinuteKey,
      value: minute,
    );
  }

  Future<bool> getIsOnIllustBackground() async {
    return await _sharedPreferencesApiClient.getBool(
          key: _isOnIllustBackgroundKey,
        ) ??
        true;
  }

  Future<void> setIsOnIllustBackground({required bool isShow}) async {
    await _sharedPreferencesApiClient.setBool(
      key: _isOnIllustBackgroundKey,
      value: isShow,
    );
  }
}