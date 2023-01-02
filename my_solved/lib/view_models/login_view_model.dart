import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:my_solved/pages/main_tab_page.dart';
import 'package:my_solved/services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/User.dart';
import '../providers/user/show_api.dart';

class LoginViewModel with ChangeNotifier {
  String handle = '';
  Future<User>? future;

  void textFieldChanged(String userName) {
    handle = userName;
    notifyListeners();
  }

  void onTapLoginButton(BuildContext context) {
    UserService().setUserName(handle);
    Provider.of<UserService>(context, listen: false).setUserName(handle);
    future = userShow(handle);
    future!.then((value) {
      saveName();
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainTabPage()),
          (route) => false);
    }).catchError((error) {
      showToast();
    });
  }

  void saveName() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('username', handle);
  }
}

void showToast() {
  Fluttertoast.showToast(
      msg: "존재하지 않는 닉네임입니다.",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0);
}
