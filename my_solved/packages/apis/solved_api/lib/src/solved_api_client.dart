import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:solved_api/solved_api.dart';

class UserRequestFailed implements Exception {}

class BackgroundRequestFailed implements Exception {}

class BadgeRequestFailed implements Exception {}

class SearchRequestFailed implements Exception {}

class ArenaRequestFailed implements Exception {}

class SiteRequestFailed implements Exception {}

class SolvedApiClient {
  SolvedApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  static const String _baseUrl = 'solved.ac';

  final http.Client _httpClient;

  Future<User> userShow(String handle) async {
    final userRequest =
        Uri.https(_baseUrl, '/api/v3/user/show', {'handle': handle});

    final userResponse = await _httpClient.get(userRequest);

    if (userResponse.statusCode != 200) {
      throw UserRequestFailed();
    }

    final userJson = jsonDecode(userResponse.body);

    return User.fromJson(userJson);
  }

  Future<Organizations> userOrganizations(String handle) async {
    final userRequest =
        Uri.https(_baseUrl, '/api/v3/user/organizations', {'handle': handle});

    final userResponse = await _httpClient.get(userRequest);

    if (userResponse.statusCode != 200) {
      throw UserRequestFailed();
    }

    final userJson = jsonDecode(userResponse.body);

    return Organizations.fromJson(userJson);
  }

  Future<Badges> userAvailableBadges(String handle) async {
    final userRequest = Uri.https(
        _baseUrl, '/api/v3/user/available_badges', {'handle': handle});

    final userResponse = await _httpClient.get(userRequest);

    if (userResponse.statusCode != 200) {
      throw UserRequestFailed();
    }

    final userJson = jsonDecode(userResponse.body);

    return Badges.fromJson(userJson);
  }

  Future<Grass> userGrass(String handle, String? topic) async {
    final userRequest = Uri.https(_baseUrl, '/api/v3/user/grass',
        {'handle': handle, 'topic': topic ?? 'default'});

    final userResponse = await _httpClient.get(userRequest);

    if (userResponse.statusCode != 200) {
      throw UserRequestFailed();
    }

    final userJson = jsonDecode(userResponse.body);

    return Grass.fromJson(userJson);
  }

  Future<Top100> userTop100(String handle) async {
    final userRequest =
        Uri.https(_baseUrl, '/api/v3/user/top_100', {'handle': handle});

    final userResponse = await _httpClient.get(userRequest);

    if (userResponse.statusCode != 200) {
      throw UserRequestFailed();
    }

    final userJson = jsonDecode(userResponse.body);

    return Top100.fromJson(userJson);
  }

  Future<List<TagRatings>> userTagRatings(String handle) async {
    final userRequest =
        Uri.https(_baseUrl, '/api/v3/user/tag_ratings', {'handle': handle});

    final userResponse = await _httpClient.get(userRequest);

    if (userResponse.statusCode != 200) {
      throw UserRequestFailed();
    }

    final userJson = jsonDecode(userResponse.body);

    return List<TagRatings>.from(userJson.map((x) => TagRatings.fromJson(x)));
  }

  Future<Background> backgroundShow(String backgroundId) async {
    final backgroundRequest = Uri.https(
        _baseUrl, '/api/v3/background/show', {'backgroundId': backgroundId});

    final backgroundResponse = await _httpClient.get(backgroundRequest);

    if (backgroundResponse.statusCode != 200) {
      throw BackgroundRequestFailed();
    }

    final backgroundJson = jsonDecode(backgroundResponse.body);

    return Background.fromJson(backgroundJson);
  }

  Future<Badge> badgeShow(String badgeId) async {
    final badgeRequest =
        Uri.https(_baseUrl, '/api/v3/badge/show', {'badgeId': badgeId});

    final badgeResponse = await _httpClient.get(badgeRequest);

    if (badgeResponse.statusCode != 200) {
      throw BadgeRequestFailed();
    }

    final badgeJson = jsonDecode(badgeResponse.body);

    return Badge.fromJson(badgeJson);
  }

  Future<SearchSuggestion> searchSuggestion(String query) async {
    final searchRequest =
        Uri.https(_baseUrl, '/api/v3/search/suggestion', {'query': query});

    final searchResponse = await _httpClient.get(searchRequest);

    if (searchResponse.statusCode != 200) {
      throw SearchRequestFailed();
    }

    final searchJson = jsonDecode(searchResponse.body);

    return SearchSuggestion.fromJson(searchJson);
  }

  Future<SearchObject> searchProblem(
      String query, int? page, String? sort, String? direction) async {
    final searchRequest = Uri.https(_baseUrl, '/api/v3/search/problem', {
      'query': query,
      'page': page.toString(),
      'sort': sort,
      'direction': direction
    });

    final searchResponse = await _httpClient.get(searchRequest);

    if (searchResponse.statusCode != 200) {
      throw SearchRequestFailed();
    }

    final searchJson = jsonDecode(searchResponse.body);

    return SearchObject.fromJson(searchJson);
  }

  Future<SearchObject> searchTag(String query, int? page) async {
    final searchRequest = Uri.https(_baseUrl, '/api/v3/search/tag',
        {'query': query, 'page': page.toString()});

    final searchResponse = await _httpClient.get(searchRequest);

    if (searchResponse.statusCode != 200) {
      throw SearchRequestFailed();
    }

    final searchJson = jsonDecode(searchResponse.body);

    return SearchObject.fromJson(searchJson);
  }

  Future<List<ArenaContest>> arenaContests() async {
    final arenaRequest = Uri.https(_baseUrl, '/api/v3/arena/contests');

    final arenaResponse = await _httpClient.get(arenaRequest);

    if (arenaResponse.statusCode != 200) {
      throw ArenaRequestFailed();
    }

    final arenaJson = jsonDecode(arenaResponse.body);

    final List<ArenaContest> arenaContests = [];
    for (var status in arenaJson.keys) {
      arenaJson[status].forEach((contest) {
        arenaContests.add(ArenaContest.fromJson(contest));
      });
    }
    return arenaContests;
  }

  Future<SiteStats> siteStats() async {
    final siteRequest = Uri.https(_baseUrl, '/api/v3/site/stats');

    final siteResponse = await _httpClient.get(siteRequest);

    if (siteResponse.statusCode != 200) {
      throw SiteRequestFailed();
    }

    final siteJson = jsonDecode(siteResponse.body);

    return SiteStats.fromJson(siteJson);
  }
}
