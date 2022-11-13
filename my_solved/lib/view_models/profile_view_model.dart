import 'package:flutter/material.dart';
import 'package:my_solved/models/User.dart';
import 'package:my_solved/providers/user/show_api.dart';

class ProfileViewModel with ChangeNotifier {
  String handle = '';
  bool isSubmitted = false;
  late Future<User> future;

  void textFieldChanged(String value) {
    handle = value;
    notifyListeners();
  }

  void textFieldSubmitted() {
    isSubmitted = true;
    future = userShow(handle);
    notifyListeners();
  }
}
