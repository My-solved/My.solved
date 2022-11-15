import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:my_solved/models/search/problem.dart';

Future<SearchProblem> searchProblem(String query) async {
  final response = await http
      .get(Uri.parse('https://solved.ac/api/v3/search/problem?query=$query'));
  final statusCode = response.statusCode;

  if (statusCode == 200) {
    SearchProblem searchedProblems =
        SearchProblem.fromJson(jsonDecode(response.body));
    return searchedProblems;
  } else {
    throw Exception('Failed to load');
  }
}
