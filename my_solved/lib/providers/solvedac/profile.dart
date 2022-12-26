import 'dart:async';
import 'dart:developer' as developer;

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

Future<dom.Document> profileTop100(String handle) async {
  final init = await http.get(Uri.parse("https://solved.ac/profile/$handle"));
  final cookie = init.headers.toString();
  developer.log(init.toString());
  developer.log(cookie.toString());
  final response = await http.get(
    Uri.parse("https://solved.ac/profile/$handle"),
    headers: {
      'cookie': cookie,
    },
  );

  final statusCode = response.statusCode;

  // if (statusCode == 400) {
  //   throw Exception('Failed to load');
  // } else if (statusCode == 200) {
  //   dom.Document document = parser.parse(response.body);
  //   return document;
  // } else {
  //   throw Exception('Failed to load');
  // }

  // final document = parser.parse(response.body);
  // developer.log(document.getElementsByClassName('css-1948bce').toString());

  final document = parser.parse(response.body);
  developer.log(document.body!
      .getElementsByClassName('css-1wnvjz2')[1]
      .getElementsByTagName('img')
      .first
      .attributes['src']
      .toString()
      .replaceAll('https://static.solved.ac/tier_small/', 'lib/assets/tiers/'));

  if (statusCode == 200) {
    return document;
  } else {
    throw Exception('Failed to load');
  }
}
