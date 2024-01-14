import 'dart:async';
import 'dart:convert';
port 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:my_solved/models/badge.dart';
import 'package:my_solved/models/search/object.dart';
import 'package:my_solved/models/search/suggestion.dart';
import 'package:my_solved/models/site_stats.dart';
import 'package:my_solved/models/user.dart';
import 'package:my_solved/models/user/background.dart';
import 'package:my_solved/models/user/badges.dart';
import 'package:my_solved/models/user/grass.dart';
import 'package:my_solved/models/user/organizations.dart';
import 'package:my_solved/models/user/tag_ratings.dart';
import 'package:my_solved/models/user/top_100.dart';
import 'package:my_solved/services/user_service.dart';

import '../models/contest.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._privateConstructor();

  NetworkService._privateConstructor();

  factory NetworkService() {
    return _instance;
  }

  // Request for Home
  Future<User> requestUser(String handle) async {
    final response = await http
        .get(Uri.parse("https://solved.ac/api/v3/user/show?handle=$handle"));
    final statusCode = response.statusCode;

    if (statusCode == 200) {
      User user = User.fromJson(jsonDecode(response.body));
      return user;
    } else {
      throw Exception('Failed to load');
    }
  }

  Future<Organizations> requestOrganizations(String handle) async {
    final response = await http.get(Uri.parse(
        "https://solved.ac/api/v3/user/organizations?handle=$handle"));
    final statusCode = response.statusCode;

    if (statusCode == 200) {
      return Organizations.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load');
    }
  }

  Future<Background> requestBackground(String backgroundId) async {
    final response = await http.get(Uri.parse(
        "https://solved.ac/api/v3/background/show?backgroundId=$backgroundId"));
    final statusCode = response.statusCode;

    if (statusCode == 200) {
      return Background.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load');
    }
  }

  Future<Badge> requestBadge(String badgeId) async {
    final response = await http.get(
        Uri.parse("https://solved.ac/api/v3/badge/show?badgeId=$badgeId"),
        headers: {'x-solvedac-language': 'ko'});
    final statusCode = response.statusCode;

    if (statusCode == 200) {
      return Badge.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load');
    }
  }

  Future<Badges> requestBadges(String handle) async {
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

  Future<Grass> requestStreak(String handle) async {
    final response = await http.get(Uri.parse(
        "https://solved.ac/api/v3/user/grass?handle=$handle&topic=default"));
    final statusCode = response.statusCode;

    if (statusCode == 200) {
      Grass streak = Grass.fromJson(jsonDecode(response.body));
      return streak;
    } else {
      throw Exception('Failed to load');
    }
  }

  Future<Top100> requestTop100(String handle) async {
    final response = await http
        .get(Uri.parse("https://solved.ac/api/v3/user/top_100?handle=$handle"));
    final statusCode = response.statusCode;

    if (statusCode == 200) {
      Top100 top100 = Top100.fromJson(jsonDecode(response.body));
      return top100;
    } else {
      throw Exception('Failed to load');
    }
  }

  Future<List<TagRatings>> requestTagRatings(String handle) async {
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

  // Request for Search
  Future<SearchSuggestion> requestSearchSuggestion(String query) async {
    final response = await http.get(
        Uri.parse("https://solved.ac/api/v3/search/suggestion?query=$query"));
    final statusCode = response.statusCode;

    if (statusCode == 200) {
      SearchSuggestion search =
          SearchSuggestion.fromJson(jsonDecode(response.body));
      return search;
    } else {
      throw Exception('Fail to load');
    }
  }

  // 문제 검색
  Future<SearchObject> requestSearchProblem(
      String query, int? page, String? sort, String? direction) async {
    String url = "https://solved.ac/api/v3/search/problem?query=$query";
    if (page != null) {
      url += "&page=$page";
    }
    if (sort != null) {
      url += "&sort=$sort";
    }
    if (direction != null) {
      url += "&direction=$direction";
    }

    final response = await http.get(Uri.parse(url
        .replaceAll('\$me', UserService().name)
        .replaceAll(' ', '%20')
        .replaceAll('#', '%23')
        .replaceAll('@', '%40')));
    final statusCode = response.statusCode;

    if (statusCode == 200) {
      SearchObject search = SearchObject.fromJson(jsonDecode(response.body));
      return search;
    } else {
      throw Exception('Fail to load');
    }
  }

  // 사용자 검색
  Future<SearchObject> requestSearchUser(String query, int? page) async {
    String url = "https://solved.ac/api/v3/search/user?query=$query";
    if (page != null) {
      url += "&page=$page";
    }
    final response = await http.get(Uri.parse(url));
    final statusCode = response.statusCode;

    if (statusCode == 200) {
      SearchObject search = SearchObject.fromJson(jsonDecode(response.body));
      return search;
    } else {
      throw Exception('Fail to load');
    }
  }

  // 태그 검색
  Future<SearchObject> requestSearchTag(String query, int? page) async {
    String url = "https://solved.ac/api/v3/search/tag?query=$query";
    if (page != null) {
      url += "&page=$page";
    }
    final response = await http.get(Uri.parse(url));
    final statusCode = response.statusCode;

    if (statusCode == 200) {
      SearchObject search = SearchObject.fromJson(jsonDecode(response.body));
      return search;
    } else {
      throw Exception('Fail to load');
    }
  }

  Future<List<List<Contest>>> requestContests() async {
    List<Contest> upcomingContests(dom.Element element) {
      if (element.getElementsByClassName('col-md-12').length < 5) {
        return element
            .getElementsByClassName('col-md-12')[2]
            .getElementsByTagName('tbody')
            .first
            .getElementsByTagName('tr')
            .toList()
            .map((e) {
          return Contest.fromElement(e);
        }).toList();
      } else {
        return element
            .getElementsByClassName('col-md-12')[4]
            .getElementsByTagName('tbody')
            .first
            .getElementsByTagName('tr')
            .toList()
            .map<Contest>((e) {
          return Contest.fromElement(e);
        }).toList();
      }
    }

    List<Contest> ongoingContests(dom.Element element) {
      if (element.getElementsByClassName('col-md-12').length < 5) {
        return [];
      } else {
        return element
            .getElementsByClassName('col-md-12')[2]
            .getElementsByTagName('tbody')
            .first
            .getElementsByTagName('tr')
            .toList()
            .map((e) {
          return Contest.fromElement(e);
        }).toList();
      }
    }

    List<Contest> endedContests(dom.Element element) {
      final endedContestList = element
          .getElementsByClassName('col-md-12')[1]
          .getElementsByTagName('tbody')
          .first
          .getElementsByTagName('tr')
          .where(
              (element) => element.getElementsByTagName('td')[5].text == '종료')
          .toList();

      return endedContestList.map((e) {
        List<String> startTimeList = e
            .getElementsByTagName('td')[3]
            .text
            .toString()
            .replaceAll('년', '')
            .replaceAll('월', '')
            .replaceAll('일', '')
            .split(' ');
        List<String> endTimeList = e
            .getElementsByTagName('td')[4]
            .text
            .toString()
            .replaceAll('년', '')
            .replaceAll('월', '')
            .replaceAll('일', '')
            .split(' ');

        DateTime startTime = DateTime.parse(
                "${startTimeList[0].padLeft(4, "0")}-${startTimeList[1].padLeft(2, "0")}-${startTimeList[2].padLeft(2, "0")}T${startTimeList[3].padLeft(2, "0")}:00+09:00")
            .toLocal();
        DateTime endTime = DateTime.parse(
                "${endTimeList[0].padLeft(4, "0")}-${endTimeList[1].padLeft(2, "0")}-${endTimeList[2].padLeft(2, "0")}T${endTimeList[3].padLeft(2, "0")}:00+09:00")
            .toLocal();

        return Contest(
          venue: 'BOJ Open',
          name: e.getElementsByTagName('td')[0].text.trim(),
          url:
              'https://www.acmicpc.net${e.getElementsByTagName('td')[0].getElementsByTagName('a')[0].attributes['href']}',
          startTime: startTime,
          endTime: endTime,
        );
      }).toList();
    }

    final others =
        await http.get(Uri.parse("https://www.acmicpc.net/contest/other/list"));
    dom.Document docOthers = parser.parse(others.body);
    final othersStatus = others.statusCode;

    final ended = await http
        .get(Uri.parse("https://www.acmicpc.net/contest/official/list"));
    dom.Document docEnded = parser.parse(ended.body);
    final endedStatus = ended.statusCode;

    if (othersStatus != 200 || endedStatus != 200) {
      throw Exception('Failed to load');
    }

    return [
      ongoingContests(docOthers.body!),
      upcomingContests(docOthers.body!),
      endedContests(docEnded.body!),
    ];
  }

  Future<Set<int>> requestArenaContests() async {
    final response =
        await http.get(Uri.parse("https://solved.ac/api/v3/arena/contests"));
    final statusCode = response.statusCode;

    if (statusCode == 200) {
      Map<String, dynamic> contestMap = jsonDecode(response.body);
      Set<int> contestIds = {};

      for (var contests in contestMap.values) {
        for (var contest in contests) {
          if (contest['arenaBojContestId'] != null) {
            contestIds.add(contest['arenaBojContestId']);
          }
        }
      }
      return contestIds;
    } else {
      throw Exception('Fail to load');
    }
  }

  Future<SiteStats> requestSiteStats() async {
    final response =
        await http.get(Uri.parse("https://solved.ac/api/v3/site/stats"));
    final statusCode = response.statusCode;

    if (statusCode == 200) {
      SiteStats siteStats = SiteStats.fromJson(jsonDecode(response.body));
      return siteStats;
    } else {
      throw Exception('Fail to load');
    }
  }
}
