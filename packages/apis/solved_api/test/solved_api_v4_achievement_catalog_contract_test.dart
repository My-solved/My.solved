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

  test('builds the catalog with exact optional language semantics', () {
    final omitted = contract.achievementCatalog();
    final empty = contract.achievementCatalog(language: '');
    final raw = contract.achievementCatalog(language: '한 글 & raw');
    final language16 = List<String>.filled(16, '🌏').join();

    expect(omitted.direct.path, 'achievements');
    expect(omitted.direct.queryParameters, isEmpty);
    expect(omitted.proxy.path, omitted.direct.path);
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(empty.direct.queryParameters, {'lang': ''});
    expect(empty.proxy.queryParameters, {'lang': ''});
    expect(raw.direct.queryParameters, {'lang': '한 글 & raw'});
    expect(
      contract.achievementCatalog(language: language16).direct.queryParameters,
      {'lang': language16},
    );
    expect(
      () => contract.achievementCatalog(
        language: List<String>.filled(17, '🌏').join(),
      ),
      throwsArgumentError,
    );
  });

  test('decodes the complete official achievement catalog fixture', () {
    final actual = contract.achievementCatalog().decode(
          jsonDecode(fixture('v4/achievement_catalog.json')),
        );

    expect(actual.userCount, 0);
    expect(actual.items, hasLength(2));
    final first = actual.items.first;
    expect(first.id, -1);
    expect(first.key, 'streak');
    expect(first.series, '');
    expect(first.seriesOrder, -2);
    expect(first.historic, isTrue);
    expect(first.hidden, isFalse);
    expect(first.name, '연속 기록');
    expect(first.condition, '');
    expect(first.searchQuery, 'solved:100');
    expect(first.shopKey, '');
    expect(first.holderCount, -7);
    expect(first.earnedAt, '');
    expect(first.progress?.current, -1);
    expect(first.progress?.target, 0);
    expect(first.rewards, hasLength(2));
    expect(first.rewards.first.kind, OfficialAchievementItemKind.badge);
    expect(first.rewards.first.id, -3);
    expect(first.rewards.first.imageUrl, 'not necessarily a URI');
    expect(first.rewards.last.kind, OfficialAchievementItemKind.background);
    expect(first.rewards.last.addedAt, '');

    final second = actual.items.last;
    expect(second.key, 'streak');
    expect(second.condition, isNull);
    expect(second.searchQuery, isNull);
    expect(second.shopKey, isNull);
    expect(second.earnedAt, isNull);
    expect(second.progress, isNull);
    expect(second.rewards, isEmpty);
  });

  test('requires the outer object items and non-negative user count', () {
    final endpoint = contract.achievementCatalog();
    for (final invalid in <Object?>[
      null,
      0,
      false,
      'catalog',
      const <Object?>[],
      const <String, Object?>{},
      const <String, Object?>{'items': <Object?>[]},
      const <String, Object?>{'userCount': 0},
      const <String, Object?>{'items': null, 'userCount': 0},
      const <String, Object?>{'items': 1, 'userCount': 0},
      const <String, Object?>{'items': <Object?>[], 'userCount': null},
      const <String, Object?>{'items': <Object?>[], 'userCount': 1.0},
      const <String, Object?>{'items': <Object?>[], 'userCount': -1},
    ]) {
      expect(
        () => endpoint.decode(invalid),
        throwsFormatException,
        reason: '$invalid',
      );
    }

    expect(
      endpoint.decode({'items': <Object?>[], 'userCount': 0}).userCount,
      0,
    );
    expect(
      endpoint.decode({'items': <Object?>[], 'userCount': 1000000}).userCount,
      1000000,
    );
  });

  test('requires every item field and validates all items eagerly', () {
    final endpoint = contract.achievementCatalog();
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
        reason: '$invalid',
      );
    }

    for (final field in _itemFields) {
      expect(
        () => endpoint.decode(_envelope([_item()..remove(field)])),
        throwsFormatException,
        reason: '$field missing',
      );
      if (!_nullableItemFields.contains(field)) {
        expect(
          () => endpoint.decode(_envelope([_item()..[field] = null])),
          throwsFormatException,
          reason: '$field null',
        );
      }
    }
  });

  test('preserves required nullable strings and arbitrary raw values', () {
    final endpoint = contract.achievementCatalog();
    final longValue = List<String>.filled(512, '🌏').join();
    for (final field in ['condition', 'searchQuery', 'shopKey', 'earnedAt']) {
      expect(
        endpoint.decode(_envelope([_item()..[field] = null])).items.single,
        isA<AchievementCatalogItem>(),
      );
      for (final value in ['', ' ', '한 글 & raw', longValue]) {
        final item =
            endpoint.decode(_envelope([_item()..[field] = value])).items.single;
        final actual = switch (field) {
          'condition' => item.condition,
          'searchQuery' => item.searchQuery,
          'shopKey' => item.shopKey,
          _ => item.earnedAt,
        };
        expect(actual, value);
      }
      for (final invalid in <Object?>[
        0,
        false,
        const <Object?>[],
        const <String, Object?>{},
      ]) {
        expect(
          () => endpoint.decode(_envelope([_item()..[field] = invalid])),
          throwsFormatException,
          reason: '$field = $invalid',
        );
      }
    }
  });

  test('preserves unbounded item integers and strict booleans and strings', () {
    final endpoint = contract.achievementCatalog();
    for (final field in ['id', 'seriesOrder', 'holderCount']) {
      for (final value in [-1000000, 0, 1000000]) {
        expect(
          () => endpoint.decode(_envelope([_item()..[field] = value])),
          returnsNormally,
          reason: '$field = $value',
        );
      }
      for (final invalid in <Object?>[1.0, '1', false, const <Object?>[]]) {
        expect(
          () => endpoint.decode(_envelope([_item()..[field] = invalid])),
          throwsFormatException,
          reason: '$field = $invalid',
        );
      }
    }

    for (final field in ['key', 'series', 'name']) {
      final item =
          endpoint.decode(_envelope([_item()..[field] = ' 한 글 '])).items.single;
      expect(
          switch (field) {
            'key' => item.key,
            'series' => item.series,
            _ => item.name,
          },
          ' 한 글 ');
      expect(
        () => endpoint.decode(_envelope([_item()..[field] = 1])),
        throwsFormatException,
      );
    }
    for (final field in ['historic', 'hidden']) {
      expect(
        () => endpoint.decode(_envelope([_item()..[field] = 'true'])),
        throwsFormatException,
      );
    }
  });

  test('requires complete rewards and exact kinds without extra inference', () {
    final endpoint = contract.achievementCatalog();
    for (final invalid in <Object?>[
      0,
      false,
      'rewards',
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(_envelope([_item()..['rewards'] = invalid])),
        throwsFormatException,
        reason: 'rewards = $invalid',
      );
    }
    for (final invalid in <Object?>[
      null,
      0,
      false,
      'reward',
      const <Object?>[],
    ]) {
      expect(
        () => endpoint.decode(
          _envelope([
            _item()..['rewards'] = <Object?>[_reward(), invalid],
          ]),
        ),
        throwsFormatException,
        reason: '$invalid',
      );
    }
    for (final field in _rewardFields) {
      expect(
        () => endpoint.decode(
          _envelope([
            _item()..['rewards'] = [_reward()..remove(field)],
          ]),
        ),
        throwsFormatException,
        reason: '$field missing',
      );
      expect(
        () => endpoint.decode(
          _envelope([
            _item()..['rewards'] = [_reward()..[field] = null],
          ]),
        ),
        throwsFormatException,
        reason: '$field null',
      );
    }

    for (final kind in ['badge', 'background']) {
      expect(
        () => endpoint.decode(
          _envelope([
            _item()..['rewards'] = [_reward()..['kind'] = kind],
          ]),
        ),
        returnsNormally,
      );
    }
    expect(
      () => endpoint.decode(
        _envelope([
          _item()..['rewards'] = [_reward()..['kind'] = 'future'],
        ]),
      ),
      throwsFormatException,
    );
    for (final id in [-1000000, 0, 1000000]) {
      expect(
        () => endpoint.decode(
          _envelope([
            _item()..['rewards'] = [_reward()..['id'] = id],
          ]),
        ),
        returnsNormally,
      );
    }
    expect(
      () => endpoint.decode(
        _envelope([
          _item()..['rewards'] = [_reward()..['id'] = 1.0],
        ]),
      ),
      throwsFormatException,
    );
    for (final field in ['key', 'name', 'imageUrl', 'category', 'addedAt']) {
      final item = endpoint
          .decode(
            _envelope([
              _item()..['rewards'] = [_reward()..[field] = ' 한 글 '],
            ]),
          )
          .items
          .single;
      final reward = item.rewards.single;
      expect(
        switch (field) {
          'key' => reward.key,
          'name' => reward.name,
          'imageUrl' => reward.imageUrl,
          'category' => reward.category,
          _ => reward.addedAt,
        },
        ' 한 글 ',
      );
      expect(
        () => endpoint.decode(
          _envelope([
            _item()..['rewards'] = [_reward()..[field] = 1],
          ]),
        ),
        throwsFormatException,
      );
    }
  });

  test('distinguishes nullable progress and validates its complete object', () {
    final endpoint = contract.achievementCatalog();
    expect(
      endpoint
          .decode(_envelope([_item()..['progress'] = null]))
          .items
          .single
          .progress,
      isNull,
    );
    for (final invalid in <Object?>[0, false, 'progress', const <Object?>[]]) {
      expect(
        () => endpoint.decode(_envelope([_item()..['progress'] = invalid])),
        throwsFormatException,
      );
    }
    for (final field in ['current', 'target']) {
      expect(
        () => endpoint.decode(
          _envelope([_item()..['progress'] = (_progress()..remove(field))]),
        ),
        throwsFormatException,
      );
      expect(
        () => endpoint.decode(
          _envelope([_item()..['progress'] = (_progress()..[field] = 1.0)]),
        ),
        throwsFormatException,
      );
    }

    final progress = endpoint
        .decode(
          _envelope([
            _item()
              ..['progress'] = (_progress()
                ..['current'] = 100
                ..['target'] = -100),
          ]),
        )
        .items
        .single
        .progress;
    expect(progress?.current, 100);
    expect(progress?.target, -100);
  });

  test(
    'preserves empty order duplicates future fields and source isolation',
    () {
      final endpoint = contract.achievementCatalog();
      final emptyItems = <Object?>[];
      final empty = endpoint.decode({
        'items': emptyItems,
        'userCount': 0,
        'futureEnvelope': true,
      });
      emptyItems.add(_item());
      expect(empty.items, isEmpty);
      expect(() => empty.items.clear(), throwsUnsupportedError);

      final reward = _reward()
        ..['futureReward'] = true
        ..['key'] = 'duplicate';
      final rewards = <Object?>[reward, reward];
      final progress = _progress()..['futureProgress'] = true;
      final item = _item()
        ..['key'] = 'duplicate'
        ..['rewards'] = rewards
        ..['progress'] = progress
        ..['futureItem'] = true;
      final items = <Object?>[item, item];
      final actual = endpoint.decode(_envelope(items));
      items.clear();
      rewards.clear();
      reward['key'] = 'changed';
      progress['current'] = 999;
      item['key'] = 'changed';

      expect(actual.items.map((value) => value.key), [
        'duplicate',
        'duplicate',
      ]);
      expect(actual.items.first.rewards.map((value) => value.key), [
        'duplicate',
        'duplicate',
      ]);
      expect(actual.items.first.progress?.current, 1);
      expect(() => actual.items.first.rewards.clear(), throwsUnsupportedError);
    },
  );
}

