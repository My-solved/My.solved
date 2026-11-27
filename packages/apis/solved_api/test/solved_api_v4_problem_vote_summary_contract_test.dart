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

  test('builds the vote summary with an omitted or raw sub', () {
    final omitted = contract.problemVoteSummary(1000);
    final explicit = contract.problemVoteSummary(1, sub: '');

    expect(omitted.direct.path, 'problems/1000/votes/summary');
    expect(omitted.direct.queryParameters, isEmpty);
    expect(omitted.proxy.path, omitted.direct.path);
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(explicit.direct.queryParameters, {'sub': ''});
    expect(explicit.proxy.queryParameters, {'sub': ''});
    for (final id in [0, -1]) {
      expect(
        () => contract.problemVoteSummary(id),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'problemId'),
        ),
      );
    }
  });

  test('decodes the complete fixture without inferred relationships', () {
    final actual = contract.problemVoteSummary(1).decode(
          jsonDecode(fixture('v4/problem_vote_summary.json')),
        );

    expect(actual.items, hasLength(2));
    final first = actual.items.first;
    expect(first.votedAt, 'not a date');
    expect(first.level, 12.5);
    expect(first.weight, -1);
    expect(
      [first.invalidated, first.notInCalculation, first.banned, first.cutoff],
      [true, false, true, false],
    );
    expect(actual.items.last.level, isNull);
    expect(actual.items.last.votedAt, '');

    expect(actual.tagDistribution, hasLength(2));
    expect(actual.tagDistribution.first.tag.key, 'math');
    expect(actual.tagDistribution.first.count, 2.5);
    expect(actual.tagDistribution.first.denominator, 0);
    expect(actual.tagDistribution.last.tag.id, 1.5);
    expect(actual.tagDistribution.last.tag.isMeta, isTrue);
    expect(actual.tagDistribution.last.count, -1);
  });

  test('requires every field and preserves the nullable level', () {
    final endpoint = contract.problemVoteSummary(1);
    for (final invalid in <Object?>[null, 0, 'items', const <Object?>[]]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
    for (final field in ['items', 'tagDistribution']) {
      expect(
        () => endpoint.decode(_response()..remove(field)),
        throwsFormatException,
      );
      expect(
        () => endpoint.decode(_response()..[field] = null),
        throwsFormatException,
      );
    }
    for (final field in _pointFields) {
      final missing = _response();
      _first(missing, 'items').remove(field);
      expect(
        () => endpoint.decode(missing),
        throwsFormatException,
        reason: '$field missing',
      );
      final nulled = _response();
      _first(nulled, 'items')[field] = null;
      if (field == 'level') {
        expect(endpoint.decode(nulled).items.first.level, isNull);
      } else {
        expect(
          () => endpoint.decode(nulled),
          throwsFormatException,
          reason: '$field null',
        );
      }
    }
    for (final field in ['tag', 'count', 'denominator']) {
      for (final mutate in <void Function(Map<String, dynamic>)>[
        (share) => share.remove(field),
        (share) => share[field] = null,
      ]) {
        final body = _response();
        mutate(_first(body, 'tagDistribution'));
        expect(() => endpoint.decode(body), throwsFormatException);
      }
    }
    final tag = _response();
    (_first(tag, 'tagDistribution')['tag'] as Map<String, dynamic>)
        .remove('isMeta');
    expect(() => endpoint.decode(tag), throwsFormatException);
  });

  test('enforces finite numbers, strict booleans, and strings', () {
    final endpoint = contract.problemVoteSummary(1);
    for (final entry in <String, Object?>{
      'level': double.nan,
      'weight': '1',
      'banned': 1,
      'votedAt': 0,
    }.entries) {
      final body = _response();
      _first(body, 'items')[entry.key] = entry.value;
      expect(
        () => endpoint.decode(body),
        throwsFormatException,
        reason: entry.key,
      );
    }
    for (final field in ['count', 'denominator']) {
      final body = _response();
      _first(body, 'tagDistribution')[field] = double.infinity;
      expect(() => endpoint.decode(body), throwsFormatException);
    }
  });

  test('eagerly snapshots ordered unmodifiable lists', () {
    final endpoint = contract.problemVoteSummary(1);
    final body = _response();
    final items = body['items'] as List<dynamic>;
    final shares = body['tagDistribution'] as List<dynamic>;
    final actual = endpoint.decode(body);
    items.clear();
    shares.clear();

    expect(actual.items, hasLength(2));
    expect(actual.tagDistribution, hasLength(2));
    expect(() => actual.items.clear(), throwsUnsupportedError);
    expect(() => actual.tagDistribution.clear(), throwsUnsupportedError);
    final empty = endpoint.decode(<String, Object?>{
      'items': <Object?>[],
      'tagDistribution': <Object?>[],
      'future': true,
    });
    expect(empty.items, isEmpty);
    expect(empty.tagDistribution, isEmpty);
  });
}

const _pointFields = [
  'votedAt',
  'level',
  'weight',
  'invalidated',
  'notInCalculation',
  'banned',
  'cutoff',
];

Map<String, dynamic> _response() =>
    jsonDecode(fixture('v4/problem_vote_summary.json')) as Map<String, dynamic>;

Map<String, dynamic> _first(Map<String, dynamic> body, String field) =>
    (body[field] as List<dynamic>).first as Map<String, dynamic>;
