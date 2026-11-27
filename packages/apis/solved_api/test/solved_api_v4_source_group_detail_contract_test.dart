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

  test('builds the group detail path and rejects ids below one', () {
    for (final id in [1, 42, 9007199254740991]) {
      final endpoint = contract.sourceGroupDetail(id);
      expect(endpoint.direct.path, 'sources/groups/$id');
      expect(endpoint.direct.queryParameters, isEmpty);
      expect(endpoint.proxy.path, endpoint.direct.path);
      expect(endpoint.proxy.queryParameters, isEmpty);
    }
    for (final id in [0, -1]) {
      expect(
        () => contract.sourceGroupDetail(id),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'id')
              .having((error) => error.invalidValue, 'invalidValue', id),
        ),
      );
    }
  });

  test('decodes the complete fixture without inferred relationships', () {
    final actual = contract.sourceGroupDetail(1).decode(
          jsonDecode(fixture('v4/source_group_detail.json')),
        );

    expect(actual.group.id, 10);
    expect(actual.group.abbreviation, isNull);
    expect(actual.group.contestCount, 2.5);
    expect(actual.group.problemCount, isNull);
    expect(actual.group.level, isNull);
    expect(actual.group.order, SourceProblemOrder.random);

    expect(actual.path.map((entry) => entry.id), [1, -2.5, 1]);
    expect(actual.path.map((entry) => entry.name), ['Root', '', 'Root']);
    expect(actual.path[1].id, isA<double>());

    expect(actual.links.first.ojId, 'boj');
    expect(actual.links.first.ojName, 'Example Judge');
    expect(actual.links.first.url, 'not necessarily a URI');
    expect(actual.links.last.url, '');
    expect(actual.query, 'raw & 한 글');

    final child = actual.groups.single;
    expect(child.id, 11.0);
    expect(child.id, isA<double>());
    expect(child.level!.q50, 5);
    expect(child.level!.order, SourceProblemOrder.ascending);
    expect(child.level!.progress, isNull);
    expect(child.order, isNull);

    final first = actual.contests.first;
    expect(first.id, 100);
    expect(first.name, 'Round 1');
    expect(first.abbreviation, 'R1');
    expect(first.startsAt, 'not a date');
    expect(first.problemCount, 7.5);
    expect(first.solvedCount, isNull);
    expect(first.level!.tierCounts, isEmpty);
    expect(first.level!.progress!.solved, -1);
    expect(first.level!.progress!.through.q75, isTrue);

    final last = actual.contests.last;
    expect(last.id, -100.5);
    expect(last.name, '');
    expect(last.abbreviation, isNull);
    expect(last.startsAt, isNull);
    expect(last.problemCount, 0);
    expect(last.solvedCount, 9);
    expect(last.level, isNull);
  });

  test('requires every outer field and preserves a nullable query', () {
    final endpoint = contract.sourceGroupDetail(1);
    for (final invalid in <Object?>[null, 0, 'group', const <Object?>[]]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
    for (final field in _outerFields) {
      expect(
        () => endpoint.decode(_response()..remove(field)),
        throwsFormatException,
        reason: '$field missing',
      );
      if (field == 'query') {
        expect(endpoint.decode(_response()..[field] = null).query, isNull);
      } else {
        expect(
          () => endpoint.decode(_response()..[field] = null),
          throwsFormatException,
          reason: '$field null',
        );
      }
    }
    for (final invalid in <Object?>[0, false, const <Object?>[]]) {
      expect(
        () => endpoint.decode(_response()..['query'] = invalid),
        throwsFormatException,
      );
    }
    expect(
      () =>
          endpoint.decode(_response()..['group'] = (_group()..remove('order'))),
      throwsFormatException,
    );
    expect(
      () => endpoint.decode(
        _response()..['groups'] = [_group()..remove('level')],
      ),
      throwsFormatException,
    );
  });

  test('requires strict path and link entries', () {
    final endpoint = contract.sourceGroupDetail(1);
    for (final field in ['id', 'name']) {
      for (final invalid in <Object?>[_missing, null, false]) {
        final entry = _pathEntry();
        _mutate(entry, field, invalid);
        expect(
          () => endpoint.decode(_response()..['path'] = [entry]),
          throwsFormatException,
          reason: 'path.$field = $invalid',
        );
      }
    }
    for (final invalid in <Object?>[double.nan, double.infinity, '1']) {
      expect(
        () => endpoint.decode(
          _response()..['path'] = [_pathEntry()..['id'] = invalid],
        ),
        throwsFormatException,
      );
    }
    for (final field in ['ojId', 'ojName', 'url']) {
      for (final invalid in <Object?>[_missing, null, 0]) {
        final link = _link();
        _mutate(link, field, invalid);
        expect(
          () => endpoint.decode(_response()..['links'] = [link]),
          throwsFormatException,
          reason: 'links.$field = $invalid',
        );
      }
    }
    expect(
      () => endpoint.decode(_response()..['path'] = [1]),
      throwsFormatException,
    );
    expect(
      () => endpoint.decode(_response()..['links'] = ['link']),
      throwsFormatException,
    );
  });

  test('requires every contest field and preserves nullable states', () {
    final endpoint = contract.sourceGroupDetail(1);
    for (final field in _contestFields) {
      expect(
        () => endpoint.decode(
          _response()..['contests'] = [_contest()..remove(field)],
        ),
        throwsFormatException,
        reason: '$field missing',
      );
      final nulled = _response()..['contests'] = [_contest()..[field] = null];
      if (_nullableContestFields.contains(field)) {
        final actual = endpoint.decode(nulled).contests.single;
        expect(_contestValue(actual, field), isNull, reason: field);
      } else {
        expect(
          () => endpoint.decode(nulled),
          throwsFormatException,
          reason: '$field null',
        );
      }
    }
    for (final field in ['id', 'problemCount', 'solvedCount']) {
      for (final value in <num>[-1, 0, 1.5, 2.0]) {
        final actual = endpoint
            .decode(_response()..['contests'] = [_contest()..[field] = value])
            .contests
            .single;
        expect(_contestValue(actual, field), value);
        expect(_contestValue(actual, field).runtimeType, value.runtimeType);
      }
      for (final invalid in <Object?>[double.nan, '1', false]) {
        expect(
          () => endpoint.decode(
            _response()..['contests'] = [_contest()..[field] = invalid],
          ),
          throwsFormatException,
          reason: '$field = $invalid',
        );
      }
    }
    for (final field in ['name', 'abbreviation', 'startsAt']) {
      expect(
        () => endpoint.decode(
          _response()..['contests'] = [_contest()..[field] = 0],
        ),
        throwsFormatException,
        reason: field,
      );
    }
    expect(
      () => endpoint.decode(
        _response()
          ..['contests'] = [
            _contest()..['level'] = (_level()..['q25'] = 1.0),
          ],
      ),
      throwsFormatException,
    );
    for (final value in ['', ' ', '2026-13-45T99:99:99Z', 'not a date']) {
      final actual = endpoint
          .decode(
              _response()..['contests'] = [_contest()..['startsAt'] = value])
          .contests
          .single;
      expect(actual.startsAt, value);
    }
  });

  test('eagerly snapshots ordered duplicate unmodifiable lists', () {
    final endpoint = contract.sourceGroupDetail(1);
    final entry = _pathEntry()..['name'] = 'entry';
    final link = _link()..['ojName'] = 'link';
    final group = _group()..['name'] = 'group';
    final contest = _contest()..['name'] = 'contest';
    final path = <Object?>[entry, entry];
    final links = <Object?>[link, link];
    final groups = <Object?>[group, group];
    final contests = <Object?>[contest, contest];
    final source = _response()
      ..['path'] = path
      ..['links'] = links
      ..['groups'] = groups
      ..['contests'] = contests;

    final actual = endpoint.decode(source);
    for (final value in [entry, group, contest]) {
      value['name'] = 'changed';
    }
    link['ojName'] = 'changed';
    for (final list in [path, links, groups, contests]) {
      list.clear();
    }

    expect(actual.path.map((value) => value.name), ['entry', 'entry']);
    expect(actual.links.map((value) => value.ojName), ['link', 'link']);
    expect(actual.groups.map((value) => value.name), ['group', 'group']);
    expect(actual.contests.map((value) => value.name), ['contest', 'contest']);
    expect(() => actual.path.clear(), throwsUnsupportedError);
    expect(() => actual.links.clear(), throwsUnsupportedError);
    expect(() => actual.groups.clear(), throwsUnsupportedError);
    expect(() => actual.contests.clear(), throwsUnsupportedError);

    final empty = endpoint.decode(
      _response()
        ..['path'] = <Object?>[]
        ..['links'] = <Object?>[]
        ..['groups'] = <Object?>[]
        ..['contests'] = <Object?>[]
        ..['future'] = true,
    );
    expect(empty.path, isEmpty);
    expect(empty.links, isEmpty);
    expect(empty.groups, isEmpty);
    expect(empty.contests, isEmpty);
  });
}

