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

  test('builds the contest detail path and rejects ids below one', () {
    for (final id in [1, 42, 9007199254740991]) {
      final endpoint = contract.sourceContestDetail(id);
      expect(endpoint.direct.path, 'sources/contests/$id');
      expect(endpoint.direct.queryParameters, isEmpty);
      expect(endpoint.proxy.path, endpoint.direct.path);
      expect(endpoint.proxy.queryParameters, isEmpty);
    }
    for (final id in [0, -1]) {
      expect(
        () => contract.sourceContestDetail(id),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'id')
              .having((error) => error.invalidValue, 'invalidValue', id),
        ),
      );
    }
  });

  test('decodes the complete fixture without inferred relationships', () {
    final actual = contract.sourceContestDetail(1).decode(
          jsonDecode(fixture('v4/source_contest_detail.json')),
        );

    final contest = actual.contest;
    expect(contest.id, 100);
    expect(contest.name, 'Round 1');
    expect(contest.abbreviation, isNull);
    expect(contest.startsAt, 'not a date');
    expect(contest.problemCount, 2.5);
    expect(contest.solvedCount, isNull);
    expect(contest.level!.order, SourceProblemOrder.mixed);
    expect(contest.level!.tierCounts, [2, 0]);
    expect(contest.url, 'not necessarily a URI');
    expect(contest.venue, '');

    expect(actual.path.map((entry) => entry.id), [1, 2.5]);
    expect(actual.links.single.ojName, 'Example Judge');
    expect(actual.query, isNull);

    expect(actual.problems.map((item) => item.numberInContest), [
      'A',
      '',
      'A',
    ]);
    expect(actual.problems.map((item) => item.problem.problemId), [
      1001,
      1002,
      1001,
    ]);
    expect(
        actual.problems.first.problem.titles?.first.title, 'English original');
    expect(actual.problems.first.problem.viewerFolders, isEmpty);
  });

  test('requires every outer and contest field', () {
    final endpoint = contract.sourceContestDetail(1);
    for (final invalid in <Object?>[null, 0, 'contest', const <Object?>[]]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
    for (final field in ['contest', 'path', 'links', 'query', 'problems']) {
      final body = _response();
      body.remove(field);
      expect(
        () => endpoint.decode(body),
        throwsFormatException,
        reason: '$field missing',
      );
      final nulled = _response()..[field] = null;
      if (field == 'query') {
        expect(endpoint.decode(nulled).query, isNull);
      } else {
        expect(
          () => endpoint.decode(nulled),
          throwsFormatException,
          reason: '$field null',
        );
      }
    }

    for (final field in _contestFields) {
      final missing = _response();
      (missing['contest'] as Map<String, dynamic>).remove(field);
      expect(
        () => endpoint.decode(missing),
        throwsFormatException,
        reason: 'contest.$field missing',
      );
      final nulled = _response();
      (nulled['contest'] as Map<String, dynamic>)[field] = null;
      if (_nullableContestFields.contains(field)) {
        final contest = endpoint.decode(nulled).contest;
        expect(_contestValue(contest, field), isNull, reason: field);
      } else {
        expect(
          () => endpoint.decode(nulled),
          throwsFormatException,
          reason: 'contest.$field null',
        );
      }
    }
    for (final field in ['url', 'venue', 'startsAt', 'name']) {
      final body = _response();
      (body['contest'] as Map<String, dynamic>)[field] = 0;
      expect(() => endpoint.decode(body), throwsFormatException);
    }
    for (final field in ['id', 'problemCount']) {
      final body = _response();
      (body['contest'] as Map<String, dynamic>)[field] = double.nan;
      expect(() => endpoint.decode(body), throwsFormatException);
    }
  });

  test('requires strict problem entries in the exact search-item shape', () {
    final endpoint = contract.sourceContestDetail(1);
    for (final field in ['numberInContest', 'problem']) {
      for (final invalid in <Object?>[_missing, null, 0]) {
        final body = _response();
        final item = _firstProblem(body);
        if (identical(invalid, _missing)) {
          item.remove(field);
        } else {
          item[field] = invalid;
        }
        expect(
          () => endpoint.decode(body),
          throwsFormatException,
          reason: '$field = $invalid',
        );
      }
    }
    for (final field in ['viewerFolders', 'userStatus', 'solvedUserCount']) {
      final body = _response();
      (_firstProblem(body)['problem'] as Map<String, dynamic>).remove(field);
      expect(
        () => endpoint.decode(body),
        throwsFormatException,
        reason: 'problem.$field missing',
      );
    }
    expect(
      () => endpoint.decode(_response()..['problems'] = [1]),
      throwsFormatException,
    );
  });

  test('eagerly snapshots ordered unmodifiable problems', () {
    final endpoint = contract.sourceContestDetail(1);
    final body = _response();
    final problems = body['problems'] as List<dynamic>;
    final first = problems.first as Map<String, dynamic>;
    problems.add(first);

    final actual = endpoint.decode(body);
    first['numberInContest'] = 'changed';
    problems.clear();

    expect(actual.problems.map((item) => item.numberInContest), [
      'A',
      '',
      'A',
      'A',
    ]);
    expect(() => actual.problems.clear(), throwsUnsupportedError);
    expect(
      endpoint
          .decode(_response()
            ..['problems'] = <Object?>[]
            ..['future'] = true)
          .problems,
      isEmpty,
    );
  });
}

const _missing = Object();

const _contestFields = [
  'id',
  'name',
  'abbreviation',
  'startsAt',
  'problemCount',
  'solvedCount',
  'level',
  'url',
  'venue',
];

const _nullableContestFields = {
  'abbreviation',
  'startsAt',
  'solvedCount',
  'level',
  'url',
  'venue',
};

Map<String, dynamic> _response() =>
    jsonDecode(fixture('v4/source_contest_detail.json'))
        as Map<String, dynamic>;

Map<String, dynamic> _firstProblem(Map<String, dynamic> body) =>
    (body['problems'] as List<dynamic>).first as Map<String, dynamic>;

Object? _contestValue(SourceContestDetail contest, String field) =>
    switch (field) {
      'abbreviation' => contest.abbreviation,
      'startsAt' => contest.startsAt,
      'solvedCount' => contest.solvedCount,
      'level' => contest.level,
      'url' => contest.url,
      _ => contest.venue,
    };
