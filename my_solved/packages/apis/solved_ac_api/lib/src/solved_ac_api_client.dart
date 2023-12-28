import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:solved_ac_api/solved_ac_api.dart';

class userRequestFailed implements Exception {}

class backgroundRequestFailed implements Exception {}

class badgeRequestFailed implements Exception {}

class searchRequestFailed implements Exception {}

class arenaRequestFailed implements Exception {}

class siteRequestFailed implements Exception {}

class SolvedAcApiClient {
  SolvedAcApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  static const String _baseUrl = 'solved.ac/api/v3';

  final http.Client _httpClient;

  Future<User> userShow(String handle) async {
    final userRequest = Uri.https(_baseUrl, '/user/show', {'handle': handle});

    final userResponse = await _httpClient.get(userRequest);

    if (userResponse.statusCode != 200) {
      throw userRequestFailed();
    }

    final userJson = jsonDecode(userResponse.body);

    return User.fromJson(userJson);
  }

  Future<Organizations> userOrganizations(String handle) async {
    final userRequest =
        Uri.https(_baseUrl, '/user/organizations', {'handle': handle});

    final userResponse = await _httpClient.get(userRequest);

    if (userResponse.statusCode != 200) {
      throw userRequestFailed();
    }

    final userJson = jsonDecode(userResponse.body);

    return Organizations.fromJson(userJson);
  }

  Future<Badges> userAvailableBadges(String handle) async {
    final userRequest =
        Uri.https(_baseUrl, '/user/available_badges', {'handle': handle});

    final userResponse = await _httpClient.get(userRequest);

    if (userResponse.statusCode != 200) {
      throw userRequestFailed();
    }

    final userJson = jsonDecode(userResponse.body);

    return Badges.fromJson(userJson);
  }

  Future<Grass> userGrass(String handle) async {
    final userRequest = Uri.https(_baseUrl, '/user/grass', {'handle': handle});

    final userResponse = await _httpClient.get(userRequest);

    if (userResponse.statusCode != 200) {
      throw userRequestFailed();
    }

    final userJson = jsonDecode(userResponse.body);

    return Grass.fromJson(userJson);
  }

  Future<Top100> userTop100(String handle) async {
    final userRequest =
        Uri.https(_baseUrl, '/user/top_100', {'handle': handle});

    final userResponse = await _httpClient.get(userRequest);

    if (userResponse.statusCode != 200) {
      throw userRequestFailed();
    }

    final userJson = jsonDecode(userResponse.body);

    return Top100.fromJson(userJson);
  }

  Future<List<TagRatings>> userTagRatings(String handle) async {
    final userRequest =
        Uri.https(_baseUrl, '/user/tag_ratings', {'handle': handle});

    final userResponse = await _httpClient.get(userRequest);

    if (userResponse.statusCode != 200) {
      throw userRequestFailed();
    }

    final userJson = jsonDecode(userResponse.body);

    return List<TagRatings>.from(userJson.map((x) => TagRatings.fromJson(x)));
  }

  Future<Background> backgroundShow(String backgroundId) async {
    final backgroundRequest =
        Uri.https(_baseUrl, '/background/show', {'backgroundId': backgroundId});

    final backgroundResponse = await _httpClient.get(backgroundRequest);

    if (backgroundResponse.statusCode != 200) {
      throw backgroundRequestFailed();
    }

    final backgroundJson = jsonDecode(backgroundResponse.body);

    return Background.fromJson(backgroundJson);
  }

  Future<Badge> badgeShow(String badgeId) async {
    final badgeRequest =
        Uri.https(_baseUrl, '/badge/show', {'badgeId': badgeId});

    final badgeResponse = await _httpClient.get(badgeRequest);

    if (badgeResponse.statusCode != 200) {
      throw badgeRequestFailed();
    }

    final badgeJson = jsonDecode(badgeResponse.body);

    return Badge.fromJson(badgeJson);
  }

  Future<SearchSuggestion> searchSuggestion(String query) async {
    final searchRequest =
        Uri.https(_baseUrl, '/search/suggestion', {'query': query});

    final searchResponse = await _httpClient.get(searchRequest);

    if (searchResponse.statusCode != 200) {
      throw searchRequestFailed();
    }

    final searchJson = jsonDecode(searchResponse.body);

    return SearchSuggestion.fromJson(searchJson);
  }

  Future<SearchObject> searchProblem(
      String query, int? page, String? sort, String? direction) async {
    final searchRequest = Uri.https(_baseUrl, '/search/problem', {
      'query': query,
      'page': page.toString(),
      'sort': sort,
      'direction': direction
    });

    final searchResponse = await _httpClient.get(searchRequest);

    if (searchResponse.statusCode != 200) {
      throw searchRequestFailed();
    }

    final searchJson = jsonDecode(searchResponse.body);

    return SearchObject.fromJson(searchJson);
  }

  Future<SearchObject> searchTag(String query, int? page) async {
    final searchRequest = Uri.https(
        _baseUrl, '/search/tag', {'query': query, 'page': page.toString()});

    final searchResponse = await _httpClient.get(searchRequest);

    if (searchResponse.statusCode != 200) {
      throw searchRequestFailed();
    }

    final searchJson = jsonDecode(searchResponse.body);

    return SearchObject.fromJson(searchJson);
  }

  Future<Set<int>> arenaContests() async {
    final arenaRequest = Uri.https(_baseUrl, '/arena/contests');

    final arenaResponse = await _httpClient.get(arenaRequest);

    if (arenaResponse.statusCode != 200) {
      throw arenaRequestFailed();
    }

    final arenaJson = jsonDecode(arenaResponse.body);

    return Set<int>.from(arenaJson.map((x) => x['arenaBojContestId']));
  }

  Future<SiteStats> siteStats() async {
    final siteRequest = Uri.https(_baseUrl, '/site/stats');

    final siteResponse = await _httpClient.get(siteRequest);

    if (siteResponse.statusCode != 200) {
      throw siteRequestFailed();
    }

    final siteJson = jsonDecode(siteResponse.body);

    return SiteStats.fromJson(siteJson);
  }
}
