import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/user/Badges.dart';

Future<Badges> availableBadges(String handle) async {
  final response = await http.get(
      Uri.parse(
          "https://solved.ac/api/v3/user/available_badges?handle=$handle"),
      headers: {'x-solvedac-language': 'ko'});
  final statusCode = response.statusCode;

  if (statusCode == 200) {
    Badges badges = Badges.fromJson(jsonDecode(response.body));
    return badges;
  } else {
    throw Exception('Failed to load');
  }
}
