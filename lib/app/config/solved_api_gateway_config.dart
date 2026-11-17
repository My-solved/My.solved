import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:solved_api/solved_api.dart';

const solvedApiModeDefine = 'SOLVED_API_MODE';
const solvedApiV4ProxyBaseUriDefine = 'SOLVED_API_V4_PROXY_BASE_URI';
const solvedApiLegacyV3Mode = 'legacy-v3';
const solvedApiOfficialV4Mode = 'official-v4';

enum SolvedApiMode { legacyV3, officialV4 }

/// Public runtime configuration for the credential-holding solved.ac gateway.
///
/// This configuration contains only the public activation mode and gateway
/// URL. solved.ac client credentials belong on the backend and must never be
/// compiled into Flutter.
final class SolvedApiGatewayConfig {
  const SolvedApiGatewayConfig._({
    required this.mode,
    required this.v4ProxyBaseUri,
  });

  factory SolvedApiGatewayConfig.fromEnvironment() =>
      SolvedApiGatewayConfig.parse(
        mode: const String.fromEnvironment(
          solvedApiModeDefine,
          defaultValue: solvedApiLegacyV3Mode,
        ),
        v4ProxyBaseUri: const String.fromEnvironment(
          solvedApiV4ProxyBaseUriDefine,
        ),
        allowInsecureLoopback: kDebugMode,
      );

  factory SolvedApiGatewayConfig.parse({
    required String mode,
    required String v4ProxyBaseUri,
    required bool allowInsecureLoopback,
  }) {
    final parsedMode = _parseMode(mode);
    if (parsedMode == SolvedApiMode.legacyV3) {
      if (v4ProxyBaseUri.isNotEmpty) {
        throw const FormatException(
          '$solvedApiV4ProxyBaseUriDefine must be empty in $solvedApiLegacyV3Mode mode',
        );
      }
      return const SolvedApiGatewayConfig._(
        mode: SolvedApiMode.legacyV3,
        v4ProxyBaseUri: null,
      );
    }
    if (v4ProxyBaseUri.isEmpty) {
      throw const FormatException(
        '$solvedApiV4ProxyBaseUriDefine is required in $solvedApiOfficialV4Mode mode',
      );
    }
    if (v4ProxyBaseUri.trim() != v4ProxyBaseUri) {
      throw const FormatException(
        '$solvedApiV4ProxyBaseUriDefine must not contain surrounding whitespace',
      );
    }

    final uri = Uri.tryParse(v4ProxyBaseUri);
    if (uri == null || !uri.isAbsolute || uri.host.isEmpty) {
      throw const FormatException(
        '$solvedApiV4ProxyBaseUriDefine must be an absolute URI',
      );
    }
    if (_isSolvedAcHost(uri.host)) {
      throw const FormatException(
        '$solvedApiV4ProxyBaseUriDefine must point to solved-proxy, not solved.ac',
      );
    }
    if (uri.userInfo.isNotEmpty ||
        v4ProxyBaseUri.contains('@') ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException(
        '$solvedApiV4ProxyBaseUriDefine must not contain user info, a query, or a fragment',
      );
    }
    if (!_hasCanonicalGatewayPath(v4ProxyBaseUri)) {
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

    return SolvedApiGatewayConfig._(
      mode: SolvedApiMode.officialV4,
      v4ProxyBaseUri: uri,
    );
  }

  final SolvedApiMode mode;
  final Uri? v4ProxyBaseUri;

  bool get hasV4Gateway => mode == SolvedApiMode.officialV4;

  /// Whether the validated v4 gateway itself uses an HTTP loopback boundary.
  ///
  /// The parser's broad debug permission is intentionally not retained. Only
  /// an accepted HTTP loopback URI carries this effective capability forward.
  bool get usesInsecureV4Loopback => v4ProxyBaseUri?.scheme == 'http';

  SolvedApiClient createClient({required http.Client httpClient}) {
    switch (mode) {
      case SolvedApiMode.legacyV3:
        return SolvedApiClient(httpClient: httpClient);
      case SolvedApiMode.officialV4:
        return SolvedApiClient(
          httpClient: httpClient,
          v4Contract: SolvedApiV4Contract(proxyBaseUri: v4ProxyBaseUri!),
        );
    }
  }
}

SolvedApiMode _parseMode(String value) {
  switch (value) {
    case solvedApiLegacyV3Mode:
      return SolvedApiMode.legacyV3;
    case solvedApiOfficialV4Mode:
      return SolvedApiMode.officialV4;
    default:
      throw const FormatException(
        '$solvedApiModeDefine must be exactly $solvedApiLegacyV3Mode or $solvedApiOfficialV4Mode',
      );
  }
}

bool _isLoopbackHost(String host) =>
    host == 'localhost' || host == '127.0.0.1' || host == '::1';

bool _isSolvedAcHost(String host) {
  var canonicalHost = host.toLowerCase();
  while (canonicalHost.endsWith('.')) {
    canonicalHost = canonicalHost.substring(0, canonicalHost.length - 1);
  }
  return canonicalHost == 'solved.ac' ||
      canonicalHost.endsWith('.solved.ac');
}

bool _hasCanonicalGatewayPath(String value) {
  final schemeSeparator = value.indexOf('://');
  if (schemeSeparator < 0) return false;
  final pathStart = value.indexOf('/', schemeSeparator + 3);
  return pathStart >= 0 && value.substring(pathStart) == '/solved/v4/';
}
