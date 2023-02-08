import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:my_solved/models/User.dart';
import 'package:my_solved/models/search/suggestion.dart';
import 'package:my_solved/models/user/Badges.dart';
import 'package:my_solved/models/user/Grass.dart';
import 'package:my_solved/models/user/Top_100.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._privateConstructor();

  NetworkService._privateConstructor();

  factory NetworkService() {
    return _instance;
  }

  // Request for Home
  Future<User> requestUser(String name) async {
    final response = await http
        .get(Uri.parse("https://solved.ac/api/v3/user/show?handle=$name"));
    final statusCode = response.statusCode;

    if (statusCode == 200) {
      User user = User.fromJson(jsonDecode(response.body));
      return user;
    } else {
      throw Exception('Failed to load');
    }
  }

  Future<Badges> requestBadges(String name) async {
    final response = await http.get(
        Uri.parse(
            "https://solved.ac/api/v3/user/available_badges?handle=$name"),
        headers: {'x-solvedac-language': 'ko'});
    final statusCode = response.statusCode;

    if (statusCode == 200) {
      Badges badges = Badges.fromJson(jsonDecode(response.body));
      return badges;
    } else {
      throw Exception('Failed to load');
    }
  }

  Future<Grass> requestStreak(String name) async {
    final response = await http.get(Uri.parse(
        "https://solved.ac/api/v3/user/grass?handle=$name&topic=today-solved"));
    final statusCode = response.statusCode;

    if (statusCode == 200) {
      Grass streak = Grass.fromJson(jsonDecode(response.body));
      return streak;
    } else {
      throw Exception('Failed to load');
    }
  }

  Future<Top_100> requestTop100(String name) async {
    final response = await http
        .get(Uri.parse("https://solved.ac/api/v3/user/top_100?handle=$name"));
    final statusCode = response.statusCode;

    if (statusCode == 200) {
      Top_100 top100 = Top_100.fromJson(jsonDecode(response.body));
      return top100;
    } else {
      throw Exception('Failed to load');
    }
  }

  // Request for Search
  Future<SearchSuggestion> requestSearch(String query) async {
    final response = await http.get(Uri.parse("https://solved.ac/api/v3/search/suggestion?query=$query"));
    final statusCode = response.statusCode;

    if (statusCode == 200) {
      SearchSuggestion search = SearchSuggestion.fromJson(jsonDecode(response.body));
      return search;
    } else {
      throw Exception('Fail to load');
    }
  }
}