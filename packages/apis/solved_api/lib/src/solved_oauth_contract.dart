/// Public OAuth scopes documented by solved.ac.
///
/// Undocumented scopes are intentionally not representable in requests.
enum SolvedOAuthScope {
  profile('profile'),
  profilePersonal('profile.personal'),
  settings('settings'),
  settingsWrite('settings.write'),
  collection('collection'),
  wallet('wallet'),
  standing('standing'),
  solves('solves'),
  votes('votes'),
  rivals('rivals'),
  bookmarks('bookmarks'),
  bookmarksWrite('bookmarks.write'),
  offlineAccess('offline.access');

  const SolvedOAuthScope(this.value);

  final String value;

  static SolvedOAuthScope? tryParse(String value) {
    for (final scope in values) {
      if (scope.value == value) return scope;
    }
    return null;
  }
}

/// A solved.ac authorization-code request using PKCE with S256.
final class SolvedOAuthAuthorizationRequest {
  SolvedOAuthAuthorizationRequest({
    required this.clientId,
    required this.redirectUri,
    Iterable<SolvedOAuthScope> scopes = const <SolvedOAuthScope>[],
    required this.state,
    required this.codeChallenge,
  }) : scopes = _orderedScopes(scopes, includeProfile: true) {
    _requireNonEmpty(clientId, 'clientId');
    _requireRedirectUri(redirectUri);
    _requireNonEmpty(state, 'state');
    _requireCodeChallenge(codeChallenge);
  }

  static final Uri endpoint = Uri.https('solved.ac', '/oauth/authorize');

  final String clientId;
  final Uri redirectUri;
  final List<SolvedOAuthScope> scopes;
  final String state;
  final String codeChallenge;

  /// The exact seven-parameter authorization URI documented by solved.ac.
  Uri get authorizationUri => endpoint.replace(
        queryParameters: <String, String>{
          'response_type': 'code',
          'client_id': clientId,
          'redirect_uri': redirectUri.toString(),
          'scope': _encodeScopes(scopes),
          'state': state,
          'code_challenge': codeChallenge,
          'code_challenge_method': 'S256',
        },
      );
}

/// A request body accepted by the solved.ac OAuth token endpoint.
sealed class SolvedOAuthTokenGrant {
  const SolvedOAuthTokenGrant();

  Map<String, String> get formFields;
}

/// Exchanges an authorization code using the verifier that created its PKCE
/// challenge.
final class SolvedOAuthAuthorizationCodeGrant extends SolvedOAuthTokenGrant {
  SolvedOAuthAuthorizationCodeGrant({
    required this.code,
    required this.redirectUri,
    required this.codeVerifier,
  }) {
    _requireNonEmpty(code, 'code');
    _requireRedirectUri(redirectUri);
    _requireCodeVerifier(codeVerifier);
  }

  final String code;
  final Uri redirectUri;
  final String codeVerifier;

  @override
  Map<String, String> get formFields => Map<String, String>.unmodifiable(
        <String, String>{
          'code': code,
          'code_verifier': codeVerifier,
          'grant_type': 'authorization_code',
          'redirect_uri': redirectUri.toString(),
        },
      );
}

/// Spends a single-use refresh token and optionally narrows its scopes.
final class SolvedOAuthRefreshTokenGrant extends SolvedOAuthTokenGrant {
  SolvedOAuthRefreshTokenGrant({
    required this.refreshToken,
    Iterable<SolvedOAuthScope>? scopes,
  }) : scopes = scopes == null
            ? null
            : _orderedScopes(scopes, includeProfile: false) {
    _requireNonEmpty(refreshToken, 'refreshToken');
    if (this.scopes != null && this.scopes!.isEmpty) {
      throw ArgumentError.value(
        this.scopes,
        'scopes',
        'Must be omitted or contain at least one scope',
      );
    }
  }

  final String refreshToken;
  final List<SolvedOAuthScope>? scopes;

  @override
  Map<String, String> get formFields => Map<String, String>.unmodifiable(
        <String, String>{
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          if (scopes != null) 'scope': _encodeScopes(scopes!),
        },
      );
}

/// A successful token endpoint response.
final class SolvedOAuthTokenResponse {
  SolvedOAuthTokenResponse._({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.refreshToken,
    required this.scope,
    required List<String> scopeValues,
  }) : scopeValues = List<String>.unmodifiable(scopeValues);

  factory SolvedOAuthTokenResponse.fromJson(Object? json) {
    final body = _jsonObject(json, 'OAuth token response');
    final accessToken = _requiredString(body, 'access_token');
    if (accessToken.isEmpty) {
      throw const FormatException('access_token must not be empty');
    }

    final tokenType = _requiredString(body, 'token_type');
    if (tokenType != 'Bearer') {
      throw const FormatException('token_type must be Bearer');
    }

    final expiresIn = body['expires_in'];
    if (expiresIn is! num || !expiresIn.isFinite || expiresIn <= 0) {
      throw const FormatException(
          'expires_in must be a positive finite number');
    }

    final refreshToken = _optionalString(body, 'refresh_token');
    if (refreshToken != null && refreshToken.isEmpty) {
      throw const FormatException('refresh_token must not be empty');
    }

    final scope = _requiredString(body, 'scope');
    final scopeValues = _parseScope(scope);
    return SolvedOAuthTokenResponse._(
      accessToken: accessToken,
      tokenType: tokenType,
      expiresIn: expiresIn,
      refreshToken: refreshToken,
      scope: scope,
      scopeValues: scopeValues,
    );
  }

