import 'dart:convert';

import 'package:solved_api/solved_api.dart';
import 'package:test/test.dart';

import 'helpers/fixture.dart';

void main() {
  late SolvedApiV4Contract contract;

  setUp(() {
    contract = SolvedApiV4Contract(
      proxyBaseUri: Uri.parse('https://proxy.example/solved/v4/'),
    );
  });

  test('builds the bodyless viewer wallet endpoint', () {
    final endpoint = contract.accountWallet();
    expect(endpoint.proxy.path, 'account/wallet');
    expect(endpoint.proxy.queryParameters, isEmpty);
  });

  test('decodes the wallet without inferred relationships', () {
    final actual = contract.accountWallet().decode(
          jsonDecode(fixture('v4/account_wallet.json')),
        );

    expect(actual.stardusts, -5);
    expect(actual.today.day, 'not a date');
    expect(actual.today.earned, 120);
    expect(actual.today.cap, 100);
    expect(actual.earnings.firstSolve, 0);
    expect(actual.earnings.solve, -1);
    expect(actual.earnings.contribute, 3);
    expect(actual.earnings.welcomePerSolve, 7);
    expect(actual.earnings.welcomeMax, 2);
  });

  test('requires every field with strict types', () {
    final endpoint = contract.accountWallet();
    for (final invalid in <Object?>[null, 0, 'wallet', const <Object?>[]]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
    for (final field in ['stardusts', 'today', 'earnings']) {
      for (final invalid in <Object?>[_missing, null, '1']) {
        final body = _response();
        _mutate(body, field, invalid);
        expect(
          () => endpoint.decode(body),
          throwsFormatException,
          reason: '$field = $invalid',
        );
      }
    }
    expect(
      () => endpoint.decode(_response()..['stardusts'] = 1.0),
      throwsFormatException,
    );
    for (final (object, field) in [
      ('today', 'day'),
      ('today', 'earned'),
      ('today', 'cap'),
      ('earnings', 'firstSolve'),
      ('earnings', 'solve'),
      ('earnings', 'contribute'),
      ('earnings', 'welcomePerSolve'),
      ('earnings', 'welcomeMax'),
    ]) {
      for (final invalid in <Object?>[
        _missing,
        null,
        field == 'day' ? 0 : 1.0,
      ]) {
        final body = _response();
        _mutate(body[object] as Map<String, dynamic>, field, invalid);
        expect(
          () => endpoint.decode(body),
          throwsFormatException,
          reason: '$object.$field = $invalid',
        );
      }
    }
    expect(
      endpoint.decode(_response()..['future'] = true).stardusts,
      -5,
    );
  });
}

const _missing = Object();

void _mutate(Map<String, dynamic> body, String field, Object? value) {
  if (identical(value, _missing)) {
    body.remove(field);
  } else {
    body[field] = value;
  }
}

Map<String, dynamic> _response() =>
    jsonDecode(fixture('v4/account_wallet.json')) as Map<String, dynamic>;
