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

  test('builds ranking users with omitted and explicit defaults', () {
    final omitted = contract.rankingUsers();
    final pageOnly = contract.rankingUsers(page: 1);
    final sortOnly = contract.rankingUsers(sort: SolvedApiV4UserSort.rating);
    final combined = contract.rankingUsers(
      page: 999999,
      sort: SolvedApiV4UserSort.contribution,
    );

    expect(omitted.direct.path, 'rankings/users');
    expect(omitted.direct.queryParameters, isEmpty);
    expect(omitted.proxy.path, omitted.direct.path);
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(pageOnly.direct.queryParameters, {'page': '1'});
    expect(sortOnly.direct.queryParameters, {'sort': 'rating'});
    expect(combined.direct.queryParameters, {
      'page': '999999',
      'sort': 'contribution',
    });
    expect(combined.proxy.queryParameters, combined.direct.queryParameters);
    expect(
      SolvedApiV4UserSort.values.map((sort) => sort.value),
      ['rating', 'solved', 'contribution'],
    );

    for (final page in [0, -1]) {
      expect(
        () => contract.rankingUsers(page: page),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'page')
              .having((error) => error.invalidValue, 'invalidValue', page),
        ),
      );
    }
  });

  test('decodes the complete fixture without inferred relationships', () {
    final actual = contract.rankingUsers().decode(
          jsonDecode(fixture('v4/ranking_users.json')),
        );

    expect(actual.me, isNotNull);
    expect(actual.me!.id, -1.5);
    expect(actual.me!.id, isA<double>());
    expect(actual.me!.handle, 'me unrelated to items');
    expect(actual.me!.tier, isNull);
    expect(actual.me!.profileImageUrl, '');
    expect(actual.me!.rank, -10);
    expect(actual.me!.rating, 0);
    expect(actual.me!.solvedCount, -7);
    expect(actual.me!.voteCount, 42);
    expect(actual.me!.reputation, -9);
    expect(actual.me!.userClass, -3);
    expect(actual.me!.classPlus, isTrue);
    expect(actual.me!.tagRating, isNull);
    expect(actual.me!.globalRank, -8);
    expect(actual.mePage, -2);
    expect(actual.total, -5);
    expect(actual.page, 99);
    expect(actual.pageSize, 0);
    expect(actual.items, hasLength(3));
    expect(actual.items[0].id, 2.0);
    expect(actual.items[0].id, isA<double>());
    expect(actual.items[0].handle, '');
    expect(actual.items[0].tier, 0);
    expect(actual.items[0].profileImageUrl, isNull);
    expect(actual.items[0].rank, 500);
    expect(actual.items[0].rating, -1);
    expect(actual.items[0].solvedCount, 0);
    expect(actual.items[0].voteCount, -4);
    expect(actual.items[0].reputation, 9);
    expect(actual.items[0].userClass, -2);
    expect(actual.items[0].classPlus, isFalse);
    expect(actual.items[0].tagRating, -5);
    expect(actual.items[0].globalRank, isNull);
    expect(actual.items[1].handle, actual.items[0].handle);
    expect(actual.items[1].rank, actual.items[0].rank);
    expect(actual.items[2].id, 3);
    expect(actual.items[2].id, isA<int>());
    expect(actual.items[2].handle, 'raw / 한 글');
    expect(actual.items[2].tier, 31);
    expect(actual.items[2].profileImageUrl, 'not necessarily a URI');
    expect(actual.items[2].globalRank, -99);
  });

  test('requires the complete outer object and preserves nullable states', () {
    final endpoint = contract.rankingUsers();
    for (final invalid in <Object?>[
      null,
      0,
      false,
      'ranking',
      const <Object?>[],
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(invalid),
        throwsFormatException,
        reason: '$invalid',
      );
    }

    for (final field in _outerFields) {
      expect(
        () => endpoint.decode(_response()..remove(field)),
        throwsFormatException,
        reason: '$field missing',
      );
      final body = _response()..[field] = null;
      if (_nullableOuterFields.contains(field)) {
        final actual = endpoint.decode(body);
        expect(field == 'me' ? actual.me : actual.mePage, isNull);
      } else {
        expect(
          () => endpoint.decode(body),
          throwsFormatException,
          reason: '$field null',
        );
      }
    }
  });

  test('requires all 13 user fields and their nullable wire keys', () {
    final endpoint = contract.rankingUsers();
    for (final field in _userFields) {
      final missing = _user()..remove(field);
      expect(
        () => endpoint.decode(_response()..['items'] = [missing]),
        throwsFormatException,
        reason: '$field missing',
      );

      final nullable = _user()..[field] = null;
      if (_nullableUserFields.contains(field)) {
        final actual = endpoint.decode(_response()..['items'] = [nullable]);
        expect(_nullableUserValue(actual.items.single, field), isNull);
      } else {
        expect(
          () => endpoint.decode(_response()..['items'] = [nullable]),
          throwsFormatException,
          reason: '$field null',
        );
      }
    }

    expect(
      () => endpoint.decode(_response()..['me'] = 1),
      throwsFormatException,
    );
    expect(
      () => endpoint.decode(
        _response()..['me'] = (_user()..remove('handle')),
      ),
      throwsFormatException,
    );
  });

  test('preserves every finite raw id number and rejects other values', () {
    final endpoint = contract.rankingUsers();
    for (final value in <num>[-1000000, 0, 1000000, -1.5, 0.0, 2.0]) {
      final actual = endpoint.decode(
        _response()..['items'] = [_user()..['id'] = value],
      );
      expect(actual.items.single.id, value);
      expect(actual.items.single.id.runtimeType, value.runtimeType);
    }
    for (final invalid in <Object?>[
      null,
      double.nan,
      double.infinity,
      double.negativeInfinity,
      '1',
      false,
      const <Object?>[],
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(
          _response()..['items'] = [_user()..['id'] = invalid],
        ),
        throwsFormatException,
        reason: '$invalid',
      );
    }
  });

  test('preserves exact unbounded integers and strict nullable integers', () {
    final endpoint = contract.rankingUsers();
    for (final field in _outerIntegerFields) {
      for (final value in [-1000000, 0, 1000000]) {
        final actual = endpoint.decode(_response()..[field] = value);
        expect(_outerInteger(actual, field), value, reason: field);
      }
      for (final invalid in <Object?>[
        1.0,
        -1.0,
        '1',
        false,
        const <Object?>[],
        const <String, Object?>{},
      ]) {
        expect(
          () => endpoint.decode(_response()..[field] = invalid),
          throwsFormatException,
          reason: '$field = $invalid',
        );
      }
    }
    expect(endpoint.decode(_response()..['mePage'] = null).mePage, isNull);

    for (final field in _userIntegerFields) {
      for (final value in [-1000000, 0, 1000000]) {
        final actual = endpoint.decode(
          _response()..['items'] = [_user()..[field] = value],
        );
        expect(_userInteger(actual.items.single, field), value, reason: field);
      }
      for (final invalid in <Object?>[
        1.0,
        -1.0,
        '1',
        false,
        const <Object?>[],
        const <String, Object?>{},
      ]) {
        expect(
          () => endpoint.decode(
            _response()..['items'] = [_user()..[field] = invalid],
          ),
          throwsFormatException,
          reason: '$field = $invalid',
        );
      }
    }
    for (final field in ['tagRating', 'globalRank']) {
      final actual = endpoint.decode(
        _response()..['items'] = [_user()..[field] = null],
      );
      expect(_userInteger(actual.items.single, field), isNull);
    }
  });

  test('enforces only the nullable tier bounds', () {
    final endpoint = contract.rankingUsers();
    for (final value in <int?>[null, 0, 31]) {
      final actual = endpoint.decode(
        _response()..['items'] = [_user()..['tier'] = value],
      );
      expect(actual.items.single.tier, value);
    }
    for (final invalid in <Object?>[
      -1,
      32,
      1.0,
      '1',
      false,
      const <Object?>[],
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(
          _response()..['items'] = [_user()..['tier'] = invalid],
        ),
        throwsFormatException,
        reason: '$invalid',
      );
    }
  });

  test('preserves raw strings and requires a strict boolean', () {
    final endpoint = contract.rankingUsers();
    final longValue = List<String>.filled(512, '🌏').join();
    for (final value in ['', ' ', 'raw / 한 글 & value', longValue]) {
      final actual = endpoint.decode(
        _response()..['items'] = [_user()..['handle'] = value],
      );
      expect(actual.items.single.handle, value);
    }
    for (final invalid in <Object?>[
      null,
      0,
      false,
      const <Object?>[],
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(
          _response()..['items'] = [_user()..['handle'] = invalid],
        ),
        throwsFormatException,
      );
    }

    for (final value in <String?>[
      null,
      '',
      ' ',
      'not necessarily a URI',
      longValue,
    ]) {
      final actual = endpoint.decode(
        _response()..['items'] = [_user()..['profileImageUrl'] = value],
      );
      expect(actual.items.single.profileImageUrl, value);
    }
    for (final invalid in <Object?>[
      0,
      false,
      const <Object?>[],
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(
          _response()
            ..['items'] = [
              _user()..['profileImageUrl'] = invalid,
            ],
        ),
        throwsFormatException,
      );
    }

    for (final value in [false, true]) {
      final actual = endpoint.decode(
        _response()..['items'] = [_user()..['classPlus'] = value],
      );
      expect(actual.items.single.classPlus, value);
    }
    for (final invalid in <Object?>[null, 0, 1, 'true', const <Object?>[]]) {
      expect(
        () => endpoint.decode(
          _response()..['items'] = [_user()..['classPlus'] = invalid],
        ),
        throwsFormatException,
      );
    }
  });

  test('eagerly snapshots an ordered duplicate unmodifiable item list', () {
    final endpoint = contract.rankingUsers();
    for (final invalid in <Object?>[
      null,
      0,
      false,
      'items',
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(_response()..['items'] = invalid),
        throwsFormatException,
      );
    }
    expect(
      () => endpoint.decode(_response()..['items'] = [_user(), 1]),
      throwsFormatException,
    );
    expect(
      () => endpoint.decode(
        _response()..['items'] = [_user(), _user()..remove('rank')],
      ),
      throwsFormatException,
    );

    final duplicate = _user()..['handle'] = 'duplicate';
    final last = _user()..['handle'] = 'last';
    final items = <Object?>[duplicate, duplicate, last];
    final source = _response()..['items'] = items;
    final actual = endpoint.decode(source);
    duplicate['handle'] = 'changed';
    last['handle'] = 'changed';
    items.clear();
    source['items'] = <Object?>[];

    expect(
      actual.items.map((item) => item.handle),
      ['duplicate', 'duplicate', 'last'],
    );
    expect(() => actual.items.clear(), throwsUnsupportedError);
    expect(
        endpoint.decode(_response()..['items'] = <Object?>[]).items, isEmpty);
  });

  test('preserves future fields and deliberately unrelated values', () {
    final endpoint = contract.rankingUsers();
    final item = _user()
      ..['id'] = 42.5
      ..['handle'] = 'wire handle'
      ..['rank'] = 100
      ..['globalRank'] = -100
      ..['futureUser'] = <String, Object?>{'ignored': true};
    final source = _response()
      ..['me'] = null
      ..['mePage'] = 999
      ..['total'] = -1
      ..['page'] = 700
      ..['pageSize'] = -4
      ..['items'] = <Object?>[item]
      ..['futureResult'] = <String, Object?>{'ignored': true};
    final actual = endpoint.decode(source);
    item
      ..['id'] = 1
      ..['handle'] = 'changed'
      ..['rank'] = -1
      ..['globalRank'] = 1;
    source
      ..['mePage'] = 1
      ..['total'] = 1
      ..['page'] = 1
      ..['pageSize'] = 1;

    expect(actual.me, isNull);
    expect(actual.mePage, 999);
    expect(actual.total, -1);
    expect(actual.page, 700);
    expect(actual.pageSize, -4);
    expect(actual.items.single.id, 42.5);
    expect(actual.items.single.handle, 'wire handle');
    expect(actual.items.single.rank, 100);
    expect(actual.items.single.globalRank, -100);
  });
}

