import 'package:flutter/cupertino.dart';

import '../models/User.dart';
import '../providers/user/show_api.dart';

class HomeViewModel with ChangeNotifier {
  String handle = 'w8385';
  Future<User>? future;

  void onInit() {
    future = userShow(handle);
    notifyListeners();
  }
}
