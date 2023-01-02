import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:my_solved/models/User.dart';
import 'package:my_solved/providers/user/show_api.dart';

import '../providers/solvedac/profile.dart';

class ProfileDetailViewModel with ChangeNotifier {
  String handle = '';
  Future<User>? future;
  Future<dom.Document>? futureTop;

  ProfileDetailViewModel(this.handle) {
    future = userShow(handle);
    futureTop = profileTop100(handle);
    notifyListeners();
  }
}
