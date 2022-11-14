import 'package:flutter/material.dart';
import 'package:my_solved/providers/acmicpc/problem_api.dart';
import 'package:html/dom.dart' as dom;

class ProblemDetailViewModel with ChangeNotifier {
  Future<dom.Document>? future;

  ProblemDetailViewModel(int problemId) {
    future = problemShow('$problemId');
    notifyListeners();
  }
}
