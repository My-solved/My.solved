import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'solved_bearer_authorization.dart';

/// Internal bounded transport for typed `solved-proxy` operations.
///
/// This file is intentionally not exported from `solved_api.dart`. Public
/// clients retain responsibility for endpoint semantics and failure mapping.
final class SolvedProxyTransport {
  SolvedProxyTransport({
    required Uri proxyBaseUri,
    http.Client? httpClient,
    Duration requestTimeout = const Duration(seconds: 10),
    bool allowInsecureLoopback = false,
  })  : proxyBaseUri = _validateProxyBaseUri(
          proxyBaseUri,
          allowInsecureLoopback: allowInsecureLoopback,
        ),
        requestTimeout = _validateRequestTimeout(requestTimeout),
        _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null;

  static const int maximumPayloadBytes = 64 * 1024;
  static const int maximumPublicResponseBytes = 5 * 1024 * 1024;

  final Uri proxyBaseUri;
  final Duration requestTimeout;
  final http.Client _httpClient;
  final bool _ownsHttpClient;

  bool _isClosed = false;

  /// Sends one bounded form POST without following redirects or interpreting
  /// its response.
  Future<SolvedProxyResponse> postForm({
    required String relativePath,
    required Map<String, String> fields,
  }) {
    if (_isClosed) {
      throw StateError('SolvedProxyTransport is closed');
    }

    final uri = _resolveRelativePath(relativePath);
    final abortTrigger = Completer<void>();
    final request = http.AbortableRequest(
      'POST',
      uri,
      abortTrigger: abortTrigger.future,
    )
      ..followRedirects = false
      ..maxRedirects = 0
      ..headers['accept'] = 'application/json'
      ..bodyFields = fields;
    if (request.bodyBytes.length > maximumPayloadBytes) {
      throw const SolvedProxyRequestTooLarge();
    }

    return _sendAndRead(
      request,
      maximumResponseBytes: maximumPayloadBytes,
    ).timeout(
      requestTimeout,
      onTimeout: () {
        abortTrigger.complete();
        throw const SolvedProxyDeadlineExceeded();
      },
    );
  }

  /// Sends one bounded public GET without following redirects or interpreting
  /// its response.
  ///
  /// OAuth and authenticated operations remain hard-limited to 64 KiB. A
  /// larger limit must be selected explicitly for a known public operation.
  Future<SolvedProxyResponse> getPublic({
    required String relativePath,
    Map<String, String> queryParameters = const <String, String>{},
    int maximumResponseBytes = maximumPayloadBytes,
  }) {
    if (_isClosed) {
      throw StateError('SolvedProxyTransport is closed');
    }

    _validateMaximumResponseBytes(maximumResponseBytes);
    final resolvedPath = _resolveRelativePath(relativePath);
    final uri = queryParameters.isEmpty
        ? resolvedPath
        : resolvedPath.replace(queryParameters: queryParameters);
    final abortTrigger = Completer<void>();
    final request = http.AbortableRequest(
      'GET',
      uri,
      abortTrigger: abortTrigger.future,
    )
      ..followRedirects = false
      ..maxRedirects = 0
      ..headers['accept'] = 'application/json';

    return _sendAndRead(
      request,
      maximumResponseBytes: maximumResponseBytes,
    ).timeout(
      requestTimeout,
      onTimeout: () {
        abortTrigger.complete();
        throw const SolvedProxyDeadlineExceeded();
      },
    );
  }

  /// Sends one bounded authenticated GET without following redirects or
  /// interpreting its response.
  Future<SolvedProxyResponse> getWithBearer({
    required String relativePath,
    required SolvedBearerAuthorization authorization,
  }) {
    if (_isClosed) {
      throw StateError('SolvedProxyTransport is closed');
    }

    final uri = _resolveRelativePath(relativePath);
    final abortTrigger = Completer<void>();
    final request = http.AbortableRequest(
      'GET',
      uri,
      abortTrigger: abortTrigger.future,
    )
      ..followRedirects = false
      ..maxRedirects = 0
      ..headers['accept'] = 'application/json'
      ..headers['authorization'] = authorization.headerValue;

    return _sendAndRead(
      request,
      maximumResponseBytes: maximumPayloadBytes,
    ).timeout(
      requestTimeout,
      onTimeout: () {
        abortTrigger.complete();
        throw const SolvedProxyDeadlineExceeded();
      },
    );
  }

