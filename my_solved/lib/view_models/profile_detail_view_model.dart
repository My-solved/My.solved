import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:my_solved/models/User.dart';
import 'package:my_solved/providers/user/show_api.dart';

import '../models/user/Badges.dart';
import '../providers/solvedac/profile.dart';
import '../providers/user/available_badges_api.dart';

class ProfileDetailViewModel with ChangeNotifier {
  String handle = '';
  Future<User>? future;
  Future<dom.Document>? futureTop;
  Future<Badges>? futureBadges;

  ProfileDetailViewModel(this.handle) {
    future = userShow(handle);
    futureTop = profileTop100(handle);
    futureBadges = availableBadges(handle);
    notifyListeners();
  }
}
