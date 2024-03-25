import 'package:shared_preferences_api/shared_preferences_api.dart';

class SharedPreferencesRepository {
  SharedPreferencesRepository({SharedPreferencesApiClient? sharedPreferencesApiClient}) : _sharedPreferencesApiClient = sharedPreferencesApiClient ?? SharedPreferencesApiClient();

  final SharedPreferencesApiClient _sharedPreferencesApiClient;

  Future<String?> requestHandle() async {
    await Future.delayed(const Duration(seconds: 1));
    return await _sharedPreferencesApiClient.getString(key: "handle");
  }

  Future<void> login({required String handle}) async {
    await Future.delayed(const Duration(seconds: 1));
    await _sharedPreferencesApiClient.setString(key: "handle", value: handle);
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(seconds: 1));
    await _sharedPreferencesApiClient.removeByKey(key: "handle");
  }
}