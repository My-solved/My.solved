import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:solved_api/solved_api.dart';
import 'package:test/test.dart';

typedef _RequestHandler = Future<http.StreamedResponse> Function(
  http.Request request,
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

void main() {
  group('SolvedOAuthClient configuration', () {
    test('requires the canonical secure proxy base URI', () {
      final transport = _RecordingClient(_unusedHandler);
      for (final uri in <Uri>[
        Uri.parse('/solved/v4/'),
        Uri.parse('http://proxy.example/solved/v4/'),
        Uri.parse('https://solved.ac/solved/v4/'),
        Uri.parse('https://api.solved.ac/solved/v4/'),
        Uri.parse('https://proxy.example/api/v4/'),
        Uri.parse('https://proxy.example/solved/v4'),
        Uri.parse('https://user@proxy.example/solved/v4/'),
        Uri.parse('https://proxy.example/solved/v4/?query=yes'),
        Uri.parse('https://proxy.example/solved/v4/#fragment'),
      ]) {
        expect(
          () => SolvedOAuthClient(
            proxyBaseUri: uri,
            httpClient: transport,
          ),
          throwsA(isA<ArgumentError>()),
          reason: uri.toString(),
        );
      }

      expect(
        SolvedOAuthClient(
          proxyBaseUri: Uri.parse('https://proxy.example/solved/v4/'),
          httpClient: transport,
        ),
        isA<SolvedOAuthClient>(),
      );
    });

    test('requires an explicit opt-in for insecure loopback', () {
      final transport = _RecordingClient(_unusedHandler);
      for (final value in <String>[
        'http://localhost:8080/solved/v4/',
        'http://127.0.0.1:8080/solved/v4/',
        'http://[::1]:8080/solved/v4/',
      ]) {
        final uri = Uri.parse(value);
        expect(
          () => SolvedOAuthClient(
            proxyBaseUri: uri,
            httpClient: transport,
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          SolvedOAuthClient(
            proxyBaseUri: uri,
            httpClient: transport,
            allowInsecureLoopback: true,
          ),
          isA<SolvedOAuthClient>(),
        );
      }
    });

    test('requires a positive timeout', () {
      final transport = _RecordingClient(_unusedHandler);
      for (final timeout in <Duration>[
        Duration.zero,
        const Duration(microseconds: -1),
      ]) {
        expect(
          () => SolvedOAuthClient(
            proxyBaseUri: Uri.parse('https://proxy.example/solved/v4/'),
            httpClient: transport,
            requestTimeout: timeout,
          ),
          throwsA(isA<ArgumentError>()),
        );
      }
    });
  });

  group('SolvedOAuthClient token transport', () {
    late _RequestHandler handler;
    late _RecordingClient transport;
    late SolvedOAuthClient client;

    setUp(() {
      handler = (_) async => _jsonResponse(_tokenBody);
      transport = _RecordingClient((request) => handler(request));
      client = SolvedOAuthClient(
        proxyBaseUri: Uri.parse('https://proxy.example/solved/v4/'),
        httpClient: transport,
      );
    });

    tearDown(() => client.close());

    test('sends an authorization-code form exactly once to the proxy',
        () async {
      final response = await client.exchange(
        SolvedOAuthAuthorizationCodeGrant(
          code: 'issued-code',
          redirectUri: Uri.parse('https://app.example/oauth/callback?x=1'),
          codeVerifier: _verifier,
        ),
      );

      expect(response.accessToken, 'access-token');
      expect(response.unknownScopes, <String>['future.scope']);
      expect(transport.requests, hasLength(1));
      final request = transport.requests.single;
      expect(request.method, 'POST');
      expect(
        request.url,
        Uri.parse('https://proxy.example/solved/v4/oauth/token'),
      );
      expect(request.followRedirects, isFalse);
      expect(request.maxRedirects, 0);
      expect(request.headers['accept'], 'application/json');
      expect(
        request.headers['content-type'],
        'application/x-www-form-urlencoded',
      );
      expect(request.bodyFields, <String, String>{
        'code': 'issued-code',
        'code_verifier': _verifier,
        'grant_type': 'authorization_code',
        'redirect_uri': 'https://app.example/oauth/callback?x=1',
      });
      expect(
        request.body,
        'code=issued-code&code_verifier=$_verifier&'
        'grant_type=authorization_code&redirect_uri='
        'https%3A%2F%2Fapp.example%2Foauth%2Fcallback%3Fx%3D1',
      );
      for (final name in <String>[
        'authorization',
        'x-client-id',
        'x-client-secret',
      ]) {
        expect(request.headers.containsKey(name), isFalse);
      }
    });

    test('sends only the refresh grant fields', () async {
      await client.exchange(
        SolvedOAuthRefreshTokenGrant(
          refreshToken: 'refresh +/',
          scopes: <SolvedOAuthScope>[
            SolvedOAuthScope.profile,
            SolvedOAuthScope.offlineAccess,
          ],
        ),
      );

      final request = transport.requests.single;
      expect(request.bodyFields, <String, String>{
        'grant_type': 'refresh_token',
        'refresh_token': 'refresh +/',
        'scope': 'profile offline.access',
      });
      expect(
        request.body,
        'grant_type=refresh_token&refresh_token=refresh+%2B%2F&'
        'scope=profile+offline.access',
      );
      expect(request.bodyFields, isNot(contains('code')));
    });

    test('maps documented token errors to definite rejections', () async {
      for (final entry in <(int, String)>[
        (400, 'invalid_request'),
        (400, 'invalid_grant'),
        (400, 'invalid_scope'),
        (400, 'unsupported_grant_type'),
        (401, 'invalid_client'),
      ]) {
        handler = (_) async => _jsonResponse(
              '{"error":"${entry.$2}","error_description":"spent"}',
              statusCode: entry.$1,
            );

        final error = await _captureFailure(
          client.exchange(_refreshGrant),
        );
        expect(error, isA<SolvedOAuthRejected>());
        final rejected = error as SolvedOAuthRejected;
        expect(rejected.statusCode, entry.$1);
        expect(rejected.error.error, entry.$2);
        expect(rejected.error.errorDescription, 'spent');
        expect(rejected.isRetryable, isFalse);
        expect(rejected.toString(), isNot(contains('spent')));
        expect(rejected.toString(), isNot(contains(entry.$2)));
      }
      expect(transport.requests, hasLength(5));
    });

    test('keeps undocumented token status and error pairs unknown', () async {
      for (final entry in <(int, String)>[
        (400, 'invalid_client'),
        (401, 'invalid_grant'),
        (400, 'future_error'),
      ]) {
        handler = (_) async => _jsonResponse(
              '{"error":"${entry.$2}"}',
              statusCode: entry.$1,
            );

        final error = await _captureUnknown(client.exchange(_refreshGrant));
        expect(error.kind, SolvedOAuthFailureKind.invalidResponse);
        expect(error.statusCode, entry.$1);
      }
      expect(transport.requests, hasLength(3));
    });

    test('treats redirects and unexpected statuses as unknown outcomes',
        () async {
      for (final entry in <(int, SolvedOAuthFailureKind)>[
        (302, SolvedOAuthFailureKind.redirect),
        (429, SolvedOAuthFailureKind.unexpectedStatus),
        (503, SolvedOAuthFailureKind.unexpectedStatus),
      ]) {
        handler = (_) async => _bytesResponse(
              utf8.encode('ignored'),
              statusCode: entry.$1,
              headers: const <String, String>{'location': 'https://elsewhere/'},
            );

        final error = await _captureUnknown(client.exchange(_refreshGrant));
        expect(error.kind, entry.$2);
        expect(error.statusCode, entry.$1);
        expect(error.isRetryable, isFalse);
      }
      expect(transport.requests, hasLength(3));
      expect(transport.requests.first.followRedirects, isFalse);
    });

    test('does not retry a timed-out refresh exchange', () async {
      client = SolvedOAuthClient(
        proxyBaseUri: Uri.parse('https://proxy.example/solved/v4/'),
        httpClient: transport,
        requestTimeout: const Duration(milliseconds: 1),
      );
      final streamCancelled = Completer<void>();
      late StreamController<List<int>> responseController;
      responseController = StreamController<List<int>>(
        onCancel: () {
          if (!streamCancelled.isCompleted) streamCancelled.complete();
        },
      );
      handler = (request) async {
        expect(request, isA<http.AbortableRequest>());
        final abortTrigger = (request as http.AbortableRequest).abortTrigger!;
        unawaited(
          abortTrigger.then((_) async {
            responseController.addError(
              http.RequestAbortedException(request.url),
            );
            await responseController.close();
          }),
        );
        return http.StreamedResponse(
          responseController.stream,
          200,
          headers: const <String, String>{
            'content-type': 'application/json',
          },
        );
      };

      final error = await _captureUnknown(client.exchange(_refreshGrant));
      await streamCancelled.future.timeout(const Duration(seconds: 1));

      expect(error.kind, SolvedOAuthFailureKind.timeout);
      expect(error.isTimeout, isTrue);
      expect(error.statusCode, isNull);
      expect(transport.requests, hasLength(1));
    });

    test('does not retry a client or response-stream failure', () async {
      handler = (_) async => throw http.ClientException('offline');
      var error = await _captureUnknown(client.exchange(_refreshGrant));
      expect(error.kind, SolvedOAuthFailureKind.transport);
      expect(error.cause, isA<http.ClientException>());

      handler = (_) async => http.StreamedResponse(
            Stream<List<int>>.error(http.ClientException('stream failed')),
            200,
            headers: const <String, String>{
              'content-type': 'application/json',
            },
          );
      error = await _captureUnknown(client.exchange(_refreshGrant));
      expect(error.kind, SolvedOAuthFailureKind.transport);
      expect(transport.requests, hasLength(2));
    });

    test('fails closed on invalid success responses without exposing tokens',
        () async {
      final cases = <http.StreamedResponse>[
        _bytesResponse(utf8.encode(_tokenBody)),
        _bytesResponse(
          utf8.encode(_tokenBody),
          headers: const <String, String>{'content-type': 'text/plain'},
        ),
        _bytesResponse(
          const <int>[0xff],
          headers: const <String, String>{
            'content-type': 'application/json',
          },
        ),
        _jsonResponse('{'),
        _jsonResponse(
          '{"access_token":"do-not-log-this-token",'
          '"token_type":"wrong","expires_in":3600,"scope":"profile"}',
        ),
      ];

      for (final response in cases) {
        handler = (_) async => response;
        final error = await _captureUnknown(client.exchange(_refreshGrant));
        expect(error.kind, SolvedOAuthFailureKind.invalidResponse);
        expect(error.statusCode, 200);
        expect(error.toString(), isNot(contains('do-not-log-this-token')));
        expect(
          error.cause.toString(),
          isNot(contains('do-not-log-this-token')),
        );
      }
      expect(transport.requests, hasLength(cases.length));
    });

    test('bounds request and response bodies at 64 KiB', () async {
      final oversizedToken = List<String>.filled(
        SolvedOAuthClient.maximumPayloadBytes,
        'x',
      ).join();
      await expectLater(
        client.exchange(
          SolvedOAuthRefreshTokenGrant(refreshToken: oversizedToken),
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(transport.requests, isEmpty);

      handler = (_) async => _bytesResponse(
            List<int>.filled(
              SolvedOAuthClient.maximumPayloadBytes + 1,
              0x20,
            ),
            headers: const <String, String>{
              'content-type': 'application/json',
            },
          );
      final error = await _captureUnknown(client.exchange(_refreshGrant));
      expect(error.kind, SolvedOAuthFailureKind.responseTooLarge);
      expect(error.statusCode, 200);
      expect(transport.requests, hasLength(1));
    });

    test('does not close an injected client and rejects use after close',
        () async {
      client.close();
      client.close();

      expect(transport.wasClosed, isFalse);
      await expectLater(
        client.exchange(_refreshGrant),
        throwsStateError,
      );
      expect(transport.requests, isEmpty);
    });
  });

  group('SolvedOAuthClient revocation transport', () {
    test('sends only the token field and accepts a JSON object', () async {
      final transport = _RecordingClient(
        (_) async => _jsonResponse('{}'),
      );
      final client = SolvedOAuthClient(
        proxyBaseUri: Uri.parse('https://proxy.example/solved/v4/'),
        httpClient: transport,
      );

      await client.revoke(SolvedOAuthRevokeRequest(token: 'opaque-token'));

      expect(transport.requests, hasLength(1));
      final request = transport.requests.single;
      expect(
        request.url,
        Uri.parse('https://proxy.example/solved/v4/oauth/revoke'),
      );
      expect(request.method, 'POST');
      expect(request.followRedirects, isFalse);
      expect(request.bodyFields, <String, String>{'token': 'opaque-token'});
      expect(request.headers.containsKey('authorization'), isFalse);
      expect(request.headers.containsKey('x-client-secret'), isFalse);
      client.close();
      expect(transport.wasClosed, isFalse);
    });

    test('treats a non-object 200 response as an unknown outcome', () async {
      final transport = _RecordingClient(
        (_) async => _jsonResponse('[]'),
      );
      final client = SolvedOAuthClient(
        proxyBaseUri: Uri.parse('https://proxy.example/solved/v4/'),
        httpClient: transport,
      );

      final error = await _captureUnknown(
        client.revoke(SolvedOAuthRevokeRequest(token: 'opaque-token')),
      );

      expect(error.operation, SolvedOAuthOperation.revoke);
      expect(error.kind, SolvedOAuthFailureKind.invalidResponse);
      expect(error.statusCode, 200);
      expect(error.toString(), isNot(contains('opaque-token')));
      expect(transport.requests, hasLength(1));
      client.close();
    });

    test('requires the documented revoke status and error pairs', () async {
      late int statusCode;
      late String errorCode;
      final transport = _RecordingClient(
        (_) async => _jsonResponse(
          '{"error":"$errorCode"}',
          statusCode: statusCode,
        ),
      );
      final client = SolvedOAuthClient(
        proxyBaseUri: Uri.parse('https://proxy.example/solved/v4/'),
        httpClient: transport,
      );

      for (final entry in <(int, String)>[
        (400, 'invalid_request'),
        (401, 'invalid_client'),
      ]) {
        statusCode = entry.$1;
        errorCode = entry.$2;
        final error = await _captureFailure(
          client.revoke(SolvedOAuthRevokeRequest(token: 'opaque-token')),
        );
        expect(error, isA<SolvedOAuthRejected>());
      }

      statusCode = 400;
      errorCode = 'invalid_grant';
      final mismatch = await _captureUnknown(
        client.revoke(SolvedOAuthRevokeRequest(token: 'opaque-token')),
      );
      expect(mismatch.kind, SolvedOAuthFailureKind.invalidResponse);
      expect(transport.requests, hasLength(3));
      client.close();
    });
  });
}

Future<http.StreamedResponse> _unusedHandler(http.Request request) async =>
    throw StateError('Unexpected request: ${request.url}');

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

Future<SolvedOAuthRequestFailed> _captureFailure(Future<Object?> future) async {
  try {
    await future;
  } on SolvedOAuthRequestFailed catch (error) {
    return error;
  }
  throw StateError('Expected an OAuth failure');
}

Future<SolvedOAuthOutcomeUnknown> _captureUnknown(
    Future<Object?> future) async {
  final error = await _captureFailure(future);
  if (error is SolvedOAuthOutcomeUnknown) return error;
  throw StateError('Expected an unknown OAuth outcome, got $error');
}

const String _verifier = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

final SolvedOAuthRefreshTokenGrant _refreshGrant =
    SolvedOAuthRefreshTokenGrant(refreshToken: 'single-use-refresh');

const String _tokenBody =
    '{"access_token":"access-token","token_type":"Bearer",'
    '"expires_in":3600,"refresh_token":"rotated-refresh",'
    '"scope":"profile future.scope"}';
