import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'solved_oauth_contract.dart';

/// One in-progress solved.ac OAuth authorization attempt.
///
/// The authorization request and its PKCE verifier are generated together so
/// that a code cannot accidentally be exchanged with another attempt's
/// verifier or redirect URI. This session is intentionally memory-only;
/// protected persistence and restoration belong to the storage boundary.
final class SolvedOAuthAuthorizationSession {
  SolvedOAuthAuthorizationSession._({
    required this.authorizationRequest,
    required String codeVerifier,
  }) : _codeVerifier = codeVerifier;

  /// Starts an authorization attempt with independent 256-bit state and PKCE
  /// verifier values from the platform's cryptographically secure RNG.
  ///
  /// No insecure fallback is used when secure randomness is unavailable.
  factory SolvedOAuthAuthorizationSession.generate({
    required String clientId,
    required Uri redirectUri,
    Iterable<SolvedOAuthScope> scopes = const <SolvedOAuthScope>[],
  }) {
    final random = Random.secure();
    final state = _randomBase64Url(random);
    final codeVerifier = _randomBase64Url(random);
    final codeChallenge = _s256Challenge(codeVerifier);

    return SolvedOAuthAuthorizationSession._(
      authorizationRequest: SolvedOAuthAuthorizationRequest(
        clientId: clientId,
        redirectUri: redirectUri,
        scopes: scopes,
        state: state,
        codeChallenge: codeChallenge,
      ),
      codeVerifier: codeVerifier,
    );
  }

  final SolvedOAuthAuthorizationRequest authorizationRequest;
  final String _codeVerifier;

  /// Builds the single-use token grant bound to this authorization attempt.
  ///
  /// The same grant must not be retried after an outcome-unknown failure.
  SolvedOAuthAuthorizationCodeGrant createAuthorizationCodeGrant({
    required String code,
  }) => SolvedOAuthAuthorizationCodeGrant(
    code: code,
    redirectUri: authorizationRequest.redirectUri,
    codeVerifier: _codeVerifier,
  );

  @override
  String toString() => 'SolvedOAuthAuthorizationSession(<redacted>)';
}

String _randomBase64Url(Random random) => _withoutBase64Padding(
  base64UrlEncode(
    List<int>.generate(
      _entropyBytes,
      (_) => random.nextInt(256),
      growable: false,
    ),
  ),
);

String _s256Challenge(String codeVerifier) => _withoutBase64Padding(
  base64UrlEncode(sha256.convert(ascii.encode(codeVerifier)).bytes),
);

String _withoutBase64Padding(String value) => value.replaceAll('=', '');

const int _entropyBytes = 32;
