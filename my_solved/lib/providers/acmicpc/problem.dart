import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

Future<dom.Document> problemShow(String text) async {
  final response = await http.get(Uri.parse("https://www.acmicpc.net/problem/$text"));
  final statusCode = response.statusCode;

  final document = parser.parse(response.body);

  if (statusCode == 200){
    return document;
  } else {
    throw Exception('Failed to load');
  }
}