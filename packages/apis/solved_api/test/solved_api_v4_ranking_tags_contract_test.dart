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

  test(
    'builds the public ranking-tags endpoint with raw optional language',
    () {
      final omitted = contract.rankingTags();
      final empty = contract.rankingTags(language: '');
      final raw = contract.rankingTags(language: '한 글 & raw');
      final longLanguage = List<String>.filled(512, '🌏').join();

      expect(omitted.direct.path, 'rankings/tags');
      expect(omitted.direct.queryParameters, isEmpty);
      expect(omitted.proxy.path, omitted.direct.path);
      expect(omitted.proxy.queryParameters, isEmpty);
      expect(empty.direct.queryParameters, {'lang': ''});
      expect(empty.proxy.queryParameters, {'lang': ''});
      expect(raw.direct.queryParameters, {'lang': '한 글 & raw'});
      expect(
        contract.rankingTags(language: longLanguage).direct.queryParameters,
        {'lang': longLanguage},
      );
    },
  );

  test('decodes the complete official ranking-tags fixture', () {
    final actual = contract.rankingTags().decode(
          jsonDecode(fixture('v4/ranking_tags.json')),
        );

    expect(actual.tags.map((tag) => tag.key), ['math', '', 'math']);
    expect(actual.tags.map((tag) => tag.ratingTagIndex), [0, -7, 42]);
    expect(actual.tags.map((tag) => tag.displayName), [
      '수학',
      '',
      'Mathematics',
    ]);
  });

  test('requires the response object and tags array', () {
    final endpoint = contract.rankingTags();
    for (final invalid in <Object?>[
      null,
      0,
      false,
      'tags',
      const <Object?>[],
      const <String, Object?>{},
      const <String, Object?>{'tags': null},
      const <String, Object?>{'tags': 1},
      const <String, Object?>{'tags': 'math'},
      const <String, Object?>{'tags': <String, Object?>{}},
    ]) {
      expect(
        () => endpoint.decode(invalid),
        throwsFormatException,
        reason: '$invalid',
      );
    }
  });

  test('requires each complete tag object and validates eagerly', () {
    final endpoint = contract.rankingTags();
    for (final invalid in <Object?>[
      null,
      0,
      false,
      'math',
      const <Object?>[],
    ]) {
      expect(
        () => endpoint.decode(_envelope([_tag(), invalid])),
        throwsFormatException,
        reason: '$invalid',
      );
    }
    for (final field in ['key', 'ratingTagIndex', 'displayName']) {
      expect(
        () => endpoint.decode(_envelope([_tag()..remove(field)])),
        throwsFormatException,
        reason: '$field missing',
      );
      expect(
        () => endpoint.decode(_envelope([_tag()..[field] = null])),
        throwsFormatException,
        reason: '$field null',
      );
    }
  });

  test('preserves raw tag strings without format or length inference', () {
    final endpoint = contract.rankingTags();
    final longValue = List<String>.filled(512, '🌏').join();
    for (final field in ['key', 'displayName']) {
      for (final value in ['', ' ', '한 글 & raw', longValue]) {
        final actual = endpoint.decode(_envelope([_tag()..[field] = value]));
        final tag = actual.tags.single;
        expect(field == 'key' ? tag.key : tag.displayName, value);
      }

      for (final invalid in <Object?>[
        0,
        false,
        const <Object?>[],
        const <String, Object?>{},
      ]) {
        expect(
          () => endpoint.decode(_envelope([_tag()..[field] = invalid])),
          throwsFormatException,
          reason: '$field = $invalid',
        );
      }
    }
  });

  test('accepts exact unbounded indices and rejects other scalar types', () {
    final endpoint = contract.rankingTags();
    for (final index in [-1000000, 0, 1000000]) {
      final actual = endpoint.decode(
        _envelope([_tag()..['ratingTagIndex'] = index]),
      );
      expect(actual.tags.single.ratingTagIndex, index);
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
        () =>
            endpoint.decode(_envelope([_tag()..['ratingTagIndex'] = invalid])),
        throwsFormatException,
        reason: '$invalid',
      );
    }
  });

  test(
    'preserves empty order duplicates future fields and source isolation',
    () {
      final endpoint = contract.rankingTags();
      final empty = endpoint.decode({
        'tags': <Object?>[],
        'futureEnvelope': true,
      });
      expect(empty.tags, isEmpty);
      expect(
        () => empty.tags.add(
          const RankingTag(key: 'math', ratingTagIndex: 0, displayName: 'Math'),
        ),
        throwsUnsupportedError,
      );

      final first = _tag()
        ..['key'] = 'math'
        ..['ratingTagIndex'] = -1
        ..['displayName'] = '수학'
        ..['futureTag'] = 'ignored';
      final second = _tag()
        ..['key'] = 'math'
        ..['ratingTagIndex'] = 99
        ..['displayName'] = 'Math';
      final source = <Object?>[first, second];
      final actual = endpoint.decode(_envelope(source));
      source.clear();
      first
        ..['key'] = 'changed'
        ..['ratingTagIndex'] = 1000
        ..['displayName'] = 'Changed';

      expect(actual.tags.map((tag) => tag.key), ['math', 'math']);
      expect(actual.tags.map((tag) => tag.ratingTagIndex), [-1, 99]);
      expect(actual.tags.map((tag) => tag.displayName), ['수학', 'Math']);
      expect(() => actual.tags.clear(), throwsUnsupportedError);
    },
  );
}

Map<String, Object?> _envelope(List<Object?> tags) => <String, Object?>{
      'tags': tags,
    };

Map<String, Object?> _tag() => <String, Object?>{
      'key': 'math',
      'ratingTagIndex': 1,
      'displayName': 'Math',
    };
