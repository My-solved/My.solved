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

  test('builds user achievements with exact optional query semantics', () {
    final omitted = contract.userAchievements('index');
    final emptyLanguage = contract.userAchievements('index', language: '');
    final rawQuery = contract.userAchievements(
      '한 글',
      language: '한 글 & raw',
      versusHandle: ' / 한 글 & raw ',
    );
    final handle64 = List<String>.filled(64, '🌏').join();
    final language16 = List<String>.filled(16, '🌏').join();
    final versus64 = List<String>.filled(64, '🌏').join();

    expect(omitted.direct.path, 'users/index/achievements');
    expect(omitted.direct.queryParameters, isEmpty);
    expect(omitted.proxy.path, omitted.direct.path);
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(emptyLanguage.direct.queryParameters, {'lang': ''});
    expect(emptyLanguage.proxy.queryParameters, {'lang': ''});
    expect(
      contract.userAchievements('a', versusHandle: 'b').direct.path,
      'users/a/achievements',
    );
    expect(
      rawQuery.direct.path,
      'users/%ED%95%9C%20%EA%B8%80/achievements',
    );
    expect(rawQuery.direct.queryParameters, {
      'lang': '한 글 & raw',
      'vs': ' / 한 글 & raw ',
    });
    expect(rawQuery.proxy.queryParameters, rawQuery.direct.queryParameters);
    expect(
      contract
          .userAchievements(
            handle64,
            language: language16,
            versusHandle: versus64,
          )
          .direct
          .queryParameters,
      {'lang': language16, 'vs': versus64},
    );

    final handle65 = List<String>.filled(65, 'a').join();
    for (final invalid in [
      '',
      handle65,
      '.',
      '..',
      'a/b',
      r'a\b',
      'a\u0000b',
    ]) {
      expect(
        () => contract.userAchievements(invalid),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'handle')
              .having((error) => error.invalidValue, 'invalidValue', invalid),
        ),
        reason: 'handle = $invalid',
      );
    }
    expect(
      () => contract.userAchievements(
        'index',
        language: List<String>.filled(17, '🌏').join(),
      ),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.name,
          'name',
          'language',
        ),
      ),
    );
    for (final invalid in [
      '',
      List<String>.filled(65, '🌏').join(),
    ]) {
      expect(
        () => contract.userAchievements('index', versusHandle: invalid),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'versusHandle')
              .having((error) => error.invalidValue, 'invalidValue', invalid),
        ),
        reason: 'versusHandle = $invalid',
      );
    }
  });

  test('decodes the complete official user achievements fixture', () {
    final actual = contract.userAchievements('requested').decode(
          jsonDecode(fixture('v4/user_achievements.json')),
        );

    expect(actual.handle, 'response handle');
    expect(actual.vsHandle, 'different comparison');
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
    expect(first.rewards.first, isA<AchievementReward>());
    expect(first.rewards.first.kind, OfficialAchievementItemKind.badge);
    expect(first.rewards.first.id, -3);
    expect(first.rewards.first.imageUrl, 'not necessarily a URI');
    expect(first.rewards.last.kind, OfficialAchievementItemKind.background);
    expect(first.rewards.last.addedAt, '');
    expect(first.vs?.earnedAt, 'not-a-date');

    final second = actual.items.last;
    expect(second.condition, isNull);
    expect(second.searchQuery, isNull);
    expect(second.shopKey, isNull);
    expect(second.earnedAt, isNull);
    expect(second.progress, isNull);
    expect(second.rewards, isEmpty);
    expect(second.vs, isNull);
  });

  test('requires the complete outer object and non-negative user count', () {
    final endpoint = contract.userAchievements('requested');
    for (final invalid in <Object?>[
      null,
      0,
      false,
      'achievements',
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
      if (field != 'vsHandle') {
        expect(
          () => endpoint.decode(_envelope(<Object?>[])..[field] = null),
          throwsFormatException,
          reason: '$field null',
        );
      }
    }

    for (final value in <String?>[null, '', ' ', 'raw response']) {
      final actual = endpoint.decode(
        _envelope(<Object?>[])..['vsHandle'] = value,
      );
      expect(actual.vsHandle, value);
    }
    for (final field in ['handle', 'vsHandle']) {
      expect(
        () => endpoint.decode(_envelope(<Object?>[])..[field] = 1),
        throwsFormatException,
      );
    }
    expect(
      () => endpoint.decode(_envelope(<Object?>[])..['items'] = false),
      throwsFormatException,
    );
    for (final value in [0, 1000000]) {
      expect(
        endpoint
            .decode(_envelope(<Object?>[])..['userCount'] = value)
            .userCount,
        value,
      );
    }
    for (final invalid in <Object?>[-1, 1.0, '1', false]) {
      expect(
        () => endpoint.decode(
          _envelope(<Object?>[])..['userCount'] = invalid,
        ),
        throwsFormatException,
      );
    }

    final unrelated = contract
        .userAchievements('requested', versusHandle: 'query comparison')
        .decode(
          _envelope(<Object?>[])
            ..['handle'] = 'different response'
            ..['vsHandle'] = null,
        );
    expect(unrelated.handle, 'different response');
    expect(unrelated.vsHandle, isNull);
  });

  test('requires every item field and validates all items eagerly', () {
    final endpoint = contract.userAchievements('requested');
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

  test('preserves required nullable strings and strict item scalars', () {
    final endpoint = contract.userAchievements('requested');
    final longValue = List<String>.filled(512, '🌏').join();
    for (final field in ['condition', 'searchQuery', 'shopKey', 'earnedAt']) {
      expect(
        () => endpoint.decode(_envelope([_item()..[field] = null])),
        returnsNormally,
      );
      for (final value in ['', ' ', '한 글 & raw', longValue]) {
        final item =
            endpoint.decode(_envelope([_item()..[field] = value])).items.single;
        expect(
          switch (field) {
            'condition' => item.condition,
            'searchQuery' => item.searchQuery,
            'shopKey' => item.shopKey,
            _ => item.earnedAt,
          },
          value,
        );
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

    for (final field in ['id', 'seriesOrder', 'holderCount']) {
      for (final value in [-1000000, 0, 1000000]) {
        expect(
          () => endpoint.decode(_envelope([_item()..[field] = value])),
          returnsNormally,
          reason: '$field = $value',
        );
      }
      for (final invalid in <Object?>[1.0, '1', false]) {
        expect(
          () => endpoint.decode(_envelope([_item()..[field] = invalid])),
          throwsFormatException,
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
        ' 한 글 ',
      );
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

  test('requires the exact shared reward shape without extra inference', () {
    final endpoint = contract.userAchievements('requested');
    for (final invalid in <Object?>[
      0,
      false,
      'rewards',
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(_envelope([_item()..['rewards'] = invalid])),
        throwsFormatException,
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
      final reward = endpoint
          .decode(
            _envelope([
              _item()..['rewards'] = [_reward()..['kind'] = kind],
            ]),
          )
          .items
          .single
          .rewards
          .single;
      expect(reward.kind.value, kind);
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
      final reward = endpoint
          .decode(
            _envelope([
              _item()..['rewards'] = [_reward()..['id'] = id],
            ]),
          )
          .items
          .single
          .rewards
          .single;
      expect(reward.id, id);
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
      final reward = endpoint
          .decode(
            _envelope([
              _item()..['rewards'] = [_reward()..[field] = ' 한 글 '],
            ]),
          )
          .items
          .single
          .rewards
          .single;
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
    final endpoint = contract.userAchievements('requested');
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

  test('requires nullable versus state and its nullable earned time', () {
    final endpoint = contract.userAchievements('requested');
    expect(
      endpoint.decode(_envelope([_item()..['vs'] = null])).items.single.vs,
      isNull,
    );
    for (final invalid in <Object?>[0, false, 'vs', const <Object?>[]]) {
      expect(
        () => endpoint.decode(_envelope([_item()..['vs'] = invalid])),
        throwsFormatException,
      );
    }
    expect(
      () => endpoint.decode(_envelope([_item()..['vs'] = <String, Object?>{}])),
      throwsFormatException,
    );
    for (final value in <String?>[null, '', ' ', 'not-a-date']) {
      final vs = endpoint
          .decode(
            _envelope([
              _item()..['vs'] = <String, Object?>{'earnedAt': value},
            ]),
          )
          .items
          .single
          .vs;
      expect(vs?.earnedAt, value);
    }
    for (final invalid in <Object?>[
      0,
      false,
      const <Object?>[],
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(
          _envelope([
            _item()..['vs'] = <String, Object?>{'earnedAt': invalid},
          ]),
        ),
        throwsFormatException,
      );
    }
    expect(
      endpoint
          .decode(
            _envelope([
              _item()
                ..['vs'] = <String, Object?>{
                  'earnedAt': null,
                  'futureVs': true,
                },
            ]),
          )
          .items
          .single
          .vs
          ?.earnedAt,
      isNull,
    );
  });

  test(
    'preserves empty order duplicates future fields and source isolation',
    () {
      final endpoint = contract.userAchievements('requested');
      final emptyItems = <Object?>[];
      final empty = endpoint.decode(
        _envelope(emptyItems)..['futureEnvelope'] = true,
      );
      emptyItems.add(_item());
      expect(empty.items, isEmpty);
      expect(() => empty.items.clear(), throwsUnsupportedError);

      final reward = _reward()
        ..['futureReward'] = true
        ..['key'] = 'duplicate';
      final rewards = <Object?>[reward, reward];
      final progress = _progress()..['futureProgress'] = true;
      final versus = <String, Object?>{
        'earnedAt': 'raw',
        'futureVs': true,
      };
      final item = _item()
        ..['key'] = 'duplicate'
        ..['rewards'] = rewards
        ..['progress'] = progress
        ..['vs'] = versus
        ..['futureItem'] = true;
      final items = <Object?>[item, item];
      final source = _envelope(items);
      final actual = endpoint.decode(source);
      items.clear();
      rewards.clear();
      reward['key'] = 'changed';
      progress['current'] = 999;
      versus['earnedAt'] = 'changed';
      item['key'] = 'changed';
      source['handle'] = 'changed';

      expect(actual.handle, 'response handle');
      expect(actual.items.map((value) => value.key), [
        'duplicate',
        'duplicate',
      ]);
      expect(actual.items.first.rewards.map((value) => value.key), [
        'duplicate',
        'duplicate',
      ]);
      expect(actual.items.first.progress?.current, 1);
      expect(actual.items.first.vs?.earnedAt, 'raw');
      expect(() => actual.items.first.rewards.clear(), throwsUnsupportedError);
    },
  );
}

const _outerFields = ['handle', 'vsHandle', 'items', 'userCount'];

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
  'vs',
];

const _nullableItemFields = {
  'condition',
  'searchQuery',
  'shopKey',
  'earnedAt',
  'progress',
  'vs',
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
      'handle': 'response handle',
      'vsHandle': 'response comparison',
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
      'vs': <String, Object?>{'earnedAt': null},
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
