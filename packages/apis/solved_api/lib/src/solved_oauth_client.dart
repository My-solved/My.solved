import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

import 'solved_oauth_contract.dart';

enum SolvedOAuthOperation { token, revoke }

enum SolvedOAuthFailureKind {
  timeout,
  transport,
  redirect,
  unexpectedStatus,
  invalidResponse,
  responseTooLarge,
}

/// A failed OAuth mutation.
///
/// OAuth mutations are never safe for automatic retry because an
/// authorization code or refresh token may have been consumed already.
sealed class SolvedOAuthRequestFailed implements Exception {
  const SolvedOAuthRequestFailed({
    required this.operation,
    required this.uri,
  });

  final SolvedOAuthOperation operation;
  final Uri uri;

  bool get isRetryable => false;
}

/// A valid documented OAuth rejection proving the mutation did not succeed.
final class SolvedOAuthRejected extends SolvedOAuthRequestFailed {
  const SolvedOAuthRejected({
    required super.operation,
    required super.uri,
    required this.statusCode,
    required this.error,
  });

  final int statusCode;
  final SolvedOAuthErrorResponse error;

  @override
  String toString() => '$runtimeType(operation: ${operation.name}, uri: $uri, '
      'statusCode: $statusCode)';
}

/// A failure where the mutation may have succeeded.
///
/// Never replay the same authorization code or refresh token after this
/// failure. A delayed or malformed response does not prove that the server did
/// not spend it.
final class SolvedOAuthOutcomeUnknown extends SolvedOAuthRequestFailed {
  const SolvedOAuthOutcomeUnknown({
    required super.operation,
    required super.uri,
    required this.kind,
    this.statusCode,
    this.cause,
    this.stackTrace,
  });

  final SolvedOAuthFailureKind kind;
  final int? statusCode;
  final Object? cause;
  final StackTrace? stackTrace;

  bool get isTimeout => kind == SolvedOAuthFailureKind.timeout;

  @override
  String toString() {
    final details = <String>[
      'operation: ${operation.name}',
      'uri: $uri',
      'kind: ${kind.name}',
      if (statusCode != null) 'statusCode: $statusCode',
    ];
    return '$runtimeType(${details.join(', ')})';
  }
}

/// Credential-free Flutter transport for solved.ac OAuth mutations.
///
/// This client calls [http.Client.send] exactly once per mutation. An injected
/// client must not add retries; in particular, never pass a `RetryClient`.
/// Requests go only to a configured `solved-proxy` v4 base URI. The client
/// never calls the direct solved.ac token endpoint, never adds app credentials
/// or a bearer token, and never follows redirects.
final class SolvedOAuthClient {
  SolvedOAuthClient({
    required Uri proxyBaseUri,
    http.Client? httpClient,
    Duration requestTimeout = const Duration(seconds: 10),
    bool allowInsecureLoopback = false,
  })  : _proxyBaseUri = _validateProxyBaseUri(
          proxyBaseUri,
          allowInsecureLoopback: allowInsecureLoopback,
        ),
        requestTimeout = _validateRequestTimeout(requestTimeout),
        _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null;

  static const int maximumPayloadBytes = 64 * 1024;

  final Uri _proxyBaseUri;
  final http.Client _httpClient;
  final bool _ownsHttpClient;
  final Duration requestTimeout;

  bool _isClosed = false;

