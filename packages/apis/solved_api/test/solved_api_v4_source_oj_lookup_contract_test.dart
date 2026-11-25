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

  test('builds both encoded public OJ source lookup endpoints', () {
    final contest = contract.sourceContest('한 글', 'round & #1');
    final group = contract.sourceGroup('한 글', 'team & #1');

    expect(
      contest.direct.path,
      'sources/oj/%ED%95%9C%20%EA%B8%80/contests/round%20%26%20%231',
    );
    expect(
      group.direct.path,
      'sources/oj/%ED%95%9C%20%EA%B8%80/groups/team%20%26%20%231',
    );
    expect(contest.direct.queryParameters, isEmpty);
    expect(group.direct.queryParameters, isEmpty);
    expect(contest.proxy.path, contest.direct.path);
    expect(group.proxy.path, group.direct.path);
  });

  test('accepts exact path length boundaries without normalization', () {
    final ojId = List<String>.filled(32, '🌏').join();
    final nativeId = List<String>.filled(64, '한').join();
    final endpoint = contract.sourceContest(ojId, nativeId);

    expect(endpoint.direct.path, startsWith('sources/oj/'));
    expect(endpoint.direct.path, contains('/contests/'));
    expect(
      contract.sourceGroup(' ', '&').direct.path,
      'sources/oj/%20/groups/%26',
    );
  });

  test('rejects oversized and unsafe path segments before transport', () {
    final oversizedOjId = List<String>.filled(33, 'a').join();
    final oversizedNativeId = List<String>.filled(65, 'b').join();

    expect(
      () => contract.sourceContest(oversizedOjId, 'native'),
      throwsArgumentError,
    );
    expect(
      () => contract.sourceContest('boj', oversizedNativeId),
      throwsArgumentError,
    );
    for (final invalid in ['', '.', '..', 'a/b', r'a\b', 'a\u0000b']) {
      expect(
        () => contract.sourceContest(invalid, 'native'),
        throwsArgumentError,
        reason: 'ojId = $invalid',
      );
      expect(
        () => contract.sourceGroup('boj', invalid),
        throwsArgumentError,
        reason: 'nativeId = $invalid',
      );
    }
  });

  test('decodes the same official result shape for both lookups', () {
    final source = jsonDecode(fixture('v4/source_lookup.json'));
    final contest = contract.sourceContest('boj', 'contest').decode(source);
    final group = contract.sourceGroup('boj', 'group').decode(source);

    expect(contest.id, -42.5);
    expect(contest.id, isA<double>());
    expect(group.id, -42.5);
    expect(group.id, isA<double>());
  });

  test('requires the response object and id field', () {
    final endpoint = contract.sourceContest('boj', 'contest');
    for (final invalid in <Object?>[
      null,
      0,
      false,
      'source',
      const <Object?>[],
      const <String, Object?>{},
      const <String, Object?>{'id': null},
    ]) {
      expect(
        () => endpoint.decode(invalid),
        throwsFormatException,
        reason: '$invalid',
      );
    }
  });

  test('preserves every finite number and its runtime type without bounds', () {
    final endpoint = contract.sourceGroup('boj', 'group');
    for (final value in <num>[-42.5, -1, 0, 1.0, 1000000]) {
      final actual = endpoint.decode(<String, Object?>{'id': value});
      expect(actual.id, value);
      expect(actual.id.runtimeType, value.runtimeType);
    }
  });

  test(
    'rejects non-numbers and non-finite values but permits future fields',
    () {
      final endpoint = contract.sourceContest('boj', 'contest');
      for (final invalid in <Object?>[
        double.nan,
        double.infinity,
        double.negativeInfinity,
        '1',
        false,
        const <Object?>[],
        const <String, Object?>{},
      ]) {
        expect(
          () => endpoint.decode(<String, Object?>{'id': invalid}),
          throwsFormatException,
          reason: '$invalid',
        );
      }

      final actual = endpoint.decode(<String, Object?>{
        'id': 7,
        'future': <String, Object?>{'ignored': true},
      });
      expect(actual.id, 7);
    },
  );
}
