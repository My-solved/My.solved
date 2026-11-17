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
    final actual = contract.userProfile('index').decode(source);

    expect(actual.handle, 'index');
    expect(actual.tier, isNull);
    expect(actual.rating, 2417);
    expect(actual.solvedCount, 2048);
    expect(actual.bio, isNull);
    expect(actual.classPlus, isTrue);
    expect(actual.currentStreak, 12);
    expect(actual.maxStreak, 365);
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
    expect((source as Map<String, dynamic>)['voteCount'], 37);
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

  test('normalizes sparse activity days for an explicit date range', () {
    final endpoint = contract.userActivity(
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
    expect(actual.currentStreak, 12);
    expect(actual.maxStreak, 365);
    expect(actual.theme, isNull);
    expect(actual.firstActiveDay, '2020-01-02');
    expect(actual.days, hasLength(2));
    expect(actual.days.first.solvedCount, 4);
    expect(actual.days.first.maxSolvedLevel, 18);
    expect(actual.days.first.ratingDelta, 12);
    expect(actual.days.last.freezeUsed, isTrue);
    expect(actual.days.last.streakRepaired, isTrue);
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
