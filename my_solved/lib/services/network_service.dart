import 'dart:async';
import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:my_solved/models/User.dart';
import 'package:my_solved/models/search/object.dart';
import 'package:my_solved/models/search/suggestion.dart';
import 'package:my_solved/models/user/badges.dart';
import 'package:my_solved/models/user/grass.dart';
import 'package:my_solved/models/user/tag_ratings.dart';
import 'package:my_solved/models/user/top_100.dart';

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
        "https://solved.ac/api/v3/user/grass?handle=$handle&topic=today-solved"));
    final statusCode = response.statusCode;

    if (statusCode == 200) {
      Grass streak = Grass.fromJson(jsonDecode(response.body));
      return streak;
    } else {
      throw Exception('Failed to load');
    }
  }

  Future<Top_100> requestTop100(String handle) async {
    final response = await http
        .get(Uri.parse("https://solved.ac/api/v3/user/top_100?handle=$handle"));
    final statusCode = response.statusCode;

    if (statusCode == 200) {
      Top_100 top100 = Top_100.fromJson(jsonDecode(response.body));
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

  Future<dom.Document> requestContests() async {
    final response =
        await http.get(Uri.parse("https://www.acmicpc.net/contest/other/list"));
    final statusCode = response.statusCode;

    if (statusCode == 200) {
      dom.Document document = parser.parse(response.body);
      return document;
    } else {
      throw Exception('Fail to load');
    }
  }
}
