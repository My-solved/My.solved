import 'package:http/http.dart' as http;

import 'models/models.dart';
import 'solved_authenticated_api_client.dart';
import 'solved_oauth_authorization_session.dart';
import 'solved_oauth_client.dart';
import 'solved_oauth_contract.dart';
import 'solved_proxy_transport.dart';

/// Observable phases of one in-memory OAuth authorization attempt.
enum SolvedOAuthAuthorizationState { idle, awaitingCallback, completing }

/// An opaque, in-memory solved.ac credential.
///
/// The complete token response, including a possible refresh token, remains
/// private. This capability can be passed to trusted solved_api operations but
/// offers no raw access-token or refresh-token API.
final class SolvedOAuthCredential {
  const SolvedOAuthCredential._(this._token);

  final SolvedOAuthTokenResponse _token;

  @override
  String toString() => 'SolvedOAuthCredential(<redacted>)';
}

/// Resolves the stable user identity spoken for by an opaque credential.
///
/// Implementations must make at most one identity request per invocation and
/// must not expose the credential's raw token values.
abstract interface class SolvedOAuthIdentityResolver {
  Future<SolvedUserIdentity> resolveCurrentUser(
    SolvedOAuthCredential credential,
  );
}

/// Official proxy-backed identity resolver for an OAuth credential.
///
/// Each invocation performs exactly one `/solved/v4/me` request and never
/// retries automatically. An injected HTTP client remains caller-owned and
/// must not add retries or credentials.
final class SolvedOAuthProxyIdentityResolver
    implements SolvedOAuthIdentityResolver {
  factory SolvedOAuthProxyIdentityResolver({
    required Uri proxyBaseUri,
    http.Client? httpClient,
    Duration requestTimeout = const Duration(seconds: 10),
    bool allowInsecureLoopback = false,
  }) {
    final validationTransport = SolvedProxyTransport(
      proxyBaseUri: proxyBaseUri,
      httpClient: httpClient,
      requestTimeout: requestTimeout,
      allowInsecureLoopback: allowInsecureLoopback,
    );
    try {
      return SolvedOAuthProxyIdentityResolver._(
        proxyBaseUri: validationTransport.proxyBaseUri,
        httpClient: httpClient,
        requestTimeout: validationTransport.requestTimeout,
        allowInsecureLoopback: allowInsecureLoopback,
      );
    } finally {
      validationTransport.close();
    }
  }

  const SolvedOAuthProxyIdentityResolver._({
    required Uri proxyBaseUri,
    required http.Client? httpClient,
    required Duration requestTimeout,
    required bool allowInsecureLoopback,
  })  : _proxyBaseUri = proxyBaseUri,
        _httpClient = httpClient,
        _requestTimeout = requestTimeout,
        _allowInsecureLoopback = allowInsecureLoopback;

  final Uri _proxyBaseUri;
  final http.Client? _httpClient;
  final Duration _requestTimeout;
  final bool _allowInsecureLoopback;

  @override
  Future<SolvedUserIdentity> resolveCurrentUser(
    SolvedOAuthCredential credential,
  ) async {
    final client = SolvedAuthenticatedApiClient(
      proxyBaseUri: _proxyBaseUri,
      token: credential._token,
      httpClient: _httpClient,
      requestTimeout: _requestTimeout,
      allowInsecureLoopback: _allowInsecureLoopback,
    );
    try {
      return await client.currentUser();
    } finally {
      client.close();
    }
  }

  @override
  String toString() => 'SolvedOAuthProxyIdentityResolver(<redacted>)';
}

/// A completed token exchange whose opaque credential remains caller-owned.
sealed class SolvedOAuthAuthorizationOutcome {
  const SolvedOAuthAuthorizationOutcome({required this.credential});

  final SolvedOAuthCredential credential;
}

/// Authorization and stable identity resolution both completed.
final class SolvedOAuthAuthorizationCompleted
    extends SolvedOAuthAuthorizationOutcome {
  const SolvedOAuthAuthorizationCompleted({
    required super.credential,
    required this.identity,
  });

  final SolvedUserIdentity identity;

  @override
  String toString() => 'SolvedOAuthAuthorizationCompleted(<redacted>)';
}

