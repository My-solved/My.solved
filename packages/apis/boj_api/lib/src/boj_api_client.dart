import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../boj_api.dart';

class ContestRequestFailed implements Exception {}

class BojApiClient {
  BojApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  // static const String _baseUrl = 'codepoker.w8385.dev';
  static const String _baseUrl = '10.0.2.2:6370';

  final http.Client _httpClient;

  Future<Map<ContestType, List<Contest>>> contests() async {
    // final contestRequest = Uri.https(_baseUrl, '/boj/contests');
    final contestRequest = Uri.http(_baseUrl, '/boj/contests');

    final contestResponse = await _httpClient.get(contestRequest);

    if (contestResponse.statusCode != 200) {
      throw ContestRequestFailed();
    }

    final contestJson = jsonDecode(contestResponse.body);
    final ongoingList = contestJson['ongoing']
        .map((contest) => Contest.fromJson(contest))
        .toList()
        .cast<Contest>();
    final upcomingList = contestJson['upcoming']
        .map((contest) => Contest.fromJson(contest))
        .toList()
        .cast<Contest>();
    final endedList = contestJson['ended']
        .map((contest) => Contest.fromJson(contest))
        .toList()
        .cast<Contest>();

    final Map<ContestType, List<Contest>> contests = {
      ContestType.ongoing: ongoingList,
      ContestType.upcoming: upcomingList,
      ContestType.ended: endedList
    };

    return contests;
  }
}
