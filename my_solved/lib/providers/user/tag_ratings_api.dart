import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:my_solved/models/user/TagRatings.dart';

Future<List<TagRatings>> tagRatings(String handle) async {
  final response = await http.get(
      Uri.parse("https://solved.ac/api/v3/user/tag_ratings?handle=$handle"));
  final statusCode = response.statusCode;

  if (statusCode == 200) {
    List<TagRatings> tagRatings =
        json.decode(response.body).map<TagRatings>((json) {
      return TagRatings.fromJson(json);
    }).toList();
    return tagRatings;
  } else {
    throw Exception('Failed to load');
  }
}
