import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:my_solved/pages/main_tab_page.dart';
import 'package:my_solved/providers/user/user_name.dart';
import 'package:provider/provider.dart';

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
    Provider.of<UserName>(context, listen: false).setName(handle);
    future = userShow(handle);
    future!.then((value) {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => MainTabPage(),
        ),
      );
    })
    .catchError((error) {
      return showToast();
    });
  }
}

void showToast() {
  Fluttertoast.showToast(
      msg: "로그인 실패",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0
  );
}
