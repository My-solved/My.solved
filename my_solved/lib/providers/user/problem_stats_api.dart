import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../models/user/ProblemStats.dart';

Future<List<dynamic>> userProblemStats(String handle) async {
  final response = await http.get(
      Uri.parse("https://solved.ac/api/v3/user/problem_stats?handle=$handle"));
  final statusCode = response.statusCode;

  if (statusCode == 200) {
    List<ProblemStats> ps = jsonDecode(response.body);
    return ps;
  } else {
    throw Exception('Failed to load');
  }
}
