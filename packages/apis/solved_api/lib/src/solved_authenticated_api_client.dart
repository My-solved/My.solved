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
  accountWallet,
  emoticons,
  accountBackgrounds,
  accountBans,
  accountStanding,
  accountBookmarks,
  walletHistory,
  accountItems,
  accountProfile,
  accountSettings,
  updateAccountSettings,
  addBookmarkFavorite,
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

  /// Every folder the viewer owns, for the add-to-folder menu. The token
  /// needs the `bookmarks` scope.
  ///
  /// An invalid [problemId] fails the returned future with an [ArgumentError]
  /// before any request is sent.
  Future<AccountBookmarkFoldersResult> accountBookmarks({int? problemId}) =>
      _get(
        SolvedAuthenticatedOperation.accountBookmarks,
        () => _contract.accountBookmarks(problemId: problemId),
      );

  /// The items the viewer holds, and the vacation the viewer is on. The token
  /// needs the `collection` scope.
  ///
  /// An invalid [language] fails the returned future with an [ArgumentError]
  /// before any request is sent.
  Future<AccountItemsResult> accountItems({String? language}) => _get(
        SolvedAuthenticatedOperation.accountItems,
        () => _contract.accountItems(language: language),
      );

  /// The viewer's own editable profile fields and visibility flags. The token
  /// needs the `profile.personal` scope.
  Future<AccountProfileResult> accountProfile() => _get(
        SolvedAuthenticatedOperation.accountProfile,
        _contract.accountProfile,
      );

  /// The viewer's resolved settings, defaults applied. The token needs the
  /// `settings` scope.
  Future<AccountSettingsResult> accountSettings() => _get(
        SolvedAuthenticatedOperation.accountSettings,
        _contract.accountSettings,
      );

  /// The viewer's standing warnings and bans. The token needs the `standing`
  /// scope.
  Future<AccountStandingResult> accountStanding() => _get(
        SolvedAuthenticatedOperation.accountStanding,
        _contract.accountStanding,
      );

  /// The viewer's bans that can be or have been appealed. The token needs the
  /// `standing` scope.
  Future<AccountBansResult> accountBans() => _get(
        SolvedAuthenticatedOperation.accountBans,
        _contract.accountBans,
      );

  /// Backgrounds the viewer may equip, in picker order. The token needs the
  /// `collection` scope.
  Future<AccountBackgroundsResult> accountBackgrounds() => _get(
        SolvedAuthenticatedOperation.accountBackgrounds,
        _contract.accountBackgrounds,
      );

  /// The emoticon catalog with the viewer's ownership flags. The token needs
  /// the `collection` scope.
  Future<EmoticonCatalogResult> emoticons() => _get(
        SolvedAuthenticatedOperation.emoticons,
        _contract.emoticons,
      );

  /// One month of the viewer's Stardust history. The token needs the
  /// `wallet` scope.
  ///
  /// Invalid arguments fail the returned future with an [ArgumentError]
  /// before any request is sent.
  Future<WalletHistoryResult> walletHistory({
    String? month,
    String? language,
  }) =>
      _get(
        SolvedAuthenticatedOperation.walletHistory,
        () => _contract.walletHistory(month: month, language: language),
      );

  /// The viewer's Stardust balance and today's capped earnings. The token
  /// needs the `wallet` scope.
  Future<AccountWalletResult> accountWallet() => _get(
        SolvedAuthenticatedOperation.accountWallet,
        _contract.accountWallet,
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

  /// Changes some of the viewer's settings and returns every setting after
  /// the patch. The token needs the `settings.write` scope.
  ///
  /// Fields left `null` in [patch] are not sent. An out-of-range integer
  /// fails the returned future with an [ArgumentError] before any request.
  /// The request is sent once and never retried; after a timeout or
  /// transport failure the change may or may not have been applied.
  Future<AccountSettingsResult> updateAccountSettings(
    AccountSettingsPatch patch,
  ) =>
      _mutate(
        SolvedAuthenticatedOperation.updateAccountSettings,
        () => _contract.updateAccountSettings(patch),
      );

  /// Adds [handle]'s folder [slug] to the viewer's favorites. The token needs
  /// the `bookmarks.write` scope.
  ///
  /// Invalid arguments fail the returned future with an [ArgumentError]
  /// before any request. The request is sent once and never retried; after a
  /// timeout or transport failure the change may or may not have been
  /// applied.
  Future<BookmarkFavoriteState> addBookmarkFavorite(
    String handle,
    String slug,
  ) =>
      _mutate(
        SolvedAuthenticatedOperation.addBookmarkFavorite,
        () => _contract.addBookmarkFavorite(handle, slug),
      );

  Future<T> _get<T>(
    SolvedAuthenticatedOperation operation,
    SolvedApiEndpoint<T> Function() buildEndpoint,
  ) =>
      _execute(operation, () {
        final endpoint = buildEndpoint();
        final target = endpoint.proxy;
        return (
          target: target,
          decode: endpoint.decode,
          send: () => _transport.getWithBearer(
                relativePath: target.path,
                queryParameters: target.queryParameters,
                authorization: _authorization,
              ),
        );
      });

  Future<T> _mutate<T>(
    SolvedAuthenticatedOperation operation,
    SolvedApiMutation<T> Function() buildMutation,
  ) =>
      _execute(operation, () {
        final mutation = buildMutation();
        final target = mutation.proxy;
        return (
          target: target,
          decode: mutation.decode,
          send: () => _transport.sendJsonWithBearer(
                method: mutation.method.value,
                relativePath: target.path,
                queryParameters: target.queryParameters,
                authorization: _authorization,
                jsonBody: mutation.jsonBody,
              ),
        );
      });

  Future<T> _execute<T>(
    SolvedAuthenticatedOperation operation,
    _PreparedRequest<T> Function() prepare,
  ) async {
    if (_isClosed) {
      throw StateError('SolvedAuthenticatedApiClient is closed');
    }

    final request = prepare();
    final target = request.target;
    final resolved = _transport.proxyBaseUri.resolve(target.path);
    final uri = target.queryParameters.isEmpty
        ? resolved
        : resolved.replace(queryParameters: target.queryParameters);

    late SolvedProxyResponse response;
    try {
      response = await request.send();
    } on SolvedProxyRequestTooLarge {
      throw ArgumentError('The request body must not exceed 64 KiB');
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
      return request.decode(json);
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

typedef _PreparedRequest<T> = ({
  SolvedApiTarget target,
  SolvedApiDecoder<T> decode,
  Future<SolvedProxyResponse> Function() send,
});

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
