import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:my_solved/model/search/suggestion.dart';

Future<SearchSuggestion> searchSuggestion(String query) async {
  var url =
      Uri.parse("https://solved.ac/api/v3/search/suggestion?query=" + query);
  final response = await http.get(url);
  final statusCode = response.statusCode;

  if (statusCode == 200) {
    SearchSuggestion searchedSuggestions =
        SearchSuggestion.fromJson(jsonDecode(response.body));
    return searchedSuggestions;
  } else {
    throw Exception('Failed to load');
  }
}
