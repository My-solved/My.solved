import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_solved/app/config/solved_api_gateway_config.dart';
import 'package:my_solved/app/config/solved_oauth_runtime_config.dart';
import 'package:solved_api/solved_api.dart';

void main() {
  group('SolvedOAuthRuntimeConfig', () {
    test('keeps OAuth disabled when both public values are absent', () {
      final config = SolvedOAuthRuntimeConfig.parse(
        clientId: '',
        redirectUri: '',
        gatewayConfig: _legacyGateway(),
        allowInsecureLoopback: false,
      );
      final httpClient = MockClient((_) async => http.Response('{}', 200));

      expect(config.isConfigured, isFalse);
      expect(config.clientId, isNull);
      expect(config.redirectUri, isNull);
      expect(config.createAuthorizationSession, throwsStateError);
      expect(
        () => config.createClient(httpClient: httpClient),
        throwsStateError,
      );
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
            allowInsecureLoopback: false,
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
          allowInsecureLoopback: false,
        ),
        throwsFormatException,
      );
    });

    test('creates a bound session and proxy-only client when configured', () {
      final config = SolvedOAuthRuntimeConfig.parse(
        clientId: 'client-id',
        redirectUri:
            'https://app.example/oauth/callback?source=solved&source=mobile',
        gatewayConfig: _v4Gateway(),
        allowInsecureLoopback: false,
      );
      final session = config.createAuthorizationSession(
        scopes: <SolvedOAuthScope>[SolvedOAuthScope.wallet],
      );
      final httpClient = MockClient((_) async => http.Response('{}', 200));
      final oauthClient = config.createClient(httpClient: httpClient);

      expect(config.isConfigured, isTrue);
      expect(config.clientId, 'client-id');
      expect(
        config.redirectUri,
        Uri.parse(
          'https://app.example/oauth/callback?source=solved&source=mobile',
        ),
      );
      expect(session.authorizationRequest.clientId, 'client-id');
      expect(session.authorizationRequest.redirectUri, config.redirectUri);
      expect(session.authorizationRequest.scopes, <SolvedOAuthScope>[
        SolvedOAuthScope.profile,
        SolvedOAuthScope.wallet,
      ]);
      expect(oauthClient, isA<SolvedOAuthClient>());
      oauthClient.close();
    });

    test('requests only profile by default', () {
      final config = _configured();

      expect(
        config.createAuthorizationSession().authorizationRequest.scopes,
        <SolvedOAuthScope>[SolvedOAuthScope.profile],
      );
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
            allowInsecureLoopback: false,
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
          allowInsecureLoopback: true,
        ).redirectUri,
        Uri.parse(redirectUri),
      );
      expect(
        () => SolvedOAuthRuntimeConfig.parse(
          clientId: 'client-id',
          redirectUri: redirectUri,
          gatewayConfig: _v4Gateway(),
          allowInsecureLoopback: false,
        ),
        throwsFormatException,
      );
      expect(
        () => SolvedOAuthRuntimeConfig.parse(
          clientId: 'client-id',
          redirectUri: 'http://127.0.0.1:8080/oauth/callback',
          gatewayConfig: _v4Gateway(),
          allowInsecureLoopback: true,
        ),
        throwsFormatException,
      );
    });

    test('passes explicit loopback permission to the OAuth client', () {
      final gateway = SolvedApiGatewayConfig.parse(
        mode: solvedApiOfficialV4Mode,
        v4ProxyBaseUri: 'http://localhost:3000/solved/v4/',
        allowInsecureLoopback: true,
      );
      expect(
        () => SolvedOAuthRuntimeConfig.parse(
          clientId: 'client-id',
          redirectUri: 'https://app.example/oauth/callback',
          gatewayConfig: gateway,
          allowInsecureLoopback: false,
        ),
        throwsFormatException,
      );
      final config = SolvedOAuthRuntimeConfig.parse(
        clientId: 'client-id',
        redirectUri: 'http://localhost:8080/oauth/callback',
        gatewayConfig: gateway,
        allowInsecureLoopback: true,
      );
      final oauthClient = config.createClient(
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );

      expect(oauthClient, isA<SolvedOAuthClient>());
      oauthClient.close();
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
            allowInsecureLoopback: false,
          ),
          throwsFormatException,
          reason: redirectUri,
        );
      }
    });
  });
}

SolvedOAuthRuntimeConfig _configured() => SolvedOAuthRuntimeConfig.parse(
  clientId: 'client-id',
  redirectUri: 'https://app.example/oauth/callback',
  gatewayConfig: _v4Gateway(),
  allowInsecureLoopback: false,
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