  final String accessToken;
  final String tokenType;
  final num expiresIn;
  final String? refreshToken;
  final String scope;

  /// Ordered raw scope tokens, including future scopes unknown to this client.
  final List<String> scopeValues;

  List<SolvedOAuthScope> get knownScopes => List<SolvedOAuthScope>.unmodifiable(
        scopeValues
            .map(SolvedOAuthScope.tryParse)
            .whereType<SolvedOAuthScope>(),
      );

  List<String> get unknownScopes => List<String>.unmodifiable(
        scopeValues.where((value) => SolvedOAuthScope.tryParse(value) == null),
      );
}

/// A standards-shaped OAuth error response from token or revocation.
final class SolvedOAuthErrorResponse {
  SolvedOAuthErrorResponse._({
    required this.error,
    required this.errorDescription,
  });

  factory SolvedOAuthErrorResponse.fromJson(Object? json) {
    final body = _jsonObject(json, 'OAuth error response');
    final error = _requiredString(body, 'error');
    if (error.isEmpty) {
      throw const FormatException('error must not be empty');
    }
    return SolvedOAuthErrorResponse._(
      error: error,
      errorDescription: _optionalString(body, 'error_description'),
    );
  }

  final String error;
  final String? errorDescription;
}

/// Revokes an access or refresh token and its associated sign-in.
final class SolvedOAuthRevokeRequest {
  SolvedOAuthRevokeRequest({required this.token}) {
    _requireNonEmpty(token, 'token');
  }

  final String token;

  Map<String, String> get formFields =>
      Map<String, String>.unmodifiable(<String, String>{'token': token});
}

List<SolvedOAuthScope> _orderedScopes(
  Iterable<SolvedOAuthScope> scopes, {
  required bool includeProfile,
}) {
  final selected = <SolvedOAuthScope>{...scopes};
  if (includeProfile) selected.add(SolvedOAuthScope.profile);
  return List<SolvedOAuthScope>.unmodifiable(
    SolvedOAuthScope.values.where(selected.contains),
  );
}

String _encodeScopes(Iterable<SolvedOAuthScope> scopes) =>
    scopes.map((scope) => scope.value).join(' ');

void _requireNonEmpty(String value, String name) {
  if (value.isEmpty) {
    throw ArgumentError.value(value, name, 'Must not be empty');
  }
}

void _requireRedirectUri(Uri value) {
  final isHttps = value.scheme == 'https';
  final isLocalHttp = value.scheme == 'http' && value.host == 'localhost';
  if (!value.isAbsolute ||
      value.host.isEmpty ||
      value.userInfo.isNotEmpty ||
      value.hasFragment ||
      (!isHttps && !isLocalHttp)) {
    throw ArgumentError.value(
      value,
      'redirectUri',
      'Must be HTTPS or HTTP on localhost, without credentials or a fragment',
    );
  }
}

void _requireCodeChallenge(String value) {
  if (value.length != 43 || !_matchesEntirely(_codeChallengePattern, value)) {
    throw ArgumentError.value(
      value,
      'codeChallenge',
      'Must be a 43-character unpadded base64url SHA-256 challenge',
    );
  }
}

void _requireCodeVerifier(String value) {
  if (value.length < 43 ||
      value.length > 128 ||
      !_matchesEntirely(_codeVerifierPattern, value)) {
    throw ArgumentError.value(
      value,
      'codeVerifier',
      'Must contain 43 to 128 RFC 7636 unreserved characters',
    );
  }
}

bool _matchesEntirely(RegExp pattern, String value) {
  final match = pattern.matchAsPrefix(value);
  return match != null && match.end == value.length;
}

Map<String, Object?> _jsonObject(Object? value, String name) {
  if (value is! Map) {
    throw FormatException('$name must be a JSON object');
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('$name must have string keys');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

String _requiredString(Map<String, Object?> body, String key) {
  final value = body[key];
  if (value is! String) {
    throw FormatException('$key must be a string');
  }
  return value;
}

String? _optionalString(Map<String, Object?> body, String key) {
  if (!body.containsKey(key)) return null;
  final value = body[key];
  if (value is! String) {
    throw FormatException('$key must be a string when present');
  }
  return value;
}

List<String> _parseScope(String value) {
  if (value.isEmpty) {
    throw const FormatException('scope must not be empty');
  }
  final tokens = value.split(' ');
  if (tokens.any((token) => token.isEmpty || !_isScopeToken(token))) {
    throw const FormatException('scope must be an RFC 6749 scope list');
  }
  return tokens;
}

bool _isScopeToken(String value) => value.codeUnits.every(
      (codeUnit) =>
          codeUnit == 0x21 ||
          (codeUnit >= 0x23 && codeUnit <= 0x5b) ||
          (codeUnit >= 0x5d && codeUnit <= 0x7e),
    );

final RegExp _codeChallengePattern = RegExp(r'[A-Za-z0-9_-]+');
final RegExp _codeVerifierPattern = RegExp(r'[A-Za-z0-9._~-]+');
