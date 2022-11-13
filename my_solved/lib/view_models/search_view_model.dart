import 'package:flutter/material.dart';
import 'package:my_solved/models/search/suggestion.dart';
import 'package:my_solved/providers/search/suggestion_api.dart';

class SearchViewModel with ChangeNotifier {
  String text = '';
  bool isSubmitted = false;
  late Future<SearchSuggestion> future;

  var problems = [
    Problem(1450, '냅색문제', 1450, 2, 3.33),
    Problem(1451, '테스트문제', 11, 2, 2.12),
  ];
  var users = [User('mathking1021'), User('handle')];
  var tags = [Tag('key1', 10), Tag('key2', 10)];

  void textFieldChanged(String value) {
    text = value;
    notifyListeners();
  }

  void textFieldSubmitted() {
    isSubmitted = true;
    future = searchSuggestion(text);
    notifyListeners();
  }

  Problem dynamicToProblem(dynamic problemBefore) {
    return problemBefore as Problem;
  }
}

// ignore: todo
// TODO: - 더미 모델이므로 삭제 예정
class Problem {
  late int problemID;
  late String titleKo;
  late int acceptedUserCount;
  late int level;
  late double averageTries;

  Problem(this.problemID, this.titleKo, this.acceptedUserCount, this.level,
      this.averageTries);
}

class User {
  late String handle;

  User(this.handle);
}

class Tag {
  late String key;
  late int problemCount;

  Tag(this.key, this.problemCount);
}
