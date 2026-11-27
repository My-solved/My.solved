import 'package:solved_api/solved_api.dart';
import 'package:test/test.dart';

void main() {
  group('SolvedOAuthScope', () {
    test('exposes only the documented public scopes', () {
      expect(
        SolvedOAuthScope.values.map((scope) => scope.value),
        <String>[
          'profile',
          'profile.personal',
          'settings',
          'settings.write',
          'collection',
          'wallet',
          'standing',
          'solves',
          'votes',
          'rivals',
          'bookmarks',
          'bookmarks.write',
          'offline.access',
        ],
      );
      expect(SolvedOAuthScope.tryParse('judge.link'), isNull);
    });
  });

  group('SolvedOAuthAuthorizationRequest', () {
    test('builds the exact seven documented parameters without a secret', () {
      final request = _authorizationRequest(
        scopes: <SolvedOAuthScope>[
          SolvedOAuthScope.offlineAccess,
          SolvedOAuthScope.profile,
          SolvedOAuthScope.offlineAccess,
        ],
      );

      expect(
        request.scopes,
        <SolvedOAuthScope>[
          SolvedOAuthScope.profile,
          SolvedOAuthScope.offlineAccess,
        ],
      );
      final uri = request.authorizationUri;
      expect(uri.scheme, 'https');
      expect(uri.host, 'solved.ac');
      expect(uri.path, '/oauth/authorize');
      expect(uri.queryParameters, <String, String>{
        'response_type': 'code',
        'client_id': 'client-id',
        'redirect_uri': 'https://app.example/oauth/callback',
        'scope': 'profile offline.access',
        'state': 'state-value',
        'code_challenge': _challenge,
        'code_challenge_method': 'S256',
      });
      expect(uri.queryParameters, isNot(contains('client_secret')));
      expect(uri.queryParameters, hasLength(7));
      expect(
        () => request.scopes.add(SolvedOAuthScope.wallet),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('round-trips Unicode, spaces, plus signs, and redirect queries', () {
      final redirectUri = Uri.https(
        'app.example',
        '/oauth/한글',
        <String, String>{'next': '한 글', 'plus': '+'},
      );
      final uri = _authorizationRequest(
        clientId: '클라이언트 + id',
        redirectUri: redirectUri,
        state: '상태 + 값',
      ).authorizationUri;

      expect(uri.queryParameters['client_id'], '클라이언트 + id');
      expect(uri.queryParameters['redirect_uri'], redirectUri.toString());
      expect(uri.queryParameters['state'], '상태 + 값');
      expect(uri.toString(), isNot(contains('한글')));
    });

    test('allows HTTPS and HTTP only on localhost', () {
      expect(
        _authorizationRequest(
          redirectUri: Uri.parse('http://localhost:8080/oauth/callback?x=1'),
        ).redirectUri.host,
        'localhost',
      );
      expect(
        _authorizationRequest(
          redirectUri: Uri.parse('https://127.0.0.1/oauth/callback'),
        ).redirectUri.scheme,
        'https',
      );

      for (final redirectUri in <Uri>[
        Uri.parse('/relative'),
        Uri.parse('http://app.example/oauth/callback'),
        Uri.parse('http://localhost.example/oauth/callback'),
        Uri.parse('my.solved://oauth/callback'),
        Uri.parse('https://user@app.example/oauth/callback'),
        Uri.parse('https://app.example/oauth/callback#fragment'),
      ]) {
        expect(
          () => _authorizationRequest(redirectUri: redirectUri),
          throwsA(isA<ArgumentError>()),
          reason: redirectUri.toString(),
        );
      }
    });

    test('requires non-empty client state and an S256-shaped challenge', () {
      expect(
        () => _authorizationRequest(clientId: ''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => _authorizationRequest(state: ''),
        throwsA(isA<ArgumentError>()),
      );
      for (final challenge in <String>[
        _repeat('a', 42),
        _repeat('a', 44),
        '${_repeat('a', 42)}=',
        '${_repeat('a', 42)}.',
        '${_repeat('a', 42)}한',
      ]) {
        expect(
          () => _authorizationRequest(codeChallenge: challenge),
          throwsA(isA<ArgumentError>()),
          reason: challenge,
        );
      }
    });
  });

  group('SolvedOAuthTokenGrant', () {
    test('keeps authorization-code fields exclusive and deterministic', () {
      final redirectUri = Uri.parse('https://app.example/oauth/callback?x=1');
      final grant = SolvedOAuthAuthorizationCodeGrant(
        code: 'issued-code',
        redirectUri: redirectUri,
        codeVerifier: _verifier43,
      );

      expect(grant.formFields, <String, String>{
        'code': 'issued-code',
        'code_verifier': _verifier43,
        'grant_type': 'authorization_code',
        'redirect_uri': redirectUri.toString(),
      });
      expect(grant.formFields, isNot(contains('refresh_token')));
    });

    test('accepts verifier boundaries and every allowed unreserved symbol', () {
      for (final verifier in <String>[
        _verifier43,
        '${_repeat('z', 124)}._~-',
      ]) {
        expect(
          SolvedOAuthAuthorizationCodeGrant(
            code: 'code',
            redirectUri: Uri.parse('https://app.example/callback'),
            codeVerifier: verifier,
          ).codeVerifier,
          verifier,
        );
      }
    });

    test('rejects invalid PKCE verifiers and redirect URIs', () {
      for (final verifier in <String>[
        _repeat('a', 42),
        _repeat('a', 129),
        '${_repeat('a', 42)}=',
        '${_repeat('a', 42)} ',
        '${_repeat('a', 42)}한',
        '${_repeat('a', 42)}\n',
      ]) {
        expect(
          () => SolvedOAuthAuthorizationCodeGrant(
            code: 'code',
            redirectUri: Uri.parse('https://app.example/callback'),
            codeVerifier: verifier,
          ),
          throwsA(isA<ArgumentError>()),
          reason: verifier,
        );
      }
      expect(
        () => SolvedOAuthAuthorizationCodeGrant(
          code: 'code',
          redirectUri: Uri.parse('my.solved://callback'),
          codeVerifier: _verifier43,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('keeps refresh fields exclusive and supports scope narrowing', () {
      final plain = SolvedOAuthRefreshTokenGrant(refreshToken: 'refresh');
      expect(plain.formFields, <String, String>{
        'grant_type': 'refresh_token',
        'refresh_token': 'refresh',
      });

      final narrowed = SolvedOAuthRefreshTokenGrant(
        refreshToken: 'refresh',
        scopes: <SolvedOAuthScope>[
          SolvedOAuthScope.offlineAccess,
          SolvedOAuthScope.profilePersonal,
          SolvedOAuthScope.offlineAccess,
        ],
      );
      expect(narrowed.formFields, <String, String>{
        'grant_type': 'refresh_token',
        'refresh_token': 'refresh',
        'scope': 'profile.personal offline.access',
      });
      expect(narrowed.formFields, isNot(contains('code')));
      expect(narrowed.formFields, isNot(contains('code_verifier')));
      expect(narrowed.formFields, isNot(contains('redirect_uri')));
    });

    test('rejects empty tokens and an explicitly empty scope list', () {
      expect(
        () => SolvedOAuthRefreshTokenGrant(refreshToken: ''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => SolvedOAuthRefreshTokenGrant(
          refreshToken: 'refresh',
          scopes: const <SolvedOAuthScope>[],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('SolvedOAuthTokenResponse', () {
    test('parses tokens and preserves future scope strings', () {
      final response = SolvedOAuthTokenResponse.fromJson(<String, Object?>{
        'access_token': 'access',
        'token_type': 'Bearer',
        'expires_in': 3600,
        'refresh_token': 'refresh',
        'scope': 'profile future.scope offline.access',
        'future_response_field': true,
      });

      expect(response.accessToken, 'access');
      expect(response.tokenType, 'Bearer');
      expect(response.expiresIn, 3600);
      expect(response.refreshToken, 'refresh');
      expect(
        response.scopeValues,
        <String>['profile', 'future.scope', 'offline.access'],
      );
      expect(
        response.knownScopes,
        <SolvedOAuthScope>[
          SolvedOAuthScope.profile,
          SolvedOAuthScope.offlineAccess,
        ],
      );
      expect(response.unknownScopes, <String>['future.scope']);
    });

    test('accepts a response without an offline refresh token', () {
      final response = SolvedOAuthTokenResponse.fromJson(<String, Object?>{
        'access_token': 'access',
        'token_type': 'Bearer',
        'expires_in': 3600.5,
        'scope': 'profile',
      });

      expect(response.refreshToken, isNull);
      expect(response.expiresIn, 3600.5);
    });

    test('accepts only proxy-compatible opaque access tokens', () {
      final tokens = <String>[
        'a',
        'abc-._~+/=',
        'header.payload.signature',
        'padded==',
        List<String>.filled(4089, 'a').join(),
      ];

      for (final token in tokens) {
        final response = SolvedOAuthTokenResponse.fromJson(<String, Object?>{
          'access_token': token,
          'token_type': 'Bearer',
          'expires_in': 3600,
          'scope': 'profile',
        });
        expect(response.accessToken, token);
      }
    });

    test('keeps refresh tokens opaque and redacts token responses', () {
      const accessToken = 'do-not-log-access';
      const refreshToken = '회전 refresh +/~!=';
      final response = SolvedOAuthTokenResponse.fromJson(<String, Object?>{
        'access_token': accessToken,
        'token_type': 'Bearer',
        'expires_in': 3600,
        'refresh_token': refreshToken,
        'scope': 'profile offline.access',
      });

      expect(response.refreshToken, refreshToken);
      expect(response.toString(), 'SolvedOAuthTokenResponse(<redacted>)');
      expect(response.toString(), isNot(contains(accessToken)));
      expect(response.toString(), isNot(contains(refreshToken)));
    });

    test('rejects malformed required fields and scope syntax', () {
      final valid = <String, Object?>{
        'access_token': 'access',
        'token_type': 'Bearer',
        'expires_in': 3600,
        'scope': 'profile',
      };
      final invalid = <Object?>[
        null,
        <Object?, Object?>{1: 'not a string key'},
        <String, Object?>{...valid}..remove('access_token'),
        <String, Object?>{...valid, 'access_token': ''},
        <String, Object?>{
          ...valid,
          'access_token': List<String>.filled(4090, 'a').join(),
        },
        <String, Object?>{...valid, 'access_token': ' access'},
        <String, Object?>{...valid, 'access_token': 'access '},
        <String, Object?>{...valid, 'access_token': 'ac cess'},
        <String, Object?>{...valid, 'access_token': 'access\r\nheader'},
        <String, Object?>{...valid, 'access_token': 'access,other'},
        <String, Object?>{...valid, 'access_token': '토큰'},
        <String, Object?>{...valid, 'access_token': '=access'},
        <String, Object?>{...valid, 'access_token': 'access=middle=x'},
        <String, Object?>{...valid, 'access_token': '='},
        <String, Object?>{...valid, 'access_token': 'access\u0000'},
        <String, Object?>{...valid, 'token_type': 'bearer'},
        <String, Object?>{...valid, 'expires_in': 0},
        <String, Object?>{...valid, 'expires_in': double.nan},
        <String, Object?>{...valid, 'refresh_token': null},
        <String, Object?>{...valid, 'refresh_token': ''},
        <String, Object?>{...valid, 'scope': ''},
        <String, Object?>{...valid, 'scope': 'profile  offline.access'},
        <String, Object?>{...valid, 'scope': 'profile"bad'},
        <String, Object?>{...valid, 'scope': r'profile\bad'},
      ];

      for (final body in invalid) {
        expect(
          () => SolvedOAuthTokenResponse.fromJson(body),
          throwsA(isA<FormatException>()),
          reason: body.toString(),
        );
      }
    });
  });

  group('SolvedOAuthErrorResponse', () {
    test('parses required and optional fields while allowing future fields',
        () {
      final response = SolvedOAuthErrorResponse.fromJson(<String, Object?>{
        'error': 'invalid_grant',
        'error_description': 'The code was already used.',
        'future_response_field': true,
      });

      expect(response.error, 'invalid_grant');
      expect(response.errorDescription, 'The code was already used.');
      expect(
        SolvedOAuthErrorResponse.fromJson(<String, Object?>{
          'error': 'invalid_client',
        }).errorDescription,
        isNull,
      );
    });

    test('rejects malformed fields', () {
      for (final body in <Object?>[
        null,
        <String, Object?>{},
        <String, Object?>{'error': ''},
        <String, Object?>{'error': 1},
        <String, Object?>{'error': 'invalid_grant', 'error_description': null},
      ]) {
        expect(
          () => SolvedOAuthErrorResponse.fromJson(body),
          throwsA(isA<FormatException>()),
          reason: body.toString(),
        );
      }
    });
  });

  group('SolvedOAuthRevokeRequest', () {
    test('emits only the documented token field', () {
      final request = SolvedOAuthRevokeRequest(token: 'opaque-token');
      expect(request.formFields, <String, String>{'token': 'opaque-token'});
      expect(
        () => request.formFields['token_type_hint'] = 'access_token',
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('rejects an empty token', () {
      expect(
        () => SolvedOAuthRevokeRequest(token: ''),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

SolvedOAuthAuthorizationRequest _authorizationRequest({
  String clientId = 'client-id',
  Uri? redirectUri,
  Iterable<SolvedOAuthScope> scopes = const <SolvedOAuthScope>[],
  String state = 'state-value',
  String codeChallenge = _challenge,
}) =>
    SolvedOAuthAuthorizationRequest(
      clientId: clientId,
      redirectUri:
          redirectUri ?? Uri.parse('https://app.example/oauth/callback'),
      scopes: scopes,
      state: state,
      codeChallenge: codeChallenge,
    );

String _repeat(String value, int count) =>
    List<String>.filled(count, value).join();

const String _challenge = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const String _verifier43 = _challenge;
