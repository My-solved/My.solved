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

  test('builds the problem achievements with exact request bounds', () {
    final omitted = contract.achievementsForProblem(1);
    final empty = contract.achievementsForProblem(2, language: '');
    final raw = contract.achievementsForProblem(3, language: '한 글 & raw');
    final language16 = List<String>.filled(16, '🌏').join();

    expect(omitted.direct.path, 'achievements/for-problem/1');
    expect(omitted.direct.queryParameters, isEmpty);
    expect(omitted.proxy.path, omitted.direct.path);
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(empty.direct.queryParameters, {'lang': ''});
    expect(empty.proxy.queryParameters, {'lang': ''});
    expect(raw.direct.queryParameters, {'lang': '한 글 & raw'});
    expect(
      contract
          .achievementsForProblem(2147483647, language: language16)
          .direct
          .queryParameters,
      {'lang': language16},
    );
    for (final invalid in [0, -1]) {
      expect(
        () => contract.achievementsForProblem(invalid),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'problemId')
              .having((error) => error.invalidValue, 'invalidValue', invalid),
        ),
      );
    }
    expect(
      () => contract.achievementsForProblem(
        1,
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
  });

  test('decodes the complete problem achievements fixture', () {
    final actual = contract.achievementsForProblem(1000).decode(
          jsonDecode(fixture('v4/problem_achievements.json')),
        );

    expect(actual.items, hasLength(2));
    final first = actual.items.first;
    expect(first.key, 'problem-streak');
    expect(first.name, '문제 연속 기록');
    expect(first.condition, '');
    expect(first.holderCount, -7);
    expect(first.earnedAt, '');
    expect(first.relation, ProblemAchievementRelation.unlocks);
    expect(first.byLevel, isTrue);
    expect(first.rewards, hasLength(2));
    expect(first.rewards.first, isA<AchievementReward>());
    expect(first.rewards.first.kind, OfficialAchievementItemKind.badge);
    expect(first.rewards.first.id, -3);
    expect(first.rewards.first.imageUrl, 'not necessarily a URI');
    expect(first.rewards.last.kind, OfficialAchievementItemKind.background);
    expect(first.rewards.last.addedAt, '');

    final second = actual.items.last;
    expect(second.key, 'problem-streak');
    expect(second.name, '');
    expect(second.condition, isNull);
    expect(second.rewards, isEmpty);
    expect(second.holderCount, 0);
    expect(second.earnedAt, isNull);
    expect(second.relation, ProblemAchievementRelation.counts);
    expect(second.byLevel, isFalse);
  });

  test('requires an outer object and items array', () {
    final endpoint = contract.achievementsForProblem(1);
    for (final invalid in <Object?>[
      null,
      0,
      false,
      'achievements',
      const <Object?>[],
      const <String, Object?>{},
      const <String, Object?>{'items': null},
      const <String, Object?>{'items': 1},
      const <String, Object?>{'items': false},
      const <String, Object?>{'items': <String, Object?>{}},
    ]) {
      expect(
        () => endpoint.decode(invalid),
        throwsFormatException,
        reason: '$invalid',
      );
    }

    expect(endpoint.decode({'items': <Object?>[]}).items, isEmpty);
  });

  test('requires every item field and validates all items eagerly', () {
    final endpoint = contract.achievementsForProblem(1);
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
    final endpoint = contract.achievementsForProblem(1);
    final longValue = List<String>.filled(512, '🌏').join();
    for (final field in ['condition', 'earnedAt']) {
      final nullable =
          endpoint.decode(_envelope([_item()..[field] = null])).items.single;
      expect(field == 'condition' ? nullable.condition : nullable.earnedAt,
          isNull);
      for (final value in ['', ' ', '한 글 & raw', longValue]) {
        final item =
            endpoint.decode(_envelope([_item()..[field] = value])).items.single;
        expect(field == 'condition' ? item.condition : item.earnedAt, value);
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

  test('preserves strict item scalars without undocumented inference', () {
    final endpoint = contract.achievementsForProblem(1);
    for (final value in [-1000000, 0, 1000000]) {
      final item = endpoint
          .decode(_envelope([_item()..['holderCount'] = value]))
          .items
          .single;
      expect(item.holderCount, value);
    }
    for (final invalid in <Object?>[
      1.0,
      '1',
      false,
      const <Object?>[],
    ]) {
      expect(
        () => endpoint.decode(
          _envelope([_item()..['holderCount'] = invalid]),
        ),
        throwsFormatException,
      );
    }

    for (final field in ['key', 'name']) {
      final item =
          endpoint.decode(_envelope([_item()..[field] = ' 한 글 '])).items.single;
      expect(field == 'key' ? item.key : item.name, ' 한 글 ');
      expect(
        () => endpoint.decode(_envelope([_item()..[field] = 1])),
        throwsFormatException,
      );
    }
    expect(
      () => endpoint.decode(_envelope([_item()..['byLevel'] = 'true'])),
      throwsFormatException,
    );

    for (final relation in ['unlocks', 'counts']) {
      final actual = endpoint
          .decode(_envelope([_item()..['relation'] = relation]))
          .items
          .single
          .relation;
      expect(actual.value, relation);
    }
    for (final invalid in <Object?>[
      '',
      'future',
      1,
      false,
      const <Object?>[],
    ]) {
      expect(
        () => endpoint.decode(_envelope([_item()..['relation'] = invalid])),
        throwsFormatException,
        reason: 'relation = $invalid',
      );
    }
  });

  test('requires the exact shared reward shape without extra inference', () {
    final endpoint = contract.achievementsForProblem(1);
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

  test(
    'preserves empty order duplicates future fields and source isolation',
    () {
      final endpoint = contract.achievementsForProblem(1);
      final emptyItems = <Object?>[];
      final empty = endpoint.decode({
        'items': emptyItems,
        'futureEnvelope': true,
      });
      emptyItems.add(_item());
      expect(empty.items, isEmpty);
      expect(() => empty.items.clear(), throwsUnsupportedError);

      final reward = _reward()
        ..['futureReward'] = true
        ..['key'] = 'duplicate';
      final rewards = <Object?>[reward, reward];
      final item = _item()
        ..['key'] = 'duplicate'
        ..['rewards'] = rewards
        ..['futureItem'] = true;
      final items = <Object?>[item, item];
      final actual = endpoint.decode(_envelope(items));
      items.clear();
      rewards.clear();
      reward['key'] = 'changed';
      item['key'] = 'changed';

      expect(actual.items.map((value) => value.key), [
        'duplicate',
        'duplicate',
      ]);
      expect(actual.items.first.rewards.map((value) => value.key), [
        'duplicate',
        'duplicate',
      ]);
      expect(() => actual.items.clear(), throwsUnsupportedError);
      expect(() => actual.items.first.rewards.clear(), throwsUnsupportedError);
    },
  );
}

const _itemFields = [
  'key',
  'name',
  'condition',
  'rewards',
  'holderCount',
  'earnedAt',
  'relation',
  'byLevel',
];

const _nullableItemFields = {'condition', 'earnedAt'};

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
    };

Map<String, Object?> _item() => <String, Object?>{
      'key': 'achievement',
      'name': 'Achievement',
      'condition': null,
      'rewards': <Object?>[_reward()],
      'holderCount': 1,
      'earnedAt': null,
      'relation': 'unlocks',
      'byLevel': false,
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
