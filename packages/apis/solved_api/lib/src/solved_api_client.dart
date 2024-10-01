import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
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
  static const String _bypassUrl = 'codepoker.w8385.dev';

  final http.Client _httpClient;

  Future<User> userShow(String handle) async {
    final userRequest =
        Uri.https(_baseUrl, '/api/v3/user/show', {'handle': handle});

    http.Response userResponse;

    try {
      if (GetPlatform.isWeb) {
        final bypassRequest =
            Uri.https(_bypassUrl, '/solved/user/show', {'handle': handle});

        userResponse = await _httpClient.get(bypassRequest);
      } else {
        userResponse = await _httpClient.get(userRequest);
      }
    } catch (e) {
      throw UserRequestFailed();
    }

    final userJson = jsonDecode(userResponse.body);

    return User.fromJson(userJson);
  }

  Future<List<Organization>> userOrganizations(String handle) async {
    final userRequest =
        Uri.https(_baseUrl, '/api/v3/user/organizations', {'handle': handle});

    http.Response userResponse;

    try {
      if (GetPlatform.isWeb) {
        final bypassRequest = Uri.https(
            _bypassUrl, '/solved/user/organizations', {'handle': handle});

        userResponse = await _httpClient.get(bypassRequest);
      } else {
        userResponse = await _httpClient.get(userRequest);
      }
    } catch (e) {
      throw UserRequestFailed();
    }

    final userJson = jsonDecode(userResponse.body);

    return userJson
        .map((i) => Organization.fromJson(i))
        .toList()
        .cast<Organization>();
  }

  Future<List<Badge>> userAvailableBadges(String handle) async {
    final userRequest = Uri.https(
        _baseUrl, '/api/v3/user/available_badges', {'handle': handle});

    http.Response userResponse;

    try {
      if (GetPlatform.isWeb) {
        final bypassRequest = Uri.https(
            _bypassUrl, '/solved/user/available_badges', {'handle': handle});

        userResponse = await _httpClient.get(bypassRequest);
      } else {
        userResponse = await _httpClient.get(userRequest);
      }
    } catch (e) {
      throw UserRequestFailed();
    }

    final userJson = jsonDecode(userResponse.body);

    return userJson['items']
        .map((i) => Badge.fromJson(i))
        .toList()
        .cast<Badge>();
  }

  Future<Streak> userGrass(String handle, String? topic) async {
    final userRequest = Uri.https(_baseUrl, '/api/v3/user/grass',
        {'handle': handle, 'topic': topic ?? 'default'});

    http.Response userResponse;

    try {
      if (GetPlatform.isWeb) {
        final bypassRequest = Uri.https(_bypassUrl, '/solved/user/grass',
            {'handle': handle, 'topic': topic ?? 'default'});

        userResponse = await _httpClient.get(bypassRequest);
      } else {
        userResponse = await _httpClient.get(userRequest);
      }
    } catch (e) {
      throw UserRequestFailed();
    }

    final userJson = jsonDecode(userResponse.body);

    return Streak.fromJson(userJson);
  }

  Future<List<Problem>> userTop100(String handle) async {
    final userRequest =
        Uri.https(_baseUrl, '/api/v3/user/top_100', {'handle': handle});

    http.Response userResponse;

    try {
      if (GetPlatform.isWeb) {
        final bypassRequest =
            Uri.https(_bypassUrl, '/solved/user/top_100', {'handle': handle});

        userResponse = await _httpClient.get(bypassRequest);
      } else {
        userResponse = await _httpClient.get(userRequest);
      }
    } catch (e) {
      throw UserRequestFailed();
    }

    final userJson = jsonDecode(userResponse.body);

    return userJson['items']
        .map((i) => Problem.fromJson(i))
        .cast<Problem>()
        .toList();
  }

  Future<List<ProblemStat>> userProblemStats(String handle) async {
    final userRequest =
        Uri.https(_baseUrl, '/api/v3/user/problem_stats', {'handle': handle});

    http.Response userResponse;

    try {
      if (GetPlatform.isWeb) {
        final bypassRequest = Uri.https(
            _bypassUrl, '/solved/user/problem_stats', {'handle': handle});

        userResponse = await _httpClient.get(bypassRequest);
      } else {
        userResponse = await _httpClient.get(userRequest);
      }
    } catch (e) {
      throw UserRequestFailed();
    }

    final userJson = jsonDecode(userResponse.body);

    return List<ProblemStat>.from(
        userJson.map((problemStats) => ProblemStat.fromJson(problemStats)));
  }

  Future<List<TagRating>> userTagRatings(String handle) async {
    final userRequest =
        Uri.https(_baseUrl, '/api/v3/user/tag_ratings', {'handle': handle});

    http.Response userResponse;

    try {
      if (GetPlatform.isWeb) {
        final bypassRequest = Uri.https(
            _bypassUrl, '/solved/user/tag_ratings', {'handle': handle});

        userResponse = await _httpClient.get(bypassRequest);
      } else {
        userResponse = await _httpClient.get(userRequest);
      }
    } catch (e) {
      throw UserRequestFailed();
    }

    final userJson = jsonDecode(userResponse.body);

    return List<TagRating>.from(
        userJson.map((tagRating) => TagRating.fromJson(tagRating)));
  }

  Future<Background> backgroundShow(String backgroundId) async {
    final backgroundRequest = Uri.https(
        _baseUrl, '/api/v3/background/show', {'backgroundId': backgroundId});

    http.Response backgroundResponse;

    try {
      if (GetPlatform.isWeb) {
        final bypassRequest = Uri.https(_bypassUrl, '/solved/background/show',
            {'backgroundId': backgroundId});

        backgroundResponse = await _httpClient.get(bypassRequest);
      } else {
        backgroundResponse = await _httpClient.get(backgroundRequest);
      }
    } catch (e) {
      throw BackgroundRequestFailed();
    }

    final backgroundJson = jsonDecode(backgroundResponse.body);

    return Background.fromJson(backgroundJson);
  }

  Future<Badge> badgeShow(String badgeId) async {
    final badgeRequest =
        Uri.https(_baseUrl, '/api/v3/badge/show', {'badgeId': badgeId});

    http.Response badgeResponse;

    try {
      if (GetPlatform.isWeb) {
        final bypassRequest =
            Uri.https(_bypassUrl, '/solved/badge/show', {'badgeId': badgeId});

        badgeResponse = await _httpClient.get(bypassRequest);
      } else {
        badgeResponse = await _httpClient.get(badgeRequest);
      }
    } catch (e) {
      throw BadgeRequestFailed();
    }

    final badgeJson = jsonDecode(badgeResponse.body);

    return Badge.fromJson(badgeJson);
  }

  Future<SearchSuggestion> searchSuggestion(String query) async {
    final searchRequest =
        Uri.https(_baseUrl, '/api/v3/search/suggestion', {'query': query});

    http.Response searchResponse;

    try {
      if (GetPlatform.isWeb) {
        final bypassRequest = Uri.https(
            _bypassUrl, '/solved/search/suggestion', {'query': query});

        searchResponse = await _httpClient.get(bypassRequest);
      } else {
        searchResponse = await _httpClient.get(searchRequest);
      }
    } catch (e) {
      throw SearchRequestFailed();
    }

    final searchJson = jsonDecode(searchResponse.body);

    return SearchSuggestion.fromJson(searchJson);
  }

  Future<SearchObject> searchProblem(
      String query, int? page, String? sort, String? direction) async {
    final searchRequest = Uri.https(_baseUrl, '/api/v3/search/problem', {
      'query': query,
      'page': page?.toString() ?? '1',
      'sort': sort ?? 'solved',
      'direction': direction ?? 'descending',
    });

    http.Response searchResponse;

    try {
      if (GetPlatform.isWeb) {
        final bypassRequest = Uri.https(_bypassUrl, '/solved/search/problem', {
          'query': query,
          'page': page?.toString() ?? '1',
          'sort': sort ?? 'solved',
          'direction': direction ?? 'descending',
        });

        searchResponse = await _httpClient.get(bypassRequest);
      } else {
        searchResponse = await _httpClient.get(searchRequest);
      }
    } catch (e) {
      throw SearchRequestFailed();
    }

    final searchJson = jsonDecode(searchResponse.body);
    searchJson['items'] = searchJson['items']
        .map((problem) => Problem.fromJson(problem))
        .toList()
        .cast<Problem>();

    return SearchObject.fromJson(searchJson);
  }

  Future<SearchObject> searchUser(String query, int? page) async {
    final searchRequest = Uri.https(_baseUrl, '/api/v3/search/user',
        {'query': query, 'page': page?.toString() ?? '1'});

    http.Response searchResponse;

    try {
      if (GetPlatform.isWeb) {
        final bypassRequest = Uri.https(_bypassUrl, '/solved/search/user', {
          'query': query,
          'page': page?.toString() ?? '1',
        });

        searchResponse = await _httpClient.get(bypassRequest);
      } else {
        searchResponse = await _httpClient.get(searchRequest);
      }
    } catch (e) {
      throw SearchRequestFailed();
    }

    final searchJson = jsonDecode(utf8.decode(searchResponse.bodyBytes));
    searchJson['items'] = searchJson['items']
        .map((user) => User.fromJson(user))
        .toList()
        .cast<User>();

    return SearchObject.fromJson(searchJson);
  }

  Future<SearchObject> searchTag(String query, int? page) async {
    final searchRequest = Uri.https(_baseUrl, '/api/v3/search/tag',
        {'query': query, 'page': page?.toString() ?? '1'});

    http.Response searchResponse;

    try {
      if (GetPlatform.isWeb) {
        final bypassRequest = Uri.https(_bypassUrl, '/solved/search/tag', {
          'query': query,
          'page': page?.toString() ?? '1',
        });

        searchResponse = await _httpClient.get(bypassRequest);
      } else {
        searchResponse = await _httpClient.get(searchRequest);
      }
    } catch (e) {
      throw SearchRequestFailed();
    }

    final searchJson = jsonDecode(searchResponse.body);
    searchJson['items'] = searchJson['items']
        .map((tag) => Tag.fromJson(tag))
        .toList()
        .cast<Tag>();

    return SearchObject.fromJson(searchJson);
  }

  Future<List<ArenaContest>> arenaContests() async {
    final arenaRequest = Uri.https(_baseUrl, '/api/v3/arena/contests');

    http.Response arenaResponse;

    try {
      if (GetPlatform.isWeb) {
        final bypassRequest = Uri.https(_bypassUrl, '/solved/arena/contests');

        arenaResponse = await _httpClient.get(bypassRequest);
      } else {
        arenaResponse = await _httpClient.get(arenaRequest);
      }
    } catch (e) {
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

    http.Response siteResponse;

    try {
      if (GetPlatform.isWeb) {
        final bypassRequest = Uri.https(_bypassUrl, '/solved/site/stats');

        siteResponse = await _httpClient.get(bypassRequest);
      } else {
        siteResponse = await _httpClient.get(siteRequest);
      }
    } catch (e) {
      throw SiteRequestFailed();
    }

    final siteJson = jsonDecode(siteResponse.body);

    return SiteStats.fromJson(siteJson);
  }
}
