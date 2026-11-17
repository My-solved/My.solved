import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show parseHttpDate;

import 'models/models.dart';
import 'platform/is_web.dart' as platform;

class SolvedApiException implements Exception {
  const SolvedApiException({
    this.uri,
    this.statusCode,
    this.cause,
    this.stackTrace,
    this.responseBody,
    this.retryAfter,
  });

  final Uri? uri;
  final int? statusCode;
  final Object? cause;
  final StackTrace? stackTrace;
  final String? responseBody;
  final Duration? retryAfter;

  bool get isRetryable {
    final status = statusCode;
    if (status != null) {
      return status == 408 || status == 429 || status >= 500;
    }
    return cause is TimeoutException || cause is http.ClientException;
  }

  bool get isTimeout => cause is TimeoutException;

  @override
  String toString() {
    final details = <String>[
      if (uri != null) 'uri: $uri',
      if (statusCode != null) 'statusCode: $statusCode',
      if (retryAfter != null) 'retryAfter: $retryAfter',
      if (cause != null) 'cause: $cause',
    ];
    return '${runtimeType.toString()}(${details.join(', ')})';
  }
}

class UserRequestFailed extends SolvedApiException {
  const UserRequestFailed({
    super.uri,
    super.statusCode,
    super.cause,
    super.stackTrace,
    super.responseBody,
    super.retryAfter,
  });
}

class BackgroundRequestFailed extends SolvedApiException {
  const BackgroundRequestFailed({
    super.uri,
    super.statusCode,
    super.cause,
    super.stackTrace,
    super.responseBody,
    super.retryAfter,
  });
}

class BadgeRequestFailed extends SolvedApiException {
  const BadgeRequestFailed({
    super.uri,
    super.statusCode,
    super.cause,
    super.stackTrace,
    super.responseBody,
    super.retryAfter,
  });
}

class SearchRequestFailed extends SolvedApiException {
  const SearchRequestFailed({
    super.uri,
    super.statusCode,
    super.cause,
    super.stackTrace,
    super.responseBody,
    super.retryAfter,
  });
}

class ArenaRequestFailed extends SolvedApiException {
  const ArenaRequestFailed({
    super.uri,
    super.statusCode,
    super.cause,
    super.stackTrace,
    super.responseBody,
    super.retryAfter,
  });
}

class SiteRequestFailed extends SolvedApiException {
  const SiteRequestFailed({
    super.uri,
    super.statusCode,
    super.cause,
    super.stackTrace,
    super.responseBody,
    super.retryAfter,
  });
}

enum _RequestType { user, background, badge, search, arena, site }

class SolvedApiClient {
  SolvedApiClient({
    http.Client? httpClient,
    bool? useProxy,
    Uri? apiBaseUri,
    Uri? proxyBaseUri,
    this.requestTimeout = const Duration(seconds: 10),
  })  : _httpClient = httpClient ?? http.Client(),
        _useProxy = useProxy ?? platform.isWeb,
        _apiBaseUri = _normalizeBaseUri(
          apiBaseUri ?? Uri.https('solved.ac', '/api/v3/'),
        ),
        _proxyBaseUri = _normalizeBaseUri(
          proxyBaseUri ?? Uri.https('codepoker.w8385.dev', '/solved/'),
        );

  final http.Client _httpClient;
  final bool _useProxy;
  final Uri _apiBaseUri;
  final Uri _proxyBaseUri;
  final Duration requestTimeout;

  Future<User> userShow(String handle) => _get(
        'user/show',
        queryParameters: {'handle': handle},
        requestType: _RequestType.user,
        parser: (json) => User.fromJson(json),
      );

  Future<List<Organization>> userOrganizations(String handle) => _get(
        'user/organizations',
        queryParameters: {'handle': handle},
        requestType: _RequestType.user,
        parser: (json) => json
            .map((item) => Organization.fromJson(item))
            .toList()
            .cast<Organization>(),
      );

