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

  test('builds rivals with an omitted or explicit page', () {
    final omitted = contract.rivals();
    final explicit = contract.rivals(page: 1);

    expect(omitted.proxy.path, 'rankings/rivals');
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(explicit.proxy.queryParameters, {'page': '1'});
    expect(explicit.direct.queryParameters, {'page': '1'});
    for (final page in [0, -1]) {
      expect(
        () => contract.rivals(page: page),
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', 'page'),
        ),
      );
    }
  });

  test('builds reverse rivals with the same strict decoder', () {
    final omitted = contract.reverseRivals();
    final explicit = contract.reverseRivals(page: 1);

    expect(omitted.proxy.path, 'rankings/reverse-rivals');
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(explicit.proxy.queryParameters, {'page': '1'});
    expect(
      () => contract.reverseRivals(page: 0),
      throwsA(
        isA<ArgumentError>().having((error) => error.name, 'name', 'page'),
      ),
    );
    final actual = omitted.decode(
      jsonDecode(fixture('v4/rival_leaderboard.json')),
    );
    expect(actual.reverseRivalCount, 0);
    expect(actual.items[1].isReverseRival, isTrue);
    expect(
      () => omitted.decode(_response()..remove('rivalCount')),
      throwsFormatException,
    );
  });

  test('decodes the complete fixture with the shared leaderboard user', () {
    final actual = contract.rivals().decode(
          jsonDecode(fixture('v4/rival_leaderboard.json')),
        );

    expect(actual.me!.id, -1.5);
    expect(actual.mePage, -2);
    expect(actual.total, -5);
    expect(actual.page, 99);
    expect(actual.pageSize, 0);
    expect(actual.rivalCount, -1);
    expect(actual.reverseRivalCount, 0);
    expect(actual.items.map((item) => item.isRival), [true, false, true]);
    expect(actual.items.map((item) => item.isReverseRival), [
      false,
      true,
      false,
    ]);
    expect(actual.items.last.user.tier, 31);
    expect(actual.items.last.user.globalRank, -99);
    expect(actual.items.first.user.id, isA<double>());
  });

  test('requires every field and preserves nullable states', () {
    final endpoint = contract.rivals();
    for (final invalid in <Object?>[null, 0, 'items', const <Object?>[]]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
    for (final field in _outerFields) {
      expect(
        () => endpoint.decode(_response()..remove(field)),
        throwsFormatException,
        reason: '$field missing',
      );
      final nulled = _response()..[field] = null;
      if (field == 'me' || field == 'mePage') {
        final actual = endpoint.decode(nulled);
        expect(field == 'me' ? actual.me : actual.mePage, isNull);
      } else {
        expect(
          () => endpoint.decode(nulled),
          throwsFormatException,
          reason: '$field null',
        );
      }
    }
    for (final field in ['isRival', 'isReverseRival', 'tagRating', 'class']) {
      final missing = _response();
      _first(missing).remove(field);
      expect(
        () => endpoint.decode(missing),
        throwsFormatException,
        reason: 'items[].$field missing',
      );
    }
    for (final entry in <String, Object?>{
      'isRival': 'true',
      'isReverseRival': null,
      'tier': 32,
      'rank': 1.0,
    }.entries) {
      final body = _response();
      _first(body)[entry.key] = entry.value;
      expect(
        () => endpoint.decode(body),
        throwsFormatException,
        reason: entry.key,
      );
    }
    for (final field in ['rivalCount', 'reverseRivalCount']) {
      expect(
        () => endpoint.decode(_response()..[field] = 1.0),
        throwsFormatException,
      );
    }
  });

  test('eagerly snapshots an ordered unmodifiable list', () {
    final endpoint = contract.rivals();
    final body = _response();
    final items = body['items'] as List<dynamic>;
    final actual = endpoint.decode(body);
    _first(body)['isRival'] = false;
    items.clear();

    expect(actual.items, hasLength(3));
    expect(actual.items.first.isRival, isTrue);
    expect(() => actual.items.clear(), throwsUnsupportedError);
  });
}

const _outerFields = [
  'me',
  'mePage',
  'total',
  'page',
  'pageSize',
  'items',
  'rivalCount',
  'reverseRivalCount',
];

Map<String, dynamic> _response() =>
    jsonDecode(fixture('v4/rival_leaderboard.json')) as Map<String, dynamic>;

Map<String, dynamic> _first(Map<String, dynamic> body) =>
    (body['items'] as List<dynamic>).first as Map<String, dynamic>;
