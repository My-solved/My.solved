import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'solved_oauth_contract.dart';

/// A callback that cannot be bound to its originating authorization attempt.
///
/// Details are intentionally withheld because callback URIs contain an
/// authorization code and anti-forgery state.
final class SolvedOAuthAuthorizationCallbackRejected implements Exception {
  const SolvedOAuthAuthorizationCallbackRejected();

  @override
  String toString() => 'SolvedOAuthAuthorizationCallbackRejected(<redacted>)';
}

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

    final authorizationRequest = SolvedOAuthAuthorizationRequest(
      clientId: clientId,
      redirectUri: redirectUri,
      scopes: scopes,
      state: state,
      codeChallenge: codeChallenge,
    );
    _requireCallbackParametersAvailable(authorizationRequest.redirectUri);

    return SolvedOAuthAuthorizationSession._(
      authorizationRequest: authorizationRequest,
      codeVerifier: codeVerifier,
    );
  }

  final SolvedOAuthAuthorizationRequest authorizationRequest;
  String? _codeVerifier;

  /// Validates and consumes the successful callback for this attempt.
  ///
  /// Invalid callbacks do not consume the session. After a successful call,
  /// no second grant can be created from this session. The returned grant must
  /// not be retried after an outcome-unknown token exchange failure.
  SolvedOAuthAuthorizationCodeGrant consumeAuthorizationCodeCallback({
    required Uri callbackUri,
  }) {
    final codeVerifier = _codeVerifier;
    if (codeVerifier == null) {
      throw StateError('OAuth authorization session has already been consumed');
    }

    final code = _validateCallback(
      callbackUri: callbackUri,
      redirectUri: authorizationRequest.redirectUri,
      expectedState: authorizationRequest.state,
    );
    final grant = SolvedOAuthAuthorizationCodeGrant(
      code: code,
      redirectUri: authorizationRequest.redirectUri,
      codeVerifier: codeVerifier,
    );
    _codeVerifier = null;
    return grant;
  }

  @override
  String toString() => 'SolvedOAuthAuthorizationSession(<redacted>)';
}

void _requireCallbackParametersAvailable(Uri redirectUri) {
  final query = redirectUri.queryParametersAll;
  if (query.containsKey('code') || query.containsKey('state')) {
    throw ArgumentError.value(
      redirectUri,
      'redirectUri',
      'Must not contain reserved OAuth callback parameters',
    );
  }
}

String _validateCallback({
  required Uri callbackUri,
  required Uri redirectUri,
  required String expectedState,
}) {
  try {
    if (callbackUri.hasFragment ||
        callbackUri.scheme != redirectUri.scheme ||
        callbackUri.hasAuthority != redirectUri.hasAuthority ||
        callbackUri.authority != redirectUri.authority ||
        callbackUri.path != redirectUri.path) {
      throw const SolvedOAuthAuthorizationCallbackRejected();
    }

    final expectedQuery = redirectUri.queryParametersAll;
    final callbackQuery = callbackUri.queryParametersAll;
    final codeValues = callbackQuery['code'];
    final stateValues = callbackQuery['state'];
    if (callbackQuery.length != expectedQuery.length + 2 ||
        codeValues == null ||
        codeValues.length != 1 ||
        codeValues.single.isEmpty ||
        stateValues == null ||
        stateValues.length != 1 ||
        !_fixedLengthEquals(stateValues.single, expectedState)) {
      throw const SolvedOAuthAuthorizationCallbackRejected();
    }

    for (final entry in expectedQuery.entries) {
      if (!_sameStrings(callbackQuery[entry.key], entry.value)) {
        throw const SolvedOAuthAuthorizationCallbackRejected();
      }
    }
    return codeValues.single;
  } on SolvedOAuthAuthorizationCallbackRejected {
    rethrow;
  } on FormatException {
    throw const SolvedOAuthAuthorizationCallbackRejected();
  }
}

bool _sameStrings(List<String>? actual, List<String> expected) {
  if (actual == null || actual.length != expected.length) return false;
  for (var index = 0; index < expected.length; index += 1) {
    if (actual[index] != expected[index]) return false;
  }
  return true;
}

bool _fixedLengthEquals(String actual, String expected) {
  if (actual.length != expected.length) return false;
  var difference = 0;
  for (var index = 0; index < expected.length; index += 1) {
    difference |= actual.codeUnitAt(index) ^ expected.codeUnitAt(index);
  }
  return difference == 0;
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
