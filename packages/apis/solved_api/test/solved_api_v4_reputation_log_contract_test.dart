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

  test('builds the reputation log with an omitted or pattern month', () {
    final omitted = contract.userReputationLog('alice');
    final month = contract.userReputationLog('a b&한', month: '0000-12');

    expect(omitted.direct.path, 'users/alice/reputation/log');
    expect(omitted.direct.queryParameters, isEmpty);
    expect(omitted.proxy.path, omitted.direct.path);
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(month.direct.path, 'users/a%20b%26%ED%95%9C/reputation/log');
    expect(month.direct.queryParameters, {'month': '0000-12'});
    expect(month.proxy.queryParameters, month.direct.queryParameters);
    for (final value in ['2026-01', '9999-09', '2026-10']) {
      expect(
        contract
            .userReputationLog('alice', month: value)
            .direct
            .queryParameters,
        {'month': value},
      );
    }
  });

  test('rejects months outside the official pattern and unsafe handles', () {
    for (final invalid in [
      '',
      '2026-1',
      '2026-00',
      '2026-13',
      '26-01',
      '2026-01-01',
      ' 2026-01',
      '２０２６-01',
    ]) {
      expect(
        () => contract.userReputationLog('alice', month: invalid),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'month')
              .having((error) => error.invalidValue, 'invalidValue', invalid),
        ),
        reason: invalid,
      );
    }
    for (final invalid in ['', '..', 'a/b', List.filled(65, 'a').join()]) {
      expect(
        () => contract.userReputationLog(invalid),
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', 'handle'),
        ),
      );
    }
  });

  test('decodes the complete fixture without inferred relationships', () {
    final actual = contract.userReputationLog('alice').decode(
          jsonDecode(fixture('v4/reputation_log.json')),
        );

    expect(actual.firstDay, '9999-99-99');
    expect(actual.days, hasLength(2));
    final first = actual.days.first;
    expect(first.day, '2026-02-30');
    expect([first.change, first.after, first.capped], [-3, 0, 5]);
    expect(first.items.map((item) => item.kind), [
      ProfileReputationLogKind.contribution,
      ProfileReputationLogKind.markedUnhelpful,
      ProfileReputationLogKind.contribution,
    ]);
    final item = first.items.first;
    expect(item.problem!.problemId, -1000);
    expect(item.problem!.level, 30);
    expect(item.problem!.userStatus, ProblemUserStatus.partial);
    expect(item.problem!.titles, hasLength(2));
    expect([item.count, item.points], [2, -1]);
    expect(first.items[1].problem, isNull);
    expect(first.others!.count, -1);
    expect(first.others!.points, 7);

    final last = actual.days.last;
    expect(last.day, '0000-00-00');
    expect(last.items, isEmpty);
    expect(last.others, isNull);
  });

  test('requires every field and preserves nullable states', () {
    final endpoint = contract.userReputationLog('alice');
    for (final invalid in <Object?>[null, 0, 'days', const <Object?>[]]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
    for (final field in ['days', 'firstDay']) {
      expect(
        () => endpoint.decode(_response()..remove(field)),
        throwsFormatException,
        reason: '$field missing',
      );
    }
    expect(endpoint.decode(_response()..['firstDay'] = null).firstDay, isNull);
    expect(
      () => endpoint.decode(_response()..['days'] = null),
      throwsFormatException,
    );

    for (final field in ['day', 'change', 'after', 'capped', 'items']) {
      for (final invalid in <Object?>[_missing, null]) {
        final body = _response();
        _mutate(_firstDay(body), field, invalid);
        expect(
          () => endpoint.decode(body),
          throwsFormatException,
          reason: 'days[].$field = $invalid',
        );
      }
    }
    final missingOthers = _response();
    _firstDay(missingOthers).remove('others');
    expect(() => endpoint.decode(missingOthers), throwsFormatException);

    for (final field in ['kind', 'problem', 'count', 'points']) {
      final body = _response();
      _firstItem(body).remove(field);
      expect(
        () => endpoint.decode(body),
        throwsFormatException,
        reason: 'items[].$field missing',
      );
    }
    for (final field in ['count', 'points']) {
      for (final invalid in <Object?>[_missing, null, 1.0]) {
        final body = _response();
        _mutate(
          _firstDay(body)['others'] as Map<String, dynamic>,
          field,
          invalid,
        );
        expect(
          () => endpoint.decode(body),
          throwsFormatException,
          reason: 'others.$field = $invalid',
        );
      }
    }
    final missingStatus = _response();
    (_firstItem(missingStatus)['problem'] as Map<String, dynamic>)
        .remove('userStatus');
    expect(() => endpoint.decode(missingStatus), throwsFormatException);
  });

  test('enforces strict types, day patterns, kinds, and problem bounds', () {
    final endpoint = contract.userReputationLog('alice');
    for (final field in ['change', 'after', 'capped']) {
      for (final invalid in <Object?>[1.0, '1', false]) {
        final body = _response();
        _firstDay(body)[field] = invalid;
        expect(() => endpoint.decode(body), throwsFormatException);
      }
    }
    for (final field in ['count', 'points']) {
      final body = _response();
      _firstItem(body)[field] = 1.5;
      expect(() => endpoint.decode(body), throwsFormatException);
    }
    for (final invalid in <Object?>['2026-1-01', '2026-01-01T00', '', 0]) {
      final day = _response();
      _firstDay(day)['day'] = invalid;
      expect(() => endpoint.decode(day), throwsFormatException);
      expect(
        () => endpoint.decode(_response()..['firstDay'] = invalid),
        throwsFormatException,
      );
    }
    for (final kind in ProfileReputationLogKind.values) {
      final body = _response();
      _firstItem(body)['kind'] = kind.value;
      expect(endpoint.decode(body).days.first.items.first.kind, kind);
    }
    for (final invalid in <Object?>['Contribution', 'marked_unhelpful', 0]) {
      final body = _response();
      _firstItem(body)['kind'] = invalid;
      expect(() => endpoint.decode(body), throwsFormatException);
    }
    for (final entry in <String, Object?>{
      'level': 31,
      'effectiveVoteCount': -1,
      'problemId': 1.0,
    }.entries) {
      final body = _response();
      (_firstItem(body)['problem'] as Map<String, dynamic>)[entry.key] =
          entry.value;
      expect(
        () => endpoint.decode(body),
        throwsFormatException,
        reason: entry.key,
      );
    }
  });

  test('eagerly snapshots ordered duplicate unmodifiable lists', () {
    final endpoint = contract.userReputationLog('alice');
    final body = _response();
    final days = body['days'] as List<dynamic>;
    final items = _firstDay(body)['items'] as List<dynamic>;
    final actual = endpoint.decode(body);
    _firstItem(body)['count'] = 99;
    items.clear();
    days.clear();

    expect(actual.days, hasLength(2));
    expect(actual.days.first.items, hasLength(3));
    expect(actual.days.first.items.first.count, 2);
    expect(() => actual.days.clear(), throwsUnsupportedError);
    expect(() => actual.days.first.items.clear(), throwsUnsupportedError);
    expect(
      endpoint.decode(<String, Object?>{
        'days': <Object?>[],
        'firstDay': null,
        'future': true,
      }).days,
      isEmpty,
    );
  });
}

const _missing = Object();

void _mutate(Map<String, dynamic> body, String field, Object? value) {
  if (identical(value, _missing)) {
    body.remove(field);
  } else {
    body[field] = value;
  }
}

Map<String, dynamic> _response() =>
    jsonDecode(fixture('v4/reputation_log.json')) as Map<String, dynamic>;

Map<String, dynamic> _firstDay(Map<String, dynamic> body) =>
    (body['days'] as List<dynamic>).first as Map<String, dynamic>;

Map<String, dynamic> _firstItem(Map<String, dynamic> body) =>
    (_firstDay(body)['items'] as List<dynamic>).first as Map<String, dynamic>;
