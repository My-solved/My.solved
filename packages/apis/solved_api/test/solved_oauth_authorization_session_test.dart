import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:solved_api/solved_api.dart';
import 'package:test/test.dart';

void main() {
  group('SolvedOAuthAuthorizationSession', () {
    test('binds secure state, PKCE, redirect, and callback values', () {
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
      const code = 'issued +/%한글';
      final grant = session.consumeAuthorizationCodeCallback(
        callbackUri: _validCallback(session, code: code),
      );

      expect(request.clientId, 'client-id');
      expect(request.redirectUri, redirectUri);
      expect(request.scopes, <SolvedOAuthScope>[
        SolvedOAuthScope.profile,
        SolvedOAuthScope.wallet,
        SolvedOAuthScope.offlineAccess,
      ]);
      expect(request.state, matches(_base64Url43));
      expect(grant.code, code);
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
      final states = sessions
          .map((session) => session.authorizationRequest.state)
          .toList();
      final verifiers = sessions
          .map(
            (session) => session
                .consumeAuthorizationCodeCallback(
                  callbackUri: _validCallback(session),
                )
                .codeVerifier,
          )
          .toList();

      expect(states, everyElement(matches(_base64Url43)));
      expect(verifiers, everyElement(matches(_base64Url43)));
      expect(states.toSet(), hasLength(states.length));
      expect(verifiers.toSet(), hasLength(verifiers.length));
      expect(states.toSet().intersection(verifiers.toSet()), isEmpty);
    });

    test('accepts the registered query multimap regardless of key order', () {
      final session = _session(
        redirectUri: Uri.parse(
          'https://app.example/oauth/callback?source=solved&source=mobile&next=a%2Bb',
        ),
      );
      final state = session.authorizationRequest.state;
      final callback = Uri.parse(
        'https://app.example/oauth/callback?code=issued-code&next=a%2Bb&'
        'source=solved&source=mobile&state=$state',
      );

      expect(
        session.consumeAuthorizationCodeCallback(callbackUri: callback).code,
        'issued-code',
      );
    });

    test('rejects another attempt state without consuming the session', () {
      final session = _session();
      final otherSession = _session();
      final wrongCallback = _validCallback(
        session,
        state: otherSession.authorizationRequest.state,
      );

      expect(
        () => session.consumeAuthorizationCodeCallback(
          callbackUri: wrongCallback,
        ),
        throwsA(isA<SolvedOAuthAuthorizationCallbackRejected>()),
      );
      expect(
        session
            .consumeAuthorizationCodeCallback(
              callbackUri: _validCallback(session),
            )
            .code,
        'issued-code',
      );
    });

    test('rejects wrong-length and same-length state mismatches', () {
      final session = _session();
      final state = session.authorizationRequest.state;
      final sameLengthMismatch =
          '${state.substring(0, state.length - 1)}${state.endsWith('a') ? 'b' : 'a'}';

      for (final invalidState in <String>['short', sameLengthMismatch]) {
        expect(
          () => session.consumeAuthorizationCodeCallback(
            callbackUri: _validCallback(session, state: invalidState),
          ),
          throwsA(isA<SolvedOAuthAuthorizationCallbackRejected>()),
          reason: invalidState,
        );
      }
      expect(
        session
            .consumeAuthorizationCodeCallback(
              callbackUri: _validCallback(session),
            )
            .code,
        'issued-code',
      );
    });

    test('rejects redirect component and fragment changes', () {
      final session = _session();
      final state = session.authorizationRequest.state;
      final callbacks = <Uri>[
        _callbackWithRawParameters(
            session,
            <String>[
              'code=issued-code',
              'state=$state',
            ],
            baseUri: Uri.parse('http://app.example/oauth/callback')),
        _callbackWithRawParameters(
            session,
            <String>[
              'code=issued-code',
              'state=$state',
            ],
            baseUri: Uri.parse('https://other.example/oauth/callback')),
        _callbackWithRawParameters(
            session,
            <String>[
              'code=issued-code',
              'state=$state',
            ],
            baseUri: Uri.parse('https://user@app.example/oauth/callback')),
        _callbackWithRawParameters(
            session,
            <String>[
              'code=issued-code',
              'state=$state',
            ],
            baseUri: Uri.parse('https://app.example:8443/oauth/callback')),
        _callbackWithRawParameters(
            session,
            <String>[
              'code=issued-code',
              'state=$state',
            ],
            baseUri: Uri.parse('https://app.example/oauth/other')),
        Uri.parse('${_validCallback(session)}#fragment'),
      ];

      for (final callback in callbacks) {
        expect(
          () => session.consumeAuthorizationCodeCallback(callbackUri: callback),
          throwsA(isA<SolvedOAuthAuthorizationCallbackRejected>()),
          reason: callback.toString(),
        );
      }

      final encodedPathSession = _session(
        redirectUri: Uri.parse('https://app.example/oauth/a%2Fb'),
      );
      expect(
        () => encodedPathSession.consumeAuthorizationCodeCallback(
          callbackUri: _callbackWithRawParameters(
            encodedPathSession,
            <String>[
              'code=issued-code',
              'state=${encodedPathSession.authorizationRequest.state}',
            ],
            baseUri: Uri.parse('https://app.example/oauth/a/b'),
          ),
        ),
        throwsA(isA<SolvedOAuthAuthorizationCallbackRejected>()),
      );
      expect(
        session
            .consumeAuthorizationCodeCallback(
              callbackUri: _validCallback(session),
            )
            .code,
        'issued-code',
      );
    });

    test('rejects changed registered query values and duplicate order', () {
      final session = _session(
        redirectUri: Uri.parse(
          'https://app.example/oauth/callback?source=solved&source=mobile',
        ),
      );
      final state = session.authorizationRequest.state;
      final callbacks = <Uri>[
        Uri.parse(
          'https://app.example/oauth/callback?source=solved&code=issued-code&state=$state',
        ),
        Uri.parse(
          'https://app.example/oauth/callback?source=changed&source=mobile&code=issued-code&state=$state',
        ),
        Uri.parse(
          'https://app.example/oauth/callback?source=mobile&source=solved&code=issued-code&state=$state',
        ),
        Uri.parse(
          'https://app.example/oauth/callback?source=solved&source=mobile&source=extra&code=issued-code&state=$state',
        ),
      ];

      for (final callback in callbacks) {
        expect(
          () => session.consumeAuthorizationCodeCallback(callbackUri: callback),
          throwsA(isA<SolvedOAuthAuthorizationCallbackRejected>()),
          reason: callback.toString(),
        );
      }
      expect(
        session
            .consumeAuthorizationCodeCallback(
              callbackUri: _validCallback(session),
            )
            .code,
        'issued-code',
      );
    });

    test('rejects missing empty duplicate and unknown callback fields', () {
      final session = _session();
      final state = session.authorizationRequest.state;
      final callbacks = <Uri>[
        _callbackWithRawParameters(session, <String>['state=$state']),
        _callbackWithRawParameters(session, <String>['code=issued-code']),
        _callbackWithRawParameters(session, <String>['code=', 'state=$state']),
        _callbackWithRawParameters(session, <String>[
          'code=issued-code',
          'state=',
        ]),
        _callbackWithRawParameters(session, <String>[
          'code=first',
          'code=second',
          'state=$state',
        ]),
        _callbackWithRawParameters(session, <String>[
          'code=issued-code',
          'state=$state',
          'state=$state',
        ]),
        _callbackWithRawParameters(session, <String>[
          'code=issued-code',
          'state=$state',
          'extra=value',
        ]),
      ];

      for (final callback in callbacks) {
        expect(
          () => session.consumeAuthorizationCodeCallback(callbackUri: callback),
          throwsA(isA<SolvedOAuthAuthorizationCallbackRejected>()),
          reason: callback.toString(),
        );
      }
      expect(
        session
            .consumeAuthorizationCodeCallback(
              callbackUri: _validCallback(session),
            )
            .code,
        'issued-code',
      );
    });

    test('rejects percent-encoded duplicate callback field names', () {
      final session = _session();
      final state = session.authorizationRequest.state;
      for (final callback in <Uri>[
        _callbackWithRawParameters(session, <String>[
          'code=first',
          'co%64e=second',
          'state=$state',
        ]),
        _callbackWithRawParameters(session, <String>[
          'code=issued-code',
          'state=$state',
          '%73tate=other',
        ]),
      ]) {
        expect(
          () => session.consumeAuthorizationCodeCallback(callbackUri: callback),
          throwsA(isA<SolvedOAuthAuthorizationCallbackRejected>()),
        );
      }
      expect(
        session
            .consumeAuthorizationCodeCallback(
              callbackUri: _validCallback(session),
            )
            .code,
        'issued-code',
      );
    });

    test('allows exactly one grant after a successful callback', () {
      final session = _session();
      final callback = _validCallback(session, code: 'one-time-code');
      final grant = session.consumeAuthorizationCodeCallback(
        callbackUri: callback,
      );

      expect(grant.code, 'one-time-code');
      expect(
        () => session.consumeAuthorizationCodeCallback(callbackUri: callback),
        throwsStateError,
      );
      expect(
        () => session.consumeAuthorizationCodeCallback(
          callbackUri: Uri.parse('https://attacker.example/callback'),
        ),
        throwsStateError,
      );
    });

    test('redacts callback rejection and consumed-session errors', () {
      final session = _session();
      final state = session.authorizationRequest.state;
      const code = 'secret-authorization-code';
      final invalidCallback = _validCallback(
        session,
        code: code,
        state: 'wrong-state-value',
      );
      final rejected = _captureError(
        () => session.consumeAuthorizationCodeCallback(
          callbackUri: invalidCallback,
        ),
      );

      expect(rejected, isA<SolvedOAuthAuthorizationCallbackRejected>());
      expect(
        rejected.toString(),
        'SolvedOAuthAuthorizationCallbackRejected(<redacted>)',
      );
      for (final secret in <String>[code, state, invalidCallback.toString()]) {
        expect(rejected.toString(), isNot(contains(secret)));
      }

      final grant = session.consumeAuthorizationCodeCallback(
        callbackUri: _validCallback(session, code: code),
      );
      final consumed = _captureError(
        () => session.consumeAuthorizationCodeCallback(
          callbackUri: _validCallback(session, code: code),
        ),
      );
      for (final secret in <String>[code, state, grant.codeVerifier]) {
        expect(consumed.toString(), isNot(contains(secret)));
      }
    });

    test('does not expose state or verifier through toString', () {
      final session = _session();
      final state = session.authorizationRequest.state;
      final verifier = session
          .consumeAuthorizationCodeCallback(
            callbackUri: _validCallback(session),
          )
          .codeVerifier;

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
      for (final reservedName in <String>[
        'code',
        'state',
        'co%64e',
        '%73tate',
      ]) {
        expect(
          () => _session(
            redirectUri: Uri.parse(
              'https://app.example/oauth/callback?$reservedName=value',
            ),
          ),
          throwsA(isA<ArgumentError>()),
          reason: reservedName,
        );
      }

      final session = _session();
      expect(
        () => session.consumeAuthorizationCodeCallback(
          callbackUri: _callbackWithRawParameters(session, <String>[
            'code=',
            'state=${session.authorizationRequest.state}',
          ]),
        ),
        throwsA(isA<SolvedOAuthAuthorizationCallbackRejected>()),
      );
    });
  });
}

