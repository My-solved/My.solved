import 'dart:async';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

import '../boj_api.dart';

class ContestRequestFailed implements Exception {}

class BojApiClient {
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
        .where((element) => element.getElementsByTagName('td')[5].text == '종료')
        .toList();

    final endedContestList = contestListElement
        .map((element) {
          element.insertBefore(
              dom.Element.tag('td')..text = 'BOJ Open', element.firstChild);
          element.getElementsByTagName('td')[2].remove();
          element.getElementsByTagName('td')[2].remove();
          return Contest.fromElement(element);
        })
        .toList()
        .cast<Contest>();
    print(endedContestList[0].name);
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

    final ongoingContestList =
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

    return (upcomingContestListElement, ongoingContestList);
  }
}
