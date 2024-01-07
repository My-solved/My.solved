import 'dart:async';

import 'package:boj_api/boj_api.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

class ContestRequestFailed implements Exception {}

final class BojApiClient {
  BojApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  static const String _baseUrl = 'acmicpc.net';

  final http.Client _httpClient;

  Future<List<Contest>> officialContestList() async {
    final contestRequest = Uri.https(_baseUrl, '/contest/official/list');

    final contestResponse = await _httpClient.get(contestRequest);

    if (contestResponse.statusCode != 200) {
      throw ContestRequestFailed();
    }

    dom.Document document = parser.parse(contestResponse.body);

    final contestListElement = document
        .getElementsByClassName('col-md-12')[1]
        .getElementsByTagName('tbody')
        .first
        .getElementsByTagName('tr')
        .where((element) => element.getElementsByTagName('td')[4].text == '종료')
        .toList();

    final endedContestList = contestListElement
        .map((element) {
          element
              .getElementsByTagName('td')
              .insert(0, dom.Element.tag('td')..text = 'BOJ Open');

          final String url =
              'https://acmicpc.net${element.getElementsByTagName('td')[1].getElementsByTagName('a')[0].attributes['href']}';
          element
              .getElementsByTagName('td')[1]
              .getElementsByTagName('a')[0]
              .attributes['href'] = url;

          element.getElementsByTagName('td').removeRange(2, 4);

          return Contest.fromElement(element);
        })
        .toList()
        .cast<Contest>();

    return endedContestList;
  }

  Future<(List<Contest>, List<Contest>)> otherContestList() async {
    final contestRequest = Uri.https(_baseUrl, '/contest/other/list');

    final contestResponse = await _httpClient.get(contestRequest);

    if (contestResponse.statusCode != 200) {
      throw ContestRequestFailed();
    }

    dom.Document document = parser.parse(contestResponse.body);

    final upcomingContestListElement = document
        .getElementsByClassName('col-md-12')[
            document.getElementsByClassName('col-md-12').length < 5 ? 2 : 4]
        .getElementsByTagName('tbody')
        .first
        .getElementsByTagName('tr')
        .toList()
        .map((e) => Contest.fromElement(e))
        .toList()
        .cast<Contest>();

    final endedContestListElement =
        document.getElementsByClassName('col-md-12').length < 5
            ? [].cast<Contest>()
            : document
                .getElementsByClassName('col-md-12')[2]
                .getElementsByTagName('tbody')
                .first
                .getElementsByTagName('tr')
                .toList()
                .map((e) => Contest.fromElement(e))
                .toList()
                .cast<Contest>();

    return (upcomingContestListElement, endedContestListElement);
  }
}
