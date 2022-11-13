import 'package:flutter/material.dart';
import 'package:my_solved/providers/acmicpc/problem_api.dart';
import 'package:html/dom.dart' as dom;

class ProblemViewModel with ChangeNotifier {
  String text = '';
  bool isSubmitted = false;
  late Future<dom.Document> future;

  void textFieldChanged(String value) {
    text = value;
    notifyListeners();
  }

  void textFieldSubmitted() {
    isSubmitted = true;
    future = problemShow(text);
    notifyListeners();
  }
}
