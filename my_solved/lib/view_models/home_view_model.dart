import 'package:flutter/cupertino.dart';
import 'package:html/dom.dart' as dom;

import '../models/User.dart';
import '../providers/solvedac/profile.dart';
import '../providers/user/show_api.dart'as dom;

class HomeViewModel with ChangeNotifier {
  Future<User>? future;
  Future<dom.Document>? futureTop;

  void onInit(String handle) {
    future = userShow(handle);
    futureTop = profileTop100(handle);
    notifyListeners();
  }
}
