import 'package:flutter/cupertino.dart';
import 'package:my_solved/pages/main_tab_page.dart';
import 'package:my_solved/providers/user/user_name.dart';
import 'package:provider/provider.dart';

class LoginViewModel with ChangeNotifier {
  String handle = '';

  void textFieldChanged(String userName) {
    handle = userName;
    notifyListeners();
  }

  void onTapLoginButton(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: ((context) => MainTabPage()),
      ),
    );
    Provider.of<UserName>(context, listen: false).setName(handle);
  }
}