  Future<SolvedOAuthTokenResponse> exchange(
    SolvedOAuthTokenGrant grant,
  ) async {
    final uri = _proxyBaseUri.resolve('oauth/token');
    final json = await _post(
      operation: SolvedOAuthOperation.token,
      uri: uri,
      formFields: grant.formFields,
    );
    try {
      return SolvedOAuthTokenResponse.fromJson(json);
    } on Object catch (_, stackTrace) {
      throw SolvedOAuthOutcomeUnknown(
        operation: SolvedOAuthOperation.token,
        uri: uri,
        kind: SolvedOAuthFailureKind.invalidResponse,
        statusCode: 200,
        cause: const FormatException('OAuth token response is invalid'),
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> revoke(SolvedOAuthRevokeRequest request) async {
    final uri = _proxyBaseUri.resolve('oauth/revoke');
    final json = await _post(
      operation: SolvedOAuthOperation.revoke,
      uri: uri,
      formFields: request.formFields,
    );
    if (json is! Map) {
      throw SolvedOAuthOutcomeUnknown(
        operation: SolvedOAuthOperation.revoke,
        uri: uri,
        kind: SolvedOAuthFailureKind.invalidResponse,
        statusCode: 200,
        cause: const FormatException('OAuth revocation response is invalid'),
      );
    }
  }

  /// Releases the internally-created HTTP client.
  ///
  /// An injected client remains owned by its caller.
  void close() {
    if (_isClosed) return;
    _isClosed = true;
    if (_ownsHttpClient) _httpClient.close();
  }

  Future<Object?> _post({
    required SolvedOAuthOperation operation,
    required Uri uri,
    required Map<String, String> formFields,
  }) async {
    if (_isClosed) {
      throw StateError('SolvedOAuthClient is closed');
    }

    final abortTrigger = Completer<void>();
    final request = http.AbortableRequest(
      'POST',
      uri,
      abortTrigger: abortTrigger.future,
    )
      ..followRedirects = false
      ..maxRedirects = 0
      ..headers['accept'] = 'application/json'
      ..bodyFields = formFields;
    if (request.bodyBytes.length > maximumPayloadBytes) {
      throw ArgumentError(
        'Encoded OAuth request exceeds the $maximumPayloadBytes-byte limit',
      );
    }

    late _OAuthHttpResponse response;
    try {
      response = await _sendAndRead(request).timeout(
        requestTimeout,
        onTimeout: () {
          abortTrigger.complete();
          throw TimeoutException('OAuth request timed out', requestTimeout);
        },
      );
    } on TimeoutException catch (error, stackTrace) {
      throw SolvedOAuthOutcomeUnknown(
        operation: operation,
        uri: uri,
        kind: SolvedOAuthFailureKind.timeout,
        cause: error,
        stackTrace: stackTrace,
      );
    } on _OAuthResponseTooLarge catch (error, stackTrace) {
      throw SolvedOAuthOutcomeUnknown(
        operation: operation,
        uri: uri,
        kind: SolvedOAuthFailureKind.responseTooLarge,
        statusCode: error.statusCode,
        stackTrace: stackTrace,
      );
    } on Object catch (error, stackTrace) {
      throw SolvedOAuthOutcomeUnknown(
        operation: operation,
        uri: uri,
        kind: SolvedOAuthFailureKind.transport,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (response.statusCode >= 300 && response.statusCode < 400) {
      throw SolvedOAuthOutcomeUnknown(
        operation: operation,
        uri: uri,
        kind: SolvedOAuthFailureKind.redirect,
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode != 200 &&
        response.statusCode != 400 &&
        response.statusCode != 401) {
      throw SolvedOAuthOutcomeUnknown(
        operation: operation,
        uri: uri,
        kind: SolvedOAuthFailureKind.unexpectedStatus,
        statusCode: response.statusCode,
      );
    }

    late Object? json;
    try {
      _requireJsonContentType(response.headers);
      json = jsonDecode(utf8.decode(response.bodyBytes));
    } on Object catch (_, stackTrace) {
      throw SolvedOAuthOutcomeUnknown(
        operation: operation,
        uri: uri,
        kind: SolvedOAuthFailureKind.invalidResponse,
        statusCode: response.statusCode,
        cause:
            const FormatException('OAuth response metadata or body is invalid'),
        stackTrace: stackTrace,
      );
    }

    if (response.statusCode == 200) return json;

    late SolvedOAuthErrorResponse oauthError;
    try {
      oauthError = SolvedOAuthErrorResponse.fromJson(json);
    } on Object catch (_, stackTrace) {
      throw SolvedOAuthOutcomeUnknown(
        operation: operation,
        uri: uri,
        kind: SolvedOAuthFailureKind.invalidResponse,
        statusCode: response.statusCode,
        cause: const FormatException('OAuth error response is invalid'),
        stackTrace: stackTrace,
      );
    }
    if (!_isDocumentedRejection(operation, response.statusCode, oauthError)) {
      throw SolvedOAuthOutcomeUnknown(
        operation: operation,
        uri: uri,
        kind: SolvedOAuthFailureKind.invalidResponse,
        statusCode: response.statusCode,
        cause: const FormatException(
          'OAuth error does not match the documented status contract',
        ),
      );
    }

    throw SolvedOAuthRejected(
      operation: operation,
      uri: uri,
      statusCode: response.statusCode,
      error: oauthError,
    );
  }

  Future<_OAuthHttpResponse> _sendAndRead(http.Request request) async {
    final response = await _httpClient.send(request);
    final builder = BytesBuilder(copy: false);
    await for (final chunk in response.stream) {
      if (builder.length + chunk.length > maximumPayloadBytes) {
        throw _OAuthResponseTooLarge(response.statusCode);
      }
      builder.add(chunk);
    }
    return _OAuthHttpResponse(
      statusCode: response.statusCode,
      headers: response.headers,
      bodyBytes: builder.takeBytes(),
    );
  }
}

final class _OAuthHttpResponse {
  const _OAuthHttpResponse({
    required this.statusCode,
    required this.headers,
    required this.bodyBytes,
  });

  final int statusCode;
  final Map<String, String> headers;
  final Uint8List bodyBytes;
}

final class _OAuthResponseTooLarge implements Exception {
  const _OAuthResponseTooLarge(this.statusCode);

  final int statusCode;
}

Uri _validateProxyBaseUri(
  Uri uri, {
  required bool allowInsecureLoopback,
}) {
  final isSecure = uri.scheme == 'https';
  final isLoopbackHttp = allowInsecureLoopback &&
      uri.scheme == 'http' &&
      (uri.host == 'localhost' || uri.host == '127.0.0.1' || uri.host == '::1');
  final isSolvedAcHost =
      uri.host == 'solved.ac' || uri.host.endsWith('.solved.ac');
  if (!uri.isAbsolute ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      uri.path != '/solved/v4/' ||
      (!isSecure && !isLoopbackHttp) ||
      isSolvedAcHost) {
    throw ArgumentError.value(
      uri,
      'proxyBaseUri',
      'Must be an HTTPS solved-proxy /solved/v4/ base URI '
          'or an explicitly allowed HTTP loopback equivalent',
    );
  }
  return uri;
}

Duration _validateRequestTimeout(Duration timeout) {
  if (timeout <= Duration.zero) {
    throw ArgumentError.value(timeout, 'requestTimeout', 'Must be positive');
  }
  return timeout;
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
    throw const FormatException('OAuth response Content-Type is missing');
  }

  final mediaType = MediaType.parse(value);
  if (mediaType.mimeType.toLowerCase() != 'application/json') {
    throw const FormatException('OAuth response must be application/json');
  }
}

bool _isDocumentedRejection(
  SolvedOAuthOperation operation,
  int statusCode,
  SolvedOAuthErrorResponse error,
) =>
    switch ((operation, statusCode, error.error)) {
      (
        SolvedOAuthOperation.token,
        400,
        'invalid_request' ||
            'invalid_grant' ||
            'invalid_scope' ||
            'unsupported_grant_type'
      ) =>
        true,
      (SolvedOAuthOperation.token, 401, 'invalid_client') => true,
      (SolvedOAuthOperation.revoke, 400, 'invalid_request') => true,
      (SolvedOAuthOperation.revoke, 401, 'invalid_client') => true,
      _ => false,
    };
