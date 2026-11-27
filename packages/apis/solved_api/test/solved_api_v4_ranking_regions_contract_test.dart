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

  test('builds the public ranking-regions endpoint without parameters', () {
    final endpoint = contract.rankingRegions();

    expect(endpoint.direct.path, 'rankings/regions');
    expect(endpoint.direct.queryParameters, isEmpty);
    expect(endpoint.proxy.path, endpoint.direct.path);
    expect(endpoint.proxy.queryParameters, isEmpty);
  });

  test('decodes the complete official ranking-regions fixture', () {
    final actual = contract.rankingRegions().decode(
          jsonDecode(fixture('v4/ranking_regions.json')),
        );

    expect(actual.regions.map((region) => region.countryCode), [
      'KR',
      '',
      'KR',
    ]);
    expect(actual.regions.map((region) => region.userCount), [0, -7, 100]);
  });

  test('requires the response object and regions array', () {
    final endpoint = contract.rankingRegions();
    for (final invalid in <Object?>[
      null,
      0,
      false,
      'regions',
      const <Object?>[],
      const <String, Object?>{},
      const <String, Object?>{'regions': null},
      const <String, Object?>{'regions': 1},
      const <String, Object?>{'regions': 'KR'},
      const <String, Object?>{'regions': <String, Object?>{}},
    ]) {
      expect(
        () => endpoint.decode(invalid),
        throwsFormatException,
        reason: '$invalid',
      );
    }
  });

  test('requires each complete region object and validates eagerly', () {
    final endpoint = contract.rankingRegions();
    for (final invalid in <Object?>[null, 0, false, 'KR', const <Object?>[]]) {
      expect(
        () => endpoint.decode(_envelope([_region(), invalid])),
        throwsFormatException,
        reason: '$invalid',
      );
    }
    for (final field in ['countryCode', 'userCount']) {
      expect(
        () => endpoint.decode(_envelope([_region()..remove(field)])),
        throwsFormatException,
        reason: '$field missing',
      );
      expect(
        () => endpoint.decode(_envelope([_region()..[field] = null])),
        throwsFormatException,
        reason: '$field null',
      );
    }
  });

  test('preserves raw country strings without format or length inference', () {
    final endpoint = contract.rankingRegions();
    final longCode = List<String>.filled(512, '🌏').join();
    for (final code in ['', 'K', 'kr', 'not-a-country', longCode]) {
      final actual = endpoint.decode(
        _envelope([_region()..['countryCode'] = code]),
      );
      expect(actual.regions.single.countryCode, code);
    }

    for (final invalid in <Object?>[
      0,
      false,
      const <Object?>[],
      const <String, Object?>{},
    ]) {
      expect(
        () =>
            endpoint.decode(_envelope([_region()..['countryCode'] = invalid])),
        throwsFormatException,
        reason: '$invalid',
      );
    }
  });

  test('accepts exact unbounded integers and rejects other scalar types', () {
    final endpoint = contract.rankingRegions();
    for (final count in [-1000000, 0, 1000000]) {
      final actual = endpoint.decode(
        _envelope([_region()..['userCount'] = count]),
      );
      expect(actual.regions.single.userCount, count);
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
        () => endpoint.decode(_envelope([_region()..['userCount'] = invalid])),
        throwsFormatException,
        reason: '$invalid',
      );
    }
  });

  test(
    'preserves empty order duplicates future fields and source isolation',
    () {
      final endpoint = contract.rankingRegions();
      final empty = endpoint.decode({
        'regions': <Object?>[],
        'futureEnvelope': true,
      });
      expect(empty.regions, isEmpty);
      expect(
        () => empty.regions.add(
          const RankingRegion(countryCode: 'KR', userCount: 1),
        ),
        throwsUnsupportedError,
      );

      final first = _region()
        ..['countryCode'] = 'KR'
        ..['userCount'] = -1
        ..['futureRegion'] = 'ignored';
      final second = _region()
        ..['countryCode'] = 'KR'
        ..['userCount'] = 99;
      final source = <Object?>[first, second];
      final actual = endpoint.decode(_envelope(source));
      source.clear();
      first
        ..['countryCode'] = 'US'
        ..['userCount'] = 1000;

      expect(actual.regions.map((region) => region.countryCode), ['KR', 'KR']);
      expect(actual.regions.map((region) => region.userCount), [-1, 99]);
      expect(() => actual.regions.clear(), throwsUnsupportedError);
    },
  );
}

Map<String, Object?> _envelope(List<Object?> regions) => <String, Object?>{
      'regions': regions,
    };

Map<String, Object?> _region() => <String, Object?>{
      'countryCode': 'KR',
      'userCount': 1,
    };