/// Token exchange completed, but stable identity resolution did not.
///
/// The credential is preserved so a caller can explicitly resolve identity
/// later. The coordinator itself never retries or revokes it automatically.
final class SolvedOAuthIdentityUnresolved
    extends SolvedOAuthAuthorizationOutcome {
  const SolvedOAuthIdentityUnresolved({
    required super.credential,
    required this.cause,
    required this.stackTrace,
  });

  final Object cause;
  final StackTrace stackTrace;

  @override
  String toString() => 'SolvedOAuthIdentityUnresolved(<redacted>)';
}

/// Coordinates one memory-only OAuth authorization-code attempt at a time.
///
/// Invalid callbacks preserve the pending PKCE session. A valid callback is
/// consumed before its authorization code is exchanged exactly once. The
/// injected OAuth client and identity resolver remain caller-owned.
final class SolvedOAuthAuthorizationCoordinator {
  SolvedOAuthAuthorizationCoordinator({
    required String clientId,
    required Uri redirectUri,
    Iterable<SolvedOAuthScope> scopes = const <SolvedOAuthScope>[],
    required SolvedOAuthClient oauthClient,
    required SolvedOAuthIdentityResolver identityResolver,
  })  : _clientId = clientId,
        _redirectUri = redirectUri,
        _scopes = List<SolvedOAuthScope>.unmodifiable(scopes),
        _oauthClient = oauthClient,
        _identityResolver = identityResolver;

  final String _clientId;
  final Uri _redirectUri;
  final List<SolvedOAuthScope> _scopes;
  final SolvedOAuthClient _oauthClient;
  final SolvedOAuthIdentityResolver _identityResolver;

  SolvedOAuthAuthorizationState _state = SolvedOAuthAuthorizationState.idle;
  SolvedOAuthAuthorizationSession? _session;

  SolvedOAuthAuthorizationState get state => _state;

  /// Begins a new authorization attempt without replacing a pending one.
  SolvedOAuthAuthorizationRequest begin() {
    switch (_state) {
      case SolvedOAuthAuthorizationState.idle:
        final session = SolvedOAuthAuthorizationSession.generate(
          clientId: _clientId,
          redirectUri: _redirectUri,
          scopes: _scopes,
        );
        _session = session;
        _state = SolvedOAuthAuthorizationState.awaitingCallback;
        return session.authorizationRequest;
      case SolvedOAuthAuthorizationState.awaitingCallback:
        throw StateError('OAuth authorization callback is already pending');
      case SolvedOAuthAuthorizationState.completing:
        throw StateError('OAuth authorization completion is in progress');
    }
  }

  /// Cancels a pending callback without making a network request.
  ///
  /// Cancelling while idle is idempotent. A token exchange or identity request
  /// cannot be cancelled safely after completion has started.
  void cancel() {
    switch (_state) {
      case SolvedOAuthAuthorizationState.idle:
        return;
      case SolvedOAuthAuthorizationState.awaitingCallback:
        _session = null;
        _state = SolvedOAuthAuthorizationState.idle;
        return;
      case SolvedOAuthAuthorizationState.completing:
        throw StateError('OAuth authorization completion is in progress');
    }
  }

  /// Validates a callback, exchanges its code once, and resolves identity once.
  Future<SolvedOAuthAuthorizationOutcome> complete({
    required Uri callbackUri,
  }) async {
    if (_state == SolvedOAuthAuthorizationState.completing) {
      throw StateError('OAuth authorization completion is in progress');
    }
    final session = _session;
    if (_state != SolvedOAuthAuthorizationState.awaitingCallback ||
        session == null) {
      throw StateError('No OAuth authorization callback is pending');
    }

    final grant = session.consumeAuthorizationCodeCallback(
      callbackUri: callbackUri,
    );
    _session = null;
    _state = SolvedOAuthAuthorizationState.completing;

    try {
      final token = await _oauthClient.exchange(grant);
      final credential = SolvedOAuthCredential._(token);
      try {
        final identity = await _identityResolver.resolveCurrentUser(credential);
        return SolvedOAuthAuthorizationCompleted(
          credential: credential,
          identity: identity,
        );
      } on Object catch (error, stackTrace) {
        return SolvedOAuthIdentityUnresolved(
          credential: credential,
          cause: error,
          stackTrace: stackTrace,
        );
      }
    } finally {
      _state = SolvedOAuthAuthorizationState.idle;
    }
  }

  @override
  String toString() => 'SolvedOAuthAuthorizationCoordinator(<redacted>)';
}
