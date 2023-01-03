import 'package:flutter/cupertino.dart';
import 'package:html/dom.dart' as dom;

import '../models/User.dart';
import '../models/user/Badges.dart';
import '../providers/solvedac/profile.dart';
import '../providers/user/available_badges_api.dart';
import '../providers/user/show_api.dart';

class HomeViewModel with ChangeNotifier {
  Future<User>? future;
  Future<dom.Document>? futureTop;
  Future<Badges>? futureBadges;

  void onInit(String handle) {
    future = userShow(handle);
    futureTop = profileTop100(handle);
    futureBadges = availableBadges(handle);
    notifyListeners();
  }
}
