import 'package:flutter/material.dart';

class SearchViewModel with ChangeNotifier {
  String text = '';
  bool isSubmitted = false;

  void textFieldChanged(String value) {
    text = value;
    notifyListeners();
  }

  void textFieldSubmitted() {
    isSubmitted = true;
    notifyListeners();
  }
}
