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

  test('builds the board with exact optional query semantics', () {
    final omitted = contract.rankingAffiliationBoard();
    final explicit = contract.rankingAffiliationBoard(
      page: 1,
      affiliationType: OfficialUserProfileAffiliationType.community,
      language: '',
    );
    final rawLanguage = contract.rankingAffiliationBoard(
      language: '한 글 & raw',
    );
    final language16 = List<String>.filled(16, '🌏').join();

    expect(omitted.direct.path, 'rankings/affiliation-board');
    expect(omitted.direct.queryParameters, isEmpty);
    expect(omitted.proxy.path, omitted.direct.path);
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(explicit.direct.queryParameters, {
      'page': '1',
      'type': 'community',
      'lang': '',
    });
    expect(explicit.proxy.queryParameters, explicit.direct.queryParameters);
    expect(rawLanguage.direct.queryParameters, {'lang': '한 글 & raw'});
    expect(
      contract
          .rankingAffiliationBoard(language: language16)
          .direct
          .queryParameters,
      {'lang': language16},
    );

    for (final page in [0, -1]) {
      expect(
        () => contract.rankingAffiliationBoard(page: page),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'page')
              .having((error) => error.invalidValue, 'invalidValue', page),
        ),
      );
    }
    final language17 = List<String>.filled(17, '🌏').join();
    expect(
      () => contract.rankingAffiliationBoard(language: language17),
      throwsA(
        isA<ArgumentError>()
            .having((error) => error.name, 'name', 'language')
            .having((error) => error.invalidValue, 'invalidValue', language17),
      ),
    );
  });

  test('decodes the complete fixture without inferring relationships', () {
    final actual = contract
        .rankingAffiliationBoard(
          page: 1,
          affiliationType: OfficialUserProfileAffiliationType.university,
        )
        .decode(jsonDecode(fixture('v4/ranking_affiliation_board.json')));

    expect(actual.total, -11);
    expect(actual.page, 0);
    expect(actual.pageSize, -2);
    expect(actual.mine, hasLength(1));
    final mine = actual.mine.single;
    expect(mine.id, -100);
    expect(mine.affiliationId, 999);
    expect(mine.name, 'mine only');
    expect(mine.type, OfficialUserProfileAffiliationType.company);
    expect(mine.logoThumbnailUrl, isNull);
    expect(mine.color, '');
    expect(mine.rank, -3);
    expect(mine.globalRank, isNull);
    expect(mine.rating, -4);
    expect(mine.userCount, 0);
    expect(mine.solvedCount, -5);
    expect(mine.page, -7);

    expect(actual.items, hasLength(2));
    expect(actual.items.map((item) => item.id), [-1, -1]);
    expect(actual.items.map((item) => item.affiliationId), [0, 42]);
    expect(actual.items.map((item) => item.type.value), [
      'undefined',
      'community',
    ]);
    expect(actual.items.map((item) => item.rank), [-9, 99]);
    expect(actual.items.map((item) => item.globalRank), [0, -8]);
    expect(actual.items.map((item) => item.rating), [-10, 100]);
    expect(actual.items.map((item) => item.userCount), [-7, 123]);
    expect(actual.items.map((item) => item.solvedCount), [0, -1]);
    expect(actual.items.first.logoThumbnailUrl, 'not necessarily a URI');
    expect(actual.items.first.color, isNull);
    expect(actual.items.last.color, 'not necessarily a color');
  });

  test('requires the complete outer object and strict outer integers', () {
    final endpoint = contract.rankingAffiliationBoard();
    for (final invalid in <Object?>[
      null,
      0,
      false,
      'board',
      const <Object?>[],
      const <String, Object?>{},
    ]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }

    for (final field in _outerFields) {
      expect(
        () => endpoint.decode(_envelope()..remove(field)),
        throwsFormatException,
        reason: '$field missing',
      );
      expect(
        () => endpoint.decode(_envelope()..[field] = null),
        throwsFormatException,
        reason: '$field null',
      );
    }
    for (final field in ['mine', 'items']) {
      for (final invalid in <Object?>[
        0,
        false,
        'items',
        const <String, Object?>{},
      ]) {
        expect(
          () => endpoint.decode(_envelope()..[field] = invalid),
          throwsFormatException,
        );
      }
    }
    for (final field in ['total', 'page', 'pageSize']) {
      for (final value in [-1000000, 0, 1000000]) {
        final actual = endpoint.decode(_envelope()..[field] = value);
        expect(_outerInteger(actual, field), value);
      }
      for (final invalid in <Object?>[1.0, '1', false, const <Object?>[]]) {
        expect(
          () => endpoint.decode(_envelope()..[field] = invalid),
          throwsFormatException,
        );
      }
    }
  });

  test('requires every board item field and validates items eagerly', () {
    final endpoint = contract.rankingAffiliationBoard();
    for (final invalid in <Object?>[
      null,
      0,
      false,
      'item',
      const <Object?>[],
    ]) {
      expect(
        () => endpoint.decode(
          _envelope(items: <Object?>[_item(), invalid]),
        ),
        throwsFormatException,
      );
    }
    for (final field in _itemFields) {
      expect(
        () => endpoint.decode(
          _envelope(items: <Object?>[_item()..remove(field)]),
        ),
        throwsFormatException,
        reason: '$field missing',
      );
      if (!_nullableFields.contains(field)) {
        expect(
          () => endpoint.decode(
            _envelope(items: <Object?>[_item()..[field] = null]),
          ),
          throwsFormatException,
          reason: '$field null',
        );
      }
    }
  });

  test('requires every mine field and validates mine eagerly', () {
    final endpoint = contract.rankingAffiliationBoard();
    for (final invalid in <Object?>[
      null,
      0,
      false,
      'mine',
      const <Object?>[],
    ]) {
      expect(
        () => endpoint.decode(
          _envelope(mine: <Object?>[_mine(), invalid]),
        ),
        throwsFormatException,
      );
    }
    for (final field in _mineFields) {
      expect(
        () => endpoint.decode(
          _envelope(mine: <Object?>[_mine()..remove(field)]),
        ),
        throwsFormatException,
        reason: '$field missing',
      );
      if (!_nullableFields.contains(field)) {
        expect(
          () => endpoint.decode(
            _envelope(mine: <Object?>[_mine()..[field] = null]),
          ),
          throwsFormatException,
          reason: '$field null',
        );
      }
    }
  });

  test('preserves required nullable strings and global ranks', () {
    final endpoint = contract.rankingAffiliationBoard();
    final longValue = List<String>.filled(512, '🌏').join();
    for (final mine in [false, true]) {
      for (final field in ['logoThumbnailUrl', 'color']) {
        for (final value in <String?>[null, '', ' ', '한 글 & raw', longValue]) {
          final entry = mine ? _mine() : _item();
          entry[field] = value;
          final actual = endpoint.decode(
            mine
                ? _envelope(mine: <Object?>[entry])
                : _envelope(items: <Object?>[entry]),
          );
          expect(
            mine
                ? _mineString(actual.mine.single, field)
                : _itemString(actual.items.single, field),
            value,
          );
        }
        for (final invalid in <Object?>[
          0,
          false,
          const <Object?>[],
          const <String, Object?>{},
        ]) {
          final entry = mine ? _mine() : _item();
          entry[field] = invalid;
          expect(
            () => endpoint.decode(
              mine
                  ? _envelope(mine: <Object?>[entry])
                  : _envelope(items: <Object?>[entry]),
            ),
            throwsFormatException,
          );
        }
      }
      for (final value in <int?>[null, -1000000, 0, 1000000]) {
        final entry = mine ? _mine() : _item();
        entry['globalRank'] = value;
        final actual = endpoint.decode(
          mine
              ? _envelope(mine: <Object?>[entry])
              : _envelope(items: <Object?>[entry]),
        );
        expect(
          mine ? actual.mine.single.globalRank : actual.items.single.globalRank,
          value,
        );
      }
      for (final invalid in <Object?>[1.0, '1', false, const <Object?>[]]) {
        final entry = mine ? _mine() : _item();
        entry['globalRank'] = invalid;
        expect(
          () => endpoint.decode(
            mine
                ? _envelope(mine: <Object?>[entry])
                : _envelope(items: <Object?>[entry]),
          ),
          throwsFormatException,
        );
      }
    }
  });

  test('preserves raw names and the exact shared type vocabulary', () {
    final endpoint = contract.rankingAffiliationBoard();
    const types = [
      'undefined',
      'university',
      'high_school',
      'middle_school',
      'elementary_school',
      'company',
      'community',
    ];
    expect(
      OfficialUserProfileAffiliationType.values.map((type) => type.value),
      types,
    );
    final longName = List<String>.filled(512, '🌏').join();
    for (final mine in [false, true]) {
      for (final name in ['', ' ', '한 글 & raw', longName]) {
        final entry = mine ? _mine() : _item();
        entry['name'] = name;
        final actual = endpoint.decode(
          mine
              ? _envelope(mine: <Object?>[entry])
              : _envelope(items: <Object?>[entry]),
        );
        expect(
          mine ? actual.mine.single.name : actual.items.single.name,
          name,
        );
      }
      for (final invalid in <Object?>[
        0,
        false,
        const <Object?>[],
        const <String, Object?>{},
      ]) {
        final entry = mine ? _mine() : _item();
        entry['name'] = invalid;
        expect(
          () => endpoint.decode(
            mine
                ? _envelope(mine: <Object?>[entry])
                : _envelope(items: <Object?>[entry]),
          ),
          throwsFormatException,
        );
      }
      for (final type in types) {
        final entry = mine ? _mine() : _item();
        entry['type'] = type;
        final actual = endpoint.decode(
          mine
              ? _envelope(mine: <Object?>[entry])
              : _envelope(items: <Object?>[entry]),
        );
        expect(
          mine ? actual.mine.single.type.value : actual.items.single.type.value,
          type,
        );
      }
      for (final invalid in <Object?>[
        'future',
        '',
        null,
        0,
        false,
        const <Object?>[],
        const <String, Object?>{},
      ]) {
        final entry = mine ? _mine() : _item();
        entry['type'] = invalid;
        expect(
          () => endpoint.decode(
            mine
                ? _envelope(mine: <Object?>[entry])
                : _envelope(items: <Object?>[entry]),
          ),
          throwsFormatException,
        );
      }
    }
  });

  test('preserves every exact unbounded item and mine integer', () {
    final endpoint = contract.rankingAffiliationBoard();
    for (final mine in [false, true]) {
      final fields = mine ? _mineIntegerFields : _itemIntegerFields;
      for (final field in fields) {
        for (final value in [-1000000, 0, 1000000]) {
          final entry = mine ? _mine() : _item();
          entry[field] = value;
          final actual = endpoint.decode(
            mine
                ? _envelope(mine: <Object?>[entry])
                : _envelope(items: <Object?>[entry]),
          );
          expect(
            mine
                ? _mineInteger(actual.mine.single, field)
                : _itemInteger(actual.items.single, field),
            value,
          );
        }
        for (final invalid in <Object?>[
          null,
          1.0,
          '1',
          false,
          const <Object?>[],
        ]) {
          final entry = mine ? _mine() : _item();
          entry[field] = invalid;
          expect(
            () => endpoint.decode(
              mine
                  ? _envelope(mine: <Object?>[entry])
                  : _envelope(items: <Object?>[entry]),
            ),
            throwsFormatException,
          );
        }
      }
    }
  });

  test('preserves empty order duplicates future fields and isolation', () {
    final endpoint = contract.rankingAffiliationBoard();
    final emptyMine = <Object?>[];
    final emptyItems = <Object?>[];
    final empty = endpoint.decode(
      _envelope(mine: emptyMine, items: emptyItems)..['futureEnvelope'] = true,
    );
    emptyMine.add(_mine());
    emptyItems.add(_item());
    expect(empty.mine, isEmpty);
    expect(empty.items, isEmpty);
    expect(() => empty.mine.clear(), throwsUnsupportedError);
    expect(() => empty.items.clear(), throwsUnsupportedError);

    final firstMine = _mine()
      ..['id'] = -1
      ..['page'] = -3
      ..['futureMine'] = true;
    final secondMine = _mine()
      ..['id'] = 99
      ..['page'] = 42;
    final firstItem = _item()
      ..['id'] = -2
      ..['name'] = 'duplicate'
      ..['futureItem'] = true;
    final secondItem = _item()
      ..['id'] = 100
      ..['name'] = 'duplicate';
    final mineSource = <Object?>[firstMine, firstMine, secondMine];
    final itemSource = <Object?>[firstItem, firstItem, secondItem];
    final source = _envelope(mine: mineSource, items: itemSource);
    final actual = endpoint.decode(source);
    mineSource.clear();
    itemSource.clear();
    firstMine
      ..['id'] = 1000
      ..['page'] = 1000;
    firstItem
      ..['id'] = 1000
      ..['name'] = 'changed';
    source['total'] = 1000;

    expect(actual.total, 0);
    expect(actual.mine.map((item) => item.id), [-1, -1, 99]);
    expect(actual.mine.map((item) => item.page), [-3, -3, 42]);
    expect(actual.items.map((item) => item.id), [-2, -2, 100]);
    expect(actual.items.map((item) => item.name), [
      'duplicate',
      'duplicate',
      'duplicate',
    ]);
    expect(() => actual.mine.clear(), throwsUnsupportedError);
    expect(() => actual.items.clear(), throwsUnsupportedError);
  });
}