  /// Releases only an internally-created HTTP client.
  void close() {
    if (_isClosed) return;
    _isClosed = true;
    if (_ownsHttpClient) _httpClient.close();
  }

  Uri _resolveRelativePath(String relativePath) {
    final rawSegments = relativePath.split('/');
    var hasUnsafeSegment = false;
    for (final rawSegment in rawSegments) {
      try {
        final decodedSegment = Uri.decodeComponent(rawSegment);
        if (decodedSegment.isEmpty ||
            decodedSegment == '.' ||
            decodedSegment == '..' ||
            decodedSegment.contains('/') ||
            decodedSegment.contains('\\')) {
          hasUnsafeSegment = true;
        }
      } on FormatException {
        hasUnsafeSegment = true;
      }
    }

    late Uri relativeUri;
    try {
      relativeUri = Uri.parse(relativePath);
    } on FormatException {
      throw ArgumentError.value(
        relativePath,
        'relativePath',
        'Must be a safe relative solved-proxy path',
      );
    }

    if (relativePath.isEmpty ||
        relativePath.startsWith('/') ||
        relativePath.contains('\\') ||
        relativeUri.isAbsolute ||
        relativeUri.hasQuery ||
        relativeUri.hasFragment ||
        relativeUri.pathSegments.isEmpty ||
        hasUnsafeSegment) {
      throw ArgumentError.value(
        relativePath,
        'relativePath',
        'Must be a safe relative solved-proxy path',
      );
    }

    final resolved = proxyBaseUri.resolveUri(relativeUri);
    final baseSegments = proxyBaseUri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
    final resolvedSegments = resolved.pathSegments;
    final remainsBeneathBase = resolvedSegments.length > baseSegments.length &&
        Iterable<int>.generate(baseSegments.length).every(
          (index) => resolvedSegments[index] == baseSegments[index],
        );
    if (resolved.scheme != proxyBaseUri.scheme ||
        resolved.host != proxyBaseUri.host ||
        resolved.port != proxyBaseUri.port ||
        !remainsBeneathBase) {
      throw ArgumentError.value(
        relativePath,
        'relativePath',
        'Must remain beneath the solved-proxy base path',
      );
    }
    return resolved;
  }

  Future<SolvedProxyResponse> _sendAndRead(
    http.Request request, {
    required int maximumResponseBytes,
  }) async {
    final response = await _httpClient.send(request);
    final builder = BytesBuilder(copy: false);
    await for (final chunk in response.stream) {
      if (builder.length + chunk.length > maximumResponseBytes) {
        throw SolvedProxyResponseTooLarge(response.statusCode);
      }
      builder.add(chunk);
    }
    return SolvedProxyResponse(
      uri: request.url,
      statusCode: response.statusCode,
      headers: response.headers,
      bodyBytes: builder.takeBytes(),
    );
  }
}

final class SolvedProxyResponse {
  const SolvedProxyResponse({
    required this.uri,
    required this.statusCode,
    required this.headers,
    required this.bodyBytes,
  });

  final Uri uri;
  final int statusCode;
  final Map<String, String> headers;
  final Uint8List bodyBytes;
}

final class SolvedProxyRequestTooLarge implements Exception {
  const SolvedProxyRequestTooLarge();
}

final class SolvedProxyDeadlineExceeded implements Exception {
  const SolvedProxyDeadlineExceeded();
}

final class SolvedProxyResponseTooLarge implements Exception {
  const SolvedProxyResponseTooLarge(this.statusCode);

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
  var canonicalHost = uri.host.toLowerCase();
  while (canonicalHost.endsWith('.')) {
    canonicalHost = canonicalHost.substring(0, canonicalHost.length - 1);
  }
  final isSolvedAcHost =
      canonicalHost == 'solved.ac' || canonicalHost.endsWith('.solved.ac');
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

void _validateMaximumResponseBytes(int value) {
  if (value <= 0 || value > SolvedProxyTransport.maximumPublicResponseBytes) {
    throw ArgumentError.value(
      value,
      'maximumResponseBytes',
      'Must be between 1 and '
          '${SolvedProxyTransport.maximumPublicResponseBytes} bytes',
    );
  }
}