const _outerFields = ['me', 'mePage', 'total', 'page', 'pageSize', 'items'];

const _nullableOuterFields = {'me', 'mePage'};

const _outerIntegerFields = ['mePage', 'total', 'page', 'pageSize'];

const _userFields = [
  'id',
  'handle',
  'tier',
  'profileImageUrl',
  'rank',
  'rating',
  'solvedCount',
  'voteCount',
  'reputation',
  'class',
  'classPlus',
  'tagRating',
  'globalRank',
];

const _nullableUserFields = {
  'tier',
  'profileImageUrl',
  'tagRating',
  'globalRank',
};

const _userIntegerFields = [
  'rank',
  'rating',
  'solvedCount',
  'voteCount',
  'reputation',
  'class',
  'tagRating',
  'globalRank',
];

Map<String, Object?> _response() => <String, Object?>{
      'me': _user(),
      'mePage': 1,
      'total': 2,
      'page': 3,
      'pageSize': 4,
      'items': <Object?>[_user()],
    };

Map<String, Object?> _user() => <String, Object?>{
      'id': 1.5,
      'handle': 'handle',
      'tier': 10,
      'profileImageUrl': null,
      'rank': 1,
      'rating': 2,
      'solvedCount': 3,
      'voteCount': 4,
      'reputation': 5,
      'class': 6,
      'classPlus': false,
      'tagRating': 7,
      'globalRank': 8,
    };

Object? _nullableUserValue(RankingLeaderboardUser user, String field) =>
    switch (field) {
      'tier' => user.tier,
      'profileImageUrl' => user.profileImageUrl,
      'tagRating' => user.tagRating,
      _ => user.globalRank,
    };

int? _outerInteger(RankingLeaderboardResult result, String field) =>
    switch (field) {
      'mePage' => result.mePage,
      'total' => result.total,
      'page' => result.page,
      _ => result.pageSize,
    };

int? _userInteger(RankingLeaderboardUser user, String field) => switch (field) {
      'rank' => user.rank,
      'rating' => user.rating,
      'solvedCount' => user.solvedCount,
      'voteCount' => user.voteCount,
      'reputation' => user.reputation,
      'class' => user.userClass,
      'tagRating' => user.tagRating,
      _ => user.globalRank,
    };
