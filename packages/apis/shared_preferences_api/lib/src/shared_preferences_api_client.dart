import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesApiClient {
  Future<void> setString({
    required String key,
    required String value,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
  }

  Future<void> setBool({
    required String key,
    required bool value,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, value);
  }

  Future<void> setInt({
    required String key,
    required int value,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(key, value);
  }

  Future<String?> getString({
    required String key,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<bool?> getBool({
    required String key,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  Future<int?> getInt({
    required String key,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }

  Future<void> removeByKey({
    required String key,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(key);
  }
}