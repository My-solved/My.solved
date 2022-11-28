import 'package:flutter/cupertino.dart';

class UserName with ChangeNotifier {
  String _name = '';

  String get name => _name;

  void setName(String name) {
    _name = name;
    notifyListeners();
  }
}