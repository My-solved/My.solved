import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:solved_api/solved_api.dart';

const solvedApiV4ProxyBaseUriDefine = 'SOLVED_API_V4_PROXY_BASE_URI';

/// Public runtime configuration for the credential-holding solved.ac gateway.
///
/// This configuration contains only the gateway URL. solved.ac client
/// credentials belong on the backend and must never be compiled into Flutter.
final class SolvedApiGatewayConfig {
  const SolvedApiGatewayConfig._(this.v4ProxyBaseUri);

  factory SolvedApiGatewayConfig.fromEnvironment() =>
      SolvedApiGatewayConfig.parse(
        const String.fromEnvironment(solvedApiV4ProxyBaseUriDefine),
        allowInsecureLoopback: kDebugMode,
      );

  factory SolvedApiGatewayConfig.parse(
    String value, {
    required bool allowInsecureLoopback,
  }) {
    if (value.isEmpty) return const SolvedApiGatewayConfig._(null);
    if (value.trim() != value) {
      throw const FormatException(
        '$solvedApiV4ProxyBaseUriDefine must not contain surrounding whitespace',
      );
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.isAbsolute || uri.host.isEmpty) {
      throw const FormatException(
        '$solvedApiV4ProxyBaseUriDefine must be an absolute URI',
      );
    }
    if (uri.userInfo.isNotEmpty ||
        value.contains('@') ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException(
        '$solvedApiV4ProxyBaseUriDefine must not contain user info, a query, or a fragment',
      );
    }
    if (!_hasCanonicalGatewayPath(value)) {
      throw const FormatException(
        '$solvedApiV4ProxyBaseUriDefine path must be exactly /solved/v4/',
      );
    }

    final isSecure = uri.scheme == 'https';
    final isAllowedLoopback =
        allowInsecureLoopback &&
        uri.scheme == 'http' &&
        _isLoopbackHost(uri.host);
    if (!isSecure && !isAllowedLoopback) {
      throw const FormatException(
        '$solvedApiV4ProxyBaseUriDefine must use HTTPS',
      );
    }

    return SolvedApiGatewayConfig._(uri);
  }

  final Uri? v4ProxyBaseUri;

  bool get hasV4Gateway => v4ProxyBaseUri != null;

  SolvedApiClient createClient({required http.Client httpClient}) {
    final proxyBaseUri = v4ProxyBaseUri;
    return SolvedApiClient(
      httpClient: httpClient,
      v4Contract:
          proxyBaseUri == null
              ? null
              : SolvedApiV4Contract(proxyBaseUri: proxyBaseUri),
    );
  }
}

bool _isLoopbackHost(String host) =>
    host == 'localhost' || host == '127.0.0.1' || host == '::1';

bool _hasCanonicalGatewayPath(String value) {
  final schemeSeparator = value.indexOf('://');
  if (schemeSeparator < 0) return false;
  final pathStart = value.indexOf('/', schemeSeparator + 3);
  return pathStart >= 0 && value.substring(pathStart) == '/solved/v4/';
}
