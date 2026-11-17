import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:my_solved/app/config/solved_api_gateway_config.dart';
import 'package:solved_api/solved_api.dart';

const solvedOAuthClientIdDefine = 'SOLVED_OAUTH_CLIENT_ID';
const solvedOAuthRedirectUriDefine = 'SOLVED_OAUTH_REDIRECT_URI';

/// Caller-owned app composition for one optional solved.ac OAuth runtime.
///
/// Only the memory-only coordinator is exposed. The raw OAuth mutation client
/// remains private and is closed without closing the shared HTTP client.
final class SolvedOAuthRuntime {
  SolvedOAuthRuntime._({
    required SolvedOAuthClient oauthClient,
    required this.coordinator,
  }) : _oauthClient = oauthClient;

  final SolvedOAuthClient _oauthClient;
  final SolvedOAuthAuthorizationCoordinator coordinator;

  bool _isClosed = false;

  void close() {
    if (_isClosed) return;
    _isClosed = true;
    _oauthClient.close();
  }

  @override
  String toString() => 'SolvedOAuthRuntime(<redacted>)';
}

/// Public Flutter configuration for an optional solved.ac OAuth sign-in.
///
/// The client ID and redirect URI are public protocol values. The solved.ac
/// client secret remains exclusively on the configured gateway.
final class SolvedOAuthRuntimeConfig {
  const SolvedOAuthRuntimeConfig._({
    required this.clientId,
    required this.redirectUri,
    required SolvedApiGatewayConfig gatewayConfig,
    required bool allowInsecureLoopback,
  }) : _gatewayConfig = gatewayConfig,
       _allowInsecureLoopback = allowInsecureLoopback;

  factory SolvedOAuthRuntimeConfig.fromEnvironment({
    required SolvedApiGatewayConfig gatewayConfig,
  }) => SolvedOAuthRuntimeConfig.parse(
    clientId: const String.fromEnvironment(solvedOAuthClientIdDefine),
    redirectUri: const String.fromEnvironment(solvedOAuthRedirectUriDefine),
    gatewayConfig: gatewayConfig,
    allowInsecureLoopback: kDebugMode,
  );

  factory SolvedOAuthRuntimeConfig.parse({
    required String clientId,
    required String redirectUri,
    required SolvedApiGatewayConfig gatewayConfig,
    required bool allowInsecureLoopback,
  }) {
    if (clientId.isEmpty && redirectUri.isEmpty) {
      return SolvedOAuthRuntimeConfig._(
        clientId: null,
        redirectUri: null,
        gatewayConfig: gatewayConfig,
        allowInsecureLoopback: allowInsecureLoopback,
      );
    }
    if (clientId.isEmpty || redirectUri.isEmpty) {
      throw const FormatException(
        '$solvedOAuthClientIdDefine and $solvedOAuthRedirectUriDefine must be configured together',
      );
    }
    if (clientId.trim() != clientId) {
      throw const FormatException(
        '$solvedOAuthClientIdDefine must not contain surrounding whitespace',
      );
    }
    if (redirectUri.trim() != redirectUri) {
      throw const FormatException(
        '$solvedOAuthRedirectUriDefine must not contain surrounding whitespace',
      );
    }
    if (!gatewayConfig.hasV4Gateway) {
      throw const FormatException(
        'Solved OAuth requires the $solvedApiOfficialV4Mode API mode',
      );
    }
    if (!allowInsecureLoopback &&
        gatewayConfig.v4ProxyBaseUri!.scheme != 'https') {
      throw const FormatException('Solved OAuth gateway must use HTTPS');
    }

    final parsedRedirectUri = Uri.tryParse(redirectUri);
    if (parsedRedirectUri == null ||
        !parsedRedirectUri.isAbsolute ||
        parsedRedirectUri.host.isEmpty) {
      throw const FormatException(
        '$solvedOAuthRedirectUriDefine must be an absolute URI',
      );
    }
    if (_hasExplicitUserInfo(redirectUri) || redirectUri.contains('#')) {
      throw const FormatException(
        '$solvedOAuthRedirectUriDefine must not contain user info or a fragment',
      );
    }
    final isSecure = parsedRedirectUri.scheme == 'https';
    final isAllowedLoopback =
        allowInsecureLoopback &&
        parsedRedirectUri.scheme == 'http' &&
        parsedRedirectUri.host == 'localhost';
    if (!isSecure && !isAllowedLoopback) {
      throw const FormatException(
        '$solvedOAuthRedirectUriDefine must use HTTPS',
      );
    }

    final query = parsedRedirectUri.queryParametersAll;
    if (query.containsKey('code') || query.containsKey('state')) {
      throw const FormatException(
        '$solvedOAuthRedirectUriDefine must not reserve code or state',
      );
    }

    return SolvedOAuthRuntimeConfig._(
      clientId: clientId,
      redirectUri: parsedRedirectUri,
      gatewayConfig: gatewayConfig,
      allowInsecureLoopback: allowInsecureLoopback,
    );
  }

  final String? clientId;
  final Uri? redirectUri;
  final SolvedApiGatewayConfig _gatewayConfig;
  final bool _allowInsecureLoopback;

  bool get isConfigured => clientId != null;

  SolvedOAuthRuntime createRuntime({
    required http.Client httpClient,
    Iterable<SolvedOAuthScope> scopes = const <SolvedOAuthScope>[],
  }) {
    final configuredClientId = clientId;
    final configuredRedirectUri = redirectUri;
    if (configuredClientId == null || configuredRedirectUri == null) {
      throw StateError('Solved OAuth is not configured');
    }

    final oauthClient = SolvedOAuthClient(
      proxyBaseUri: _gatewayConfig.v4ProxyBaseUri!,
      httpClient: httpClient,
      allowInsecureLoopback: _allowInsecureLoopback,
    );
    try {
      final identityResolver = SolvedOAuthProxyIdentityResolver(
        proxyBaseUri: _gatewayConfig.v4ProxyBaseUri!,
        httpClient: httpClient,
        allowInsecureLoopback: _allowInsecureLoopback,
      );
      return SolvedOAuthRuntime._(
        oauthClient: oauthClient,
        coordinator: SolvedOAuthAuthorizationCoordinator(
          clientId: configuredClientId,
          redirectUri: configuredRedirectUri,
          scopes: scopes,
          oauthClient: oauthClient,
          identityResolver: identityResolver,
        ),
      );
    } on Object {
      oauthClient.close();
      rethrow;
    }
  }
}

bool _hasExplicitUserInfo(String value) {
  final schemeEnd = value.indexOf('://');
  if (schemeEnd < 0) return false;
  final authorityStart = schemeEnd + 3;
  var authorityEnd = value.length;
  for (final delimiter in <String>['/', '?', '#']) {
    final index = value.indexOf(delimiter, authorityStart);
    if (index >= 0 && index < authorityEnd) authorityEnd = index;
  }
  return value.substring(authorityStart, authorityEnd).contains('@');
}
