import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show parseHttpDate;

import 'models/models.dart';
import 'platform/is_web.dart' as platform;
import 'solved_api_contract.dart';
import 'solved_api_v4_contract.dart';

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

enum _RequestType { user, background, badge, search }

class SolvedApiClient {
  SolvedApiClient({
    http.Client? httpClient,
    bool? useProxy,
    Uri? apiBaseUri,
    Uri? proxyBaseUri,
    SolvedApiContract contract = const SolvedApiV3Contract(),
    SolvedApiV4Contract? v4Contract,
    this.requestTimeout = const Duration(seconds: 10),
  })  : _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null,
        _useProxy = useProxy ?? platform.isWeb,
        _apiBaseUri = apiBaseUri == null ? null : _normalizeBaseUri(apiBaseUri),
        _proxyBaseUri =
            proxyBaseUri == null ? null : _normalizeBaseUri(proxyBaseUri),
        _contract = contract,
        _v4Contract = v4Contract;

  final http.Client _httpClient;
  final bool _ownsHttpClient;
  final bool _useProxy;
  final Uri? _apiBaseUri;
  final Uri? _proxyBaseUri;
  final SolvedApiContract _contract;
  final SolvedApiV4Contract? _v4Contract;
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

  Future<ProfileStreak> userGrass(String handle, String? topic) =>
      _get(_contract.userGrass(handle, topic), requestType: _RequestType.user);

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

  /// Requests the official v4 profile through its credential-holding proxy.
  Future<UserProfile> v4UserProfile(String handle) {
    final contract = _requireV4Contract();
    return _get(
      contract.userProfile(handle),
      requestType: _RequestType.user,
      forceProxy: contract.requiresProxy,
    );
  }

  Future<ProfileStreak> v4UserActivity(
    String handle, {
    required DateTime from,
    required DateTime to,
  }) {
    final contract = _requireV4Contract();
    return _get(
      contract.userActivity(handle, from: from, to: to),
      requestType: _RequestType.user,
      forceProxy: contract.requiresProxy,
    );
  }

  Future<ProfileContributionStats> v4UserReputation(
    String handle, {
    SolvedApiV4ReputationRange? range,
  }) {
    final contract = _requireV4Contract();
    return _get(
      contract.userReputation(handle, range: range),
      requestType: _RequestType.user,
      forceProxy: contract.requiresProxy,
    );
  }

  Future<ProfileBackgroundAsset?> v4BackgroundShow(String key) {
    final contract = _requireV4Contract();
    return _get(
      contract.backgroundShow(key),
      requestType: _RequestType.background,
      forceProxy: contract.requiresProxy,
    );
  }

  Future<ProfileBadgeAsset> v4BadgeShow(String key) {
    final contract = _requireV4Contract();
    return _get(
      contract.badgeShow(key),
      requestType: _RequestType.badge,
      forceProxy: contract.requiresProxy,
    );
  }

  Future<SearchObject<ProblemSearchItem>> searchProblem(
    String query,
    int? page,
    String? sort,
    String? direction,
  ) =>
      _get(
        _contract.searchProblem(query, page, sort, direction),
        requestType: _RequestType.search,
      );

  Future<SearchObject<UserSearchItem>> searchUser(String query, int? page) =>
      _get(_contract.searchUser(query, page), requestType: _RequestType.search);

  Future<SearchObject<TagSearchItem>> searchTag(String query, int? page) =>
      _get(_contract.searchTag(query, page), requestType: _RequestType.search);

  Future<T> _get<T>(
    SolvedApiEndpoint<T> endpoint, {
    required _RequestType requestType,
    bool forceProxy = false,
  }) async {
    final uri = _buildUri(endpoint, forceProxy: forceProxy);
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

  Uri _buildUri<T>(
    SolvedApiEndpoint<T> endpoint, {
    bool forceProxy = false,
  }) {
    final useProxy = forceProxy || _useProxy;
    final target = useProxy ? endpoint.proxy : endpoint.direct;
    final overrideBaseUri = useProxy ? _proxyBaseUri : _apiBaseUri;
    final baseUri = overrideBaseUri ?? target.baseUri;
    return baseUri.resolve(target.path).replace(
          queryParameters:
              target.queryParameters.isEmpty ? null : target.queryParameters,
        );
  }

  SolvedApiV4Contract _requireV4Contract() {
    final contract = _v4Contract;
    if (contract == null) {
      throw StateError('A SolvedApiV4Contract is required for v4 requests');
    }
    return contract;
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
    };
  }

  static Uri _normalizeBaseUri(Uri uri) {
    if (uri.path.endsWith('/')) return uri;
    return uri.replace(path: '${uri.path}/');
  }
}
