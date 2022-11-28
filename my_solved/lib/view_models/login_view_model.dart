import 'package:flutter/cupertino.dart';
import 'package:my_solved/pages/home_page.dart';

class LoginViewModel with ChangeNotifier {
  String text = '';

  void textFieldChanged(String value) {
    text = value;
    notifyListeners();
  }

  void onTapLoginButton(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: ((context) => HomePage()),
      ),
    );
  }
}
