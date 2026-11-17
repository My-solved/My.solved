import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show parseHttpDate;

import 'models/models.dart';
import 'platform/is_web.dart' as platform;
import 'solved_api_contract.dart';

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
    SolvedApiContract contract = const SolvedApiV3Contract(),
    this.requestTimeout = const Duration(seconds: 10),
  })  : _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null,
        _useProxy = useProxy ?? platform.isWeb,
        _apiBaseUri = apiBaseUri == null ? null : _normalizeBaseUri(apiBaseUri),
        _proxyBaseUri =
            proxyBaseUri == null ? null : _normalizeBaseUri(proxyBaseUri),
        _contract = contract;

  final http.Client _httpClient;
  final bool _ownsHttpClient;
  final bool _useProxy;
  final Uri? _apiBaseUri;
  final Uri? _proxyBaseUri;
  final SolvedApiContract _contract;
  final Duration requestTimeout;

  bool _isClosed = false;

  /// Releases the internally-created HTTP client.
  ///
  /// A client supplied through the constructor remains owned by the caller and
  /// is never closed here.
  void close() {
    if (_isClosed) return;
    _isClosed = true;
    if (_ownsHttpClient) _httpClient.close();
  }

  Future<UserProfile> userShow(String handle) =>
      _get(_contract.userShow(handle), requestType: _RequestType.user);

  Future<List<Organization>> userOrganizations(String handle) =>
      _get(_contract.userOrganizations(handle), requestType: _RequestType.user);

  Future<List<Badge>> userAvailableBadges(String handle) => _get(
        _contract.userAvailableBadges(handle),
        requestType: _RequestType.user,
      );

  Future<ProfileStreak> userGrass(String handle, String? topic) =>
      _get(_contract.userGrass(handle, topic), requestType: _RequestType.user);

  Future<List<Problem>> userTop100(String handle) =>
      _get(_contract.userTop100(handle), requestType: _RequestType.user);

  Future<List<ProfileTierStat>> userProblemStats(String handle) =>
      _get(_contract.userProblemStats(handle), requestType: _RequestType.user);

  Future<List<ProfileTagRating>> userTagRatings(String handle) =>
      _get(_contract.userTagRatings(handle), requestType: _RequestType.user);

  Future<ProfileBackgroundAsset> backgroundShow(String backgroundId) => _get(
        _contract.backgroundShow(backgroundId),
        requestType: _RequestType.background,
      );

  Future<ProfileBadgeAsset> badgeShow(String badgeId) =>
      _get(_contract.badgeShow(badgeId), requestType: _RequestType.badge);

  Future<SearchSuggestion> searchSuggestion(String query) =>
      _get(_contract.searchSuggestion(query), requestType: _RequestType.search);

  Future<SearchObject> searchProblem(
    String query,
    int? page,
    String? sort,
    String? direction,
  ) =>
      _get(
        _contract.searchProblem(query, page, sort, direction),
        requestType: _RequestType.search,
      );

  Future<SearchObject> searchUser(String query, int? page) =>
      _get(_contract.searchUser(query, page), requestType: _RequestType.search);

  Future<SearchObject> searchTag(String query, int? page) =>
      _get(_contract.searchTag(query, page), requestType: _RequestType.search);

  Future<List<ArenaContest>> arenaContests() =>
      _get(_contract.arenaContests(), requestType: _RequestType.arena);

  Future<SiteStats> siteStats() =>
      _get(_contract.siteStats(), requestType: _RequestType.site);

  Future<T> _get<T>(
    SolvedApiEndpoint<T> endpoint, {
    required _RequestType requestType,
  }) async {
    final uri = _buildUri(endpoint);
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
      return endpoint.decode(jsonDecode(body));
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

  Uri _buildUri<T>(SolvedApiEndpoint<T> endpoint) {
    final target = _useProxy ? endpoint.proxy : endpoint.direct;
    final overrideBaseUri = _useProxy ? _proxyBaseUri : _apiBaseUri;
    final baseUri = overrideBaseUri ?? target.baseUri;
    return baseUri.resolve(target.path).replace(
          queryParameters:
              target.queryParameters.isEmpty ? null : target.queryParameters,
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