  Future<List<Badge>> userAvailableBadges(String handle) => _get(
        'user/available_badges',
        queryParameters: {'handle': handle},
        requestType: _RequestType.user,
        parser: (json) => json['items']
            .map((item) => Badge.fromJson(item))
            .toList()
            .cast<Badge>(),
      );

  Future<Streak> userGrass(String handle, String? topic) => _get(
        'user/grass',
        queryParameters: {'handle': handle, 'topic': topic ?? 'default'},
        requestType: _RequestType.user,
        parser: (json) => Streak.fromJson(json),
      );

  Future<List<Problem>> userTop100(String handle) => _get(
        'user/top_100',
        queryParameters: {'handle': handle},
        requestType: _RequestType.user,
        parser: (json) => json['items']
            .map((item) => Problem.fromJson(item))
            .toList()
            .cast<Problem>(),
      );

  Future<List<ProblemStat>> userProblemStats(String handle) => _get(
        'user/problem_stats',
        queryParameters: {'handle': handle},
        requestType: _RequestType.user,
        parser: (json) => List<ProblemStat>.from(
          json.map((item) => ProblemStat.fromJson(item)),
        ),
      );

  Future<List<TagRating>> userTagRatings(String handle) => _get(
        'user/tag_ratings',
        queryParameters: {'handle': handle},
        requestType: _RequestType.user,
        parser: (json) =>
            List<TagRating>.from(json.map((item) => TagRating.fromJson(item))),
      );

  Future<Background> backgroundShow(String backgroundId) => _get(
        'background/show',
        queryParameters: {'backgroundId': backgroundId},
        requestType: _RequestType.background,
        parser: (json) => Background.fromJson(json),
      );

  Future<Badge> badgeShow(String badgeId) => _get(
        'badge/show',
        queryParameters: {'badgeId': badgeId},
        requestType: _RequestType.badge,
        parser: (json) => Badge.fromJson(json),
      );

  Future<SearchSuggestion> searchSuggestion(String query) => _get(
        'search/suggestion',
        queryParameters: {'query': query},
        requestType: _RequestType.search,
        parser: (json) => SearchSuggestion.fromJson(json),
      );

  Future<SearchObject> searchProblem(
    String query,
    int? page,
    String? sort,
    String? direction,
  ) =>
      _get(
        'search/problem',
        queryParameters: {
          'query': query,
          'page': page?.toString() ?? '1',
          'sort': sort ?? 'solved',
          'direction': direction ?? 'descending',
        },
        requestType: _RequestType.search,
        parser: (json) {
          json['items'] = json['items']
              .map((problem) => Problem.fromJson(problem))
              .toList()
              .cast<Problem>();
          return SearchObject.fromJson(json);
        },
      );

  Future<SearchObject> searchUser(String query, int? page) => _get(
        'search/user',
        queryParameters: {'query': query, 'page': page?.toString() ?? '1'},
        requestType: _RequestType.search,
        parser: (json) {
          json['items'] = json['items']
              .map((user) => User.fromJson(user))
              .toList()
              .cast<User>();
          return SearchObject.fromJson(json);
        },
      );

  Future<SearchObject> searchTag(String query, int? page) => _get(
        'search/tag',
        queryParameters: {'query': query, 'page': page?.toString() ?? '1'},
        requestType: _RequestType.search,
        parser: (json) {
          json['items'] = json['items']
              .map((tag) => Tag.fromJson(tag))
              .toList()
              .cast<Tag>();
          return SearchObject.fromJson(json);
        },
      );

  Future<List<ArenaContest>> arenaContests() => _get(
        'arena/contests',
        requestType: _RequestType.arena,
        parser: (json) {
          final contests = <ArenaContest>[];
          for (final status in json.keys) {
            json[status].forEach(
              (contest) => contests.add(ArenaContest.fromJson(contest)),
            );
          }
          return contests;
        },
      );

  Future<SiteStats> siteStats() => _get(
        'site/stats',
        requestType: _RequestType.site,
        parser: (json) => SiteStats.fromJson(json),
      );

