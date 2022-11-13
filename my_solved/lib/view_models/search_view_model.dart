import 'package:flutter/material.dart';
import 'package:my_solved/models/search/suggestion.dart';
import 'package:my_solved/providers/search/suggestion_api.dart';

class SearchViewModel with ChangeNotifier {
  String text = '';
  bool isSubmitted = false;
  late Future<SearchSuggestion> future;

  void textFieldChanged(String value) {
    text = value;
    notifyListeners();
  }

  void textFieldSubmitted() {
    isSubmitted = true;
    future = searchSuggestion(text);
    notifyListeners();
  }
}
