import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesApiClient {
  Future<void> setString({
    required String key,
    required String value,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
  }

  Future<String?> getString({
    required String key,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> removeByKey({
    required String key,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(key);
  }
}