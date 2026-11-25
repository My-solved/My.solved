import 'dart:convert';

import 'package:solved_api/solved_api.dart';
import 'package:test/test.dart';

import 'helpers/fixture.dart';

void main() {
  late SolvedApiV4Contract contract;

  setUp(() {
    contract = SolvedApiV4Contract(
      proxyBaseUri: Uri.parse('https://proxy.example.com/api/v4/'),
    );
  });

  test('keeps v4 application credentials behind the proxy boundary', () {
    final endpoint = contract.userProfile('index');

    expect(contract.requiresProxy, isTrue);
    expect(endpoint.direct.baseUri, Uri.parse('https://solved.ac/api/v4/'));
    expect(endpoint.direct.path, 'users/index');
    expect(endpoint.direct.queryParameters, {'lang': 'ko'});
    expect(
      endpoint.proxy.baseUri,
      Uri.parse('https://proxy.example.com/api/v4/'),
    );
    expect(endpoint.proxy.path, 'users/index');
    expect(endpoint.proxy.queryParameters, {'lang': 'ko'});
  });

  test('pins the authenticated identity endpoint and number-shaped ID', () {
    final endpoint = contract.currentUser();
    final identity = endpoint.decode(jsonDecode(fixture('v4/me.json')));

    expect(endpoint.direct.baseUri, Uri.parse('https://solved.ac/api/v4/'));
    expect(endpoint.direct.path, 'me');
    expect(endpoint.direct.queryParameters, isEmpty);
    expect(
      endpoint.proxy.baseUri,
      Uri.parse('https://proxy.example.com/api/v4/'),
    );
    expect(endpoint.proxy.path, 'me');
    expect(endpoint.proxy.queryParameters, isEmpty);
    expect(identity.id, 123456789);
    expect(identity.handle, 'index');
    expect(
      endpoint.decode({'id': 42.5, 'handle': 'renamed'}).id,
      42.5,
    );
  });

  test('rejects malformed authenticated identity responses', () {
    final decode = contract.currentUser().decode;
    for (final body in <Object?>[
      null,
      <String, Object?>{},
      <String, Object?>{'id': 1},
      <String, Object?>{'handle': 'index'},
      <String, Object?>{'id': '1', 'handle': 'index'},
      <String, Object?>{'id': double.nan, 'handle': 'index'},
      <String, Object?>{'id': double.infinity, 'handle': 'index'},
      <String, Object?>{'id': 1, 'handle': 1},
    ]) {
      expect(
        () => decode(body),
        throwsFormatException,
        reason: body.toString(),
      );
    }
  });

  test('encodes untrusted path values and rejects ambiguous segments', () {
    expect(
      contract.userProfile('한 글').direct.path,
      'users/%ED%95%9C%20%EA%B8%80',
    );
    expect(
      contract.backgroundShow('event item').direct.path,
      'achievements/items/background/event%20item',
    );

    expect(() => contract.userProfile(''), throwsArgumentError);
    expect(() => contract.userProfile('..'), throwsArgumentError);
    expect(() => contract.badgeShow('.'), throwsArgumentError);
    expect(() => contract.userProfile('name/with/slash'), throwsArgumentError);
    expect(() => contract.badgeShow(r'name\with\slash'), throwsArgumentError);
    expect(() => contract.userProfile('line\nbreak'), throwsArgumentError);
    expect(
      () => contract.userProfile(List.filled(65, 'a').join()),
      throwsArgumentError,
    );
  });

  test('normalizes the integrated v4 public profile', () {
    final source = jsonDecode(fixture('v4/user_profile.json'));
    final OfficialUserProfile actual =
        contract.userProfile('index').decode(source);

    expect(actual.id, 1);
    expect(actual.handle, 'index');
    expect(actual.tier, isNull);
    expect(actual.rating, 2417);
    expect(actual.solvedCount, 2048);
    expect(actual.bio, isNull);
    expect(actual.classPlus, isTrue);
    expect(actual.currentStreak, 12);
    expect(actual.maxStreak, 365);
    expect(actual.streakVacation, isNull);
    expect(actual.streakCountedToday, isTrue);
    expect(actual.streakFrozenYesterday, isFalse);
    expect(actual.streakTheme, isNull);
    expect(actual.voteCount, 37);
    expect(actual.legacyContributionCount, isNull);
    expect(actual.reverseRivalCount, isNull);
    expect(actual.reputation, 314);
    expect(actual.backgroundId, 'anniversary_1st');
    expect(actual.background?.key, 'anniversary_1st');
    expect(
      actual.background?.imageUrl,
      'https://example.com/background.png',
    );
    expect(actual.badgeId, 'boardgame');
    expect(actual.badge?.name, 'Board Game');
    expect(actual.ratingBreakdown?.ratingByProblemsSum, 2010);
    expect(actual.ratingBreakdown?.ratingByClass, 200);
    expect(actual.ratingBreakdown?.ratingBySolvedCount, 207);
    expect(actual.ratingBreakdown?.ratingProblemsCutoff, 100);
    expect(actual.ratingBreakdown?.ratingProblemsHistogram, [2, 7, 15]);
    expect(actual.ratingBreakdown?.noRatingSolvedCount, 4);
    expect(actual.ratingBreakdown?.overRating, isNull);
    expect(actual.tagRatings, hasLength(2));
    expect(actual.tagRatings.first.key, 'dp');
    expect(actual.tagRatings.first.rating, 1750);
    expect(actual.tagRatings.first.solvedCount, 120);
    expect(actual, isA<UserProfile>());
  });

  test('requires raw public profile identity fields without inference', () {
    final endpoint = contract.userProfile('index');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/user_profile.json')) as Map,
        );

    for (final field in ['id', 'voteCount']) {
      expect(
        () => endpoint.decode(source()..remove(field)),
        throwsFormatException,
        reason: '$field missing',
      );
    }

    for (final invalid in <Object?>[
      null,
      '1',
      false,
      const <Object>[],
      const <String, Object?>{},
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(
        () => endpoint.decode(source()..['id'] = invalid),
        throwsFormatException,
        reason: 'id = $invalid',
      );
    }
    for (final invalid in <Object?>[
      null,
      '1',
      1.0,
      false,
      const <Object>[],
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(source()..['voteCount'] = invalid),
        throwsFormatException,
        reason: 'voteCount = $invalid',
      );
    }

    for (final id in <num>[-7, 0, 42, 42.0, -2.5, 42.5]) {
      final actual = endpoint.decode(source()..['id'] = id);
      expect(actual.id, id);
      expect(actual.id.runtimeType, id.runtimeType);
    }
    for (final voteCount in [-7, 0, 42]) {
      final actual = endpoint.decode(source()..['voteCount'] = voteCount);
      expect(actual.voteCount, voteCount);
    }

    final actual = endpoint.decode(
      source()
        ..['id'] = -2.5
        ..['voteCount'] = -7
        ..['reputation'] = 9001
        ..['handle'] = 'independent-handle'
        ..['futureProfileField'] = 'allowed',
    );
    expect(actual.id, -2.5);
    expect(actual.voteCount, -7);
    expect(actual.reputation, 9001);
    expect(actual.handle, 'independent-handle');
    expect(actual.legacyContributionCount, isNull);
  });

  test('requires exact public profile streak state types', () {
    final endpoint = contract.userProfile('index');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/user_profile.json')) as Map,
        );

    for (final field in [
      'streakVacation',
      'streakCountedToday',
      'streakFrozenYesterday',
      'streakTheme',
    ]) {
      expect(
        () => endpoint.decode(source()..remove(field)),
        throwsFormatException,
        reason: '$field missing',
      );
    }

    for (final invalid in <Object>[
      0,
      false,
      'vacation',
      const <Object>[],
    ]) {
      expect(
        () => endpoint.decode(source()..['streakVacation'] = invalid),
        throwsFormatException,
        reason: 'streakVacation = $invalid',
      );
    }
    for (final invalid in <Object>[
      0,
      false,
      const <Object>[],
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(source()..['streakTheme'] = invalid),
        throwsFormatException,
        reason: 'streakTheme = $invalid',
      );
    }
    for (final field in ['streakCountedToday', 'streakFrozenYesterday']) {
      for (final invalid in <Object?>[
        null,
        0,
        'true',
        const <Object>[],
        const <String, Object?>{},
      ]) {
        expect(
          () => endpoint.decode(source()..[field] = invalid),
          throwsFormatException,
          reason: '$field = $invalid',
        );
      }
    }

    final nullable = endpoint.decode(
      source()
        ..['streakVacation'] = null
        ..['streakCountedToday'] = false
        ..['streakFrozenYesterday'] = true
        ..['streakTheme'] = null,
    );
    expect(nullable.streakVacation, isNull);
    expect(nullable.streakCountedToday, isFalse);
    expect(nullable.streakFrozenYesterday, isTrue);
    expect(nullable.streakTheme, isNull);
  });

  test('strictly preserves the public profile streak vacation', () {
    final endpoint = contract.userProfile('index');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/user_profile.json')) as Map,
        );
    expect(
      OfficialUserProfileStreakVacationSource.values
          .map((value) => value.value),
      ['item', 'launch'],
    );

    for (final sourceValue in ['item', 'launch']) {
      final fromDay = sourceValue == 'item' ? '' : ' raw from day ';
      final actual = endpoint.decode(
        source()
          ..['streakVacation'] = <String, Object?>{
            'fromDay': fromDay,
            'source': sourceValue,
            'futureVacationField': 'allowed',
          },
      );
      expect(actual.streakVacation?.fromDay, fromDay);
      expect(actual.streakVacation?.source.value, sourceValue);
    }

    for (final field in ['fromDay', 'source']) {
      final vacation = <String, Object?>{
        'fromDay': '2026-11-01',
        'source': 'item',
      }..remove(field);
      expect(
        () => endpoint.decode(source()..['streakVacation'] = vacation),
        throwsFormatException,
        reason: 'missing streakVacation.$field',
      );
    }
    for (final invalid in <Object?>[
      null,
      0,
      false,
      const <Object>[],
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(
          source()
            ..['streakVacation'] = <String, Object?>{
              'fromDay': invalid,
              'source': 'item',
            },
        ),
        throwsFormatException,
        reason: 'streakVacation.fromDay = $invalid',
      );
    }
    for (final invalid in <Object?>[
      null,
      0,
      false,
      const <Object>[],
      const <String, Object?>{},
      '',
      'Item',
      'item ',
      'unknown',
    ]) {
      expect(
        () => endpoint.decode(
          source()
            ..['streakVacation'] = <String, Object?>{
              'fromDay': '2026-11-01',
              'source': invalid,
            },
        ),
        throwsFormatException,
        reason: 'streakVacation.source = $invalid',
      );
    }
  });

  test('preserves raw public profile streak state without inference', () {
    final endpoint = contract.userProfile('index');
    final source = Map<String, dynamic>.from(
      jsonDecode(fixture('v4/user_profile.json')) as Map,
    )
      ..['currentStreak'] = -1
      ..['maxStreak'] = -2
      ..['streakVacation'] = null
      ..['streakCountedToday'] = true
      ..['streakFrozenYesterday'] = true
      ..['streakTheme'] = '  '
      ..['futureProfileField'] = 'allowed';
    final actual = endpoint.decode(source);

    expect(actual.currentStreak, -1);
    expect(actual.maxStreak, -2);
    expect(actual.streakVacation, isNull);
    expect(actual.streakCountedToday, isTrue);
    expect(actual.streakFrozenYesterday, isTrue);
    expect(actual.streakTheme, '  ');
    expect(endpoint.decode(source..['streakTheme'] = '').streakTheme, '');
  });

  test('requires nullable tier and profile image keys in public profiles', () {
    final endpoint = contract.userProfile('index');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
      jsonDecode(fixture('v4/user_profile.json')) as Map,
    );
    final invalidValues = <String, List<Object>>{
      'tier': ['1', 1.0, true, const <Object>[], const <String, Object?>{}],
      'profileImageUrl': [1, true, const <Object>[], const <String, Object?>{}],
    };

    for (final field in invalidValues.keys) {
      expect(
        () => endpoint.decode(source()..remove(field)),
        throwsFormatException,
        reason: '$field missing',
      );

      final nullable = endpoint.decode(source()..[field] = null);
      expect(
        field == 'tier' ? nullable.tier : nullable.profileImageUrl,
        isNull,
        reason: '$field explicit null',
      );

      for (final invalid in invalidValues[field]!) {
        expect(
          () => endpoint.decode(source()..[field] = invalid),
          throwsFormatException,
          reason: '$field = $invalid',
        );
      }
    }

    final actual = endpoint.decode(
      source()
        ..['tier'] = 20
        ..['profileImageUrl'] = 'https://example.com/profile.png',
    );
    expect(actual.tier, 20);
    expect(actual.profileImageUrl, 'https://example.com/profile.png');
  });

  test('enforces documented public profile tier bounds', () {
    final endpoint = contract.userProfile('index');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
      jsonDecode(fixture('v4/user_profile.json')) as Map,
    );

    for (final value in <int?>[null, 0, 31]) {
      final actual = endpoint.decode(source()..['tier'] = value);
      expect(actual.tier, value, reason: 'tier = $value');
    }

    for (final value in [-1, 32]) {
      expect(
        () => endpoint.decode(source()..['tier'] = value),
        throwsFormatException,
        reason: 'tier = $value',
      );
    }
  });

  test('requires integer profile streak summaries without inventing bounds', () {
    final endpoint = contract.userProfile('index');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/user_profile.json')) as Map,
        );

    for (final field in ['currentStreak', 'maxStreak']) {
      final missing = source()..remove(field);
      expect(
        () => endpoint.decode(missing),
        throwsFormatException,
        reason: '$field missing',
      );

      for (final invalid in <Object?>[null, '1', 1.5]) {
        final malformed = source()..[field] = invalid;
        expect(
          () => endpoint.decode(malformed),
          throwsFormatException,
          reason: '$field = $invalid',
        );
      }
    }

    final unbounded = source()
      ..['currentStreak'] = -1
      ..['maxStreak'] = -2;
    final actual = endpoint.decode(unbounded);
    expect(actual.currentStreak, -1);
    expect(actual.maxStreak, -2);
  });

  test('requires and preserves the nullable public profile biography', () {
    final endpoint = contract.userProfile('index');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/user_profile.json')) as Map,
        );

    expect(
      () => endpoint.decode(source()..remove('bio')),
      throwsFormatException,
    );
    for (final invalid in <Object>[
      0,
      false,
      const <String>[],
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(source()..['bio'] = invalid),
        throwsFormatException,
        reason: 'bio = $invalid',
      );
    }

    for (final value in <String?>[null, '', '  ', 'public biography']) {
      expect(endpoint.decode(source()..['bio'] = value).bio, value);
    }
  });

  test('requires the public CLASS+ marker as a boolean', () {
    final endpoint = contract.userProfile('index');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/user_profile.json')) as Map,
        );

    expect(
      () => endpoint.decode(source()..remove('classPlus')),
      throwsFormatException,
    );
    for (final invalid in <Object?>[null, 0, 'true']) {
      expect(
        () => endpoint.decode(source()..['classPlus'] = invalid),
        throwsFormatException,
        reason: 'classPlus = $invalid',
      );
    }

    expect(endpoint.decode(source()..['classPlus'] = false).classPlus, isFalse);
  });

  test('requires the no-rating solved count without inventing bounds', () {
    final endpoint = contract.userProfile('index');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/user_profile.json')) as Map,
        );

    expect(
      () => endpoint.decode(source()..remove('noRatingSolvedCount')),
      throwsFormatException,
    );
    for (final invalid in <Object?>[null, '4', 4.5]) {
      expect(
        () => endpoint.decode(source()..['noRatingSolvedCount'] = invalid),
        throwsFormatException,
        reason: 'noRatingSolvedCount = $invalid',
      );
    }

    for (final value in [0, -4]) {
      final actual = endpoint.decode(source()..['noRatingSolvedCount'] = value);
      expect(actual.ratingBreakdown?.noRatingSolvedCount, value);
    }
  });

  test('preserves the full sparse activity envelope and explicit range', () {
    final SolvedApiEndpoint<ProfileActivityResult> endpoint =
        contract.userActivity(
      'index',
      from: DateTime(2026, 11, 1, 23, 59),
      to: DateTime(2026, 11, 17, 1),
    );
    final actual = endpoint.decode(
      jsonDecode(fixture('v4/user_activity_days.json')),
    );

    expect(endpoint.direct.path, 'users/index/activity/days');
    expect(endpoint.direct.queryParameters, {
      'from': '2026-11-01',
      'to': '2026-11-17',
    });
    expect(actual, isA<ProfileActivityResult>());
    expect(actual, isA<ProfileStreak>());
    expect(actual.from, '2026-11-01');
    expect(actual.to, '2026-11-17');
    expect(actual.maxSolvedCount, 4);
    expect(actual.currentStreak, 12);
    expect(actual.maxStreak, 365);
    expect(actual.theme, isNull);
    expect(actual.firstActiveDay, '2020-01-02');
    expect(actual.vacation, isNull);
    expect(actual.vacations, isEmpty);
    expect(actual.countedToday, isTrue);
    expect(actual.frozenYesterday, isFalse);
    expect(actual.days, hasLength(2));
    expect(actual.days.first.solvedCount, 4);
    expect(actual.days.first.maxSolvedLevel, 18);
    expect(actual.days.first.ratingDelta, 12);
    expect(actual.days.last.freezeUsed, isTrue);
    expect(actual.days.last.streakRepaired, isTrue);
  });

  test('requires every activity envelope key and exact top-level types', () {
    final endpoint = contract.userActivity(
      'index',
      from: DateTime.utc(2026, 11),
      to: DateTime.utc(2026, 11, 17),
    );
    for (final field in [
      'from',
      'to',
      'days',
      'maxSolvedCount',
      'currentStreak',
      'maxStreak',
      'theme',
      'firstActiveDay',
      'vacation',
      'vacations',
      'countedToday',
      'frozenYesterday',
    ]) {
      expect(
        () => endpoint.decode(_activitySource()..remove(field)),
        throwsFormatException,
        reason: 'missing $field',
      );
    }

    final invalidValues = <String, List<Object?>>{
      'from': [null, 0, false, const <Object>[], const <String, Object?>{}],
      'to': [null, 0, false, const <Object>[], const <String, Object?>{}],
      'days': [null, 0, false, 'days', const <String, Object?>{}],
      'maxSolvedCount': [
        null,
        '0',
        0.0,
        false,
        const <Object>[],
        const <String, Object?>{},
      ],
      'currentStreak': [
        null,
        '0',
        0.0,
        false,
        const <Object>[],
        const <String, Object?>{},
      ],
      'maxStreak': [
        null,
        '0',
        0.0,
        false,
        const <Object>[],
        const <String, Object?>{},
      ],
      'theme': [0, false, const <Object>[], const <String, Object?>{}],
      'firstActiveDay': [
        0,
        false,
        const <Object>[],
        const <String, Object?>{},
      ],
      'vacation': [0, false, 'vacation', const <Object>[]],
      'vacations': [null, 0, false, 'vacations', const <String, Object?>{}],
      'countedToday': [
        null,
        0,
        'true',
        const <Object>[],
        const <String, Object?>{},
      ],
      'frozenYesterday': [
        null,
        0,
        'false',
        const <Object>[],
        const <String, Object?>{},
      ],
    };
    for (final entry in invalidValues.entries) {
      for (final invalid in entry.value) {
        expect(
          () => endpoint.decode(_activitySource()..[entry.key] = invalid),
          throwsFormatException,
          reason: '${entry.key} = $invalid',
        );
      }
    }
  });

  test('preserves raw activity values without cross-field inference', () {
    final endpoint = contract.userActivity(
      'index',
      from: DateTime.utc(2026, 11),
      to: DateTime.utc(2026, 11, 17),
    );
    final source = _activitySource()
      ..['from'] = ' response from '
      ..['to'] = ''
      ..['maxSolvedCount'] = 0
      ..['currentStreak'] = 0
      ..['maxStreak'] = 0
      ..['theme'] = '  '
      ..['firstActiveDay'] = ''
      ..['vacation'] = null
      ..['vacations'] = <Object>[]
      ..['countedToday'] = false
      ..['frozenYesterday'] = true
      ..['futureEnvelopeField'] = 'allowed';
    final actual = endpoint.decode(source);

    expect(actual.from, ' response from ');
    expect(actual.to, '');
    expect(actual.maxSolvedCount, 0);
    expect(actual.currentStreak, 0);
    expect(actual.maxStreak, 0);
    expect(actual.theme, '  ');
    expect(actual.firstActiveDay, '');
    expect(actual.vacation, isNull);
    expect(actual.vacations, isEmpty);
    expect(actual.countedToday, isFalse);
    expect(actual.frozenYesterday, isTrue);
    expect(actual.days.first.solvedCount, 4);

    final nullable = endpoint.decode(
      _activitySource()
        ..['theme'] = null
        ..['firstActiveDay'] = null
        ..['vacation'] = null,
    );
    expect(nullable.theme, isNull);
    expect(nullable.firstActiveDay, isNull);
    expect(nullable.vacation, isNull);

    for (final field in ['maxSolvedCount', 'currentStreak', 'maxStreak']) {
      expect(
        () => endpoint.decode(_activitySource()..[field] = -1),
        throwsFormatException,
        reason: '$field = -1',
      );
    }
  });

  test('strictly decodes the required nullable current vacation', () {
    final endpoint = contract.userActivity(
      'index',
      from: DateTime.utc(2026, 11),
      to: DateTime.utc(2026, 11, 17),
    );
    expect(
      ProfileActivityVacationSource.values.map((value) => value.value),
      ['item', 'launch'],
    );

    for (final sourceValue in ['item', 'launch']) {
      final actual = endpoint.decode(
        _activitySource()
          ..['vacation'] = <String, Object?>{
            'fromDay': ' raw day ',
            'source': sourceValue,
            'futureField': true,
          },
      );
      expect(actual.vacation?.fromDay, ' raw day ');
      expect(actual.vacation?.source.value, sourceValue);
    }

    for (final field in ['fromDay', 'source']) {
      final vacation = <String, Object?>{
        'fromDay': '2026-11-01',
        'source': 'item',
      }..remove(field);
      expect(
        () => endpoint.decode(_activitySource()..['vacation'] = vacation),
        throwsFormatException,
        reason: 'missing vacation.$field',
      );
    }
    for (final invalid in <Object?>[
      null,
      0,
      false,
      const <Object>[],
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(
          _activitySource()
            ..['vacation'] = <String, Object?>{
              'fromDay': invalid,
              'source': 'item',
            },
        ),
        throwsFormatException,
        reason: 'vacation.fromDay = $invalid',
      );
    }
    for (final invalid in <Object?>[
      null,
      0,
      false,
      '',
      'ITEM',
      ' item',
      'item ',
      'future',
      const <Object>[],
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(
          _activitySource()
            ..['vacation'] = <String, Object?>{
              'fromDay': '2026-11-01',
              'source': invalid,
            },
        ),
        throwsFormatException,
        reason: 'vacation.source = $invalid',
      );
    }
  });

  test('preserves immutable vacation order, duplicates, and raw values', () {
    final endpoint = contract.userActivity(
      'index',
      from: DateTime.utc(2026, 11),
      to: DateTime.utc(2026, 11, 17),
    );
    final first = <String, Object?>{
      'fromDay': '',
      'untilDay': null,
      'futureField': 'allowed',
    };
    final second = <String, Object?>{
      'fromDay': ' from ',
      'untilDay': ' until ',
    };
    final sourceVacations = <Object>[
      first,
      second,
      Map<String, Object?>.from(second),
    ];
    final source = _activitySource()..['vacations'] = sourceVacations;
    final actual = endpoint.decode(source);

    sourceVacations.clear();
    first['fromDay'] = 'changed';
    second['untilDay'] = 'changed';
    source['vacations'] = <Object>[];

    expect(actual.vacations, hasLength(3));
    expect(actual.vacations.map((value) => value.fromDay), [
      '',
      ' from ',
      ' from ',
    ]);
    expect(actual.vacations.map((value) => value.untilDay), [
      null,
      ' until ',
      ' until ',
    ]);
    expect(
      () => actual.vacations.add(actual.vacations.first),
      throwsUnsupportedError,
    );
    expect(
      () => actual.vacations[0] = actual.vacations[1],
      throwsUnsupportedError,
    );
  });

  test('requires every vacation entry field and exact nullable types', () {
    final endpoint = contract.userActivity(
      'index',
      from: DateTime.utc(2026, 11),
      to: DateTime.utc(2026, 11, 17),
    );
    for (final malformed in <Object?>[
      null,
      0,
      false,
      'vacation',
      const <Object>[],
    ]) {
      expect(
        () => endpoint.decode(
          _activitySource()..['vacations'] = <Object?>[malformed],
        ),
        throwsFormatException,
        reason: 'vacations[] = $malformed',
      );
    }

    for (final field in ['fromDay', 'untilDay']) {
      final vacation = <String, Object?>{
        'fromDay': '2026-11-01',
        'untilDay': null,
      }..remove(field);
      expect(
        () => endpoint.decode(
          _activitySource()..['vacations'] = <Object>[vacation],
        ),
        throwsFormatException,
        reason: 'missing vacations[].$field',
      );
    }
    for (final invalid in <Object?>[
      null,
      0,
      false,
      const <Object>[],
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(
          _activitySource()
            ..['vacations'] = <Object>[
              <String, Object?>{'fromDay': invalid, 'untilDay': null},
            ],
        ),
        throwsFormatException,
        reason: 'vacations[].fromDay = $invalid',
      );
    }
    for (final invalid in <Object>[
      0,
      false,
      const <Object>[],
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(
          _activitySource()
            ..['vacations'] = <Object>[
              <String, Object?>{
                'fromDay': '2026-11-01',
                'untilDay': invalid,
              },
            ],
        ),
        throwsFormatException,
        reason: 'vacations[].untilDay = $invalid',
      );
    }
  });

  test('requires every sparse-day field and exact value types', () {
    final endpoint = contract.userActivity(
      'index',
      from: DateTime.utc(2026, 11),
      to: DateTime.utc(2026, 11, 17),
    );

    for (final malformed in <Object?>[
      null,
      0,
      false,
      'day',
      const <Object>[],
    ]) {
      expect(
        () => endpoint.decode(
          _activitySource()..['days'] = <Object?>[malformed],
        ),
        throwsFormatException,
        reason: 'days[] = $malformed',
      );
    }

    for (final field in [
      'day',
      'solvedCount',
      'maxSolvedLevel',
      'ratingDelta',
      'freezeUsed',
      'streakRepaired',
    ]) {
      final day = _activityDaySource()..remove(field);
      expect(
        () => endpoint.decode(_activitySource()..['days'] = <Object>[day]),
        throwsFormatException,
        reason: 'missing days[].$field',
      );
    }

    final invalidValues = <String, List<Object?>>{
      'day': [null, 0, false, const <Object>[], const <String, Object?>{}],
      'solvedCount': [
        null,
        '0',
        0.0,
        false,
        const <Object>[],
        const <String, Object?>{},
      ],
      'maxSolvedLevel': [
        null,
        '0',
        0.0,
        false,
        const <Object>[],
        const <String, Object?>{},
      ],
      'ratingDelta': [
        null,
        '0',
        0.0,
        false,
        const <Object>[],
        const <String, Object?>{},
      ],
      'freezeUsed': [
        null,
        0,
        'false',
        const <Object>[],
        const <String, Object?>{},
      ],
      'streakRepaired': [
        null,
        0,
        'false',
        const <Object>[],
        const <String, Object?>{},
      ],
    };
    for (final entry in invalidValues.entries) {
      for (final invalid in entry.value) {
        final day = _activityDaySource()..[entry.key] = invalid;
        expect(
          () => endpoint.decode(_activitySource()..['days'] = <Object>[day]),
          throwsFormatException,
          reason: 'days[].${entry.key} = $invalid',
        );
      }
    }
  });

  test('matches sparse-day bounds without calendar or range inference', () {
    final endpoint = contract.userActivity(
      'index',
      from: DateTime.utc(2026, 11),
      to: DateTime.utc(2026, 11, 17),
    );
    final first = _activityDaySource()
      ..['day'] = '0000-00-00'
      ..['solvedCount'] = 0
      ..['maxSolvedLevel'] = 0
      ..['ratingDelta'] = -999
      ..['futureDayField'] = 'allowed';
    final second = _activityDaySource()
      ..['day'] = '9999-99-99'
      ..['solvedCount'] = 999999999999
      ..['maxSolvedLevel'] = 30
      ..['ratingDelta'] = 999;
    final actual = endpoint.decode(
      _activitySource()
        ..['maxSolvedCount'] = 0
        ..['days'] = <Object>[first, second],
    );

    expect(actual.maxSolvedCount, 0);
    expect(actual.days.map((value) => value.year), [0, 9999]);
    expect(actual.days.map((value) => value.month), [0, 99]);
    expect(actual.days.map((value) => value.day), [0, 99]);
    expect(actual.days.map((value) => value.solvedCount), [0, 999999999999]);
    expect(actual.days.map((value) => value.maxSolvedLevel), [0, 30]);
    expect(actual.days.map((value) => value.ratingDelta), [-999, 999]);

    for (final ratingDelta in [-1, 0, 1]) {
      final day = _activityDaySource()..['ratingDelta'] = ratingDelta;
      final decoded = endpoint.decode(
        _activitySource()..['days'] = <Object>[day],
      );
      expect(decoded.days.single.ratingDelta, ratingDelta);
    }
  });

  test('rejects values outside sparse-day bounds and malformed day tokens', () {
    final endpoint = contract.userActivity(
      'index',
      from: DateTime.utc(2026, 11),
      to: DateTime.utc(2026, 11, 17),
    );

    for (final entry in <String, List<int>>{
      'solvedCount': [-1],
      'maxSolvedLevel': [-1, 31],
    }.entries) {
      for (final invalid in entry.value) {
        final day = _activityDaySource()..[entry.key] = invalid;
        expect(
          () => endpoint.decode(_activitySource()..['days'] = <Object>[day]),
          throwsFormatException,
          reason: 'days[].${entry.key} = $invalid',
        );
      }
    }

    for (final invalid in [
      '',
      '2026-1-01',
      '2026-01-1',
      '2026-01-011',
      '2026/01/01',
      ' 2026-01-01',
      '2026-01-01 ',
    ]) {
      final day = _activityDaySource()..['day'] = invalid;
      expect(
        () => endpoint.decode(_activitySource()..['days'] = <Object>[day]),
        throwsFormatException,
        reason: 'days[].day = $invalid',
      );
    }
  });

  test('isolates and freezes decoded sparse days without changing semantics',
      () {
    final endpoint = contract.userActivity(
      'index',
      from: DateTime.utc(2026, 11),
      to: DateTime.utc(2026, 11, 17),
    );
    final source = _activitySource();
    final sourceDays = source['days'] as List<dynamic>;
    final firstSourceDay = sourceDays.first as Map<String, dynamic>;
    firstSourceDay['futureField'] = 'allowed';
    sourceDays.insert(1, Map<String, dynamic>.from(firstSourceDay));
    final actual = endpoint.decode(source);

    firstSourceDay['solvedCount'] = 999;
    (sourceDays[1] as Map<String, dynamic>)['day'] = '2026-11-16';
    sourceDays.clear();
    source['days'] = <Object>[];

    expect(actual.days, hasLength(3));
    expect(actual.days.map((value) => value.solvedCount), [4, 4, 1]);
    expect(actual.days.map((value) => value.day), [15, 15, 17]);
    expect(
      () => actual.days.add(actual.days.first),
      throwsUnsupportedError,
    );
    expect(
      () => actual.days[0] = const ProfileSolvedDay(
        year: 2026,
        month: 11,
        day: 1,
        solvedCount: 0,
      ),
      throwsUnsupportedError,
    );
  });

  test('rejects a reversed activity range before making a target', () {
    expect(
      () => contract.userActivity(
        'index',
        from: DateTime(2026, 11, 18),
        to: DateTime(2026, 11, 17),
      ),
      throwsArgumentError,
    );
  });

  test('normalizes Reputation, scoring, Helpful, and vouch counts', () {
    final endpoint = contract.userReputation(
      'index',
      range: SolvedApiV4ReputationRange.year,
    );
    final actual = endpoint.decode(
      jsonDecode(fixture('v4/user_reputation.json')),
    );

    expect(endpoint.direct.path, 'users/index/reputation');
    expect(endpoint.direct.queryParameters, {'range': '1y'});
    expect(actual.reputation, 314);
    expect(actual.scoringCount, 37);
    expect(actual.helpfulCount, 19);
    expect(actual.vouchedCount, 11);
  });

  test('normalizes standalone v4 background and badge items', () {
    final background = contract.backgroundShow('anniversary_1st').decode(
          jsonDecode(fixture('v4/background_item.json')),
        );
    final badge = contract.badgeShow('boardgame').decode(
          jsonDecode(fixture('v4/badge_item.json')),
        );

    expect(background?.key, 'anniversary_1st');
    expect(background?.imageUrl, 'https://example.com/background.png');
    expect(
      background?.fallbackImageUrl,
      'https://example.com/background-fallback.png',
    );
    expect(badge.key, 'boardgame');
    expect(badge.name, 'Board Game');
    expect(badge.imageUrl, 'https://example.com/badge.png');
  });

  test('does not reinterpret one item kind as the other', () {
    expect(
      () => contract.backgroundShow('boardgame').decode(
            jsonDecode(fixture('v4/badge_item.json')),
          ),
      throwsFormatException,
    );
    expect(
      () => contract.badgeShow('anniversary_1st').decode(
            jsonDecode(fixture('v4/background_item.json')),
          ),
      throwsFormatException,
    );
  });

  test('preserves an unavailable standalone background', () {
    final actual = contract.backgroundShow('future-background').decode({
      'kind': 'background',
      'background': null,
    });

    expect(actual, isNull);
  });
}

Map<String, dynamic> _activitySource() =>
    jsonDecode(fixture('v4/user_activity_days.json')) as Map<String, dynamic>;

Map<String, dynamic> _activityDaySource() => Map<String, dynamic>.from(
      (_activitySource()['days'] as List<dynamic>).first as Map,
    );
