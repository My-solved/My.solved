import 'package:flutter/cupertino.dart';
import 'package:my_solved/providers/user/problem_stats_api.dart';

import '../models/User.dart';
import '../providers/user/show_api.dart';

import '../models/user/ProblemStats.dart';

class HomeViewModel with ChangeNotifier {
  String handle = 'w8385';
  Future<User>? future;
  Future<ProblemStats>? futurePS;

  void onInit() {
    future = userShow(handle);
    futurePS = userProblemStats(handle);
    notifyListeners();
  }
}
