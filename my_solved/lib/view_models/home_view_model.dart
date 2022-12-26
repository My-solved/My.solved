import 'package:flutter/cupertino.dart';
import 'package:my_solved/providers/user/problem_stats_api.dart';

import '../models/User.dart';
import '../providers/solvedac/profile.dart';
import '../providers/user/show_api.dart';

import '../models/user/ProblemStats.dart';
import 'package:html/dom.dart' as dom;

class HomeViewModel with ChangeNotifier {
  Future<User>? future;
  // Future<List<ProblemStats>>? futurePS;
  Future<dom.Document>? futureTop;

  void onInit(String handle) {
    future = userShow(handle);
    // futurePS = userProblemStats(handle);
    futureTop = profileTop100(handle);
    notifyListeners();
  }
}
