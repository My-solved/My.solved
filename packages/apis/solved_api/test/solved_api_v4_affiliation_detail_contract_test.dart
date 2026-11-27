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

  test('builds affiliation detail with exact request boundaries', () {
    final omitted = contract.affiliationDetail(1);
    final empty = contract.affiliationDetail(999999, language: '');
    final raw = contract.affiliationDetail(1, language: ' / 한 글 & raw ');
    final language16 = List<String>.filled(16, '🌏').join();

    expect(omitted.direct.path, 'affiliations/1');
    expect(omitted.direct.queryParameters, isEmpty);
    expect(omitted.proxy.path, omitted.direct.path);
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(empty.direct.path, 'affiliations/999999');
    expect(empty.direct.queryParameters, {'lang': ''});
    expect(empty.proxy.queryParameters, empty.direct.queryParameters);
    expect(raw.direct.queryParameters, {'lang': ' / 한 글 & raw '});
    expect(raw.proxy.queryParameters, raw.direct.queryParameters);
    expect(
      contract
          .affiliationDetail(1, language: language16)
          .direct
          .queryParameters,
      {'lang': language16},
    );

    for (final id in [0, -1]) {
      expect(
        () => contract.affiliationDetail(id),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'id')
              .having((error) => error.invalidValue, 'invalidValue', id),
        ),
      );
    }
    final language17 = List<String>.filled(17, '🌏').join();
    expect(
      () => contract.affiliationDetail(1, language: language17),
      throwsA(
        isA<ArgumentError>()
            .having((error) => error.name, 'name', 'language')
            .having((error) => error.invalidValue, 'invalidValue', language17),
      ),
    );
  });

  test('decodes the complete fixture without inferring relationships', () {
    final actual = contract.affiliationDetail(1).decode(
          jsonDecode(fixture('v4/affiliation_detail.json')),
        );

    expect(actual.id, -1.5);
    expect(actual.id, isA<double>());
    expect(actual.affiliationId, 999);
    expect(actual.name, '');
    expect(actual.type, OfficialUserProfileAffiliationType.company);
    expect(actual.countryCode, isNull);
    expect(actual.logoImageUrl, 'not necessarily a URI');
    expect(actual.logoThumbnailUrl, '');
    expect(actual.color, 'not necessarily a color');
    expect(actual.website, isNull);
    expect(actual.rating, -10);
    expect(actual.userCount, 0);
    expect(actual.solvedCount, -7);
    expect(actual.voteCount, 42);
    expect(actual.displayName, 'unrelated display name');
    expect(actual.rank, -3);
    expect(actual.rankedOf, 0);
    expect(actual.typeRank, 100);
    expect(actual.typeRankedOf, -4);
    expect(actual.tierCounts, [-1, 0, -1]);
    expect(actual.ratingByProblemsSum, -20);
    expect(actual.ratingByClass, 0);
    expect(actual.ratingBySolvedCount, 21);
    expect(actual.ratingProblemsHistogram, [2, -3, 2]);
    expect(actual.ratingClass, -5);
    expect(actual.ratingClassPlus, isTrue);
  });

  test('requires the complete 25-field response object', () {
    final endpoint = contract.affiliationDetail(1);
    for (final invalid in <Object?>[
      null,
      0,
      false,
      'affiliation',
      const <Object?>[],
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(invalid),
        throwsFormatException,
        reason: '$invalid',
      );
    }

    for (final field in _fields) {
      expect(
        () => endpoint.decode(_detail()..remove(field)),
        throwsFormatException,
        reason: '$field missing',
      );
      if (!_nullableStringFields.contains(field)) {
        expect(
          () => endpoint.decode(_detail()..[field] = null),
          throwsFormatException,
          reason: '$field null',
        );
      }
    }
  });

  test('preserves every finite raw id number and rejects other values', () {
    final endpoint = contract.affiliationDetail(1);
    for (final value in <num>[-1000000, 0, 1000000, -1.5, 0.0, 2.0]) {
      final actual = endpoint.decode(_detail()..['id'] = value);
      expect(actual.id, value);
      expect(actual.id.runtimeType, value.runtimeType);
    }
    for (final invalid in <Object?>[
      null,
      double.nan,
      double.infinity,
      double.negativeInfinity,
      '1',
      false,
      const <Object?>[],
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(_detail()..['id'] = invalid),
        throwsFormatException,
        reason: '$invalid',
      );
    }
  });

  test('preserves every exact unbounded integer field', () {
    final endpoint = contract.affiliationDetail(1);
    for (final field in _integerFields) {
      for (final value in [-1000000, 0, 1000000]) {
        final actual = endpoint.decode(_detail()..[field] = value);
        expect(_integer(actual, field), value, reason: field);
      }
      for (final invalid in <Object?>[
        null,
        1.0,
        -1.0,
        '1',
        false,
        const <Object?>[],
        const <String, Object?>{},
      ]) {
        expect(
          () => endpoint.decode(_detail()..[field] = invalid),
          throwsFormatException,
          reason: '$field = $invalid',
        );
      }
    }
  });

  test('preserves raw required and required-nullable strings', () {
    final endpoint = contract.affiliationDetail(1);
    final longValue = List<String>.filled(512, '🌏').join();
    for (final field in ['name', 'displayName']) {
      for (final value in ['', ' ', '한 글 & raw', longValue]) {
        final actual = endpoint.decode(_detail()..[field] = value);
        expect(_string(actual, field), value);
      }
      for (final invalid in <Object?>[
        null,
        0,
        false,
        const <Object?>[],
        const <String, Object?>{},
      ]) {
        expect(
          () => endpoint.decode(_detail()..[field] = invalid),
          throwsFormatException,
        );
      }
    }

    for (final field in _nullableStringFields) {
      for (final value in <String?>[
        null,
        '',
        ' ',
        'not necessarily a URI or color',
        longValue,
      ]) {
        final actual = endpoint.decode(_detail()..[field] = value);
        expect(_nullableString(actual, field), value);
      }
      for (final invalid in <Object?>[
        0,
        false,
        const <Object?>[],
        const <String, Object?>{},
      ]) {
        expect(
          () => endpoint.decode(_detail()..[field] = invalid),
          throwsFormatException,
          reason: '$field = $invalid',
        );
      }
    }
  });

  test('accepts exactly the shared type vocabulary and a strict boolean', () {
    final endpoint = contract.affiliationDetail(1);
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
      final actual = endpoint.decode(_detail()..['type'] = type);
      expect(actual.type.value, type);
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
        () => endpoint.decode(_detail()..['type'] = invalid),
        throwsFormatException,
      );
    }

    for (final value in [false, true]) {
      final actual = endpoint.decode(_detail()..['ratingClassPlus'] = value);
      expect(actual.ratingClassPlus, value);
    }
    for (final invalid in <Object?>[null, 0, 1, 'true', const <Object?>[]]) {
      expect(
        () => endpoint.decode(_detail()..['ratingClassPlus'] = invalid),
        throwsFormatException,
      );
    }
  });

  test('strictly decodes both raw integer arrays', () {
    final endpoint = contract.affiliationDetail(1);
    for (final field in ['tierCounts', 'ratingProblemsHistogram']) {
      for (final invalid in <Object?>[
        null,
        0,
        false,
        'counts',
        const <String, Object?>{},
      ]) {
        expect(
          () => endpoint.decode(_detail()..[field] = invalid),
          throwsFormatException,
        );
      }
      for (final invalid in <Object?>[
        null,
        1.0,
        '1',
        false,
        const <Object?>[],
        const <String, Object?>{},
      ]) {
        expect(
          () => endpoint.decode(
            _detail()..[field] = <Object?>[-1, invalid],
          ),
          throwsFormatException,
          reason: '$field item = $invalid',
        );
      }

      final source = <Object?>[-1, 0, -1];
      final actual = endpoint.decode(_detail()..[field] = source);
      source
        ..clear()
        ..add(999);
      final values = field == 'tierCounts'
          ? actual.tierCounts
          : actual.ratingProblemsHistogram;
      expect(values, [-1, 0, -1]);
      expect(() => values.clear(), throwsUnsupportedError);
      final empty = endpoint.decode(_detail()..[field] = <Object?>[]);
      expect(
        field == 'tierCounts'
            ? empty.tierCounts
            : empty.ratingProblemsHistogram,
        isEmpty,
      );
    }
  });

  test('preserves future fields and source isolation without relations', () {
    final endpoint = contract.affiliationDetail(1);
    final tierCounts = <Object?>[3, 1, 3];
    final histogram = <Object?>[-2, 4, -2];
    final source = _detail()
      ..['id'] = 42.5
      ..['affiliationId'] = -100
      ..['name'] = 'wire name'
      ..['displayName'] = 'different display'
      ..['rank'] = 99
      ..['rankedOf'] = -1
      ..['tierCounts'] = tierCounts
      ..['ratingProblemsHistogram'] = histogram
      ..['futureDetail'] = <String, Object?>{'ignored': true};
    final actual = endpoint.decode(source);
    tierCounts.clear();
    histogram.clear();
    source
      ..['id'] = 1
      ..['affiliationId'] = 42
      ..['name'] = 'changed'
      ..['displayName'] = 'changed'
      ..['rank'] = -999;

    expect(actual.id, 42.5);
    expect(actual.affiliationId, -100);
    expect(actual.name, 'wire name');
    expect(actual.displayName, 'different display');
    expect(actual.rank, 99);
    expect(actual.rankedOf, -1);
    expect(actual.tierCounts, [3, 1, 3]);
    expect(actual.ratingProblemsHistogram, [-2, 4, -2]);
  });
}

