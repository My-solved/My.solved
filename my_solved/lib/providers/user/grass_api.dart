import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/user/Grass.dart';

Future<Grass> grass(String handle) async {
  final response = await http.get(Uri.parse(
      "https://solved.ac/api/v3/user/grass?handle=$handle&topic=today-solved"));
  final statusCode = response.statusCode;

  if (statusCode == 200) {
    Grass grass = Grass.fromJson(jsonDecode(response.body));
    return grass;
  } else {
    throw Exception('Failed to load');
  }
}
