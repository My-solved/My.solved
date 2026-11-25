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
    'builds suggestion endpoints and preserves omitted and empty values',
    () {
      final omitted = contract.searchSuggestions('');
      final empty = contract.searchSuggestions('tag', value: '');
      final explicit = contract.searchSuggestions('태그 & tier', value: 'A B&한');

      expect(omitted.direct.path, 'search/suggest');
      expect(omitted.direct.queryParameters, {'topic': ''});
      expect(omitted.proxy.path, omitted.direct.path);
      expect(omitted.proxy.queryParameters, omitted.direct.queryParameters);
      expect(empty.direct.queryParameters, {'topic': 'tag', 'value': ''});
      expect(explicit.direct.queryParameters, {
        'topic': '태그 & tier',
        'value': 'A B&한',
      });
      expect(explicit.proxy.queryParameters, explicit.direct.queryParameters);
    },
  );

  test('validates Unicode code-point query limits without a minimum', () {
    final topic64 = List<String>.filled(64, '😀').join();
    final topic65 = '$topic64😀';
    final value100 = List<String>.filled(100, '🧩').join();
    final value101 = '$value100🧩';

    expect(
      contract
          .searchSuggestions(topic64, value: value100)
          .direct
          .queryParameters,
      {'topic': topic64, 'value': value100},
    );
    expect(contract.searchSuggestions('').direct.queryParameters, {
      'topic': '',
    });
    expect(
      () => contract.searchSuggestions(topic65),
      throwsA(
        isA<ArgumentError>()
            .having((error) => error.name, 'name', 'topic')
            .having((error) => error.invalidValue, 'invalidValue', topic65),
      ),
    );
    expect(
      () => contract.searchSuggestions('tag', value: value101),
      throwsA(
        isA<ArgumentError>()
            .having((error) => error.name, 'name', 'value')
            .having((error) => error.invalidValue, 'invalidValue', value101),
      ),
    );
  });

  test('decodes the complete official suggestion fixture', () {
    final actual = contract
        .searchSuggestions('lang')
        .decode(jsonDecode(fixture('v4/search_suggestions.json')));

    expect(actual.suggestions, hasLength(3));
    expect(actual.suggestions.map((item) => item.value), [
      'ko',
      'raw & empty-safe',
      'future',
    ]);
    expect(actual.suggestions.map((item) => item.detail), ['한국어', null, '']);
    expect(actual.suggestions.map((item) => item.tier), [12, null, -1]);
  });

  test('requires the response object and suggestions array', () {
    final endpoint = contract.searchSuggestions('tag');
    for (final invalid in <Object?>[
      null,
      0,
      false,
      'suggestions',
      const <Object?>[],
      const <String, Object?>{},
      const <String, Object?>{'suggestions': null},
      const <String, Object?>{'suggestions': 1},
      const <String, Object?>{'suggestions': 'item'},
      const <String, Object?>{'suggestions': <String, Object?>{}},
    ]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
  });

  test('requires every item field and distinguishes nullable values', () {
    final endpoint = contract.searchSuggestions('tag');
    for (final field in ['value', 'detail', 'tier']) {
      expect(
        () => endpoint.decode({
          'suggestions': <Object?>[_item()..remove(field)],
        }),
        throwsFormatException,
        reason: '$field missing',
      );
    }

    final nullable = endpoint
        .decode({
          'suggestions': <Object?>[
            _item()
              ..['value'] = ''
              ..['detail'] = null
              ..['tier'] = null,
          ],
        })
        .suggestions
        .single;
    expect(nullable.value, '');
    expect(nullable.detail, isNull);
    expect(nullable.tier, isNull);
  });

  test('validates item types and preserves unbounded exact integers', () {
    final endpoint = contract.searchSuggestions('tag');
    final invalidValues = <String, List<Object?>>{
      'value': [null, 1, false, const <Object?>[], const <String, Object?>{}],
      'detail': [1, false, const <Object?>[], const <String, Object?>{}],
      'tier': [
        1.0,
        -1.0,
        double.nan,
        double.infinity,
        double.negativeInfinity,
        '1',
        false,
        const <Object?>[],
        const <String, Object?>{},
      ],
    };
    for (final entry in invalidValues.entries) {
      for (final invalid in entry.value) {
        expect(
          () => endpoint.decode({
            'suggestions': <Object?>[_item()..[entry.key] = invalid],
          }),
          throwsFormatException,
          reason: '${entry.key} = $invalid',
        );
      }
    }

    final actual = endpoint.decode({
      'suggestions': <Object?>[
        _item()..['tier'] = -1000000,
        _item()..['tier'] = 0,
        _item()..['tier'] = 1000000,
      ],
    });
    expect(actual.suggestions.map((item) => item.tier), [-1000000, 0, 1000000]);
    for (final item in actual.suggestions) {
      expect(item.tier, isA<int>());
    }
  });

  test('eagerly validates every item in the wire array', () {
    final endpoint = contract.searchSuggestions('tag');
    expect(
      () => endpoint.decode({
        'suggestions': <Object?>[_item(), _item()..remove('tier')],
      }),
      throwsFormatException,
    );
    expect(
      () => endpoint.decode({
        'suggestions': <Object?>[_item(), null],
      }),
      throwsFormatException,
    );
  });

  test('preserves empty, order, duplicates, future fields, and isolation', () {
    final endpoint = contract.searchSuggestions('tag');
    final emptySource = <Object?>[];
    final empty = endpoint.decode({
      'suggestions': emptySource,
      'futureEnvelope': true,
    });
    emptySource.add(_item());
    expect(empty.suggestions, isEmpty);
    expect(
      () => empty.suggestions.add(
        const SearchSuggestionItem(value: '', detail: null, tier: null),
      ),
      throwsUnsupportedError,
    );

    final first = _item()
      ..['value'] = 'duplicate'
      ..['detail'] = 'first'
      ..['tier'] = -1
      ..['futureItem'] = true;
    final second = _item()
      ..['value'] = 'duplicate'
      ..['detail'] = 'second'
      ..['tier'] = 99;
    final source = <Object?>[first, second];
    final actual = endpoint.decode({'suggestions': source});
    source
      ..clear()
      ..add(_item()..['value'] = 'mutated');
    first['value'] = 'changed';
    second['detail'] = 'changed';

    expect(actual.suggestions.map((item) => item.value), [
      'duplicate',
      'duplicate',
    ]);
    expect(actual.suggestions.map((item) => item.detail), ['first', 'second']);
    expect(actual.suggestions.map((item) => item.tier), [-1, 99]);
    expect(() => actual.suggestions.clear(), throwsUnsupportedError);
  });
}

Map<String, Object?> _item() => <String, Object?>{
      'value': 'value',
      'detail': 'detail',
      'tier': 1,
    };
