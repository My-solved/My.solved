import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:my_solved/models/Problem.dart';

Future<Problem> problemShow() async {
  final response = await http
      .get(Uri.parse('https://solved.ac/api/v3/problem/show?problemId=13705'));
  final statusCode = response.statusCode;

  if (statusCode == 200) {
    Problem searchedProblems = Problem.fromJson(jsonDecode(response.body));
    return searchedProblems;
  } else {
    throw Exception('Failed to load');
  }
}
