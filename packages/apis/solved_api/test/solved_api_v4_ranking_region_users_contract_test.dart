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

  test('builds region rankings with omitted and explicit default pages', () {
    final omitted = contract.rankingRegionUsers('KR');
    final explicit = contract.rankingRegionUsers('KR', page: 1);
    final later = contract.rankingRegionUsers('kr', page: 999999);

    expect(omitted.direct.path, 'rankings/regions/KR');
    expect(omitted.direct.queryParameters, isEmpty);
    expect(omitted.proxy.path, omitted.direct.path);
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(explicit.direct.queryParameters, {'page': '1'});
    expect(later.direct.path, 'rankings/regions/kr');
    expect(later.direct.queryParameters, {'page': '999999'});
    expect(later.proxy.queryParameters, later.direct.queryParameters);
  });

  test('accepts any two-code-point safe segment and encodes it raw', () {
    final cases = <String, String>{
      'ZZ': 'rankings/regions/ZZ',
      '00': 'rankings/regions/00',
      '한글': 'rankings/regions/%ED%95%9C%EA%B8%80',
      '🌏🌏': 'rankings/regions/%F0%9F%8C%8F%F0%9F%8C%8F',
      '%2': 'rankings/regions/%252',
      ' .': 'rankings/regions/%20.',
    };
    for (final MapEntry(key: countryCode, value: path) in cases.entries) {
      final endpoint = contract.rankingRegionUsers(countryCode);
      expect(endpoint.direct.path, path, reason: countryCode);
      expect(endpoint.proxy.path, path, reason: countryCode);
    }
  });

  test('rejects country codes outside two code points or unsafe segments', () {
    for (final invalid in [
      '',
      'K',
      '🌏',
      'KRX',
      '..',
      'K/',
      r'K\',
      'K\u0000',
      '\u007fK',
      'K\u0080',
      '\u009fK',
    ]) {
      expect(
        () => contract.rankingRegionUsers(invalid),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'countryCode')
              .having((error) => error.invalidValue, 'invalidValue', invalid),
        ),
        reason: invalid,
      );
    }
  });

  test('rejects pages below one', () {
    for (final page in [0, -1]) {
      expect(
        () => contract.rankingRegionUsers('KR', page: page),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'page')
              .having((error) => error.invalidValue, 'invalidValue', page),
        ),
      );
    }
  });

  test('decodes with the shared strict leaderboard decoder', () {
    final endpoint = contract.rankingRegionUsers('KR');
    final actual = endpoint.decode(
      jsonDecode(fixture('v4/ranking_users.json')),
    );

    expect(actual.me?.id, -1.5);
    expect(actual.me?.id, isA<double>());
    expect(actual.mePage, -2);
    expect(actual.page, 99);
    expect(actual.items, hasLength(3));
    expect(actual.items.last.tier, 31);
    expect(() => actual.items.clear(), throwsUnsupportedError);

    final body =
        jsonDecode(fixture('v4/ranking_users.json')) as Map<String, dynamic>;
    expect(
      () => endpoint.decode(Map<String, dynamic>.of(body)..remove('me')),
      throwsFormatException,
    );
    final items = body['items'] as List<dynamic>;
    (items.first as Map<String, dynamic>).remove('globalRank');
    expect(() => endpoint.decode(body), throwsFormatException);
  });
}
