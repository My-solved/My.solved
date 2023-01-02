import 'dart:async';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

Future<dom.Document> profileTop100(String handle) async {
  final init = await http.get(Uri.parse("https://solved.ac/profile/$handle"));
  final cookie = init.headers.toString();

  final response = await http.get(
    Uri.parse("https://solved.ac/profile/$handle"),
    headers: {
      'cookie': cookie,
    },
  );
  final statusCode = response.statusCode;
  final document = parser.parse(response.body);

  if (statusCode == 200) {
    return document;
  } else {
    throw Exception('Failed to load');
  }
}
