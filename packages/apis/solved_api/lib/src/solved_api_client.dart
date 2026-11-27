import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType, parseHttpDate;

import 'models/models.dart';
import 'platform/is_web.dart' as platform;
import 'solved_api_contract.dart';
import 'solved_api_v4_contract.dart';
import 'solved_proxy_transport.dart';

/// Sanitized marker for an official v4 response that exceeded its byte cap.
final class SolvedApiResponseTooLarge implements Exception {
  const SolvedApiResponseTooLarge();

  @override
  String toString() => 'SolvedApiResponseTooLarge()';
}

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
    if (cause is SolvedApiResponseTooLarge) return false;
    final status = statusCode;
    if (status != null) {
      return status == 408 || status == 429 || (status >= 500 && status <= 599);
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

class AchievementRequestFailed extends SolvedApiException {
  const AchievementRequestFailed({
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

class RankingRequestFailed extends SolvedApiException {
  const RankingRequestFailed({
    super.uri,
    super.statusCode,
    super.cause,
    super.stackTrace,
    super.responseBody,
    super.retryAfter,
  });
}

class SourceRequestFailed extends SolvedApiException {
  const SourceRequestFailed({
    super.uri,
    super.statusCode,
    super.cause,
    super.stackTrace,
    super.responseBody,
    super.retryAfter,
  });
}

enum _RequestType {
  user,
  achievement,
  background,
  badge,
  search,
  site,
  ranking,
  source,
}

class SolvedApiClient {
  /// Creates a legacy v3 client.
  ///
  /// Official v4 callers must use [SolvedApiClient.officialV4] so the endpoint
  /// contract and bounded transport cannot disagree about their gateway.
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
        _contract = contract,
        _v4Contract = null,
        _v4PublicTransport = null;

  /// Creates one credential-safe official v4 client over `solved-proxy`.
  ///
  /// The injected HTTP client remains caller-owned and must not add retries or
  /// credentials. Every public v4 request is sent exactly once through the
  /// same validated gateway with a bounded response.
  factory SolvedApiClient.officialV4({
    required Uri proxyBaseUri,
    required http.Client httpClient,
    Duration requestTimeout = const Duration(seconds: 10),
    bool allowInsecureLoopback = false,
  }) {
    final transport = SolvedProxyTransport(
      proxyBaseUri: proxyBaseUri,
      httpClient: httpClient,
      requestTimeout: requestTimeout,
      allowInsecureLoopback: allowInsecureLoopback,
    );
    return SolvedApiClient._officialV4(
      httpClient: httpClient,
      contract: SolvedApiV4Contract(proxyBaseUri: transport.proxyBaseUri),
      transport: transport,
      requestTimeout: requestTimeout,
    );
  }

  SolvedApiClient._officialV4({
    required http.Client httpClient,
    required SolvedApiV4Contract contract,
    required SolvedProxyTransport transport,
    required this.requestTimeout,
  })  : _httpClient = httpClient,
        _ownsHttpClient = false,
        _useProxy = false,
        _apiBaseUri = null,
        _proxyBaseUri = null,
        _contract = const SolvedApiV3Contract(),
        _v4Contract = contract,
        _v4PublicTransport = transport;

  final http.Client _httpClient;
  final bool _ownsHttpClient;
  final bool _useProxy;
  final Uri? _apiBaseUri;
  final Uri? _proxyBaseUri;
  final SolvedApiContract _contract;
  final SolvedApiV4Contract? _v4Contract;
  final SolvedProxyTransport? _v4PublicTransport;
  final Duration requestTimeout;

  bool _isClosed = false;

  /// Whether this instance has the credential-safe contract needed for v4 calls.
  ///
  /// When true, legacy v3 methods fail before issuing a transport request.
  bool get supportsV4 => _v4Contract != null;

  /// Releases the internally-created HTTP client.
  ///
  /// A client supplied through the constructor remains owned by the caller and
  /// is never closed here.
  void close() {
    if (_isClosed) return;
    _isClosed = true;
    _v4PublicTransport?.close();
    if (_ownsHttpClient) _httpClient.close();
  }

  Future<UserProfile> userShow(String handle) => _get(
        _requireLegacyContract().userShow(handle),
        requestType: _RequestType.user,
      );

  Future<ProfileStreak> userGrass(String handle, String? topic) => _get(
        _requireLegacyContract().userGrass(handle, topic),
        requestType: _RequestType.user,
      );

  Future<List<ProfileTierStat>> userProblemStats(String handle) => _get(
        _requireLegacyContract().userProblemStats(handle),
        requestType: _RequestType.user,
      );

  Future<List<ProfileTagRating>> userTagRatings(String handle) => _get(
        _requireLegacyContract().userTagRatings(handle),
        requestType: _RequestType.user,
      );

  Future<ProfileBackgroundAsset> backgroundShow(String backgroundId) => _get(
        _requireLegacyContract().backgroundShow(backgroundId),
        requestType: _RequestType.background,
      );

  Future<ProfileBadgeAsset> badgeShow(String badgeId) => _get(
        _requireLegacyContract().badgeShow(badgeId),
        requestType: _RequestType.badge,
      );

  /// Requests the official v4 profile through its credential-holding proxy.
  Future<OfficialUserProfile> v4UserProfile(String handle) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.userProfile(handle),
      requestType: _RequestType.user,
    );
  }

  Future<ProfileActivityResult> v4UserActivity(
    String handle, {
    required DateTime from,
    required DateTime to,
  }) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.userActivity(handle, from: from, to: to),
      requestType: _RequestType.user,
    );
  }

  Future<ProfileActivityFeedResult> v4UserActivityFeed(
    String handle, {
    String? before,
    String? from,
    String? to,
    int? limit,
  }) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.userActivityFeed(
        handle,
        before: before,
        from: from,
        to: to,
        limit: limit,
      ),
      requestType: _RequestType.user,
    );
  }

  Future<ProfileReputationResult> v4UserReputation(
    String handle, {
    SolvedApiV4ReputationRange? range,
  }) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.userReputation(handle, range: range),
      requestType: _RequestType.user,
    );
  }

  Future<ProfileRatingHistoryResult> v4UserRatingHistory(
    String handle, {
    SolvedApiV4RatingHistoryRange? range,
  }) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.userRatingHistory(handle, range: range),
      requestType: _RequestType.user,
    );
  }

  Future<ProfileTagLevelHistogramResult> v4UserTagLevelHistogram(
    String handle,
    String key,
  ) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.userTagLevelHistogram(handle, key),
      requestType: _RequestType.user,
    );
  }

  Future<ProfileAchievementsResult> v4UserAchievements(
    String handle, {
    String? language,
    String? versusHandle,
  }) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.userAchievements(
        handle,
        language: language,
        versusHandle: versusHandle,
      ),
      requestType: _RequestType.user,
    );
  }

  Future<ProfileAchievementSummaryResult> v4UserAchievementSummary(
    String handle,
  ) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.userAchievementSummary(handle),
      requestType: _RequestType.user,
    );
  }

  Future<ProfileBadgeStandResult> v4UserBadgeStand(String handle) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.userBadgeStand(handle),
      requestType: _RequestType.user,
    );
  }

  Future<AchievementCatalogResult> v4AchievementCatalog({
    String? language,
  }) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.achievementCatalog(language: language),
      requestType: _RequestType.achievement,
    );
  }

  Future<ProblemAchievementsResult> v4AchievementsForProblem(
    int problemId, {
    String? language,
  }) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.achievementsForProblem(problemId, language: language),
      requestType: _RequestType.achievement,
    );
  }

  Future<OfficialAchievementItem> v4AchievementItem(
    OfficialAchievementItemKind kind,
    String key,
  ) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.achievementItem(kind, key),
      requestType: switch (kind) {
        OfficialAchievementItemKind.background => _RequestType.background,
        OfficialAchievementItemKind.badge => _RequestType.badge,
      },
    );
  }

  Future<AchievementHoldersResult> v4AchievementHolders(
    OfficialAchievementItemKind kind,
    String key, {
    SolvedApiV4AchievementHolderSort? sort,
    int? page,
  }) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.achievementHolders(kind, key, sort: sort, page: page),
      requestType: _RequestType.achievement,
    );
  }

  Future<ProfileBackgroundAsset?> v4BackgroundShow(String key) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.backgroundShow(key),
      requestType: _RequestType.background,
    );
  }

  Future<ProfileBadgeAsset> v4BadgeShow(String key) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.badgeShow(key),
      requestType: _RequestType.badge,
    );
  }

  Future<ProblemDetailResult> v4ProblemDetail(
    int problemId, {
    String? sub,
  }) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.problemDetail(problemId, sub: sub),
      requestType: _RequestType.search,
    );
  }

  Future<ProblemSearchResult> v4SearchProblems(
    String query, {
    int page = 1,
    SolvedApiV4ProblemSort sort = SolvedApiV4ProblemSort.id,
    SolvedApiV4SearchDirection direction = SolvedApiV4SearchDirection.asc,
    String? seed,
  }) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.searchProblems(
        query,
        page: page,
        sort: sort,
        direction: direction,
        seed: seed,
      ),
      requestType: _RequestType.search,
    );
  }

  Future<UserSearchResult> v4SearchUsers(
    String query, {
    SolvedApiV4UserSort sort = SolvedApiV4UserSort.rating,
  }) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.searchUsers(query, sort: sort),
      requestType: _RequestType.search,
    );
  }

  Future<RankingLeaderboardResult> v4RankingUsers({
    int? page,
    SolvedApiV4UserSort? sort,
  }) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.rankingUsers(page: page, sort: sort),
      requestType: _RequestType.ranking,
    );
  }

  Future<RankingRegionsResult> v4RankingRegions() {
    final contract = _requireV4Contract();
    return _getV4(
      contract.rankingRegions(),
      requestType: _RequestType.ranking,
    );
  }

  Future<RankingAffiliationsResult> v4RankingAffiliations({
    String? query,
    String? language,
  }) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.rankingAffiliations(query: query, language: language),
      requestType: _RequestType.ranking,
    );
  }

  Future<RankingAffiliationBoardResult> v4RankingAffiliationBoard({
    int? page,
    OfficialUserProfileAffiliationType? affiliationType,
    String? language,
  }) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.rankingAffiliationBoard(
        page: page,
        affiliationType: affiliationType,
        language: language,
      ),
      requestType: _RequestType.ranking,
    );
  }

  Future<AffiliationDetailResult> v4AffiliationDetail(
    int id, {
    String? language,
  }) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.affiliationDetail(id, language: language),
      requestType: _RequestType.ranking,
    );
  }

  Future<RankingTagsResult> v4RankingTags({String? language}) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.rankingTags(language: language),
      requestType: _RequestType.ranking,
    );
  }

  Future<SearchSuggestionResult> v4SearchSuggestions(
    String topic, {
    String? value,
  }) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.searchSuggestions(topic, value: value),
      requestType: _RequestType.search,
    );
  }

  Future<ProblemSearchAnalysisResult> v4AnalyzeProblemSearch({
    String? query,
  }) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.analyzeProblemSearch(query: query),
      requestType: _RequestType.search,
    );
  }

  Future<RandomProblemResult> v4RandomProblem({String? query}) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.randomProblem(query: query),
      requestType: _RequestType.search,
    );
  }

  Future<SiteStatsResult> v4SiteStats() {
    final contract = _requireV4Contract();
    return _getV4(
      contract.siteStats(),
      requestType: _RequestType.site,
    );
  }

  Future<SourceLookupResult> v4SourceContest(
    String ojId,
    String nativeId,
  ) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.sourceContest(ojId, nativeId),
      requestType: _RequestType.source,
    );
  }

  Future<SourceLookupResult> v4SourceGroup(
    String ojId,
    String nativeId,
  ) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.sourceGroup(ojId, nativeId),
      requestType: _RequestType.source,
    );
  }

  Future<SearchObject<TagSearchItem>> v4SearchTags(
    String query, {
    int page = 1,
  }) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.searchTags(query, page: page),
      requestType: _RequestType.search,
    );
  }

  Future<TagDetailResult> v4TagDetail(String key) {
    final contract = _requireV4Contract();
    return _getV4(
      contract.tagDetail(key),
      requestType: _RequestType.search,
    );
  }

  Future<SearchObject<ProblemSearchItem>> searchProblem(
    String query,
    int? page,
    String? sort,
    String? direction,
  ) =>
      _get(
        _requireLegacyContract().searchProblem(query, page, sort, direction),
        requestType: _RequestType.search,
      );

  Future<SearchObject<UserSearchItem>> searchUser(String query, int? page) =>
      _get(
        _requireLegacyContract().searchUser(query, page),
        requestType: _RequestType.search,
      );

  Future<SearchObject<TagSearchItem>> searchTag(String query, int? page) =>
      _get(
        _requireLegacyContract().searchTag(query, page),
        requestType: _RequestType.search,
      );

  Future<T> _getV4<T>(
    SolvedApiEndpoint<T> endpoint, {
    required _RequestType requestType,
  }) async {
    if (_isClosed) {
      throw StateError('SolvedApiClient is closed');
    }
    final transport = _requireV4Transport();
    final target = endpoint.proxy;
    final uri = _withQueryParameters(
      transport.proxyBaseUri.resolve(target.path),
      target.queryParameters,
    );

    late SolvedProxyResponse response;
    try {
      response = await transport.getPublic(
        relativePath: target.path,
        queryParameters: target.queryParameters,
        maximumResponseBytes: SolvedProxyTransport.maximumPublicResponseBytes,
      );
    } on SolvedProxyDeadlineExceeded catch (_, stackTrace) {
      throw _failure(
        requestType,
        uri: uri,
        cause: TimeoutException(
          'Official solved.ac v4 request timed out',
          requestTimeout,
        ),
        stackTrace: stackTrace,
      );
    } on TimeoutException catch (error, stackTrace) {
      throw _failure(
        requestType,
        uri: uri,
        cause: error,
        stackTrace: stackTrace,
      );
    } on SolvedProxyResponseTooLarge catch (error, stackTrace) {
      throw _failure(
        requestType,
        uri: uri,
        statusCode: error.statusCode,
        cause: const SolvedApiResponseTooLarge(),
        stackTrace: stackTrace,
      );
    } on Object catch (error, stackTrace) {
      throw _failure(
        requestType,
        uri: uri,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (response.statusCode != 200) {
      throw _failure(
        requestType,
        uri: uri,
        statusCode: response.statusCode,
        retryAfter: response.statusCode == 429
            ? _parseRetryAfter(response.headers)
            : null,
      );
    }

    try {
      _requireJsonContentType(response.headers);
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return endpoint.decode(json);
    } on Object catch (_, stackTrace) {
      throw _failure(
        requestType,
        uri: uri,
        statusCode: response.statusCode,
        cause: const FormatException(
          'Official solved.ac v4 response metadata or body is invalid',
        ),
        stackTrace: stackTrace,
      );
    }
  }

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

  SolvedApiV4Contract _requireV4Contract() {
    final contract = _v4Contract;
    if (contract == null) {
      throw StateError('A SolvedApiV4Contract is required for v4 requests');
    }
    return contract;
  }

  SolvedProxyTransport _requireV4Transport() {
    final transport = _v4PublicTransport;
    if (transport == null) {
      throw StateError(
        'SolvedApiClient.officialV4 is required for v4 requests',
      );
    }
    return transport;
  }

  SolvedApiContract _requireLegacyContract() {
    if (_v4Contract != null) {
      throw StateError(
        'Legacy solved.ac v3 requests are disabled when v4 is configured',
      );
    }
    return _contract;
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

    final isAsciiDigits = value.codeUnits.every(
      (codeUnit) => codeUnit >= 0x30 && codeUnit <= 0x39,
    );
    if (isAsciiDigits) {
      final seconds = int.tryParse(value);
      if (seconds != null) return Duration(seconds: seconds);
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
      _RequestType.achievement => AchievementRequestFailed(
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
      _RequestType.site => SiteRequestFailed(
          uri: uri,
          statusCode: statusCode,
          cause: cause,
          stackTrace: stackTrace,
          responseBody: responseBody,
          retryAfter: retryAfter,
        ),
      _RequestType.ranking => RankingRequestFailed(
          uri: uri,
          statusCode: statusCode,
          cause: cause,
          stackTrace: stackTrace,
          responseBody: responseBody,
          retryAfter: retryAfter,
        ),
      _RequestType.source => SourceRequestFailed(
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

Uri _withQueryParameters(Uri uri, Map<String, String> queryParameters) {
  if (queryParameters.isEmpty) return uri;
  final query = queryParameters.entries.map((entry) {
    final encoded = Uri(
      queryParameters: <String, String>{entry.key: entry.value},
    ).query;
    return entry.value.isEmpty ? '$encoded=' : encoded;
  }).join('&');
  return uri.replace(query: query);
}

void _requireJsonContentType(Map<String, String> headers) {
  String? value;
  for (final header in headers.entries) {
    if (header.key.toLowerCase() == 'content-type') {
      value = header.value;
      break;
    }
  }
  if (value == null) {
    throw const FormatException(
      'Official solved.ac v4 response Content-Type is missing',
    );
  }

  final mediaType = MediaType.parse(value);
  if (mediaType.mimeType.toLowerCase() != 'application/json') {
    throw const FormatException(
      'Official solved.ac v4 response must be application/json',
    );
  }
}
