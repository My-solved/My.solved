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

  test('builds the bodyless top-level source endpoint', () {
    final endpoint = contract.sourceGroups();

    expect(endpoint.direct.path, 'sources');
    expect(endpoint.direct.queryParameters, isEmpty);
    expect(endpoint.proxy.path, 'sources');
    expect(endpoint.proxy.queryParameters, isEmpty);
    expect(SourceProblemOrder.values.map((order) => order.value), [
      'ascending',
      'random',
      'mixed',
    ]);
  });

  test('decodes the complete fixture without inferred relationships', () {
    final actual = contract.sourceGroups().decode(
          jsonDecode(fixture('v4/source_groups.json')),
        );

    expect(actual.groups, hasLength(3));
    final first = actual.groups[0];
    expect(first.id, 1);
    expect(first.id, isA<int>());
    expect(first.name, 'Olympiad');
    expect(first.abbreviation, 'OI');
    expect(first.groupCount, 12);
    expect(first.contestCount, 0);
    expect(first.problemCount, 2.5);
    expect(first.solvedCount, -1);
    expect(first.order, SourceProblemOrder.ascending);
    final level = first.level!;
    expect([level.q25, level.q50, level.q75], [31, -2, 0]);
    expect(level.tierCounts, [0, -1, 7, 7]);
    expect(level.ratedCount, -3);
    expect(level.order, SourceProblemOrder.mixed);
    expect(level.progress!.solved, 99);
    expect(level.progress!.through.q25, isFalse);
    expect(level.progress!.through.q50, isTrue);
    expect(level.progress!.through.q75, isFalse);

    final second = actual.groups[1];
    expect(second.id, 2.0);
    expect(second.id, isA<double>());
    expect(second.name, '');
    expect(second.abbreviation, isNull);
    expect(second.groupCount, -0.5);
    expect(second.problemCount, isNull);
    expect(second.solvedCount, isNull);
    expect(second.level, isNull);
    expect(second.order, isNull);

    final third = actual.groups[2];
    expect(third.id, -7.25);
    expect(third.name, 'raw / 한 글');
    expect(third.abbreviation, '');
    expect(third.contestCount, 1000.0);
    expect(third.contestCount, isA<double>());
    expect(third.level!.tierCounts, isEmpty);
    expect(third.level!.order, isNull);
    expect(third.level!.progress, isNull);
    expect(third.order, SourceProblemOrder.random);
  });

  test('requires every group field and preserves nullable states', () {
    final endpoint = contract.sourceGroups();
    for (final invalid in <Object?>[
      null,
      0,
      'groups',
      const <Object?>[],
      const <String, Object?>{},
    ]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }

    for (final field in _groupFields) {
      expect(
        () => endpoint.decode(_response(_group()..remove(field))),
        throwsFormatException,
        reason: '$field missing',
      );
      final nulled = _group()..[field] = null;
      if (_nullableGroupFields.contains(field)) {
        final actual = endpoint.decode(_response(nulled)).groups.single;
        expect(_groupValue(actual, field), isNull, reason: field);
      } else {
        expect(
          () => endpoint.decode(_response(nulled)),
          throwsFormatException,
          reason: '$field null',
        );
      }
    }
  });

  test('requires every level, progress, and through field', () {
    final endpoint = contract.sourceGroups();
    for (final field in _levelFields) {
      final level = _level()..remove(field);
      expect(
        () => endpoint.decode(_response(_group()..['level'] = level)),
        throwsFormatException,
        reason: 'level.$field missing',
      );
      final nulled = _level()..[field] = null;
      if (field == 'order' || field == 'progress') {
        final actual = endpoint.decode(_response(_group()..['level'] = nulled));
        final decoded = actual.groups.single.level!;
        expect(field == 'order' ? decoded.order : decoded.progress, isNull);
      } else {
        expect(
          () => endpoint.decode(_response(_group()..['level'] = nulled)),
          throwsFormatException,
          reason: 'level.$field null',
        );
      }
    }

    for (final field in ['solved', 'through']) {
      for (final mutate in <void Function(Map<String, Object?>)>[
        (progress) => progress.remove(field),
        (progress) => progress[field] = null,
      ]) {
        final progress = _progress();
        mutate(progress);
        expect(
          () => endpoint.decode(
            _response(
                _group()..['level'] = (_level()..['progress'] = progress)),
          ),
          throwsFormatException,
          reason: 'progress.$field',
        );
      }
    }

    for (final field in ['q25', 'q50', 'q75']) {
      for (final invalid in <Object?>[_missing, null, 0, 'true']) {
        final through = _through();
        if (identical(invalid, _missing)) {
          through.remove(field);
        } else {
          through[field] = invalid;
        }
        final progress = _progress()..['through'] = through;
        expect(
          () => endpoint.decode(
            _response(
                _group()..['level'] = (_level()..['progress'] = progress)),
          ),
          throwsFormatException,
          reason: 'through.$field = $invalid',
        );
      }
    }
  });

  test('distinguishes finite numbers from strict integers', () {
    final endpoint = contract.sourceGroups();
    for (final field in [
      'id',
      'groupCount',
      'contestCount',
      'problemCount',
      'solvedCount',
    ]) {
      for (final value in <num>[-1, 0, 1.5, 2.0]) {
        final actual =
            endpoint.decode(_response(_group()..[field] = value)).groups.single;
        expect(_groupValue(actual, field), value);
        expect(_groupValue(actual, field).runtimeType, value.runtimeType);
      }
      for (final invalid in <Object?>[
        double.nan,
        double.infinity,
        '1',
        false,
      ]) {
        expect(
          () => endpoint.decode(_response(_group()..[field] = invalid)),
          throwsFormatException,
          reason: '$field = $invalid',
        );
      }
    }

    for (final field in ['q25', 'q50', 'q75', 'ratedCount']) {
      for (final invalid in <Object?>[1.0, 1.5, '1', false]) {
        expect(
          () => endpoint.decode(
            _response(_group()..['level'] = (_level()..[field] = invalid)),
          ),
          throwsFormatException,
          reason: 'level.$field = $invalid',
        );
      }
    }
    for (final invalid in <Object?>[1.0, '1', null]) {
      expect(
        () => endpoint.decode(
          _response(
            _group()
              ..['level'] = (_level()
                ..['progress'] = (_progress()..['solved'] = invalid)),
          ),
        ),
        throwsFormatException,
        reason: 'progress.solved = $invalid',
      );
    }
  });

  test('requires strict strings and a through object', () {
    final endpoint = contract.sourceGroups();
    for (final field in ['name', 'abbreviation']) {
      for (final invalid in <Object?>[0, false, const <Object?>[]]) {
        expect(
          () => endpoint.decode(_response(_group()..[field] = invalid)),
          throwsFormatException,
          reason: '$field = $invalid',
        );
      }
    }
    for (final invalid in <Object?>[true, 'through', const <Object?>[]]) {
      final progress = _progress()..['through'] = invalid;
      expect(
        () => endpoint.decode(
          _response(_group()..['level'] = (_level()..['progress'] = progress)),
        ),
        throwsFormatException,
        reason: 'through = $invalid',
      );
    }
  });

  test('accepts only the exact nullable order values', () {
    final endpoint = contract.sourceGroups();
    for (final order in SourceProblemOrder.values) {
      final actual = endpoint
          .decode(
            _response(
              _group()
                ..['order'] = order.value
                ..['level'] = (_level()..['order'] = order.value),
            ),
          )
          .groups
          .single;
      expect(actual.order, order);
      expect(actual.level!.order, order);
    }
    for (final invalid in <Object?>['Ascending', 'ASCENDING', '', 0]) {
      expect(
        () => endpoint.decode(_response(_group()..['order'] = invalid)),
        throwsFormatException,
        reason: 'order = $invalid',
      );
      expect(
        () => endpoint.decode(
          _response(_group()..['level'] = (_level()..['order'] = invalid)),
        ),
        throwsFormatException,
        reason: 'level.order = $invalid',
      );
    }
  });

  test('eagerly snapshots ordered duplicate unmodifiable lists', () {
    final endpoint = contract.sourceGroups();
    expect(
      () => endpoint.decode(_response(_group(), 1)),
      throwsFormatException,
    );
    expect(
      () => endpoint.decode(<String, Object?>{'groups': null}),
      throwsFormatException,
    );
    for (final invalid in <Object?>[null, 1.0, '1']) {
      expect(
        () => endpoint.decode(
          _response(
            _group()..['level'] = (_level()..['tierCounts'] = [1, invalid]),
          ),
        ),
        throwsFormatException,
      );
    }

    final duplicate = _group()..['name'] = 'duplicate';
    final tierCounts = <Object?>[3, 3, 1];
    final last = _group()
      ..['name'] = 'last'
      ..['level'] = (_level()..['tierCounts'] = tierCounts);
    final groups = <Object?>[duplicate, duplicate, last];
    final source = <String, Object?>{'groups': groups};
    final actual = endpoint.decode(source);
    duplicate['name'] = 'changed';
    tierCounts.clear();
    groups.clear();

    expect(
      actual.groups.map((group) => group.name),
      ['duplicate', 'duplicate', 'last'],
    );
    expect(actual.groups.last.level!.tierCounts, [3, 3, 1]);
    expect(() => actual.groups.clear(), throwsUnsupportedError);
    expect(
      () => actual.groups.last.level!.tierCounts.add(1),
      throwsUnsupportedError,
    );
    expect(
      endpoint.decode(<String, Object?>{'groups': <Object?>[]}).groups,
      isEmpty,
    );
  });

  test('ignores future fields', () {
    final actual = contract
        .sourceGroups()
        .decode(<String, Object?>{
          'groups': <Object?>[
            _group()
              ..['future'] = true
              ..['level'] = (_level()..['future'] = <Object?>[]),
          ],
          'future': 1,
        })
        .groups
        .single;
    expect(actual.name, 'group');
  });
}

