import 'package:flutter/cupertino.dart';
import 'package:my_solved/models/user/Top_100.dart';

import '../models/User.dart';
import '../models/user/Badges.dart';
import '../providers/user/available_badges_api.dart';
import '../providers/user/show_api.dart';
import '../providers/user/top_100_api.dart';

class HomeViewModel with ChangeNotifier {
  Future<User>? future;
  Future<Top_100>? futureTop;
  Future<Badges>? futureBadges;

  void onInit(String handle) {
    future = userShow(handle);
    futureTop = top_100(handle);
    futureBadges = availableBadges(handle);
    notifyListeners();
  }
}
