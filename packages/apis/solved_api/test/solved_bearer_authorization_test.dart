import 'dart:convert';

import 'package:solved_api/src/solved_bearer_authorization.dart';
import 'package:test/test.dart';

void main() {
  test('builds a maximum-size proxy Bearer header without exposing it', () {
    final token = List<String>.filled(
      SolvedBearerAuthorization.maximumTokenBytes,
      'a',
    ).join();
    final authorization = SolvedBearerAuthorization.fromAccessToken(token);

    expect(
      utf8.encode(authorization.headerValue),
      hasLength(SolvedBearerAuthorization.maximumHeaderValueBytes),
    );
    expect(
      authorization.headerValue.length,
      SolvedBearerAuthorization.maximumHeaderValueBytes,
    );
    expect(authorization.headerValue, 'Bearer $token');
    expect(authorization.toString(), 'SolvedBearerAuthorization(<redacted>)');
    expect(authorization.toString(), isNot(contains(token)));
  });

  test('rejects tokens the proxy cannot forward', () {
    final invalid = <String>[
      List<String>.filled(
        SolvedBearerAuthorization.maximumTokenBytes + 1,
        'a',
      ).join(),
      'do-not-log\r\nheader',
      'middle=padding',
    ];

    for (final token in invalid) {
      expect(
        () => SolvedBearerAuthorization.fromAccessToken(token),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'access_token is not a valid Bearer token',
          ),
        ),
      );
    }
  });
}
