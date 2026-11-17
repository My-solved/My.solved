import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:solved_api/solved_api.dart';
import 'package:test/test.dart';

void main() {
  group('SolvedOAuthAuthorizationSession', () {
    test('binds secure state, PKCE, redirect, and grant values', () {
      final redirectUri = Uri.parse(
        'https://app.example/oauth/callback?source=solved',
      );
      final session = SolvedOAuthAuthorizationSession.generate(
        clientId: 'client-id',
        redirectUri: redirectUri,
        scopes: <SolvedOAuthScope>[
          SolvedOAuthScope.wallet,
          SolvedOAuthScope.offlineAccess,
        ],
      );
      final request = session.authorizationRequest;
      final grant = session.createAuthorizationCodeGrant(code: 'issued-code');

      expect(request.clientId, 'client-id');
      expect(request.redirectUri, redirectUri);
      expect(request.scopes, <SolvedOAuthScope>[
        SolvedOAuthScope.profile,
        SolvedOAuthScope.wallet,
        SolvedOAuthScope.offlineAccess,
      ]);
      expect(request.state, matches(_base64Url43));
      expect(grant.code, 'issued-code');
      expect(grant.redirectUri, redirectUri);
      expect(grant.codeVerifier, matches(_base64Url43));
      expect(request.state, isNot(grant.codeVerifier));
      expect(request.codeChallenge, _s256Challenge(grant.codeVerifier));
      expect(request.authorizationUri.queryParameters, <String, String>{
        'response_type': 'code',
        'client_id': 'client-id',
        'redirect_uri': redirectUri.toString(),
        'scope': 'profile wallet offline.access',
        'state': request.state,
        'code_challenge': request.codeChallenge,
        'code_challenge_method': 'S256',
      });
    });

    test('generates independent 256-bit values for every attempt', () {
      final sessions = List<SolvedOAuthAuthorizationSession>.generate(
        64,
        (_) => SolvedOAuthAuthorizationSession.generate(
          clientId: 'client-id',
          redirectUri: Uri.parse('https://app.example/oauth/callback'),
        ),
      );
      final states =
          sessions
              .map((session) => session.authorizationRequest.state)
              .toList();
      final verifiers =
          sessions
              .map(
                (session) =>
                    session
                        .createAuthorizationCodeGrant(code: 'code')
                        .codeVerifier,
              )
              .toList();

      expect(states, everyElement(matches(_base64Url43)));
      expect(verifiers, everyElement(matches(_base64Url43)));
      expect(states.toSet(), hasLength(states.length));
      expect(verifiers.toSet(), hasLength(verifiers.length));
      expect(states.toSet().intersection(verifiers.toSet()), isEmpty);
    });

    test('does not expose state or verifier through toString', () {
      final session = SolvedOAuthAuthorizationSession.generate(
        clientId: 'client-id',
        redirectUri: Uri.parse('https://app.example/oauth/callback'),
      );
      final state = session.authorizationRequest.state;
      final verifier =
          session.createAuthorizationCodeGrant(code: 'code').codeVerifier;

      expect(session.toString(), 'SolvedOAuthAuthorizationSession(<redacted>)');
      expect(session.toString(), isNot(contains(state)));
      expect(session.toString(), isNot(contains(verifier)));
    });

    test('keeps contract validation at the session boundary', () {
      expect(
        () => SolvedOAuthAuthorizationSession.generate(
          clientId: '',
          redirectUri: Uri.parse('https://app.example/oauth/callback'),
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => SolvedOAuthAuthorizationSession.generate(
          clientId: 'client-id',
          redirectUri: Uri.parse('my.solved://oauth/callback'),
        ),
        throwsA(isA<ArgumentError>()),
      );

      final session = SolvedOAuthAuthorizationSession.generate(
        clientId: 'client-id',
        redirectUri: Uri.parse('https://app.example/oauth/callback'),
      );
      expect(
        () => session.createAuthorizationCodeGrant(code: ''),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

String _s256Challenge(String verifier) => base64UrlEncode(
  sha256.convert(ascii.encode(verifier)).bytes,
).replaceAll('=', '');

final RegExp _base64Url43 = RegExp(r'^[A-Za-z0-9_-]{43}$');
