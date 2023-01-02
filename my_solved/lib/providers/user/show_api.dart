import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:my_solved/models/User.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<User> userShow(String handle) async {
  final response = await http
      .get(Uri.parse("https://solved.ac/api/v3/user/show?handle=$handle"));
  final statusCode = response.statusCode;

  if (statusCode == 200) {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('username', handle);
    User user = User.fromJson(jsonDecode(response.body));
    return user;
  } else {
    throw Exception('Failed to load');
  }
}
