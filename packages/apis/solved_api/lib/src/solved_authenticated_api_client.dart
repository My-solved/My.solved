import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType, parseHttpDate;

import 'models/models.dart';
import 'solved_api_contract.dart';
import 'solved_api_v4_contract.dart';
import 'solved_bearer_authorization.dart';
import 'solved_oauth_contract.dart';
import 'solved_proxy_transport.dart';

enum SolvedAuthenticatedOperation {
  currentUser,
  rivals,
  reverseRivals,
  bookmarkFavorites,
  collection,
  myProblemVote,
  tagProgress,
  accountConsents,
}

enum SolvedAuthenticatedFailureKind {
  timeout,
  transport,
  redirect,
  unauthorized,
  forbidden,
  rateLimited,
  unexpectedStatus,
  invalidResponse,
  responseTooLarge,
}

/// A sanitized failure from a token-bound solved.ac request.
///
/// Requests are never retried automatically. [isRetryable] only tells a caller
/// whether a new explicit attempt may be reasonable.
final class SolvedAuthenticatedRequestFailed implements Exception {
  const SolvedAuthenticatedRequestFailed({
    required this.operation,
    required this.uri,
    required this.kind,
    this.statusCode,
    this.retryAfter,
    this.cause,
    this.stackTrace,
  });

  final SolvedAuthenticatedOperation operation;
  final Uri uri;
  final SolvedAuthenticatedFailureKind kind;
  final int? statusCode;
  final Duration? retryAfter;
  final Object? cause;
  final StackTrace? stackTrace;

  bool get isTimeout => kind == SolvedAuthenticatedFailureKind.timeout;

  bool get isRetryable => switch (kind) {
        SolvedAuthenticatedFailureKind.timeout ||
        SolvedAuthenticatedFailureKind.transport =>
          true,
        SolvedAuthenticatedFailureKind.rateLimited => retryAfter != null,
        SolvedAuthenticatedFailureKind.unexpectedStatus => statusCode == 408 ||
            (statusCode != null && statusCode! >= 500 && statusCode! <= 599),
        _ => false,
      };

  @override
  String toString() {
    final details = <String>[
      'operation: ${operation.name}',
      'uri: $uri',
      'kind: ${kind.name}',
      if (statusCode != null) 'statusCode: $statusCode',
      if (retryAfter != null) 'retryAfter: $retryAfter',
    ];
    return '$runtimeType(${details.join(', ')})';
  }
}

/// Token-bound client for official solved.ac v4 user operations.
///
/// The client retains only a validated access-token capability, never a
/// refresh token. It calls the configured solved-proxy exactly once per
/// request, never follows redirects, and never retries automatically.
/// An injected HTTP client must not add retries or credentials; in particular,
/// never pass a `RetryClient` or an authenticated wrapper.
final class SolvedAuthenticatedApiClient {
  SolvedAuthenticatedApiClient({
    required Uri proxyBaseUri,
    required SolvedOAuthTokenResponse token,
    http.Client? httpClient,
    this.requestTimeout = const Duration(seconds: 10),
    bool allowInsecureLoopback = false,
  })  : _authorization =
            SolvedBearerAuthorization.fromAccessToken(token.accessToken),
        _contract = SolvedApiV4Contract(proxyBaseUri: proxyBaseUri),
        _transport = SolvedProxyTransport(
          proxyBaseUri: proxyBaseUri,
          httpClient: httpClient,
          requestTimeout: requestTimeout,
          allowInsecureLoopback: allowInsecureLoopback,
        );

  final SolvedBearerAuthorization _authorization;
  final SolvedApiV4Contract _contract;
  final SolvedProxyTransport _transport;
  final Duration requestTimeout;

  bool _isClosed = false;

  Future<SolvedUserIdentity> currentUser() => _get(
        SolvedAuthenticatedOperation.currentUser,
        _contract.currentUser,
      );

  /// One page of the viewer's rivals. The token needs the `rivals` scope.
  ///
  /// An invalid [page] fails the returned future with an [ArgumentError]
  /// before any request is sent.
  Future<RivalLeaderboardResult> rivals({int? page}) => _get(
        SolvedAuthenticatedOperation.rivals,
        () => _contract.rivals(page: page),
      );

  /// One page of those who have the viewer as a rival. The token needs the
  /// `rivals` scope.
  ///
  /// An invalid [page] fails the returned future with an [ArgumentError]
  /// before any request is sent.
  Future<RivalLeaderboardResult> reverseRivals({int? page}) => _get(
        SolvedAuthenticatedOperation.reverseRivals,
        () => _contract.reverseRivals(page: page),
      );

  /// One page of other people's folders the viewer favorited. The token needs
  /// the `bookmarks` scope.
  ///
  /// An invalid [page] fails the returned future with an [ArgumentError]
  /// before any request is sent.
  Future<BookmarkFoldersResult> bookmarkFavorites({int? page}) => _get(
        SolvedAuthenticatedOperation.bookmarkFavorites,
        () => _contract.bookmarkFavorites(page: page),
      );

  /// Policy versions in force that the viewer has not agreed to. The token
  /// needs the `profile` scope.
  Future<AccountConsentsResult> accountConsents() => _get(
        SolvedAuthenticatedOperation.accountConsents,
        _contract.accountConsents,
      );

  /// The viewer's solved and tried counts per tag. The token needs the
  /// `solves` scope.
  Future<TagProgressResult> tagProgress() => _get(
        SolvedAuthenticatedOperation.tagProgress,
        _contract.tagProgress,
      );

