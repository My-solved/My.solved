import 'package:flutter/cupertino.dart';
import 'package:my_solved/providers/user/problem_stats_api.dart';

import '../models/User.dart';
import '../providers/user/show_api.dart';

import '../models/user/ProblemStats.dart';

class HomeViewModel with ChangeNotifier {
  Future<User>? future;
  Future<ProblemStats>? futurePS;

  void onInit(String handle) {
    future = userShow(handle);
    futurePS = userProblemStats(handle);
    notifyListeners();
  }
}
