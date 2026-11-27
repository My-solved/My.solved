import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:solved_api/solved_api.dart';
import 'package:test/test.dart';

typedef _RequestHandler = Future<http.StreamedResponse> Function(
  http.Request request,
);

typedef _IdentityHandler = Future<SolvedUserIdentity> Function(
  SolvedOAuthCredential credential,
);

final class _RecordingClient extends http.BaseClient {
  _RecordingClient(this.handler);

  _RequestHandler handler;
  final List<http.Request> requests = <http.Request>[];
  bool wasClosed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (wasClosed) throw StateError('Recording client is closed');
    if (request is! http.Request) {
      throw StateError('Expected a buffered HTTP request');
    }
    requests.add(request);
    return handler(request);
  }

  @override
  void close() {
    wasClosed = true;
  }
}

final class _FakeIdentityResolver implements SolvedOAuthIdentityResolver {
  _FakeIdentityResolver(this.handler);

  _IdentityHandler handler;
  final List<SolvedOAuthCredential> credentials = <SolvedOAuthCredential>[];

  @override
  Future<SolvedUserIdentity> resolveCurrentUser(
    SolvedOAuthCredential credential,
  ) {
    credentials.add(credential);
    return handler(credential);
  }

  @override
  String toString() => '_FakeIdentityResolver(<redacted>)';
}