  /// The viewer's own vote on one problem. The token needs the `votes` scope.
  ///
  /// Invalid arguments fail the returned future with an [ArgumentError]
  /// before any request is sent.
  Future<ProblemVoteMineResult> myProblemVote(int problemId, {String? sub}) =>
      _get(
        SolvedAuthenticatedOperation.myProblemVote,
        () => _contract.myProblemVote(problemId, sub: sub),
      );

  /// One page of the badges or backgrounds the viewer owns. The token needs
  /// the `collection` scope.
  ///
  /// Invalid arguments fail the returned future with an [ArgumentError]
  /// before any request is sent.
  Future<UserCollectionResult> collection({
    String? language,
    OfficialAchievementItemKind? kind,
    SolvedApiV4CollectionSort? sort,
    String? category,
    String? query,
    int? offset,
  }) =>
      _get(
        SolvedAuthenticatedOperation.collection,
        () => _contract.accountCollection(
          language: language,
          kind: kind,
          sort: sort,
          category: category,
          query: query,
          offset: offset,
        ),
      );

  Future<T> _get<T>(
    SolvedAuthenticatedOperation operation,
    SolvedApiEndpoint<T> Function() buildEndpoint,
  ) async {
    if (_isClosed) {
      throw StateError('SolvedAuthenticatedApiClient is closed');
    }

    final endpoint = buildEndpoint();
    final target = endpoint.proxy;
    final resolved = _transport.proxyBaseUri.resolve(target.path);
    final uri = target.queryParameters.isEmpty
        ? resolved
        : resolved.replace(queryParameters: target.queryParameters);

    late SolvedProxyResponse response;
    try {
      response = await _transport.getWithBearer(
        relativePath: target.path,
        queryParameters: target.queryParameters,
        authorization: _authorization,
      );
    } on SolvedProxyDeadlineExceeded catch (_, stackTrace) {
      throw SolvedAuthenticatedRequestFailed(
        operation: operation,
        uri: uri,
        kind: SolvedAuthenticatedFailureKind.timeout,
        cause: TimeoutException(
          'Authenticated request timed out',
          requestTimeout,
        ),
        stackTrace: stackTrace,
      );
    } on TimeoutException catch (error, stackTrace) {
      throw SolvedAuthenticatedRequestFailed(
        operation: operation,
        uri: uri,
        kind: SolvedAuthenticatedFailureKind.timeout,
        cause: error,
        stackTrace: stackTrace,
      );
    } on SolvedProxyResponseTooLarge catch (error, stackTrace) {
      throw SolvedAuthenticatedRequestFailed(
        operation: operation,
        uri: uri,
        kind: SolvedAuthenticatedFailureKind.responseTooLarge,
        statusCode: error.statusCode,
        stackTrace: stackTrace,
      );
    } on Object catch (error, stackTrace) {
      throw SolvedAuthenticatedRequestFailed(
        operation: operation,
        uri: uri,
        kind: SolvedAuthenticatedFailureKind.transport,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    final statusCode = response.statusCode;
    if (statusCode >= 300 && statusCode < 400) {
      throw SolvedAuthenticatedRequestFailed(
        operation: operation,
        uri: uri,
        kind: SolvedAuthenticatedFailureKind.redirect,
        statusCode: statusCode,
      );
    }
    if (statusCode == 401) {
      throw SolvedAuthenticatedRequestFailed(
        operation: operation,
        uri: uri,
        kind: SolvedAuthenticatedFailureKind.unauthorized,
        statusCode: statusCode,
      );
    }
    if (statusCode == 403) {
      throw SolvedAuthenticatedRequestFailed(
        operation: operation,
        uri: uri,
        kind: SolvedAuthenticatedFailureKind.forbidden,
        statusCode: statusCode,
      );
    }
    if (statusCode == 429) {
      throw SolvedAuthenticatedRequestFailed(
        operation: operation,
        uri: uri,
        kind: SolvedAuthenticatedFailureKind.rateLimited,
        statusCode: statusCode,
        retryAfter: _parseRetryAfter(response.headers),
      );
    }
    if (statusCode != 200) {
      throw SolvedAuthenticatedRequestFailed(
        operation: operation,
        uri: uri,
        kind: SolvedAuthenticatedFailureKind.unexpectedStatus,
        statusCode: statusCode,
      );
    }

    try {
      _requireJsonContentType(response.headers);
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return endpoint.decode(json);
    } on Object catch (_, stackTrace) {
      throw SolvedAuthenticatedRequestFailed(
        operation: operation,
        uri: uri,
        kind: SolvedAuthenticatedFailureKind.invalidResponse,
        statusCode: statusCode,
        cause: const FormatException(
          'Authenticated response metadata or body is invalid',
        ),
        stackTrace: stackTrace,
      );
    }
  }

  /// Releases only an internally-created HTTP client.
  void close() {
    if (_isClosed) return;
    _isClosed = true;
    _transport.close();
  }

  @override
  String toString() => 'SolvedAuthenticatedApiClient(<redacted>)';
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
      'Authenticated response Content-Type is missing',
    );
  }

  final mediaType = MediaType.parse(value);
  if (mediaType.mimeType.toLowerCase() != 'application/json') {
    throw const FormatException(
      'Authenticated response must be application/json',
    );
  }
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

  final deltaMatch = RegExp(r'[0-9]+').matchAsPrefix(value);
  if (deltaMatch != null && deltaMatch.end == value.length) {
    final seconds = int.tryParse(value);
    return seconds == null ? null : Duration(seconds: seconds);
  }

  try {
    final delay = parseHttpDate(value).difference(DateTime.now().toUtc());
    return delay.isNegative ? Duration.zero : delay;
  } on FormatException {
    return null;
  }
}