const _fields = [
  'id',
  'affiliationId',
  'name',
  'type',
  'countryCode',
  'logoImageUrl',
  'logoThumbnailUrl',
  'color',
  'website',
  'rating',
  'userCount',
  'solvedCount',
  'voteCount',
  'displayName',
  'rank',
  'rankedOf',
  'typeRank',
  'typeRankedOf',
  'tierCounts',
  'ratingByProblemsSum',
  'ratingByClass',
  'ratingBySolvedCount',
  'ratingProblemsHistogram',
  'ratingClass',
  'ratingClassPlus',
];

const _nullableStringFields = {
  'countryCode',
  'logoImageUrl',
  'logoThumbnailUrl',
  'color',
  'website',
};

const _integerFields = [
  'affiliationId',
  'rating',
  'userCount',
  'solvedCount',
  'voteCount',
  'rank',
  'rankedOf',
  'typeRank',
  'typeRankedOf',
  'ratingByProblemsSum',
  'ratingByClass',
  'ratingBySolvedCount',
  'ratingClass',
];

Map<String, Object?> _detail() => <String, Object?>{
      'id': 1.5,
      'affiliationId': 2,
      'name': 'Name',
      'type': 'university',
      'countryCode': null,
      'logoImageUrl': null,
      'logoThumbnailUrl': null,
      'color': null,
      'website': null,
      'rating': 3,
      'userCount': 4,
      'solvedCount': 5,
      'voteCount': 6,
      'displayName': 'Display',
      'rank': 7,
      'rankedOf': 8,
      'typeRank': 9,
      'typeRankedOf': 10,
      'tierCounts': <Object?>[1, 2],
      'ratingByProblemsSum': 11,
      'ratingByClass': 12,
      'ratingBySolvedCount': 13,
      'ratingProblemsHistogram': <Object?>[3, 4],
      'ratingClass': 14,
      'ratingClassPlus': false,
    };

int _integer(AffiliationDetailResult value, String field) => switch (field) {
      'affiliationId' => value.affiliationId,
      'rating' => value.rating,
      'userCount' => value.userCount,
      'solvedCount' => value.solvedCount,
      'voteCount' => value.voteCount,
      'rank' => value.rank,
      'rankedOf' => value.rankedOf,
      'typeRank' => value.typeRank,
      'typeRankedOf' => value.typeRankedOf,
      'ratingByProblemsSum' => value.ratingByProblemsSum,
      'ratingByClass' => value.ratingByClass,
      'ratingBySolvedCount' => value.ratingBySolvedCount,
      _ => value.ratingClass,
    };

String _string(AffiliationDetailResult value, String field) =>
    field == 'name' ? value.name : value.displayName;

String? _nullableString(AffiliationDetailResult value, String field) =>
    switch (field) {
      'countryCode' => value.countryCode,
      'logoImageUrl' => value.logoImageUrl,
      'logoThumbnailUrl' => value.logoThumbnailUrl,
      'color' => value.color,
      _ => value.website,
    };