const _itemFields = [
  'id',
  'key',
  'series',
  'seriesOrder',
  'historic',
  'hidden',
  'name',
  'condition',
  'searchQuery',
  'shopKey',
  'rewards',
  'holderCount',
  'earnedAt',
  'progress',
];

const _nullableItemFields = {
  'condition',
  'searchQuery',
  'shopKey',
  'earnedAt',
  'progress',
};

const _rewardFields = [
  'kind',
  'id',
  'key',
  'name',
  'imageUrl',
  'category',
  'addedAt',
];

Map<String, Object?> _envelope(List<Object?> items) => <String, Object?>{
      'items': items,
      'userCount': 0,
    };

Map<String, Object?> _item() => <String, Object?>{
      'id': 1,
      'key': 'achievement',
      'series': 'series',
      'seriesOrder': 1,
      'historic': false,
      'hidden': false,
      'name': 'Achievement',
      'condition': null,
      'searchQuery': null,
      'shopKey': null,
      'rewards': <Object?>[_reward()],
      'holderCount': 1,
      'earnedAt': null,
      'progress': _progress(),
    };

Map<String, Object?> _reward() => <String, Object?>{
      'kind': 'badge',
      'id': 1,
      'key': 'reward',
      'name': 'Reward',
      'imageUrl': 'image',
      'category': 'category',
      'addedAt': 'added',
    };

Map<String, Object?> _progress() => <String, Object?>{
      'current': 1,
      'target': 2,
    };
