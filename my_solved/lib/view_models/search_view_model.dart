import 'package:flutter/material.dart';

class SearchViewModel with ChangeNotifier {
  String text = '';

  void textFieldChanged(String value) {
    text = value;
    notifyListeners();
  }
}