void main() {
  group('SolvedOAuthAuthorizationCoordinator', () {
    test('exchanges once, resolves once, and exposes only an opaque credential',
        () async {
      const code = 'issued-code-secret';
      const accessToken = 'access-token-secret';
      const refreshToken = 'refresh-token-secret';
      const handle = 'private-handle';
      late _RequestHandler handler;
      final transport = _RecordingClient((request) => handler(request));
      final oauthClient = _oauthClient(transport);
      final identityResolver = SolvedOAuthProxyIdentityResolver(
        proxyBaseUri: _proxyBaseUri,
        httpClient: transport,
      );
      final coordinator = _coordinator(oauthClient, identityResolver);
      handler = (request) async {
        if (request.method == 'POST') {
          return _jsonResponse(
            _tokenBody(
              accessToken: accessToken,
              refreshToken: refreshToken,
            ),
          );
        }
        if (request.method == 'GET') {
          return _jsonResponse('{"id":123456789,"handle":"$handle"}');
        }
        throw StateError('Unexpected request method');
      };

      final authorization = coordinator.begin();
      expect(
        coordinator.state,
        SolvedOAuthAuthorizationState.awaitingCallback,
      );
      final outcome = await coordinator.complete(
        callbackUri: _callback(authorization, code: code),
      );

      expect(outcome, isA<SolvedOAuthAuthorizationCompleted>());
      final completed = outcome as SolvedOAuthAuthorizationCompleted;
      expect(completed.identity.id, 123456789);
      expect(completed.identity.handle, handle);
      expect(completed.credential, isA<SolvedOAuthCredential>());
      expect(coordinator.state, SolvedOAuthAuthorizationState.idle);
      expect(transport.requests, hasLength(2));

      final tokenRequest = transport.requests.first;
      expect(tokenRequest.method, 'POST');
      expect(
        tokenRequest.url,
        Uri.parse('https://proxy.example/solved/v4/oauth/token'),
      );
      expect(tokenRequest.bodyFields['code'], code);
      expect(tokenRequest.bodyFields['grant_type'], 'authorization_code');
      expect(
        tokenRequest.bodyFields['redirect_uri'],
        _redirectUri.toString(),
      );
      expect(tokenRequest.bodyFields['code_verifier'], matches(_pkceValue));
      expect(tokenRequest.headers.containsKey('authorization'), isFalse);
      expect(tokenRequest.body, isNot(contains(accessToken)));
      expect(tokenRequest.body, isNot(contains(refreshToken)));

      final identityRequest = transport.requests.last;
      expect(identityRequest.method, 'GET');
      expect(
        identityRequest.url,
        Uri.parse('https://proxy.example/solved/v4/me'),
      );
      expect(identityRequest.headers['authorization'], 'Bearer $accessToken');
      expect(identityRequest.headers.containsKey('x-client-id'), isFalse);
      expect(identityRequest.headers.containsKey('x-client-secret'), isFalse);
      expect(identityRequest.bodyBytes, isEmpty);
      expect(identityRequest.body, isNot(contains(refreshToken)));
      expect(
        transport.requests
            .where((request) => request.url.path.endsWith('revoke')),
        isEmpty,
      );

      for (final object in <Object>[
        coordinator,
        identityResolver,
        completed,
        completed.credential,
      ]) {
        final value = object.toString();
        for (final secret in <String>[
          code,
          authorization.state,
          authorization.codeChallenge,
          accessToken,
          refreshToken,
          handle,
        ]) {
          expect(value, isNot(contains(secret)));
        }
      }
      expect(transport.wasClosed, isFalse);
      oauthClient.close();
      expect(transport.wasClosed, isFalse);
    });

    test('preserves a pending session after an invalid callback', () async {
      final transport =
          _RecordingClient((_) async => _jsonResponse(_tokenBody()));
      final oauthClient = _oauthClient(transport);
      final identityResolver = _FakeIdentityResolver(
        (_) async => _identity,
      );
      final coordinator = _coordinator(oauthClient, identityResolver);
      final authorization = coordinator.begin();

      await expectLater(
        coordinator.complete(
          callbackUri: _callback(authorization, state: 'wrong-state'),
        ),
        throwsA(isA<SolvedOAuthAuthorizationCallbackRejected>()),
      );

      expect(
        coordinator.state,
        SolvedOAuthAuthorizationState.awaitingCallback,
      );
      expect(transport.requests, isEmpty);
      expect(identityResolver.credentials, isEmpty);

      final outcome = await coordinator.complete(
        callbackUri: _callback(authorization),
      );
      expect(outcome, isA<SolvedOAuthAuthorizationCompleted>());
      expect(transport.requests, hasLength(1));
      expect(identityResolver.credentials, hasLength(1));
      oauthClient.close();
    });

    test('cancels without replacement and isolates the next attempt', () async {
      final transport =
          _RecordingClient((_) async => _jsonResponse(_tokenBody()));
      final oauthClient = _oauthClient(transport);
      final identityResolver = _FakeIdentityResolver(
        (_) async => _identity,
      );
      final coordinator = _coordinator(oauthClient, identityResolver);
      final cancelled = coordinator.begin();

      expect(
        coordinator.begin,
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'OAuth authorization callback is already pending',
          ),
        ),
      );
      coordinator.cancel();
      coordinator.cancel();
      expect(coordinator.state, SolvedOAuthAuthorizationState.idle);
      await expectLater(
        coordinator.complete(callbackUri: _callback(cancelled)),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'No OAuth authorization callback is pending',
          ),
        ),
      );
      expect(transport.requests, isEmpty);

      final next = coordinator.begin();
      expect(next.state, isNot(cancelled.state));
      await expectLater(
        coordinator.complete(callbackUri: _callback(cancelled)),
        throwsA(isA<SolvedOAuthAuthorizationCallbackRejected>()),
      );
      expect(
        coordinator.state,
        SolvedOAuthAuthorizationState.awaitingCallback,
      );
      expect(transport.requests, isEmpty);

      await coordinator.complete(callbackUri: _callback(next));
      expect(transport.requests, hasLength(1));
      expect(identityResolver.credentials, hasLength(1));
      oauthClient.close();
    });

    test('blocks re-entry while the authorization code is exchanging',
        () async {
      final requestStarted = Completer<void>();
      final response = Completer<http.StreamedResponse>();
      final transport = _RecordingClient((_) {
        requestStarted.complete();
        return response.future;
      });
      final oauthClient = _oauthClient(transport);
      final identityResolver = _FakeIdentityResolver(
        (_) async => _identity,
      );
      final coordinator = _coordinator(oauthClient, identityResolver);
      final authorization = coordinator.begin();

      final completion = coordinator.complete(
        callbackUri: _callback(authorization),
      );
      await requestStarted.future;

      expect(coordinator.state, SolvedOAuthAuthorizationState.completing);
      expect(
        coordinator.begin,
        throwsA(isA<StateError>()),
      );
      expect(coordinator.cancel, throwsA(isA<StateError>()));
      await expectLater(
        coordinator.complete(callbackUri: _callback(authorization)),
        throwsA(isA<StateError>()),
      );
      expect(transport.requests, hasLength(1));

      response.complete(_jsonResponse(_tokenBody()));
      final outcome = await completion;
      expect(outcome, isA<SolvedOAuthAuthorizationCompleted>());
      expect(coordinator.state, SolvedOAuthAuthorizationState.idle);
      expect(transport.requests, hasLength(1));
      expect(identityResolver.credentials, hasLength(1));
      oauthClient.close();
    });

    test('blocks re-entry while identity is resolving', () async {
      final transport =
          _RecordingClient((_) async => _jsonResponse(_tokenBody()));
      final oauthClient = _oauthClient(transport);
      final resolverStarted = Completer<void>();
      final identity = Completer<SolvedUserIdentity>();
      final identityResolver = _FakeIdentityResolver((_) {
        resolverStarted.complete();
        return identity.future;
      });
      final coordinator = _coordinator(oauthClient, identityResolver);
      final authorization = coordinator.begin();

      final completion = coordinator.complete(
        callbackUri: _callback(authorization),
      );
      await resolverStarted.future;

      expect(coordinator.state, SolvedOAuthAuthorizationState.completing);
      expect(coordinator.begin, throwsA(isA<StateError>()));
      expect(coordinator.cancel, throwsA(isA<StateError>()));
      await expectLater(
        coordinator.complete(callbackUri: _callback(authorization)),
        throwsA(isA<StateError>()),
      );
      expect(transport.requests, hasLength(1));
      expect(identityResolver.credentials, hasLength(1));

      identity.complete(_identity);
      await completion;
      expect(coordinator.state, SolvedOAuthAuthorizationState.idle);
      expect(identityResolver.credentials, hasLength(1));
      oauthClient.close();
    });

    test(
        'resets to idle without retry, identity lookup, or revoke on exchange errors',
        () async {
      late _RequestHandler handler;
      final transport = _RecordingClient((request) => handler(request));
      final oauthClient = _oauthClient(transport);
      final identityResolver = _FakeIdentityResolver(
        (_) async => _identity,
      );
      final coordinator = _coordinator(oauthClient, identityResolver);
      final cases = <(http.StreamedResponse, Type)>[
        (
          _jsonResponse(
            '{"error":"invalid_grant","error_description":"secret"}',
            statusCode: 400,
          ),
          SolvedOAuthRejected,
        ),
        (
          _bytesResponse(
            utf8.encode('secret response'),
            statusCode: 503,
          ),
          SolvedOAuthOutcomeUnknown,
        ),
      ];

      for (final entry in cases) {
        handler = (_) async => entry.$1;
        final authorization = coordinator.begin();
        final error = await _captureError(
          coordinator.complete(callbackUri: _callback(authorization)),
        );

        expect(error.runtimeType, entry.$2);
        expect(error.toString(), isNot(contains('secret')));
        expect(coordinator.state, SolvedOAuthAuthorizationState.idle);
        expect(identityResolver.credentials, isEmpty);
        await expectLater(
          coordinator.complete(callbackUri: _callback(authorization)),
          throwsA(isA<StateError>()),
        );
      }

      expect(transport.requests, hasLength(cases.length));
      expect(
        transport.requests,
        everyElement(
          isA<http.Request>().having(
            (request) => request.url.path,
            'path',
            '/solved/v4/oauth/token',
          ),
        ),
      );
      expect(identityResolver.credentials, isEmpty);
      oauthClient.close();
    });

    test('resets to idle when a consumed callback is too large to send',
        () async {
      final transport = _RecordingClient(
        (_) async => throw StateError('must not send'),
      );
      final oauthClient = _oauthClient(transport);
      final identityResolver = _FakeIdentityResolver(
        (_) async => _identity,
      );
      final coordinator = _coordinator(oauthClient, identityResolver);
      final authorization = coordinator.begin();
      final oversizedCode = List<String>.filled(64 * 1024, 'x').join();

      await expectLater(
        coordinator.complete(
          callbackUri: _callback(authorization, code: oversizedCode),
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(coordinator.state, SolvedOAuthAuthorizationState.idle);
      expect(transport.requests, isEmpty);
      expect(identityResolver.credentials, isEmpty);
      oauthClient.close();
    });

    test('returns a reusable opaque credential when identity is unresolved',
        () async {
      const accessToken = 'preserved-access-token';
      const refreshToken = 'preserved-refresh-token';
      var identityRequests = 0;
      late _RequestHandler handler;
      final transport = _RecordingClient((request) => handler(request));
      final oauthClient = _oauthClient(transport);
      final identityResolver = SolvedOAuthProxyIdentityResolver(
        proxyBaseUri: _proxyBaseUri,
        httpClient: transport,
      );
      final coordinator = _coordinator(oauthClient, identityResolver);
      handler = (request) async {
        if (request.method == 'POST') {
          return _jsonResponse(
            _tokenBody(
              accessToken: accessToken,
              refreshToken: refreshToken,
            ),
          );
        }
        identityRequests += 1;
        if (identityRequests == 1) {
          return _bytesResponse(
            utf8.encode('do-not-log-body'),
            statusCode: 401,
          );
        }
        return _jsonResponse('{"id":7,"handle":"resolved-later"}');
      };

      final authorization = coordinator.begin();
      final outcome = await coordinator.complete(
        callbackUri: _callback(authorization),
      );

      expect(outcome, isA<SolvedOAuthIdentityUnresolved>());
      final unresolved = outcome as SolvedOAuthIdentityUnresolved;
      expect(unresolved.cause, isA<SolvedAuthenticatedRequestFailed>());
      expect(
        (unresolved.cause as SolvedAuthenticatedRequestFailed).kind,
        SolvedAuthenticatedFailureKind.unauthorized,
      );
      expect(coordinator.state, SolvedOAuthAuthorizationState.idle);
      expect(transport.requests, hasLength(2));
      expect(identityRequests, 1);
      expect(unresolved.toString(), isNot(contains(accessToken)));
      expect(unresolved.toString(), isNot(contains(refreshToken)));
      expect(unresolved.toString(), isNot(contains('do-not-log-body')));

      final identity = await identityResolver.resolveCurrentUser(
        unresolved.credential,
      );
      expect(identity.id, 7);
      expect(identity.handle, 'resolved-later');
      expect(identityRequests, 2);
      expect(transport.requests, hasLength(3));
      expect(
        transport.requests.where((request) => request.method == 'GET'),
        everyElement(
          isA<http.Request>().having(
            (request) => request.headers['authorization'],
            'authorization',
            'Bearer $accessToken',
          ),
        ),
      );
      expect(
        transport.requests
            .where((request) => request.url.path.endsWith('revoke')),
        isEmpty,
      );
      expect(transport.wasClosed, isFalse);
      oauthClient.close();
    });

    test('preserves an arbitrary identity failure but redacts public strings',
        () async {
      const secret = 'identity-cause-secret';
      final failure = StateError(secret);
      final transport =
          _RecordingClient((_) async => _jsonResponse(_tokenBody()));
      final oauthClient = _oauthClient(transport);
      final identityResolver = _FakeIdentityResolver((_) => throw failure);
      final coordinator = _coordinator(oauthClient, identityResolver);
      final authorization = coordinator.begin();

      final outcome = await coordinator.complete(
        callbackUri: _callback(authorization, code: 'callback-code-secret'),
      );

      expect(outcome, isA<SolvedOAuthIdentityUnresolved>());
      final unresolved = outcome as SolvedOAuthIdentityUnresolved;
      expect(unresolved.cause, same(failure));
      expect(unresolved.stackTrace, isNotNull);
      expect(coordinator.state, SolvedOAuthAuthorizationState.idle);
      expect(identityResolver.credentials, hasLength(1));
      expect(unresolved.toString(), isNot(contains(secret)));
      expect(unresolved.toString(), isNot(contains('callback-code-secret')));
      expect(unresolved.credential.toString(), isNot(contains(secret)));
      expect(coordinator.toString(), isNot(contains(secret)));
      oauthClient.close();
    });
  });
}

