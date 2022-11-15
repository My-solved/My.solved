import 'package:flutter/material.dart';
import 'package:my_solved/models/search/problem.dart';
import 'package:my_solved/providers/search/problem_api.dart';

class TagDetailViewModel with ChangeNotifier {
  Future<SearchProblem>? future;
  String? tagName;

  TagDetailViewModel(String this.tagName) {
    future = searchProblem('tag%3A$tagName');
    notifyListeners();
  }
}
