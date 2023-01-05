import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:my_solved/models/user/Top_100.dart';

Future<Top_100> top_100(String handle) async {
  final response = await http
      .get(Uri.parse("https://solved.ac/api/v3/user/top_100?handle=$handle"));
  final statusCode = response.statusCode;

  if (statusCode == 200) {
    Top_100 top_100 = Top_100.fromJson(jsonDecode(response.body));
    return top_100;
  } else {
    throw Exception('Failed to load');
  }
}
