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

  test('builds the public site-stats endpoint without parameters', () {
    final endpoint = contract.siteStats();

    expect(endpoint.direct.path, 'site/stats');
    expect(endpoint.direct.queryParameters, isEmpty);
    expect(endpoint.proxy.path, endpoint.direct.path);
    expect(endpoint.proxy.queryParameters, isEmpty);
  });

  test('decodes the complete official site-stats fixture', () {
    final actual = contract.siteStats().decode(
          jsonDecode(fixture('v4/site_stats.json')),
        );

    expect(actual.problemsWithLevel, 120000);
    expect(actual.users, 0);
    expect(actual.contributors, -7);
    expect(actual.contributions, 345678);
    expect(actual.usersByTier, [-3, 0, 0, 31, 7]);
  });

  test('requires the response object and every documented field', () {
    final endpoint = contract.siteStats();
    for (final invalid in <Object?>[
      null,
      0,
      false,
      'stats',
      const <Object?>[],
    ]) {
      expect(
        () => endpoint.decode(invalid),
        throwsFormatException,
        reason: '$invalid',
      );
    }

    for (final field in _fields) {
      expect(
        () => endpoint.decode(_source()..remove(field)),
        throwsFormatException,
        reason: '$field missing',
      );
      expect(
        () => endpoint.decode(_source()..[field] = null),
        throwsFormatException,
        reason: '$field null',
      );
    }
  });

  test('accepts exact integers and rejects every other scalar type', () {
    final endpoint = contract.siteStats();
    const scalarFields = [
      'problemsWithLevel',
      'users',
      'contributors',
      'contributions',
    ];
    const values = <int>[-1000000, 0, 1000000];
    for (final field in scalarFields) {
      for (final value in values) {
        expect(
          () => endpoint.decode(_source()..[field] = value),
          returnsNormally,
          reason: '$field = $value',
        );
      }
      for (final invalid in <Object?>[
        1.0,
        -1.0,
        double.nan,
        double.infinity,
        double.negativeInfinity,
        '1',
        false,
        const <Object?>[],
        const <String, Object?>{},
      ]) {
        expect(
          () => endpoint.decode(_source()..[field] = invalid),
          throwsFormatException,
          reason: '$field = $invalid',
        );
      }
    }
  });

  test('requires an integer array and eagerly validates every item', () {
    final endpoint = contract.siteStats();
    for (final invalid in <Object?>[
      0,
      false,
      'tiers',
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(_source()..['usersByTier'] = invalid),
        throwsFormatException,
        reason: '$invalid',
      );
    }
    for (final invalid in <Object?>[
      null,
      1.0,
      -1.0,
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
          _source()..['usersByTier'] = <Object?>[1, 2, invalid],
        ),
        throwsFormatException,
        reason: '$invalid',
      );
    }
  });

  test(
    'preserves empty arbitrary lists, duplicates, unknown fields, and isolation',
    () {
      final endpoint = contract.siteStats();
      final emptySource = <Object?>[];
      final empty = endpoint.decode(
        _source()
          ..['usersByTier'] = emptySource
          ..['futureEnvelope'] = <String, Object?>{'ignored': true},
      );
      emptySource.add(1);
      expect(empty.usersByTier, isEmpty);
      expect(() => empty.usersByTier.add(1), throwsUnsupportedError);

      final source = <Object?>[-1, 7, 7, 2, 99, 0];
      final actual = endpoint.decode(_source()..['usersByTier'] = source);
      source
        ..clear()
        ..add(123);
      expect(actual.usersByTier, [-1, 7, 7, 2, 99, 0]);
      expect(() => actual.usersByTier.clear(), throwsUnsupportedError);
    },
  );
}

const _fields = [
  'problemsWithLevel',
  'users',
  'contributors',
  'contributions',
  'usersByTier',
];

Map<String, Object?> _source() => <String, Object?>{
      'problemsWithLevel': 1,
      'users': 2,
      'contributors': 3,
      'contributions': 4,
      'usersByTier': <Object?>[5],
    };