  Future<T> _get<T>(
    String path, {
    Map<String, String> queryParameters = const {},
    required _RequestType requestType,
    required T Function(dynamic json) parser,
  }) async {
    final uri = _buildUri(path, queryParameters);
    late http.Response response;

    try {
      response = await _httpClient.get(uri).timeout(requestTimeout);
    } on Object catch (error, stackTrace) {
      throw _failure(
        requestType,
        uri: uri,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    late String body;
    try {
      body = _decodeBody(response);
    } on Object catch (error, stackTrace) {
      throw _failure(
        requestType,
        uri: uri,
        statusCode: response.statusCode,
        cause: error,
        stackTrace: stackTrace,
        retryAfter: _parseRetryAfter(response.headers),
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _failure(
        requestType,
        uri: uri,
        statusCode: response.statusCode,
        responseBody: body,
        retryAfter: _parseRetryAfter(response.headers),
      );
    }

    try {
      return parser(jsonDecode(body));
    } on Object catch (error, stackTrace) {
      throw _failure(
        requestType,
        uri: uri,
        statusCode: response.statusCode,
        cause: error,
        stackTrace: stackTrace,
        responseBody: body,
      );
    }
  }

  Uri _buildUri(String path, Map<String, String> queryParameters) {
    final baseUri = _useProxy ? _proxyBaseUri : _apiBaseUri;
    return baseUri.resolve(path).replace(
          queryParameters: queryParameters.isEmpty ? null : queryParameters,
        );
  }

  String _decodeBody(http.Response response) {
    return utf8.decode(response.bodyBytes);
  }

  Duration? _parseRetryAfter(Map<String, String> headers) {
    String? value;
    for (final header in headers.entries) {
      if (header.key.toLowerCase() == 'retry-after') {
        value = header.value.trim();
        break;
      }
    }
    if (value == null || value.isEmpty) return null;

    final seconds = int.tryParse(value);
    if (seconds != null) {
      return seconds < 0 ? null : Duration(seconds: seconds);
    }

    try {
      final delay = parseHttpDate(value).difference(DateTime.now().toUtc());
      return delay.isNegative ? Duration.zero : delay;
    } on FormatException {
      return null;
    }
  }

  SolvedApiException _failure(
    _RequestType requestType, {
    required Uri uri,
    int? statusCode,
    Object? cause,
    StackTrace? stackTrace,
    String? responseBody,
    Duration? retryAfter,
  }) {
    return switch (requestType) {
      _RequestType.user => UserRequestFailed(
          uri: uri,
          statusCode: statusCode,
          cause: cause,
          stackTrace: stackTrace,
          responseBody: responseBody,
          retryAfter: retryAfter,
        ),
      _RequestType.background => BackgroundRequestFailed(
          uri: uri,
          statusCode: statusCode,
          cause: cause,
          stackTrace: stackTrace,
          responseBody: responseBody,
          retryAfter: retryAfter,
        ),
      _RequestType.badge => BadgeRequestFailed(
          uri: uri,
          statusCode: statusCode,
          cause: cause,
          stackTrace: stackTrace,
          responseBody: responseBody,
          retryAfter: retryAfter,
        ),
      _RequestType.search => SearchRequestFailed(
          uri: uri,
          statusCode: statusCode,
          cause: cause,
          stackTrace: stackTrace,
          responseBody: responseBody,
          retryAfter: retryAfter,
        ),
      _RequestType.arena => ArenaRequestFailed(
          uri: uri,
          statusCode: statusCode,
          cause: cause,
          stackTrace: stackTrace,
          responseBody: responseBody,
          retryAfter: retryAfter,
        ),
      _RequestType.site => SiteRequestFailed(
          uri: uri,
          statusCode: statusCode,
          cause: cause,
          stackTrace: stackTrace,
          responseBody: responseBody,
          retryAfter: retryAfter,
        ),
    };
  }

  static Uri _normalizeBaseUri(Uri uri) {
    if (uri.path.endsWith('/')) return uri;
    return uri.replace(path: '${uri.path}/');
  }
}
