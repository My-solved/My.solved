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

  test('builds tag rankings with omitted and explicit default pages', () {
    final omitted = contract.rankingTagUsers('math');
    final explicit = contract.rankingTagUsers('math', page: 1);
    final later = contract.rankingTagUsers('dp', page: 999999);

    expect(omitted.direct.path, 'rankings/tags/math');
    expect(omitted.direct.queryParameters, isEmpty);
    expect(omitted.proxy.path, omitted.direct.path);
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(explicit.direct.queryParameters, {'page': '1'});
    expect(later.direct.path, 'rankings/tags/dp');
    expect(later.direct.queryParameters, {'page': '999999'});
    expect(later.proxy.queryParameters, later.direct.queryParameters);
  });

  test('accepts 1 through 64 code-point safe keys and encodes them raw', () {
    final maximum = List<String>.filled(64, '🌏').join();
    final cases = <String, String>{
      'a': 'rankings/tags/a',
      'number_theory': 'rankings/tags/number_theory',
      'a b&한': 'rankings/tags/a%20b%26%ED%95%9C',
      '%2F': 'rankings/tags/%252F',
      '.a': 'rankings/tags/.a',
      maximum: 'rankings/tags/${Uri.encodeComponent(maximum)}',
    };
    for (final MapEntry(key: key, value: path) in cases.entries) {
      final endpoint = contract.rankingTagUsers(key);
      expect(endpoint.direct.path, path, reason: key);
      expect(endpoint.proxy.path, path, reason: key);
    }
  });

  test('rejects keys outside 1 through 64 code points or unsafe segments', () {
    for (final invalid in [
      '',
      List<String>.filled(65, 'a').join(),
      List<String>.filled(65, '🌏').join(),
      '.',
      '..',
      'a/b',
      r'a\b',
      'a\u0000',
      'a\u007f',
    ]) {
      expect(
        () => contract.rankingTagUsers(invalid),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'key')
              .having((error) => error.invalidValue, 'invalidValue', invalid),
        ),
        reason: invalid,
      );
    }
  });

  test('rejects pages below one', () {
    for (final page in [0, -1]) {
      expect(
        () => contract.rankingTagUsers('math', page: page),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'page')
              .having((error) => error.invalidValue, 'invalidValue', page),
        ),
      );
    }
  });

  test('decodes with the shared strict leaderboard decoder', () {
    final endpoint = contract.rankingTagUsers('math');
    final actual = endpoint.decode(
      jsonDecode(fixture('v4/ranking_users.json')),
    );

    expect(actual.me?.id, -1.5);
    expect(actual.me?.tagRating, isNull);
    expect(actual.total, -5);
    expect(actual.items, hasLength(3));
    expect(actual.items.first.tagRating, -5);
    expect(actual.items.last.tagRating, isNull);
    expect(() => actual.items.clear(), throwsUnsupportedError);

    final body =
        jsonDecode(fixture('v4/ranking_users.json')) as Map<String, dynamic>;
    expect(
      () => endpoint.decode(Map<String, dynamic>.of(body)..remove('mePage')),
      throwsFormatException,
    );
    final items = body['items'] as List<dynamic>;
    (items.first as Map<String, dynamic>).remove('tagRating');
    expect(() => endpoint.decode(body), throwsFormatException);
  });
}
