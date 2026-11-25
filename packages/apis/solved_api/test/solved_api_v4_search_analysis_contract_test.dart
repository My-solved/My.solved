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

  test('builds analysis endpoints with omitted, empty, and raw queries', () {
    final omitted = contract.analyzeProblemSearch();
    final empty = contract.analyzeProblemSearch(query: '');
    final explicit = contract.analyzeProblemSearch(query: '태그 & tier');

    expect(omitted.direct.path, 'search/analyze');
    expect(omitted.direct.queryParameters, isEmpty);
    expect(omitted.proxy.path, omitted.direct.path);
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(empty.direct.queryParameters, {'q': ''});
    expect(explicit.direct.queryParameters, {'q': '태그 & tier'});
    expect(explicit.proxy.queryParameters, explicit.direct.queryParameters);
  });

  test('validates the Unicode code-point query limit without a minimum', () {
    final query1000 = List<String>.filled(1000, '😀').join();
    final query1001 = '$query1000😀';

    expect(
      contract.analyzeProblemSearch(query: query1000).direct.queryParameters,
      {'q': query1000},
    );
    expect(contract.analyzeProblemSearch(query: '').direct.queryParameters, {
      'q': '',
    });
    expect(
      () => contract.analyzeProblemSearch(query: query1001),
      throwsA(
        isA<ArgumentError>()
            .having((error) => error.name, 'name', 'query')
            .having((error) => error.invalidValue, 'invalidValue', query1001),
      ),
    );
  });

  test('decodes the complete official search-analysis fixture', () {
    final actual = contract.analyzeProblemSearch().decode(
          jsonDecode(fixture('v4/search_analysis.json')),
        );

    expect(actual.diagnostics, hasLength(3));
    expect(actual.diagnostics.first.start, -1.5);
    expect(actual.diagnostics.first.start, isA<double>());
    expect(actual.diagnostics.first.end, 2);
    expect(actual.diagnostics.first.end, isA<int>());
    expect(
      actual.diagnostics.first.severity,
      ProblemSearchDiagnosticSeverity.error,
    );
    expect(
      actual.diagnostics.first.code,
      ProblemSearchDiagnosticCode.unknownFilter,
    );
    expect(actual.diagnostics.first.data, {'filter': 'raw', 'empty': ''});
    expect(actual.diagnostics[1].start, 4);
    expect(actual.diagnostics[1].start, isA<int>());
    expect(actual.diagnostics[1].end, 4.0);
    expect(actual.diagnostics[1].end, isA<double>());
    expect(actual.diagnostics[1].data, isNull);
    expect(actual.diagnostics.last.data, isEmpty);
  });

  test('requires the response object and diagnostics array', () {
    final endpoint = contract.analyzeProblemSearch();
    for (final invalid in <Object?>[
      null,
      0,
      false,
      'diagnostics',
      const <Object?>[],
      const <String, Object?>{},
      const <String, Object?>{'diagnostics': null},
      const <String, Object?>{'diagnostics': 1},
      const <String, Object?>{'diagnostics': 'item'},
      const <String, Object?>{'diagnostics': <String, Object?>{}},
    ]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
  });

  test(
    'requires every diagnostic field and preserves optional data states',
    () {
      final endpoint = contract.analyzeProblemSearch();
      for (final field in [
        'start',
        'end',
        'severity',
        'code',
        'messageKey',
        'message',
      ]) {
        expect(
          () => endpoint.decode({
            'diagnostics': <Object?>[_diagnostic()..remove(field)],
          }),
          throwsFormatException,
          reason: '$field missing',
        );
      }

      final absent = endpoint.decode({
        'diagnostics': <Object?>[_diagnostic()],
      });
      final empty = endpoint.decode({
        'diagnostics': <Object?>[_diagnostic()..['data'] = <String, Object?>{}],
      });
      expect(absent.diagnostics.single.data, isNull);
      expect(empty.diagnostics.single.data, isEmpty);
      expect(
        () => empty.diagnostics.single.data!['key'] = 'value',
        throwsUnsupportedError,
      );
    },
  );

  test('preserves all severity and diagnostic code values', () {
    final endpoint = contract.analyzeProblemSearch();
    for (final severity in ProblemSearchDiagnosticSeverity.values) {
      final actual = endpoint.decode({
        'diagnostics': <Object?>[_diagnostic()..['severity'] = severity.value],
      });
      expect(actual.diagnostics.single.severity, severity);
    }
    for (final code in ProblemSearchDiagnosticCode.values) {
      final actual = endpoint.decode({
        'diagnostics': <Object?>[_diagnostic()..['code'] = code.value],
      });
      expect(actual.diagnostics.single.code, code);
    }
    for (final field in ['severity', 'code']) {
      for (final invalid in <Object?>[
        null,
        'future',
        1,
        false,
        const <Object?>[],
      ]) {
        expect(
          () => endpoint.decode({
            'diagnostics': <Object?>[_diagnostic()..[field] = invalid],
          }),
          throwsFormatException,
        );
      }
    }
  });

  test('preserves finite raw positions without bounds or relations', () {
    final endpoint = contract.analyzeProblemSearch();
    final actual = endpoint.decode({
      'diagnostics': <Object?>[
        _diagnostic()
          ..['start'] = -2
          ..['end'] = -3.0,
        _diagnostic()
          ..['start'] = 4.0
          ..['end'] = 1,
      ],
    });
    expect(actual.diagnostics.first.start, -2);
    expect(actual.diagnostics.first.start, isA<int>());
    expect(actual.diagnostics.first.end, -3.0);
    expect(actual.diagnostics.first.end, isA<double>());
    expect(actual.diagnostics.last.start, 4.0);
    expect(actual.diagnostics.last.start, isA<double>());
    expect(actual.diagnostics.last.end, 1);
    expect(actual.diagnostics.last.end, isA<int>());

    for (final field in ['start', 'end']) {
      for (final invalid in <Object?>[
        null,
        '1',
        false,
        const <Object?>[],
        const <String, Object?>{},
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => endpoint.decode({
            'diagnostics': <Object?>[_diagnostic()..[field] = invalid],
          }),
          throwsFormatException,
        );
      }
    }
  });

  test('validates raw strings and optional data values', () {
    final endpoint = contract.analyzeProblemSearch();
    for (final field in ['messageKey', 'message']) {
      for (final invalid in <Object?>[
        null,
        1,
        false,
        const <Object?>[],
        const <String, Object?>{},
      ]) {
        expect(
          () => endpoint.decode({
            'diagnostics': <Object?>[_diagnostic()..[field] = invalid],
          }),
          throwsFormatException,
        );
      }
    }
    for (final invalid in <Object?>[
      null,
      1,
      false,
      'data',
      const <Object?>[],
      const <String, Object?>{'key': 1},
    ]) {
      expect(
        () => endpoint.decode({
          'diagnostics': <Object?>[_diagnostic()..['data'] = invalid],
        }),
        throwsFormatException,
      );
    }
  });

  test('eagerly validates every diagnostic item', () {
    final endpoint = contract.analyzeProblemSearch();
    expect(
      () => endpoint.decode({
        'diagnostics': <Object?>[
          _diagnostic(),
          _diagnostic()..remove('message'),
        ],
      }),
      throwsFormatException,
    );
    expect(
      () => endpoint.decode({
        'diagnostics': <Object?>[_diagnostic(), null],
      }),
      throwsFormatException,
    );
  });

  test('preserves empty, order, duplicates, future fields, and isolation', () {
    final endpoint = contract.analyzeProblemSearch();
    final emptySource = <Object?>[];
    final empty = endpoint.decode({
      'diagnostics': emptySource,
      'futureEnvelope': true,
    });
    emptySource.add(_diagnostic());
    expect(empty.diagnostics, isEmpty);
    expect(
      () => empty.diagnostics.add(_modelDiagnostic()),
      throwsUnsupportedError,
    );

    final first = _diagnostic()..['data'] = <String, Object?>{'raw': 'first'};
    final second = _diagnostic()..['data'] = <String, Object?>{'raw': 'second'};
    final duplicate = _diagnostic()
      ..['data'] = <String, Object?>{'raw': 'second'};
    final source = <Object?>[first, second, duplicate];
    final actual = endpoint.decode({
      'diagnostics': source,
      'futureEnvelope': true,
    });
    source
      ..clear()
      ..add(_diagnostic());
    (first['data'] as Map<String, Object?>)['raw'] = 'changed';
    second['message'] = 'changed';

    expect(actual.diagnostics, hasLength(3));
    expect(actual.diagnostics.map((item) => item.message), [
      'message',
      'message',
      'message',
    ]);
    expect(actual.diagnostics.map((item) => item.data?['raw']), [
      'first',
      'second',
      'second',
    ]);
    expect(() => actual.diagnostics.clear(), throwsUnsupportedError);
  });
}

Map<String, Object?> _diagnostic() => <String, Object?>{
      'start': 0,
      'end': 1,
      'severity': 'error',
      'code': 'unknown-filter',
      'messageKey': 'key',
      'message': 'message',
    };

ProblemSearchDiagnostic _modelDiagnostic() => const ProblemSearchDiagnostic(
      start: 0,
      end: 0,
      severity: ProblemSearchDiagnosticSeverity.error,
      code: ProblemSearchDiagnosticCode.unknownFilter,
      messageKey: '',
      message: '',
      data: null,
    );
