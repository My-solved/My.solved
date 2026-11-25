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

  test('builds both holder kinds with exact optional query semantics', () {
    final omitted = contract.achievementHolders(
      OfficialAchievementItemKind.badge,
      '한 글 & raw',
    );
    final defaults = contract.achievementHolders(
      OfficialAchievementItemKind.background,
      'key',
      sort: SolvedApiV4AchievementHolderSort.recent,
      page: 1,
    );
    final boundaries = contract.achievementHolders(
      OfficialAchievementItemKind.badge,
      'key',
      sort: SolvedApiV4AchievementHolderSort.first,
      page: 200,
    );

    expect(
      omitted.direct.path,
      'achievements/items/badge/%ED%95%9C%20%EA%B8%80%20%26%20raw/holders',
    );
    expect(omitted.direct.queryParameters, isEmpty);
    expect(omitted.proxy.path, omitted.direct.path);
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(defaults.direct.path, 'achievements/items/background/key/holders');
    expect(defaults.direct.queryParameters, {'sort': 'recent', 'page': '1'});
    expect(defaults.proxy.queryParameters, defaults.direct.queryParameters);
    expect(boundaries.direct.queryParameters, {'sort': 'first', 'page': '200'});
  });

  test('accepts exact key boundaries and rejects unsafe requests', () {
    final key64 = List<String>.filled(64, '🌏').join();
    expect(
      contract
          .achievementHolders(OfficialAchievementItemKind.badge, key64)
          .direct
          .path,
      startsWith('achievements/items/badge/'),
    );
    expect(
      contract
          .achievementHolders(OfficialAchievementItemKind.background, ' ')
          .direct
          .path,
      'achievements/items/background/%20/holders',
    );

    final key65 = List<String>.filled(65, 'a').join();
    for (final invalid in ['', key65, '.', '..', 'a/b', r'a\b', 'a\u0000b']) {
      expect(
        () => contract.achievementHolders(
          OfficialAchievementItemKind.badge,
          invalid,
        ),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'key')
              .having((error) => error.invalidValue, 'invalidValue', invalid),
        ),
        reason: 'key = $invalid',
      );
    }
    for (final invalid in [0, -1, 201]) {
      expect(
        () => contract.achievementHolders(
          OfficialAchievementItemKind.badge,
          'key',
          page: invalid,
        ),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'page')
              .having((error) => error.invalidValue, 'invalidValue', invalid),
        ),
        reason: 'page = $invalid',
      );
    }
  });

  test('decodes the complete official achievement holders fixture', () {
    final actual = contract
        .achievementHolders(OfficialAchievementItemKind.badge, 'key')
        .decode(jsonDecode(fixture('v4/achievement_holders.json')));

    expect(actual.unlockedByDefault, isTrue);
    expect(actual.total, -7);
    expect(actual.items, hasLength(2));
    final first = actual.items.first;
    expect(first.user.id, -42.5);
    expect(first.user.id, isA<double>());
    expect(first.user.handle, 'holder');
    expect(first.user.tier, 0);
    expect(first.user.profileImageUrl, 'not necessarily a URI');
    expect(first.acquiredAt, 'not-a-date');
    final second = actual.items.last;
    expect(second.user.id, 0);
    expect(second.user.id, isA<int>());
    expect(second.user.handle, 'holder');
    expect(second.user.tier, 31);
    expect(second.user.profileImageUrl, isNull);
    expect(second.acquiredAt, '');
  });

  test('requires the complete outer object and preserves raw totals', () {
    final endpoint = contract.achievementHolders(
      OfficialAchievementItemKind.badge,
      'key',
    );
    for (final invalid in <Object?>[
      null,
      0,
      false,
      'holders',
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
        () => endpoint.decode(_envelope(<Object?>[])..remove(field)),
        throwsFormatException,
        reason: '$field missing',
      );
      expect(
        () => endpoint.decode(_envelope(<Object?>[])..[field] = null),
        throwsFormatException,
        reason: '$field null',
      );
    }
    for (final value in [-1000000, 0, 1000000]) {
      expect(
        endpoint.decode(_envelope(<Object?>[])..['total'] = value).total,
        value,
      );
    }
    for (final invalid in <Object?>[1.0, '1', false, const <Object?>[]]) {
      expect(
        () => endpoint.decode(_envelope(<Object?>[])..['total'] = invalid),
        throwsFormatException,
      );
    }
    expect(
      () => endpoint.decode(
        _envelope(<Object?>[])..['unlockedByDefault'] = 'true',
      ),
      throwsFormatException,
    );
    expect(
      () => endpoint.decode(_envelope(<Object?>[])..['items'] = false),
      throwsFormatException,
    );
  });

  test('requires every item and nested user field and validates eagerly', () {
    final endpoint = contract.achievementHolders(
      OfficialAchievementItemKind.badge,
      'key',
    );
    for (final invalid in <Object?>[
      null,
      0,
      false,
      'item',
      const <Object?>[],
    ]) {
      expect(
        () => endpoint.decode(_envelope([_item(), invalid])),
        throwsFormatException,
        reason: 'item = $invalid',
      );
    }
    for (final field in _itemFields) {
      expect(
        () => endpoint.decode(_envelope([_item()..remove(field)])),
        throwsFormatException,
        reason: '$field missing',
      );
      expect(
        () => endpoint.decode(_envelope([_item()..[field] = null])),
        throwsFormatException,
        reason: '$field null',
      );
    }
    for (final invalid in <Object?>[
      0,
      false,
      'user',
      const <Object?>[],
    ]) {
      expect(
        () => endpoint.decode(_envelope([_item()..['user'] = invalid])),
        throwsFormatException,
        reason: 'user = $invalid',
      );
    }
    for (final field in _userFields) {
      expect(
        () => endpoint.decode(
          _envelope([_item()..['user'] = (_user()..remove(field))]),
        ),
        throwsFormatException,
        reason: 'user.$field missing',
      );
      if (!_nullableUserFields.contains(field)) {
        expect(
          () => endpoint.decode(
            _envelope([_item()..['user'] = (_user()..[field] = null)]),
          ),
          throwsFormatException,
          reason: 'user.$field null',
        );
      }
    }
  });

  test('preserves finite raw user IDs and rejects unsupported values', () {
    final endpoint = contract.achievementHolders(
      OfficialAchievementItemKind.badge,
      'key',
    );
    for (final value in <num>[-42.5, -1, 0, 1.0, 1000000]) {
      final actual = endpoint
          .decode(
            _envelope([_item()..['user'] = (_user()..['id'] = value)]),
          )
          .items
          .single
          .user
          .id;
      expect(actual, value);
      expect(actual.runtimeType, value.runtimeType);
    }
    for (final invalid in <Object?>[
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
          _envelope([_item()..['user'] = (_user()..['id'] = invalid)]),
        ),
        throwsFormatException,
        reason: 'id = $invalid',
      );
    }
  });

  test('preserves required nullable user fields and strict scalar types', () {
    final endpoint = contract.achievementHolders(
      OfficialAchievementItemKind.badge,
      'key',
    );
    for (final tier in <int?>[null, 0, 31]) {
      final actual = endpoint
          .decode(
            _envelope([_item()..['user'] = (_user()..['tier'] = tier)]),
          )
          .items
          .single
          .user
          .tier;
      expect(actual, tier);
    }
    for (final invalid in <Object?>[-1, 32, 1.0, '1', false]) {
      expect(
        () => endpoint.decode(
          _envelope([_item()..['user'] = (_user()..['tier'] = invalid)]),
        ),
        throwsFormatException,
        reason: 'tier = $invalid',
      );
    }

    for (final value in <String?>[
      null,
      '',
      ' ',
      'not necessarily a URI',
    ]) {
      final actual = endpoint
          .decode(
            _envelope([
              _item()..['user'] = (_user()..['profileImageUrl'] = value),
            ]),
          )
          .items
          .single
          .user
          .profileImageUrl;
      expect(actual, value);
    }
    for (final field in ['handle', 'profileImageUrl']) {
      expect(
        () => endpoint.decode(
          _envelope([_item()..['user'] = (_user()..[field] = 1)]),
        ),
        throwsFormatException,
      );
    }
    for (final value in ['', ' ', 'not-a-date', '9999-99-99']) {
      final actual = endpoint
          .decode(_envelope([_item()..['acquiredAt'] = value]))
          .items
          .single
          .acquiredAt;
      expect(actual, value);
    }
    expect(
      () => endpoint.decode(_envelope([_item()..['acquiredAt'] = 1])),
      throwsFormatException,
    );
    final rawHandle = endpoint
        .decode(
          _envelope([_item()..['user'] = (_user()..['handle'] = ' 한 글 ')]),
        )
        .items
        .single
        .user
        .handle;
    expect(rawHandle, ' 한 글 ');
  });

  test(
    'preserves empty order duplicates future fields and source isolation',
    () {
      final endpoint = contract.achievementHolders(
        OfficialAchievementItemKind.badge,
        'key',
      );
      final emptyItems = <Object?>[];
      final empty = endpoint.decode(
        _envelope(emptyItems)..['futureEnvelope'] = true,
      );
      emptyItems.add(_item());
      expect(empty.items, isEmpty);
      expect(() => empty.items.clear(), throwsUnsupportedError);

      final user = _user()
        ..['handle'] = 'duplicate'
        ..['futureUser'] = true;
      final item = _item()
        ..['user'] = user
        ..['acquiredAt'] = 'raw'
        ..['futureItem'] = true;
      final items = <Object?>[item, item];
      final source = _envelope(items);
      final actual = endpoint.decode(source);
      items.clear();
      user['handle'] = 'changed';
      item['acquiredAt'] = 'changed';
      source['total'] = 999;

      expect(actual.total, 0);
      expect(actual.items.map((value) => value.user.handle), [
        'duplicate',
        'duplicate',
      ]);
      expect(actual.items.map((value) => value.acquiredAt), ['raw', 'raw']);
      expect(() => actual.items.clear(), throwsUnsupportedError);
    },
  );
}

const _outerFields = ['unlockedByDefault', 'total', 'items'];
const _itemFields = ['user', 'acquiredAt'];
const _userFields = ['id', 'handle', 'tier', 'profileImageUrl'];
const _nullableUserFields = {'tier', 'profileImageUrl'};

Map<String, Object?> _envelope(List<Object?> items) => <String, Object?>{
      'unlockedByDefault': false,
      'total': 0,
      'items': items,
    };

Map<String, Object?> _item() => <String, Object?>{
      'user': _user(),
      'acquiredAt': 'added',
    };

Map<String, Object?> _user() => <String, Object?>{
      'id': 1,
      'handle': 'holder',
      'tier': null,
      'profileImageUrl': null,
    };
