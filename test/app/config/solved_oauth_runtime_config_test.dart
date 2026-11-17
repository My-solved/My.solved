import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:my_solved/app/config/solved_api_gateway_config.dart';
import 'package:my_solved/app/config/solved_oauth_runtime_config.dart';
import 'package:solved_api/solved_api.dart';

typedef _RequestHandler =
    Future<http.StreamedResponse> Function(http.BaseRequest request);

final class _TrackingClient extends http.BaseClient {
  _TrackingClient(this.handler);

  final _RequestHandler handler;
  final List<http.BaseRequest> requests = <http.BaseRequest>[];
  bool wasClosed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (wasClosed) throw StateError('Tracking client is closed');
    requests.add(request);
    return handler(request);
  }

  @override
  void close() {
    wasClosed = true;
  }
}

void main() {
  group('SolvedOAuthRuntimeConfig', () {
    test('keeps OAuth disabled when both public values are absent', () {
      final config = SolvedOAuthRuntimeConfig.parse(
        clientId: '',
        redirectUri: '',
        gatewayConfig: _legacyGateway(),
        allowInsecureRedirectLoopback: false,
      );
      final httpClient = _TrackingClient((_) async => _jsonResponse('{}'));

      expect(config.isConfigured, isFalse);
      expect(config.clientId, isNull);
      expect(config.redirectUri, isNull);
      expect(
        () => config.createRuntime(httpClient: httpClient),
        throwsStateError,
      );
      expect(httpClient.requests, isEmpty);
      expect(httpClient.wasClosed, isFalse);
    });

    test('rejects partial public OAuth configuration', () {
      for (final values in <(String, String)>[
        ('client-id', ''),
        ('', 'https://app.example/oauth/callback'),
      ]) {
        expect(
          () => SolvedOAuthRuntimeConfig.parse(
            clientId: values.$1,
            redirectUri: values.$2,
            gatewayConfig: _v4Gateway(),
            allowInsecureRedirectLoopback: false,
          ),
          throwsFormatException,
        );
      }
    });

    test('rejects configured OAuth without the official v4 gateway', () {
      expect(
        () => SolvedOAuthRuntimeConfig.parse(
          clientId: 'client-id',
          redirectUri: 'https://app.example/oauth/callback',
          gatewayConfig: _legacyGateway(),
          allowInsecureRedirectLoopback: false,
        ),
        throwsFormatException,
      );
    });

    test('creates one bound coordinator without sending a request', () {
      final config = SolvedOAuthRuntimeConfig.parse(
        clientId: 'client-id',
        redirectUri:
            'https://app.example/oauth/callback?source=solved&source=mobile',
        gatewayConfig: _v4Gateway(),
        allowInsecureRedirectLoopback: false,
      );
      final httpClient = _TrackingClient((_) async => _jsonResponse('{}'));
      final runtime = config.createRuntime(
        httpClient: httpClient,
        scopes: <SolvedOAuthScope>[SolvedOAuthScope.wallet],
      );
      final authorization = runtime.coordinator.begin();

      expect(config.isConfigured, isTrue);
      expect(config.clientId, 'client-id');
      expect(
        config.redirectUri,
        Uri.parse(
          'https://app.example/oauth/callback?source=solved&source=mobile',
        ),
      );
      expect(
        runtime.coordinator.state,
        SolvedOAuthAuthorizationState.awaitingCallback,
      );
      expect(authorization.clientId, 'client-id');
      expect(authorization.redirectUri, config.redirectUri);
      expect(authorization.scopes, <SolvedOAuthScope>[
        SolvedOAuthScope.profile,
        SolvedOAuthScope.wallet,
      ]);
      expect(httpClient.requests, isEmpty);
      expect(runtime.toString(), 'SolvedOAuthRuntime(<redacted>)');

      runtime.coordinator.cancel();
      runtime.close();
      runtime.close();
      expect(httpClient.wasClosed, isFalse);
    });

    test('requests only profile by default', () {
      final config = _configured();
      final httpClient = _TrackingClient((_) async => _jsonResponse('{}'));
      final runtime = config.createRuntime(httpClient: httpClient);
      final authorization = runtime.coordinator.begin();

      expect(authorization.scopes, <SolvedOAuthScope>[
        SolvedOAuthScope.profile,
      ]);
      expect(httpClient.requests, isEmpty);
      runtime.coordinator.cancel();
      runtime.close();
    });

    test(
      'wires token and identity requests only through the configured gateway',
      () async {
        final config = _configured();
        late _RequestHandler handler;
        final httpClient = _TrackingClient((request) => handler(request));
        handler = (request) async {
          if (request.method == 'POST') {
            return _jsonResponse(
              jsonEncode(<String, Object?>{
                'access_token': 'access-token',
                'token_type': 'Bearer',
                'expires_in': 3600,
                'refresh_token': 'refresh-token',
                'scope': 'profile offline.access',
              }),
            );
          }
          if (request.method == 'GET') {
            return _jsonResponse('{"id":7,"handle":"index"}');
          }
          throw StateError('Unexpected request method');
        };
        final runtime = config.createRuntime(httpClient: httpClient);
        final authorization = runtime.coordinator.begin();

        final outcome = await runtime.coordinator.complete(
          callbackUri: authorization.redirectUri.replace(
            queryParameters: <String, String>{
              'code': 'issued-code',
              'state': authorization.state,
            },
          ),
        );

        expect(outcome, isA<SolvedOAuthAuthorizationCompleted>());
        expect(httpClient.requests, hasLength(2));
        expect(httpClient.requests.first.method, 'POST');
        expect(
          httpClient.requests.first.url,
          Uri.parse('https://gateway.example/solved/v4/oauth/token'),
        );
        expect(httpClient.requests.last.method, 'GET');
        expect(
          httpClient.requests.last.url,
          Uri.parse('https://gateway.example/solved/v4/me'),
        );
        expect(
          httpClient.requests.last.headers['authorization'],
          'Bearer access-token',
        );
        expect(
          httpClient.requests.where(
            (request) =>
                request.url.host == 'solved.ac' ||
                request.url.path.endsWith('/oauth/revoke'),
          ),
          isEmpty,
        );

        runtime.close();
        expect(httpClient.wasClosed, isFalse);
      },
    );

    test('AppScreen exposes only the coordinator from the OAuth runtime', () {
      final source = File('lib/app/screen/app_screen.dart').readAsStringSync();

      expect(
        source,
        contains('RepositoryProvider<SolvedOAuthAuthorizationCoordinator>'),
      );
      expect(source, isNot(contains('RepositoryProvider<SolvedOAuthClient>')));
      expect(source, isNot(contains('value: _solvedOAuthRuntimeConfig')));
    });

    test('rejects surrounding whitespace in either public value', () {
      for (final values in <(String, String)>[
        (' client-id', 'https://app.example/oauth/callback'),
        ('client-id ', 'https://app.example/oauth/callback'),
        ('client-id', ' https://app.example/oauth/callback'),
        ('client-id', 'https://app.example/oauth/callback '),
      ]) {
        expect(
          () => SolvedOAuthRuntimeConfig.parse(
            clientId: values.$1,
            redirectUri: values.$2,
            gatewayConfig: _v4Gateway(),
            allowInsecureRedirectLoopback: false,
          ),
          throwsFormatException,
        );
      }
    });

    test('allows HTTP localhost redirects only when explicitly enabled', () {
      const redirectUri = 'http://localhost:8080/oauth/callback';
      expect(
        SolvedOAuthRuntimeConfig.parse(
          clientId: 'client-id',
          redirectUri: redirectUri,
          gatewayConfig: _v4Gateway(),
          allowInsecureRedirectLoopback: true,
        ).redirectUri,
        Uri.parse(redirectUri),
      );
      expect(
        () => SolvedOAuthRuntimeConfig.parse(
          clientId: 'client-id',
          redirectUri: redirectUri,
          gatewayConfig: _v4Gateway(),
          allowInsecureRedirectLoopback: false,
        ),
        throwsFormatException,
      );
      expect(
        () => SolvedOAuthRuntimeConfig.parse(
          clientId: 'client-id',
          redirectUri: 'http://127.0.0.1:8080/oauth/callback',
          gatewayConfig: _v4Gateway(),
          allowInsecureRedirectLoopback: true,
        ),
        throwsFormatException,
      );
    });

    test('keeps gateway and redirect loopback capabilities separate', () {
      final gateway = SolvedApiGatewayConfig.parse(
        mode: solvedApiOfficialV4Mode,
        v4ProxyBaseUri: 'http://localhost:3000/solved/v4/',
        allowInsecureLoopback: true,
      );
      final config = SolvedOAuthRuntimeConfig.parse(
        clientId: 'client-id',
        redirectUri: 'https://app.example/oauth/callback',
        gatewayConfig: gateway,
        allowInsecureRedirectLoopback: false,
      );
      final httpClient = _TrackingClient((_) async => _jsonResponse('{}'));
      final runtime = config.createRuntime(httpClient: httpClient);

      expect(runtime.coordinator.state, SolvedOAuthAuthorizationState.idle);
      expect(httpClient.requests, isEmpty);
      runtime.close();
      expect(httpClient.wasClosed, isFalse);
    });

    test('rejects malformed redirect boundaries and reserved queries', () {
      const invalidRedirects = <String>[
        '/oauth/callback',
        'https:///oauth/callback',
        'http://app.example/oauth/callback',
        'https://user@app.example/oauth/callback',
        'https://@app.example/oauth/callback',
        'https://app.example/oauth/callback#fragment',
        'https://app.example/oauth/callback#',
        'https://app.example/oauth/callback?code=value',
        'https://app.example/oauth/callback?state=value',
        'https://app.example/oauth/callback?co%64e=value',
        'https://app.example/oauth/callback?%73tate=value',
      ];

      for (final redirectUri in invalidRedirects) {
        expect(
          () => SolvedOAuthRuntimeConfig.parse(
            clientId: 'client-id',
            redirectUri: redirectUri,
            gatewayConfig: _v4Gateway(),
            allowInsecureRedirectLoopback: false,
          ),
          throwsFormatException,
          reason: redirectUri,
        );
      }
    });
  });
}

http.StreamedResponse _jsonResponse(String body, {int statusCode = 200}) =>
    http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(body)),
      statusCode,
      headers: const <String, String>{
        'content-type': 'application/json; charset=utf-8',
      },
    );

SolvedOAuthRuntimeConfig _configured() => SolvedOAuthRuntimeConfig.parse(
  clientId: 'client-id',
  redirectUri: 'https://app.example/oauth/callback',
  gatewayConfig: _v4Gateway(),
  allowInsecureRedirectLoopback: false,
);

SolvedApiGatewayConfig _legacyGateway() => SolvedApiGatewayConfig.parse(
  mode: solvedApiLegacyV3Mode,
  v4ProxyBaseUri: '',
  allowInsecureLoopback: false,
);

SolvedApiGatewayConfig _v4Gateway() => SolvedApiGatewayConfig.parse(
  mode: solvedApiOfficialV4Mode,
  v4ProxyBaseUri: 'https://gateway.example/solved/v4/',
  allowInsecureLoopback: false,
);