SolvedOAuthAuthorizationCoordinator _coordinator(
  SolvedOAuthClient oauthClient,
  SolvedOAuthIdentityResolver identityResolver,
) =>
    SolvedOAuthAuthorizationCoordinator(
      clientId: 'public-client-id',
      redirectUri: _redirectUri,
      scopes: const <SolvedOAuthScope>[
        SolvedOAuthScope.profile,
        SolvedOAuthScope.offlineAccess,
      ],
      oauthClient: oauthClient,
      identityResolver: identityResolver,
    );

SolvedOAuthClient _oauthClient(http.Client httpClient) => SolvedOAuthClient(
      proxyBaseUri: _proxyBaseUri,
      httpClient: httpClient,
    );

Uri _callback(
  SolvedOAuthAuthorizationRequest authorization, {
  String code = 'issued-code',
  String? state,
}) =>
    authorization.redirectUri.replace(
      queryParameters: <String, String>{
        'code': code,
        'state': state ?? authorization.state,
      },
    );

String _tokenBody({
  String accessToken = 'access-token',
  String refreshToken = 'refresh-token',
}) =>
    jsonEncode(<String, Object?>{
      'access_token': accessToken,
      'token_type': 'Bearer',
      'expires_in': 3600,
      'refresh_token': refreshToken,
      'scope': 'profile offline.access',
    });

http.StreamedResponse _jsonResponse(
  String body, {
  int statusCode = 200,
}) =>
    _bytesResponse(
      utf8.encode(body),
      statusCode: statusCode,
      headers: const <String, String>{
        'content-type': 'application/json; charset=utf-8',
      },
    );

http.StreamedResponse _bytesResponse(
  List<int> bytes, {
  int statusCode = 200,
  Map<String, String> headers = const <String, String>{},
}) =>
    http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      statusCode,
      headers: headers,
    );

Future<Object> _captureError(Future<Object?> future) async {
  try {
    await future;
  } on Object catch (error) {
    return error;
  }
  throw StateError('Expected an error');
}

final Uri _proxyBaseUri = Uri.parse('https://proxy.example/solved/v4/');
final Uri _redirectUri = Uri.parse('https://app.example/oauth/callback');
const SolvedUserIdentity _identity =
    SolvedUserIdentity(id: 123456789, handle: 'index');
final RegExp _pkceValue = RegExp(r'^[A-Za-z0-9._~-]{43,128}$');
