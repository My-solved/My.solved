import 'package:flutter/material.dart';
import 'package:my_solved/models/User.dart';
import 'package:my_solved/providers/user/show_api.dart';

class ProfileDetailViewModel with ChangeNotifier {
  String handle = '';
  Future<User>? future;

  ProfileDetailViewModel(this.handle) {
    future = userShow(handle);
    notifyListeners();
  }
}