const _missing = Object();

void _mutate(Map<String, Object?> body, String field, Object? value) {
  if (identical(value, _missing)) {
    body.remove(field);
  } else {
    body[field] = value;
  }
}

const _outerFields = ['group', 'path', 'links', 'query', 'groups', 'contests'];

const _contestFields = [
  'id',
  'name',
  'abbreviation',
  'startsAt',
  'problemCount',
  'solvedCount',
  'level',
];

const _nullableContestFields = {
  'abbreviation',
  'startsAt',
  'solvedCount',
  'level',
};

Map<String, Object?> _response() => <String, Object?>{
      'group': _group(),
      'path': <Object?>[_pathEntry()],
      'links': <Object?>[_link()],
      'query': 'q',
      'groups': <Object?>[_group()],
      'contests': <Object?>[_contest()],
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
      'progress': null,
    };

Map<String, Object?> _pathEntry() => <String, Object?>{'id': 1, 'name': 'p'};

Map<String, Object?> _link() => <String, Object?>{
      'ojId': 'boj',
      'ojName': 'Judge',
      'url': 'https://example.invalid/',
    };

Map<String, Object?> _contest() => <String, Object?>{
      'id': 1,
      'name': 'contest',
      'abbreviation': 'C',
      'startsAt': '2026-01-01T00:00:00Z',
      'problemCount': 3,
      'solvedCount': 1,
      'level': _level(),
    };

Object? _contestValue(SourceContestSummary contest, String field) =>
    switch (field) {
      'id' => contest.id,
      'name' => contest.name,
      'abbreviation' => contest.abbreviation,
      'startsAt' => contest.startsAt,
      'problemCount' => contest.problemCount,
      'solvedCount' => contest.solvedCount,
      _ => contest.level,
    };
