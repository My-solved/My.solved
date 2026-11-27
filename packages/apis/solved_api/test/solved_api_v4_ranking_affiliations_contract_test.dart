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

  test('builds ranking affiliations with exact optional query semantics', () {
    final omitted = contract.rankingAffiliations();
    final empty = contract.rankingAffiliations(query: '', language: '');
    final raw = contract.rankingAffiliations(
      query: ' / 한 글 & raw ',
      language: '한 글 & raw',
    );
    final query64 = List<String>.filled(64, '🌏').join();
    final language16 = List<String>.filled(16, '🌏').join();

    expect(omitted.direct.path, 'rankings/affiliations');
    expect(omitted.direct.queryParameters, isEmpty);
    expect(omitted.proxy.path, omitted.direct.path);
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(empty.direct.queryParameters, {'q': '', 'lang': ''});
    expect(empty.proxy.queryParameters, empty.direct.queryParameters);
    expect(raw.direct.queryParameters, {
      'q': ' / 한 글 & raw ',
      'lang': '한 글 & raw',
    });
    expect(raw.proxy.queryParameters, raw.direct.queryParameters);
    expect(
      contract
          .rankingAffiliations(query: query64, language: language16)
          .direct
          .queryParameters,
      {'q': query64, 'lang': language16},
    );

    final query65 = List<String>.filled(65, '🌏').join();
    expect(
      () => contract.rankingAffiliations(query: query65),
      throwsA(
        isA<ArgumentError>()
            .having((error) => error.name, 'name', 'query')
            .having((error) => error.invalidValue, 'invalidValue', query65),
      ),
    );
    final language17 = List<String>.filled(17, '🌏').join();
    expect(
      () => contract.rankingAffiliations(language: language17),
      throwsA(
        isA<ArgumentError>()
            .having((error) => error.name, 'name', 'language')
            .having((error) => error.invalidValue, 'invalidValue', language17),
      ),
    );
  });

  test('decodes the complete official ranking-affiliations fixture', () {
    final actual = contract.rankingAffiliations().decode(
          jsonDecode(fixture('v4/ranking_affiliations.json')),
        );

    expect(actual.affiliations, hasLength(3));
    expect(actual.affiliations.map((item) => item.id), [-1, 42, -1]);
    expect(actual.affiliations.map((item) => item.affiliationId), [0, -9, 0]);
    expect(actual.affiliations.map((item) => item.name), [
      '',
      '한 글 & raw',
      'duplicate',
    ]);
    expect(actual.affiliations.map((item) => item.type.value), [
      'undefined',
      'university',
      'community',
    ]);
    expect(actual.affiliations.map((item) => item.userCount), [-7, 0, 100]);
    expect(actual.affiliations.map((item) => item.logoThumbnailUrl), [
      'not necessarily a URI',
      null,
      '',
    ]);
    expect(actual.affiliations.map((item) => item.color), [
      null,
      '',
      'not necessarily a color',
    ]);
  });

  test('requires the response object and affiliations array', () {
    final endpoint = contract.rankingAffiliations();
    for (final invalid in <Object?>[
      null,
      0,
      false,
      'affiliations',
      const <Object?>[],
      const <String, Object?>{},
      const <String, Object?>{'affiliations': null},
      const <String, Object?>{'affiliations': 1},
      const <String, Object?>{'affiliations': 'school'},
      const <String, Object?>{'affiliations': <String, Object?>{}},
    ]) {
      expect(
        () => endpoint.decode(invalid),
        throwsFormatException,
        reason: '$invalid',
      );
    }
  });

  test('requires every item field and validates all items eagerly', () {
    final endpoint = contract.rankingAffiliations();
    for (final invalid in <Object?>[
      null,
      0,
      false,
      'affiliation',
      const <Object?>[],
    ]) {
      expect(
        () => endpoint.decode(_envelope([_affiliation(), invalid])),
        throwsFormatException,
        reason: '$invalid',
      );
    }

    for (final field in _itemFields) {
      expect(
        () => endpoint.decode(
          _envelope([_affiliation()..remove(field)]),
        ),
        throwsFormatException,
        reason: '$field missing',
      );
      if (!_nullableItemFields.contains(field)) {
        expect(
          () => endpoint.decode(
            _envelope([_affiliation()..[field] = null]),
          ),
          throwsFormatException,
          reason: '$field null',
        );
      }
    }
  });

  test('preserves required nullable image and color strings', () {
    final endpoint = contract.rankingAffiliations();
    final longValue = List<String>.filled(512, '🌏').join();
    for (final field in ['logoThumbnailUrl', 'color']) {
      for (final value in <String?>[
        null,
        '',
        ' ',
        '한 글 & raw',
        longValue,
      ]) {
        final item = endpoint
            .decode(_envelope([_affiliation()..[field] = value]))
            .affiliations
            .single;
        expect(
          field == 'logoThumbnailUrl' ? item.logoThumbnailUrl : item.color,
          value,
        );
      }
      for (final invalid in <Object?>[
        0,
        false,
        const <Object?>[],
        const <String, Object?>{},
      ]) {
        expect(
          () => endpoint.decode(
            _envelope([_affiliation()..[field] = invalid]),
          ),
          throwsFormatException,
          reason: '$field = $invalid',
        );
      }
    }
  });

  test('preserves raw names and exact unbounded integers', () {
    final endpoint = contract.rankingAffiliations();
    final longName = List<String>.filled(512, '🌏').join();
    for (final name in ['', ' ', '한 글 & raw', longName]) {
      final actual = endpoint.decode(
        _envelope([_affiliation()..['name'] = name]),
      );
      expect(actual.affiliations.single.name, name);
    }
    for (final invalid in <Object?>[
      0,
      false,
      const <Object?>[],
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(
          _envelope([_affiliation()..['name'] = invalid]),
        ),
        throwsFormatException,
      );
    }

    for (final field in ['id', 'affiliationId', 'userCount']) {
      for (final value in [-1000000, 0, 1000000]) {
        final item = endpoint
            .decode(_envelope([_affiliation()..[field] = value]))
            .affiliations
            .single;
        expect(
          switch (field) {
            'id' => item.id,
            'affiliationId' => item.affiliationId,
            _ => item.userCount,
          },
          value,
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
          () => endpoint.decode(
            _envelope([_affiliation()..[field] = invalid]),
          ),
          throwsFormatException,
          reason: '$field = $invalid',
        );
      }
    }
  });

  test('accepts exactly the shared official affiliation type vocabulary', () {
    final endpoint = contract.rankingAffiliations();
    const types = [
      'undefined',
      'university',
      'high_school',
      'middle_school',
      'elementary_school',
      'company',
      'community',
    ];
    expect(
      OfficialUserProfileAffiliationType.values.map((type) => type.value),
      types,
    );
    for (final type in types) {
      final item = endpoint
          .decode(_envelope([_affiliation()..['type'] = type]))
          .affiliations
          .single;
      expect(item.type.value, type);
    }
    for (final invalid in <Object?>[
      'future',
      '',
      null,
      0,
      false,
      const <Object?>[],
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(
          _envelope([_affiliation()..['type'] = invalid]),
        ),
        throwsFormatException,
        reason: '$invalid',
      );
    }
  });

  test(
    'preserves empty order duplicates future fields and source isolation',
    () {
      final endpoint = contract.rankingAffiliations();
      final emptySource = <Object?>[];
      final empty = endpoint.decode({
        'affiliations': emptySource,
        'futureEnvelope': true,
      });
      emptySource.add(_affiliation());
      expect(empty.affiliations, isEmpty);
      expect(
        () => empty.affiliations.add(
          const RankingAffiliationItem(
            id: 1,
            affiliationId: 2,
            name: 'School',
            type: OfficialUserProfileAffiliationType.university,
            userCount: 3,
            logoThumbnailUrl: null,
            color: null,
          ),
        ),
        throwsUnsupportedError,
      );

      final first = _affiliation()
        ..['id'] = -1
        ..['name'] = 'duplicate'
        ..['futureItem'] = true;
      final second = _affiliation()
        ..['id'] = 99
        ..['name'] = 'duplicate';
      final source = <Object?>[first, second];
      final actual = endpoint.decode(_envelope(source));
      source.clear();
      first
        ..['id'] = 1000
        ..['name'] = 'changed'
        ..['logoThumbnailUrl'] = 'changed';

      expect(actual.affiliations.map((item) => item.id), [-1, 99]);
      expect(actual.affiliations.map((item) => item.name), [
        'duplicate',
        'duplicate',
      ]);
      expect(
        actual.affiliations.map((item) => item.logoThumbnailUrl),
        ['logo', 'logo'],
      );
      expect(() => actual.affiliations.clear(), throwsUnsupportedError);
    },
  );
}

const _itemFields = [
  'id',
  'affiliationId',
  'name',
  'type',
  'userCount',
  'logoThumbnailUrl',
  'color',
];

const _nullableItemFields = {'logoThumbnailUrl', 'color'};

Map<String, Object?> _envelope(List<Object?> affiliations) => <String, Object?>{
      'affiliations': affiliations,
    };

Map<String, Object?> _affiliation() => <String, Object?>{
      'id': 1,
      'affiliationId': 2,
      'name': 'School',
      'type': 'university',
      'userCount': 3,
      'logoThumbnailUrl': 'logo',
      'color': 'color',
    };
