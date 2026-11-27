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

  test('builds affiliation rankings with omitted and explicit pages', () {
    final omitted = contract.rankingAffiliationUsers(1);
    final explicit = contract.rankingAffiliationUsers(1, page: 1);
    final later = contract.rankingAffiliationUsers(42, page: 999999);

    expect(omitted.direct.path, 'rankings/affiliations/1');
    expect(omitted.direct.queryParameters, isEmpty);
    expect(omitted.proxy.path, omitted.direct.path);
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(explicit.direct.queryParameters, {'page': '1'});
    expect(later.direct.path, 'rankings/affiliations/42');
    expect(later.direct.queryParameters, {'page': '999999'});
    expect(later.proxy.queryParameters, later.direct.queryParameters);
  });

  test('requires an affiliation id without inventing bounds', () {
    for (final id in [-9007199254740991, -1, 0, 9007199254740991]) {
      final endpoint = contract.rankingAffiliationUsers(id);
      expect(endpoint.direct.path, 'rankings/affiliations/$id');
      expect(endpoint.proxy.path, endpoint.direct.path);
    }
  });

  test('rejects pages below one', () {
    for (final page in [0, -1]) {
      expect(
        () => contract.rankingAffiliationUsers(1, page: page),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'page')
              .having((error) => error.invalidValue, 'invalidValue', page),
        ),
      );
    }
  });

  test('decodes with the shared strict leaderboard decoder', () {
    final endpoint = contract.rankingAffiliationUsers(1);
    final actual = endpoint.decode(
      jsonDecode(fixture('v4/ranking_users.json')),
    );

    expect(actual.me?.id, -1.5);
    expect(actual.me?.globalRank, -8);
    expect(actual.pageSize, 0);
    expect(actual.items, hasLength(3));
    expect(actual.items.first.globalRank, isNull);
    expect(actual.items.last.globalRank, -99);
    expect(() => actual.items.clear(), throwsUnsupportedError);

    final body =
        jsonDecode(fixture('v4/ranking_users.json')) as Map<String, dynamic>;
    expect(
      () => endpoint.decode(Map<String, dynamic>.of(body)..remove('items')),
      throwsFormatException,
    );
    (body['me'] as Map<String, dynamic>)['tier'] = 32;
    expect(() => endpoint.decode(body), throwsFormatException);
  });
}
