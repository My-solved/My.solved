import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

// User 상태의 열거형입니다.
enum UserState { loading, unknown, logedin }

// 현재 User의 이름과 상태를 판단하는 클래스입니다.
class UserService extends ChangeNotifier {
  // 싱글톤으로 사용하기 위해, 인스턴스를 선언했습니다.
  static final UserService _instance = UserService._privateConstructor();
  String _name = '';
  UserState state = UserState.loading;

  UserService._privateConstructor() {
    Future<String> futureName = fetchName();
    futureName.then((name) {
      print(name);
      _name = name;
      if (_name == '') {
        state = UserState.unknown;
      } else {
        state = UserState.logedin;
      }
      notifyListeners();
    });
  }

  factory UserService() {
    return _instance;
  }

  Future<String> fetchName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? '';
  }
}
