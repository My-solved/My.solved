library shared_preferences_repository;

import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesRepository {
  Future<String?> requestHandle() async {
    await Future.delayed(const Duration(seconds: 1));
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("handle");
  }

  Future<void> login({required String handle}) async {
    await Future.delayed(const Duration(seconds: 1));
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("handle", handle);
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(seconds: 1));
    final prefs = await SharedPreferences.getInstance();
    prefs.remove("handle");
  }
}
