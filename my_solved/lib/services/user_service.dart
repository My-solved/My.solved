import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserState { unknown, loggedIn, loading }

class UserService extends ChangeNotifier {
  static final UserService _instance = UserService._privateConstructor();
  UserState state = UserState.loading;
  String name = '';
  int streakTheme = 0;
  bool isOnIllustration = true;
  bool _disposed = false;

  UserService._privateConstructor() {
    Future<String> initName = initUserName();
    initName.then((name) {
      this.name = name;
      if (name.isNotEmpty) {
        state = UserState.loggedIn;
      } else {
        state = UserState.unknown;
      }
      notifyListeners();
    });

    Future<int> initStreak = initStreakTheme();
    initStreak.then((theme) {
      streakTheme = theme;
      notifyListeners();
    });

    Future<bool> initIllust = initIllustration();
    initIllust.then((isOn) {
      isOnIllustration = isOn;
      notifyListeners();
    });
  }

  factory UserService() {
    return _instance;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  notifyListeners() {
    if(!_disposed) {
      super.notifyListeners();
    }
  }

  void setUserName(String name) async {
    this.name = name;
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('username', name);
    notifyListeners();
  }

  Future<String> initUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? '';
  }

  void logout() async {
    state = UserState.unknown;
    name = '';
    streakTheme = 0;
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('username');
    notifyListeners();
  }

  Future<int> initStreakTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('streak') ?? 0;
  }

  void setStreakTheme(int theme) async {
    streakTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('streak', theme);
    notifyListeners();
  }

  Future<bool> initIllustration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isIllust') ?? true;
  }

  void setIllustration(bool isOn) async {
    isOnIllustration = isOn;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isIllust', isOn);
  }
}
