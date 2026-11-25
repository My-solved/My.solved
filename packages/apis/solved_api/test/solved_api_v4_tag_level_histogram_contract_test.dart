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

  test('builds a safe public user-tag histogram endpoint', () {
    final endpoint = contract.userTagLevelHistogram('한 글', 'tag key');

    expect(
      endpoint.direct.path,
      'users/%ED%95%9C%20%EA%B8%80/tags/tag%20key/histogram',
    );
    expect(endpoint.direct.queryParameters, isEmpty);
    expect(endpoint.proxy.path, endpoint.direct.path);
    expect(endpoint.proxy.queryParameters, isEmpty);
    expect(
      contract.userTagLevelHistogram('한', 'x').direct.path,
      'users/%ED%95%9C/tags/x/histogram',
    );

    final boundary = List<String>.filled(64, '😀').join();
    expect(
      contract.userTagLevelHistogram(boundary, boundary).direct.path,
      startsWith('users/'),
    );
    for (final invalid in <String>[
      '',
      '.',
      '..',
      'a/b',
      r'a\b',
      'line\nbreak',
      List<String>.filled(65, '😀').join(),
    ]) {
      expect(
        () => contract.userTagLevelHistogram(invalid, 'tag'),
        throwsArgumentError,
        reason: 'handle = $invalid',
      );
      expect(
        () => contract.userTagLevelHistogram('handle', invalid),
        throwsArgumentError,
        reason: 'key = $invalid',
      );
    }
  });

  test('decodes the complete official histogram fixture without inference', () {
    final endpoint = contract.userTagLevelHistogram('index', 'requested_key');
    final actual = endpoint.decode(
      jsonDecode(fixture('v4/user_tag_level_histogram.json')),
    );

    expect(actual.key, 'response_key');
    expect(actual.histogram, [-3, 0, 0, 31, 7]);
    expect(actual.histogram, hasLength(5));
  });

  test('requires the response object, key, and histogram array', () {
    final endpoint = contract.userTagLevelHistogram('index', 'tag');
    for (final invalid in <Object?>[
      null,
      0,
      false,
      'histogram',
      const <Object?>[],
      const <String, Object?>{},
      const <String, Object?>{'key': 'tag'},
      const <String, Object?>{'histogram': <Object?>[]},
      const <String, Object?>{'key': null, 'histogram': <Object?>[]},
      const <String, Object?>{'key': 'tag', 'histogram': null},
      const <String, Object?>{'key': 1, 'histogram': <Object?>[]},
      const <String, Object?>{'key': 'tag', 'histogram': 'values'},
    ]) {
      expect(
        () => endpoint.decode(invalid),
        throwsFormatException,
        reason: '$invalid',
      );
    }
  });

  test('accepts every exact integer and rejects all other item types', () {
    final endpoint = contract.userTagLevelHistogram('index', 'tag');
    final actual = endpoint.decode({
      'key': 'raw',
      'histogram': <Object?>[-1000000, 0, 1000000],
    });
    expect(actual.histogram, [-1000000, 0, 1000000]);
    for (final value in <Object?>[
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
        () => endpoint.decode({
          'key': 'tag',
          'histogram': <Object?>[value],
        }),
        throwsFormatException,
        reason: '$value',
      );
    }
  });

  test('eagerly validates every histogram bucket', () {
    final endpoint = contract.userTagLevelHistogram('index', 'tag');
    expect(
      () => endpoint.decode({
        'key': 'tag',
        'histogram': <Object?>[1, 2, 3.0],
      }),
      throwsFormatException,
    );
  });

  test(
    'preserves empty, arbitrary length, duplicates, and immutable snapshots',
    () {
      final endpoint = contract.userTagLevelHistogram('index', 'tag');
      final emptySource = <Object?>[];
      final empty = endpoint.decode({
        'key': '',
        'histogram': emptySource,
        'futureEnvelope': true,
      });
      emptySource.add(1);
      expect(empty.key, '');
      expect(empty.histogram, isEmpty);
      expect(() => empty.histogram.add(1), throwsUnsupportedError);

      final source = <Object?>[-1, 7, 7, 2, 99, 0];
      final actual = endpoint.decode({
        'key': 'raw',
        'histogram': source,
        'futureEnvelope': <String, Object?>{'kept': false},
      });
      source
        ..clear()
        ..add(123);
      expect(actual.histogram, [-1, 7, 7, 2, 99, 0]);
      expect(() => actual.histogram.clear(), throwsUnsupportedError);
    },
  );
}