SolvedOAuthAuthorizationSession _session({Uri? redirectUri}) =>
    SolvedOAuthAuthorizationSession.generate(
      clientId: 'client-id',
      redirectUri:
          redirectUri ?? Uri.parse('https://app.example/oauth/callback'),
    );

Uri _validCallback(
  SolvedOAuthAuthorizationSession session, {
  String code = 'issued-code',
  String? state,
}) =>
    _callbackWithRawParameters(session, <String>[
      'code=${Uri.encodeQueryComponent(code)}',
      'state=${Uri.encodeQueryComponent(state ?? session.authorizationRequest.state)}',
    ]);

Uri _callbackWithRawParameters(
  SolvedOAuthAuthorizationSession session,
  List<String> parameters, {
  Uri? baseUri,
}) {
  final base = baseUri ?? session.authorizationRequest.redirectUri;
  final separator = !base.hasQuery
      ? '?'
      : base.query.isEmpty
          ? ''
          : '&';
  return Uri.parse('$base$separator${parameters.join('&')}');
}

Object _captureError(void Function() callback) {
  try {
    callback();
  } catch (error) {
    return error;
  }
  fail('Expected callback to throw');
}

String _s256Challenge(String verifier) => base64UrlEncode(
      sha256.convert(ascii.encode(verifier)).bytes,
    ).replaceAll('=', '');

final RegExp _base64Url43 = RegExp(r'^[A-Za-z0-9_-]{43}$');
