import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

// User 상태의 열거형입니다.
enum UserState { loading, unknown, logedin }

// 현재 User의 이름과 상태를 판단하는 클래스입니다.
class UserService extends ChangeNotifier {
  // 싱글톤으로 사용하기 위해, 인스턴스를 선언했습니다.
  static final UserService _instance = UserService._privateConstructor();
  String _name = '';
  int _zandiTheme = 0;
  bool _isIllust = true;
  UserState state = UserState.loading;

  UserService._privateConstructor() {
    Future<String> futureName = fetchUserName();
    futureName.then((name) {
      _name = name;
      if (_name == '') {
        state = UserState.unknown;
      } else {
        state = UserState.logedin;
      }
      notifyListeners();
    });

    Future<int> futureZandiTheme = fetchZandiTheme();
    futureZandiTheme.then((zandiTheme) {
      _zandiTheme = zandiTheme;
      notifyListeners();
    });

    Future<bool> futureIllust = fetchIllust();
    futureIllust.then((isIllust) {
      _isIllust = isIllust;
      notifyListeners();
    });
  }

  factory UserService() {
    return _instance;
  }

  Future<String> fetchUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? '';
  }

  Future<int> fetchZandiTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('zandi_theme') ?? 0;
  }

  Future<bool> fetchIllust() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isIllust') ?? true;
  }

  void setUserName(String name) async {
    _name = name;
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('username', name);
  }

  void setZandiTheme(int zandiTheme) async {
    _zandiTheme = zandiTheme;
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('zandi_theme', zandiTheme);
  }

  void setIllust(bool isIllust) async {
    _isIllust = isIllust;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isIllust', isIllust);
  }

  String getUserName() {
    return _name;
  }

  int getZandiTheme() {
    return _zandiTheme;
  }

  bool getIllust() {
    return _isIllust;
  }
}
