import 'package:flutter/material.dart';
import 'package:my_solved/providers/acmicpc/problem.dart';
import 'package:html/dom.dart' as dom;

class ProblemDetailViewModel with ChangeNotifier {
  Future<dom.Document>? future;
  int? problemId;

  ProblemDetailViewModel(int this.problemId) {
    future = problemShow('$problemId');
    notifyListeners();
  }
}