const _outerFields = ['mine', 'total', 'page', 'pageSize', 'items'];

const _itemFields = [
  'id',
  'affiliationId',
  'name',
  'type',
  'logoThumbnailUrl',
  'color',
  'rank',
  'globalRank',
  'rating',
  'userCount',
  'solvedCount',
];

const _mineFields = [..._itemFields, 'page'];

const _nullableFields = {'logoThumbnailUrl', 'color', 'globalRank'};

const _itemIntegerFields = [
  'id',
  'affiliationId',
  'rank',
  'rating',
  'userCount',
  'solvedCount',
];

const _mineIntegerFields = [..._itemIntegerFields, 'page'];

Map<String, Object?> _envelope({
  List<Object?>? mine,
  List<Object?>? items,
}) =>
    <String, Object?>{
      'mine': mine ?? <Object?>[_mine()],
      'total': 0,
      'page': 0,
      'pageSize': 0,
      'items': items ?? <Object?>[_item()],
    };

Map<String, Object?> _item() => <String, Object?>{
      'id': 1,
      'affiliationId': 2,
      'name': 'School',
      'type': 'university',
      'logoThumbnailUrl': 'logo',
      'color': 'color',
      'rank': 3,
      'globalRank': 4,
      'rating': 5,
      'userCount': 6,
      'solvedCount': 7,
    };

Map<String, Object?> _mine() => _item()..['page'] = 8;

int _outerInteger(RankingAffiliationBoardResult value, String field) =>
    switch (field) {
      'total' => value.total,
      'page' => value.page,
      _ => value.pageSize,
    };

String? _itemString(RankingAffiliationBoardItem value, String field) =>
    field == 'logoThumbnailUrl' ? value.logoThumbnailUrl : value.color;

String? _mineString(RankingAffiliationBoardMineItem value, String field) =>
    field == 'logoThumbnailUrl' ? value.logoThumbnailUrl : value.color;

int _itemInteger(RankingAffiliationBoardItem value, String field) =>
    switch (field) {
      'id' => value.id,
      'affiliationId' => value.affiliationId,
      'rank' => value.rank,
      'rating' => value.rating,
      'userCount' => value.userCount,
      _ => value.solvedCount,
    };

int _mineInteger(RankingAffiliationBoardMineItem value, String field) =>
    switch (field) {
      'id' => value.id,
      'affiliationId' => value.affiliationId,
      'rank' => value.rank,
      'rating' => value.rating,
      'userCount' => value.userCount,
      'solvedCount' => value.solvedCount,
      _ => value.page,
    };
