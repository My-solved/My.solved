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

  test('builds the public feed endpoint with every query omitted', () {
    final endpoint = contract.userActivityFeed('index');

    expect(endpoint.direct.path, 'users/index/activity/feed');
    expect(endpoint.direct.queryParameters, isEmpty);
    expect(endpoint.proxy.path, endpoint.direct.path);
    expect(endpoint.proxy.queryParameters, isEmpty);
  });

  test('preserves empty, Unicode, combined, and raw query values', () {
    final unboundedCursor = List<String>.filled(2048, '🧩').join();
    expect(
      contract.userActivityFeed('index', before: '').direct.queryParameters,
      {'before': ''},
    );
    expect(
      contract
          .userActivityFeed('index', before: unboundedCursor)
          .direct
          .queryParameters,
      {'before': unboundedCursor},
    );
    expect(
      contract
          .userActivityFeed(
            '한 글',
            before: '커서 & raw',
            from: '9999-99-99',
            to: '0000-00-00',
            limit: 500,
          )
          .direct
          .queryParameters,
      {
        'before': '커서 & raw',
        'from': '9999-99-99',
        'to': '0000-00-00',
        'limit': '500',
      },
    );
    expect(contract.userActivityFeed('index', limit: 1).proxy.queryParameters, {
      'limit': '1',
    });
    expect(
      contract.userActivityFeed('한 글').direct.path,
      'users/%ED%95%9C%20%EA%B8%80/activity/feed',
    );
  });

  test('validates date patterns without calendar or ordering inference', () {
    for (final accepted in ['0000-00-00', '2026-02-31', '9999-99-99']) {
      expect(
        contract
            .userActivityFeed('index', from: accepted, to: accepted)
            .direct
            .queryParameters,
        {'from': accepted, 'to': accepted},
        reason: accepted,
      );
    }
    expect(
      contract
          .userActivityFeed('index', from: '9999-12-31', to: '0000-01-01')
          .direct
          .queryParameters,
      {'from': '9999-12-31', 'to': '0000-01-01'},
    );

    for (final name in ['from', 'to']) {
      for (final invalid in [
        '',
        '2026-1-01',
        '2026-01-1',
        '20260-01-01',
        '2026/01/01',
        ' 2026-01-01',
      ]) {
        expect(
          () => contract.userActivityFeed(
            'index',
            from: name == 'from' ? invalid : null,
            to: name == 'to' ? invalid : null,
          ),
          throwsA(
            isA<ArgumentError>()
                .having((error) => error.name, 'name', name)
                .having((error) => error.invalidValue, 'invalidValue', invalid),
          ),
          reason: '$name = $invalid',
        );
      }
    }
  });

  test('accepts only the documented limit range', () {
    for (final limit in [1, 500]) {
      expect(
        contract.userActivityFeed('index', limit: limit).direct.queryParameters,
        {'limit': '$limit'},
      );
    }
    for (final limit in [-1, 0, 501, 1000000]) {
      expect(
        () => contract.userActivityFeed('index', limit: limit),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'limit')
              .having((error) => error.invalidValue, 'invalidValue', limit),
        ),
      );
    }
  });

  test('validates the handle as one Unicode code-point-bounded segment', () {
    final boundary = List<String>.filled(64, '😀').join();
    expect(
      contract.userActivityFeed(boundary).direct.path,
      startsWith('users/'),
    );
    for (final invalid in <String>[
      '',
      '.',
      '..',
      'a/b',
      r'a\b',
      'line\nbreak',
      '$boundary😀',
    ]) {
      expect(
        () => contract.userActivityFeed(invalid),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'handle')
              .having((error) => error.invalidValue, 'invalidValue', invalid),
        ),
        reason: invalid,
      );
    }
  });

  test('decodes the complete official activity-feed fixture', () {
    final actual = contract
        .userActivityFeed('index')
        .decode(jsonDecode(fixture('v4/user_activity_feed.json')));

    expect(actual.events, hasLength(3));
    expect(actual.nextCursor, '');
    final solved = actual.events.first;
    expect(solved.id, -17);
    expect(solved.type, ProfileActivityFeedEventType.solved);
    expect(solved.occurredAt, '2026-11-25T01:02:03Z');
    expect(solved.reason, isNull);
    expect(solved.milestone, isNull);
    expect(solved.hasPayload, isTrue);
    final problem = solved.problem!;
    expect(problem.problemId, -1000);
    expect(problem.subId, 'main');
    expect(problem.level, 30);
    expect(problem.effectiveVoteCount, 0);
    expect(problem.givesNoRating, isTrue);
    expect(problem.isStandard, isFalse);
    expect(problem.titles, hasLength(2));
    expect(problem.titles.map((title) => title.title), ['활동 문제', '활동 문제']);
    expect(problem.userStatus, ProblemUserStatus.partial);

    final rating = actual.events[1];
    expect(rating.type, ProfileActivityFeedEventType.rating);
    expect(rating.occurredAt, 'not-a-date-time');
    expect(rating.problem, isNull);
    expect(rating.reason, 'raw reason');
    expect(rating.milestone, -99);
    expect(rating.hasPayload, isTrue);
    expect(rating.payload, isNull);

    final milestone = actual.events.last;
    expect(milestone.type, ProfileActivityFeedEventType.voteMilestone);
    expect(milestone.occurredAt, '');
    expect(milestone.milestone, 0);
    expect(milestone.hasPayload, isFalse);
    expect(milestone.payload, isNull);
  });

  test('requires the response object, events, and nullable cursor key', () {
    final endpoint = contract.userActivityFeed('index');
    for (final invalid in <Object?>[
      null,
      0,
      false,
      'feed',
      const <Object?>[],
      const <String, Object?>{},
      const <String, Object?>{'events': <Object?>[]},
      const <String, Object?>{'nextCursor': null},
      const <String, Object?>{'events': null, 'nextCursor': null},
      const <String, Object?>{'events': 1, 'nextCursor': null},
      const <String, Object?>{'events': <Object?>[], 'nextCursor': 1},
    ]) {
      expect(
        () => endpoint.decode(invalid),
        throwsFormatException,
        reason: '$invalid',
      );
    }

    final nullCursor = endpoint.decode({
      'events': <Object?>[],
      'nextCursor': null,
    });
    final emptyCursor = endpoint.decode({
      'events': <Object?>[],
      'nextCursor': '',
    });
    expect(nullCursor.nextCursor, isNull);
    expect(emptyCursor.nextCursor, '');
  });

  test('requires every event field while keeping payload optional', () {
    final endpoint = contract.userActivityFeed('index');
    for (final field in [
      'id',
      'type',
      'occurredAt',
      'problem',
      'reason',
      'milestone',
    ]) {
      expect(
        () => endpoint.decode(_envelope([_event()..remove(field)])),
        throwsFormatException,
        reason: '$field missing',
      );
    }

    final withoutPayload = endpoint.decode(_envelope([_event()])).events.single;
    expect(withoutPayload.hasPayload, isFalse);
    expect(withoutPayload.payload, isNull);
  });

  test('preserves all event types and rejects unknown or non-string types', () {
    final endpoint = contract.userActivityFeed('index');
    const expected = <String, ProfileActivityFeedEventType>{
      'solved': ProfileActivityFeedEventType.solved,
      'unsolved': ProfileActivityFeedEventType.unsolved,
      'vote': ProfileActivityFeedEventType.vote,
      'rating': ProfileActivityFeedEventType.rating,
      'tier': ProfileActivityFeedEventType.tier,
      'solvedMilestone': ProfileActivityFeedEventType.solvedMilestone,
      'voteMilestone': ProfileActivityFeedEventType.voteMilestone,
    };
    for (final entry in expected.entries) {
      final actual = endpoint.decode(
        _envelope([_event()..['type'] = entry.key]),
      );
      expect(actual.events.single.type, entry.value);
    }
    for (final invalid in <Object?>[
      null,
      '',
      'future',
      1,
      false,
      const <Object?>[],
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(_envelope([_event()..['type'] = invalid])),
        throwsFormatException,
        reason: '$invalid',
      );
    }
  });

  test('validates event scalar types and required-nullable values', () {
    final endpoint = contract.userActivityFeed('index');
    final invalidValues = <String, List<Object?>>{
      'id': [null, 1.0, '1', false, const <Object?>[]],
      'occurredAt': [null, 1, false, const <Object?>[]],
      'reason': [1, false, const <Object?>[], const <String, Object?>{}],
      'milestone': [1.0, '1', false, const <Object?>[]],
    };
    for (final entry in invalidValues.entries) {
      for (final invalid in entry.value) {
        expect(
          () => endpoint.decode(_envelope([_event()..[entry.key] = invalid])),
          throwsFormatException,
          reason: '${entry.key} = $invalid',
        );
      }
    }

    final actual = endpoint.decode(
      _envelope([
        _event()
          ..['id'] = -1000000
          ..['occurredAt'] = ''
          ..['reason'] = null
          ..['milestone'] = -1000000,
        _event()
          ..['id'] = 1000000
          ..['reason'] = ''
          ..['milestone'] = 1000000,
      ]),
    );
    expect(actual.events.map((event) => event.id), [-1000000, 1000000]);
    expect(actual.events.map((event) => event.milestone), [-1000000, 1000000]);
    expect(actual.events.first.reason, isNull);
    expect(actual.events.last.reason, '');
  });

  test('requires problem null or the complete documented object', () {
    final endpoint = contract.userActivityFeed('index');
    final nullable = endpoint.decode(_envelope([_event()..['problem'] = null]));
    expect(nullable.events.single.problem, isNull);

    for (final invalid in <Object?>[0, false, 'problem', const <Object?>[]]) {
      expect(
        () => endpoint.decode(_envelope([_event()..['problem'] = invalid])),
        throwsFormatException,
        reason: '$invalid',
      );
    }
    for (final field in [
      'problemId',
      'subId',
      'level',
      'effectiveVoteCount',
      'givesNoRating',
      'isStandard',
      'titles',
      'userStatus',
    ]) {
      expect(
        () => endpoint.decode(
          _envelope([_event(problem: _problem()..remove(field))]),
        ),
        throwsFormatException,
        reason: '$field missing',
      );
    }
  });

  test('enforces exact problem integers and only documented bounds', () {
    final endpoint = contract.userActivityFeed('index');
    for (final problemId in [-1000000, 0, 1000000]) {
      final actual = endpoint.decode(
        _envelope([_event(problem: _problem()..['problemId'] = problemId)]),
      );
      expect(actual.events.single.problem?.problemId, problemId);
    }
    for (final level in [0, 30]) {
      final actual = endpoint.decode(
        _envelope([_event(problem: _problem()..['level'] = level)]),
      );
      expect(actual.events.single.problem?.level, level);
    }
    for (final count in [0, 1000000]) {
      final actual = endpoint.decode(
        _envelope([
          _event(problem: _problem()..['effectiveVoteCount'] = count),
        ]),
      );
      expect(actual.events.single.problem?.effectiveVoteCount, count);
    }

    for (final field in ['problemId', 'level', 'effectiveVoteCount']) {
      for (final invalid in <Object?>[
        null,
        1.0,
        -1.0,
        double.nan,
        double.infinity,
        '1',
        false,
      ]) {
        expect(
          () => endpoint.decode(
            _envelope([_event(problem: _problem()..[field] = invalid)]),
          ),
          throwsFormatException,
          reason: '$field = $invalid',
        );
      }
    }
    for (final level in [-1, 31]) {
      expect(
        () => endpoint.decode(
          _envelope([_event(problem: _problem()..['level'] = level)]),
        ),
        throwsFormatException,
      );
    }
    expect(
      () => endpoint.decode(
        _envelope([_event(problem: _problem()..['effectiveVoteCount'] = -1)]),
      ),
      throwsFormatException,
    );
  });

  test('validates problem strings, booleans, and nullable status', () {
    final endpoint = contract.userActivityFeed('index');
    final invalidValues = <String, List<Object?>>{
      'subId': [null, 1, false, const <Object?>[]],
      'givesNoRating': [null, 1, 'true', const <Object?>[]],
      'isStandard': [null, 1, 'true', const <Object?>[]],
      'userStatus': ['', 'future', 1, false, const <Object?>[]],
    };
    for (final entry in invalidValues.entries) {
      for (final invalid in entry.value) {
        expect(
          () => endpoint.decode(
            _envelope([_event(problem: _problem()..[entry.key] = invalid)]),
          ),
          throwsFormatException,
          reason: '${entry.key} = $invalid',
        );
      }
    }

    for (final entry in <Object?, ProblemUserStatus?>{
      null: null,
      'solved': ProblemUserStatus.solved,
      'partial': ProblemUserStatus.partial,
      'tried': ProblemUserStatus.tried,
    }.entries) {
      final actual = endpoint.decode(
        _envelope([_event(problem: _problem()..['userStatus'] = entry.key)]),
      );
      expect(actual.events.single.problem?.userStatus, entry.value);
    }
  });

  test(
    'strictly decodes titles while preserving empty order and duplicates',
    () {
      final endpoint = contract.userActivityFeed('index');
      final empty = endpoint.decode(
        _envelope([_event(problem: _problem()..['titles'] = <Object?>[])]),
      );
      expect(empty.events.single.problem?.titles, isEmpty);

      for (final field in [
        'language',
        'title',
        'isOriginal',
        'latex',
        'html',
      ]) {
        expect(
          () => endpoint.decode(
            _envelope([
              _event(
                problem: _problem()
                  ..['titles'] = <Object?>[_title()..remove(field)],
              ),
            ]),
          ),
          throwsFormatException,
          reason: '$field missing',
        );
      }

      final first = _title()
        ..['title'] = 'same'
        ..['futureTitle'] = true;
      final second = _title()
        ..['title'] = 'same'
        ..['language'] = 'en';
      final source = <Object?>[first, second];
      final actual = endpoint.decode(
        _envelope([_event(problem: _problem()..['titles'] = source)]),
      );
      source.clear();
      first['title'] = 'mutated';
      final titles = actual.events.single.problem!.titles;
      expect(titles.map((title) => title.title), ['same', 'same']);
      expect(titles.map((title) => title.language), ['ko', 'en']);
      expect(() => titles.clear(), throwsUnsupportedError);
    },
  );

  test('distinguishes absent, null, and every scalar JSON payload', () {
    final endpoint = contract.userActivityFeed('index');
    final cases = <Object?>[null, true, false, '', 'raw', -7, 2.0, 1.5];
    final events = <Object?>[_event()];
    for (final value in cases) {
      events.add(_event(payload: value));
    }
    final actual = endpoint.decode(_envelope(events)).events;

    expect(actual.first.hasPayload, isFalse);
    expect(actual.first.payload, isNull);
    for (var index = 0; index < cases.length; index += 1) {
      final event = actual[index + 1];
      expect(event.hasPayload, isTrue, reason: 'payload ${cases[index]}');
      expect(event.payload, cases[index]);
      if (cases[index] is double) expect(event.payload, isA<double>());
      if (cases[index] is int) expect(event.payload, isA<int>());
    }
  });

  test('deep-copies and recursively freezes list and map payloads', () {
    final endpoint = contract.userActivityFeed('index');
    final leaf = <Object?, Object?>{'value': 7};
    final list = <Object?>[null, leaf];
    final payload = <Object?, Object?>{'items': list};
    final actual = endpoint
        .decode(_envelope([_event(payload: payload)]))
        .events
        .single
        .payload as Map<String, Object?>;

    leaf['value'] = 99;
    list
      ..clear()
      ..add('mutated');
    payload
      ..clear()
      ..['new'] = true;

    final frozenList = actual['items']! as List<Object?>;
    final frozenLeaf = frozenList.last! as Map<String, Object?>;
    expect(frozenList.first, isNull);
    expect(frozenLeaf, {'value': 7});
    expect(() => actual['new'] = true, throwsUnsupportedError);
    expect(() => frozenList.add(1), throwsUnsupportedError);
    expect(() => frozenLeaf['value'] = 8, throwsUnsupportedError);
  });

  test('eagerly rejects non-JSON and non-finite payload values', () {
    final endpoint = contract.userActivityFeed('index');
    for (final invalid in <Object?>[
      double.nan,
      double.infinity,
      double.negativeInfinity,
      <int>{1},
      DateTime.utc(2026),
      Object(),
      <Object?, Object?>{1: 'not a JSON object key'},
      <Object?>[
        1,
        <Object?>[Object()],
      ],
      <Object?, Object?>{
        'valid': true,
        'later': <Object?>[double.nan],
      },
    ]) {
      expect(
        () => endpoint.decode(_envelope([_event(payload: invalid)])),
        throwsFormatException,
        reason: '$invalid',
      );
    }
  });

  test('preserves event order, duplicates, future fields, and isolation', () {
    final endpoint = contract.userActivityFeed('index');
    final first = _event()
      ..['id'] = 7
      ..['futureEvent'] = true;
    final second = _event()
      ..['id'] = 7
      ..['type'] = 'tier';
    final source = <Object?>[first, second];
    final envelope = _envelope(source)..['futureEnvelope'] = 'ignored';
    final actual = endpoint.decode(envelope);

    source.clear();
    first['id'] = 99;
    expect(actual.events.map((event) => event.id), [7, 7]);
    expect(actual.events.map((event) => event.type), [
      ProfileActivityFeedEventType.solved,
      ProfileActivityFeedEventType.tier,
    ]);
    expect(
      () => actual.events.add(
        const ProfileActivityFeedEvent(
          id: 1,
          type: ProfileActivityFeedEventType.solved,
          occurredAt: '',
          problem: null,
          reason: null,
          milestone: null,
          hasPayload: false,
          payload: null,
        ),
      ),
      throwsUnsupportedError,
    );
  });

  test('does not infer field relations from the event type', () {
    final actual = contract.userActivityFeed('index').decode(
          _envelope([
            _event()
              ..['type'] = 'solvedMilestone'
              ..['problem'] = null
              ..['reason'] = ''
              ..['milestone'] = null,
            _event(problem: _problem())
              ..['type'] = 'rating'
              ..['milestone'] = -1,
          ]),
        );

    expect(actual.events.first.problem, isNull);
    expect(actual.events.first.reason, '');
    expect(actual.events.first.milestone, isNull);
    expect(actual.events.last.problem, isNotNull);
    expect(actual.events.last.milestone, -1);
  });
}

const _absentPayload = _AbsentPayload();

final class _AbsentPayload {
  const _AbsentPayload();
}

Map<String, Object?> _envelope(List<Object?> events) => <String, Object?>{
      'events': events,
      'nextCursor': null,
    };

Map<String, Object?> _event({
  Object? problem,
  Object? payload = _absentPayload,
}) =>
    <String, Object?>{
      'id': 1,
      'type': 'solved',
      'occurredAt': 'raw',
      'problem': problem,
      'reason': null,
      'milestone': null,
      if (!identical(payload, _absentPayload)) 'payload': payload,
    };

Map<String, Object?> _problem() => <String, Object?>{
      'problemId': 1000,
      'subId': 'main',
      'level': 1,
      'effectiveVoteCount': 0,
      'givesNoRating': false,
      'isStandard': true,
      'titles': <Object?>[_title()],
      'userStatus': null,
    };

Map<String, Object?> _title() => <String, Object?>{
      'language': 'ko',
      'title': 'title',
      'isOriginal': true,
      'latex': false,
      'html': false,
    };