const _missing = Object();

const _groupFields = [
  'id',
  'name',
  'abbreviation',
  'groupCount',
  'contestCount',
  'problemCount',
  'solvedCount',
  'level',
  'order',
];

const _nullableGroupFields = {
  'abbreviation',
  'problemCount',
  'solvedCount',
  'level',
  'order',
};

const _levelFields = [
  'q25',
  'q50',
  'q75',
  'tierCounts',
  'ratedCount',
  'order',
  'progress',
];

Map<String, Object?> _response(Object? group, [Object? extra]) =>
    <String, Object?>{
      'groups': <Object?>[group, if (extra != null) extra],
    };

Map<String, Object?> _group() => <String, Object?>{
      'id': 1,
      'name': 'group',
      'abbreviation': 'G',
      'groupCount': 2,
      'contestCount': 3,
      'problemCount': 4,
      'solvedCount': 5,
      'level': _level(),
      'order': 'ascending',
    };

Map<String, Object?> _level() => <String, Object?>{
      'q25': 1,
      'q50': 2,
      'q75': 3,
      'tierCounts': <Object?>[1, 2],
      'ratedCount': 3,
      'order': 'random',
      'progress': _progress(),
    };

Map<String, Object?> _progress() => <String, Object?>{
      'solved': 1,
      'through': _through(),
    };

Map<String, Object?> _through() => <String, Object?>{
      'q25': true,
      'q50': false,
      'q75': false,
    };

Object? _groupValue(SourceGroupSummary group, String field) => switch (field) {
      'id' => group.id,
      'name' => group.name,
      'abbreviation' => group.abbreviation,
      'groupCount' => group.groupCount,
      'contestCount' => group.contestCount,
      'problemCount' => group.problemCount,
      'solvedCount' => group.solvedCount,
      'level' => group.level,
      _ => group.order,
    };
