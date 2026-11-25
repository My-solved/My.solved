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
    expect(
      contract.userRatingHistory('한 글').direct.path,
      'users/%ED%95%9C%20%EA%B8%80/rating/history',
    );
    expect(
      contract.userAchievementSummary('한 글').direct.path,
      'users/%ED%95%9C%20%EA%B8%80/achievements/summary',
    );
    final achievement = contract.achievementItem(
      OfficialAchievementItemKind.badge,
      'event item',
    );
    expect(
      achievement.direct.path,
      'achievements/items/badge/event%20item',
    );
    expect(achievement.direct.queryParameters, {'lang': 'ko'});
    expect(achievement.proxy.path, achievement.direct.path);
    expect(
      achievement.proxy.queryParameters,
      achievement.direct.queryParameters,
    );
    expect(
      OfficialAchievementItemKind.values.map((kind) => kind.value),
      ['badge', 'background'],
    );

    expect(() => contract.userProfile(''), throwsArgumentError);
    expect(() => contract.userProfile('..'), throwsArgumentError);
    expect(() => contract.userRatingHistory('..'), throwsArgumentError);
    expect(() => contract.userAchievementSummary('..'), throwsArgumentError);
    expect(() => contract.badgeShow('.'), throwsArgumentError);
    expect(
      () => contract.achievementItem(OfficialAchievementItemKind.badge, '..'),
      throwsArgumentError,
    );
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
    expect(actual.userClass, 6);
    expect(actual.classPlus, isTrue);
    expect(actual.currentStreak, 12);
    expect(actual.maxStreak, 365);
    expect(actual.streakVacation, isNull);
    expect(actual.streakCountedToday, isTrue);
    expect(actual.streakFrozenYesterday, isFalse);
    expect(actual.streakTheme, isNull);
    expect(actual.isRival, isFalse);
    expect(actual.isReverseRival, isFalse);
    expect(actual.ojAccounts, hasLength(2));
    expect(actual.ojAccounts.first.ojId, 'boj');
    expect(actual.ojAccounts.first.ojName, 'Baekjoon Online Judge');
    expect(actual.ojAccounts.first.handle, 'index');
    expect(
      actual.ojAccounts.first.profileUrl,
      'https://www.acmicpc.net/user/index',
    );
    expect(actual.ojAccounts.first.logoUrl, isNull);
    expect(actual.ojAccounts.first.verified, isTrue);
    expect(actual.ojAccounts.last.ojId, 'codeforces');
    expect(actual.ojAccounts.last.profileUrl, isNull);
    expect(
      actual.ojAccounts.last.logoUrl,
      'https://example.com/codeforces.svg',
    );
    expect(actual.ojAccounts.last.verified, isFalse);
    expect(actual.linkedAccounts, hasLength(2));
    expect(
      actual.linkedAccounts.first.provider,
      OfficialUserProfileLinkedAccountProvider.discord,
    );
    expect(actual.linkedAccounts.first.name, 'index');
    expect(
      actual.linkedAccounts.first.url,
      'https://discord.com/users/123456789',
    );
    expect(
      actual.linkedAccounts.last.provider,
      OfficialUserProfileLinkedAccountProvider.icpc,
    );
    expect(actual.linkedAccounts.last.name, 'Index Team');
    expect(actual.linkedAccounts.last.url, 'https://icpc.global/ICPCID/INDEX');
    expect(actual.affiliations, hasLength(2));
    expect(actual.affiliations.first.id, 901);
    expect(actual.affiliations.first.affiliationId, 101);
    expect(actual.affiliations.first.name, 'Example University');
    expect(
      actual.affiliations.first.type,
      OfficialUserProfileAffiliationType.university,
    );
    expect(
      actual.affiliations.first.logoThumbnailUrl,
      'https://example.com/university.png',
    );
    expect(actual.affiliations.first.color, '#336699');
    expect(actual.affiliations.last.id, 902);
    expect(actual.affiliations.last.affiliationId, 202);
    expect(actual.affiliations.last.name, 'Algorithm Community');
    expect(
      actual.affiliations.last.type,
      OfficialUserProfileAffiliationType.community,
    );
    expect(actual.affiliations.last.logoThumbnailUrl, isNull);
    expect(actual.affiliations.last.color, isNull);
    expect(actual.bans, hasLength(2));
    expect(actual.bans.first.banType, OfficialUserProfileBanType.rating);
    expect(
      actual.bans.first.banReason,
      OfficialUserProfileBanReason.ratingCopiedCode,
    );
    expect(actual.bans.first.reason, 'Copied code');
    expect(actual.bans.first.until, '2027-01-01');
    expect(actual.bans.last.banType, OfficialUserProfileBanType.vote);
    expect(actual.bans.last.banReason, isNull);
    expect(actual.bans.last.reason, 'Manual review');
    expect(actual.bans.last.until, '2027-12-31');
    expect(actual.metadata.countryCode, 'KR');
    expect(actual.metadata.pronouns, 'they/them');
    expect(actual.metadata.name, 'Index');
    expect(actual.metadata.nameNative, '인덱스');
    expect(actual.metadata.birthday?.year, 1999);
    expect(actual.metadata.birthday?.month, 12);
    expect(actual.metadata.birthday?.day, 31);
    expect(actual.voteCount, 37);
    expect(actual.legacyContributionCount, isNull);
    expect(actual.reverseRivalCount, isNull);
    expect(actual.reputation, 314);
    expect(actual.backgroundId, 'anniversary_1st');
    expect(actual.background, isA<OfficialUserProfileBackground>());
    expect(actual.background?.key, 'anniversary_1st');
    expect(
      actual.background?.imageUrl,
      'https://example.com/background.png',
    );
    expect(
      actual.background?.fallbackImageUrl,
      'https://example.com/background-fallback.png',
    );
    expect(actual.background?.backgroundVideoUrl, isNull);
    expect(actual.background?.thumbnailPlaceholder, isNull);
    expect(actual.background?.isIllust, isTrue);
    expect(actual.background?.displayName, 'First Anniversary');
    expect(actual.background?.authors, isEmpty);
    expect(actual.badgeId, 'boardgame');
    expect(actual.badge, isA<OfficialUserProfileBadge>());
    expect(actual.badge?.key, 'boardgame');
    expect(actual.badge?.name, 'Board Game');
    expect(actual.badge?.imageUrl, 'https://example.com/badge.png');
    final UserProfile base = actual;
    expect(base.backgroundId, 'anniversary_1st');
    expect(base.background, same(actual.background));
    expect(base.badgeId, 'boardgame');
    expect(base.badge, same(actual.badge));
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

  test('requires every official public profile top-level field', () {
    final endpoint = contract.userProfile('index');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/user_profile.json')) as Map,
        );
    const profileFields = [
      'id',
      'handle',
      'tier',
      'profileImageUrl',
      'bio',
      'rating',
      'solvedCount',
      'voteCount',
      'reputation',
      'maxStreak',
      'currentStreak',
      'streakVacation',
      'streakCountedToday',
      'streakFrozenYesterday',
      'noRatingSolvedCount',
      'streakTheme',
      'background',
      'isRival',
      'isReverseRival',
      'ojAccounts',
      'linkedAccounts',
      'affiliations',
      'class',
      'classPlus',
      'badge',
      'ratingByProblemsSum',
      'ratingByClass',
      'ratingBySolvedCount',
      'ratingProblemsCutoff',
      'ratingProblemsHistogram',
      'bans',
      'tagRatings',
      'metadata',
    ];
    expect(profileFields, hasLength(33));

    for (final field in profileFields) {
      expect(
        () => endpoint.decode(source()..remove(field)),
        throwsFormatException,
        reason: '$field missing',
      );
    }

    for (final invalid in <Object?>[
      null,
      0,
      false,
      const <Object?>[],
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(source()..['handle'] = invalid),
        throwsFormatException,
        reason: 'handle = $invalid',
      );
    }

    for (final field in [
      'rating',
      'solvedCount',
      'voteCount',
      'reputation',
      'maxStreak',
      'currentStreak',
      'noRatingSolvedCount',
      'ratingByProblemsSum',
      'ratingByClass',
      'ratingBySolvedCount',
      'ratingProblemsCutoff',
    ]) {
      for (final invalid in <Object?>[
        null,
        1.0,
        '1',
        false,
        const <Object?>[],
        const <String, Object?>{},
      ]) {
        expect(
          () => endpoint.decode(source()..[field] = invalid),
          throwsFormatException,
          reason: '$field = $invalid',
        );
      }
    }

    final rawProfileImage = endpoint.decode(
      source()..['profileImageUrl'] = 'not a uri',
    );
    expect(rawProfileImage.profileImageUrl, 'not a uri');
  });

  test('requires exact public profile rating collection shapes', () {
    final endpoint = contract.userProfile('index');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/user_profile.json')) as Map,
        );
    Map<String, Object?> tagRating() => <String, Object?>{
          'key': 'dp',
          'rating': 1750,
          'solvedCount': 120,
          'ratingByProblemsSum': 1600,
          'ratingBySolvedCount': 150,
          'ratingProblemsCutoff': 50,
        };

    for (final invalid in <Object?>[
      null,
      0,
      false,
      'histogram',
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(
          source()..['ratingProblemsHistogram'] = invalid,
        ),
        throwsFormatException,
        reason: 'ratingProblemsHistogram = $invalid',
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
          source()..['ratingProblemsHistogram'] = <Object?>[invalid],
        ),
        throwsFormatException,
        reason: 'ratingProblemsHistogram[] = $invalid',
      );
    }

    for (final invalid in <Object?>[
      null,
      0,
      false,
      'ratings',
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(source()..['tagRatings'] = invalid),
        throwsFormatException,
        reason: 'tagRatings = $invalid',
      );
    }
    expect(
      () => endpoint.decode(source()..['tagRatings'] = <Object?>[0]),
      throwsFormatException,
      reason: 'tagRatings[] must be an object',
    );

    final invalidTagValues = <String, List<Object?>>{
      'key': [null, 0, false, const <Object?>[], const <String, Object?>{}],
      for (final field in [
        'rating',
        'solvedCount',
        'ratingByProblemsSum',
        'ratingBySolvedCount',
        'ratingProblemsCutoff',
      ])
        field: [
          null,
          1.0,
          '1',
          false,
          const <Object?>[],
          const <String, Object?>{},
        ],
    };
    for (final entry in invalidTagValues.entries) {
      expect(
        () => endpoint.decode(
          source()
            ..['tagRatings'] = <Object?>[
              tagRating()..remove(entry.key),
            ],
        ),
        throwsFormatException,
        reason: 'missing tagRatings[].${entry.key}',
      );
      for (final invalid in entry.value) {
        expect(
          () => endpoint.decode(
            source()
              ..['tagRatings'] = <Object?>[
                tagRating()..[entry.key] = invalid,
              ],
          ),
          throwsFormatException,
          reason: 'tagRatings[].${entry.key} = $invalid',
        );
      }
    }

    final empty = endpoint.decode(
      source()
        ..['ratingProblemsHistogram'] = <Object?>[]
        ..['tagRatings'] = <Object?>[],
    );
    expect(empty.ratingBreakdown?.ratingProblemsHistogram, isEmpty);
    expect(empty.tagRatings, isEmpty);
  });

  test('preserves immutable profile rating collections without inference', () {
    final endpoint = contract.userProfile('index');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/user_profile.json')) as Map,
        );
    Map<String, Object?> tagRating({
      required String key,
      required int rating,
    }) =>
        <String, Object?>{
          'key': key,
          'rating': rating,
          'solvedCount': -1,
          'ratingByProblemsSum': -2,
          'ratingBySolvedCount': -3,
          'ratingProblemsCutoff': -4,
        };

    final histogram = <Object?>[3, -1, 3];
    final first = tagRating(key: ' raw tag ', rating: -5)
      ..['ratingByClass'] = 999
      ..['futureTagRatingField'] = 'allowed';
    final second = tagRating(key: '', rating: 0);
    final tagRatings = <Object?>[second, first, second];
    final actual = endpoint.decode(
      source()
        ..['ratingProblemsHistogram'] = histogram
        ..['tagRatings'] = tagRatings
        ..['ratingByClass'] = 777
        ..['futureProfileField'] = 'allowed',
    );

    expect(actual.ratingBreakdown?.ratingProblemsHistogram, [3, -1, 3]);
    expect(actual.tagRatings.map((value) => value.key), [
      '',
      ' raw tag ',
      '',
    ]);
    expect(actual.tagRatings[1].rating, -5);
    expect(actual.tagRatings[1].solvedCount, -1);
    expect(actual.tagRatings[1].ratingByProblemsSum, -2);
    expect(actual.tagRatings[1].ratingBySolvedCount, -3);
    expect(actual.tagRatings[1].ratingProblemsCutoff, -4);
    expect(actual.ratingBreakdown?.ratingByClass, 777);
    expect(actual.tagRatings[1].ratingByClass, isNull);

    histogram[0] = 99;
    histogram.clear();
    first['key'] = 'mutated';
    second['rating'] = 42;
    tagRatings.clear();
    expect(actual.ratingBreakdown?.ratingProblemsHistogram, [3, -1, 3]);
    expect(actual.tagRatings.map((value) => value.key), [
      '',
      ' raw tag ',
      '',
    ]);
    expect(actual.tagRatings.first.rating, 0);
    expect(
      () => actual.ratingBreakdown!.ratingProblemsHistogram[0] = 999,
      throwsUnsupportedError,
    );
    expect(
      () => actual.tagRatings[0] = const ProfileTagRating(rating: 0),
      throwsUnsupportedError,
    );
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

  test('requires and preserves independent public profile rivalry flags', () {
    final endpoint = contract.userProfile('index');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/user_profile.json')) as Map,
        );

    for (final field in ['isRival', 'isReverseRival']) {
      expect(
        () => endpoint.decode(source()..remove(field)),
        throwsFormatException,
        reason: '$field missing',
      );
      for (final invalid in <Object?>[
        null,
        0,
        1,
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

    final legacy = const SolvedApiV3Contract()
        .userShow('index')
        .decode(jsonDecode(fixture('v3/user_show.json')));
    expect(legacy.reverseRivalCount, 44);

    for (final isRival in [false, true]) {
      for (final isReverseRival in [false, true]) {
        final actual = endpoint.decode(
          source()
            ..['isRival'] = isRival
            ..['isReverseRival'] = isReverseRival
            ..['futureProfileField'] = 'allowed',
        );

        expect(actual.isRival, isRival);
        expect(actual.isReverseRival, isReverseRival);
        expect(
          actual.reverseRivalCount,
          isNull,
          reason: 'v4 flags must not infer the v3 count',
        );
      }
    }
  });

  test('requires exact public profile external account shapes', () {
    final endpoint = contract.userProfile('index');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/user_profile.json')) as Map,
        );

    for (final field in ['ojAccounts', 'linkedAccounts']) {
      expect(
        () => endpoint.decode(source()..remove(field)),
        throwsFormatException,
        reason: '$field missing',
      );
      for (final invalid in <Object?>[
        null,
        0,
        false,
        'accounts',
        const <String, Object?>{},
      ]) {
        expect(
          () => endpoint.decode(source()..[field] = invalid),
          throwsFormatException,
          reason: '$field = $invalid',
        );
      }
      expect(
        () => endpoint.decode(source()..[field] = <Object?>[0]),
        throwsFormatException,
        reason: '$field item must be an object',
      );
    }

    final empty = endpoint.decode(
      source()
        ..['ojAccounts'] = <Object?>[]
        ..['linkedAccounts'] = <Object?>[],
    );
    expect(empty.ojAccounts, isEmpty);
    expect(empty.linkedAccounts, isEmpty);

    Map<String, Object?> ojAccount() => <String, Object?>{
          'ojId': 'boj',
          'ojName': 'Baekjoon Online Judge',
          'handle': 'index',
          'profileUrl': null,
          'logoUrl': null,
          'verified': true,
        };
    final invalidOjValues = <String, List<Object?>>{
      'ojId': [null, 0, false, const <Object?>[], const <String, Object?>{}],
      'ojName': [null, 0, false, const <Object?>[], const <String, Object?>{}],
      'handle': [null, 0, false, const <Object?>[], const <String, Object?>{}],
      'profileUrl': [0, false, const <Object?>[], const <String, Object?>{}],
      'logoUrl': [0, false, const <Object?>[], const <String, Object?>{}],
      'verified': [
        null,
        0,
        'true',
        const <Object?>[],
        const <String, Object?>{},
      ],
    };
    for (final entry in invalidOjValues.entries) {
      expect(
        () => endpoint.decode(
          source()..['ojAccounts'] = <Object?>[ojAccount()..remove(entry.key)],
        ),
        throwsFormatException,
        reason: 'missing ojAccounts[].${entry.key}',
      );
      for (final invalid in entry.value) {
        expect(
          () => endpoint.decode(
            source()
              ..['ojAccounts'] = <Object?>[
                ojAccount()..[entry.key] = invalid,
              ],
          ),
          throwsFormatException,
          reason: 'ojAccounts[].${entry.key} = $invalid',
        );
      }
    }

    Map<String, Object?> linkedAccount() => <String, Object?>{
          'provider': 'discord',
          'name': 'index',
          'url': 'https://example.com/account',
        };
    final invalidLinkedValues = <String, List<Object?>>{
      'provider': [
        null,
        0,
        false,
        const <Object?>[],
        const <String, Object?>{},
        '',
        'Discord',
        'discord ',
        'unknown',
      ],
      'name': [null, 0, false, const <Object?>[], const <String, Object?>{}],
      'url': [null, 0, false, const <Object?>[], const <String, Object?>{}],
    };
    for (final entry in invalidLinkedValues.entries) {
      expect(
        () => endpoint.decode(
          source()
            ..['linkedAccounts'] = <Object?>[
              linkedAccount()..remove(entry.key),
            ],
        ),
        throwsFormatException,
        reason: 'missing linkedAccounts[].${entry.key}',
      );
      for (final invalid in entry.value) {
        expect(
          () => endpoint.decode(
            source()
              ..['linkedAccounts'] = <Object?>[
                linkedAccount()..[entry.key] = invalid,
              ],
          ),
          throwsFormatException,
          reason: 'linkedAccounts[].${entry.key} = $invalid',
        );
      }
    }
  });

  test('preserves raw immutable external account lists', () {
    final endpoint = contract.userProfile('index');
    final firstOjAccount = <String, Object?>{
      'ojId': '',
      'ojName': '  ',
      'handle': ' raw handle ',
      'profileUrl': 'not a uri',
      'logoUrl': null,
      'verified': false,
      'futureOjField': 'allowed',
    };
    final secondOjAccount = <String, Object?>{
      'ojId': 'other',
      'ojName': 'Other Judge',
      'handle': 'other',
      'profileUrl': null,
      'logoUrl': '',
      'verified': true,
    };
    final ojAccounts = <Object?>[
      secondOjAccount,
      firstOjAccount,
      secondOjAccount,
    ];
    final discordAccount = <String, Object?>{
      'provider': 'discord',
      'name': '',
      'url': 'not a uri',
      'futureLinkedField': 'allowed',
    };
    final icpcAccount = <String, Object?>{
      'provider': 'icpc',
      'name': '  ',
      'url': '',
    };
    final linkedAccounts = <Object?>[
      icpcAccount,
      discordAccount,
      icpcAccount,
    ];
    final source = Map<String, dynamic>.from(
      jsonDecode(fixture('v4/user_profile.json')) as Map,
    )
      ..['ojAccounts'] = ojAccounts
      ..['linkedAccounts'] = linkedAccounts
      ..['futureProfileField'] = 'allowed';

    final actual = endpoint.decode(source);

    expect(
      OfficialUserProfileLinkedAccountProvider.values
          .map((provider) => provider.value),
      ['discord', 'icpc'],
    );
    expect(actual.ojAccounts.map((account) => account.ojId), [
      'other',
      '',
      'other',
    ]);
    expect(actual.ojAccounts[1].ojName, '  ');
    expect(actual.ojAccounts[1].handle, ' raw handle ');
    expect(actual.ojAccounts[1].profileUrl, 'not a uri');
    expect(actual.ojAccounts[1].logoUrl, isNull);
    expect(actual.ojAccounts[1].verified, isFalse);
    expect(actual.ojAccounts.first.profileUrl, isNull);
    expect(actual.ojAccounts.first.logoUrl, '');
    expect(
      actual.linkedAccounts.map((account) => account.provider),
      [
        OfficialUserProfileLinkedAccountProvider.icpc,
        OfficialUserProfileLinkedAccountProvider.discord,
        OfficialUserProfileLinkedAccountProvider.icpc,
      ],
    );
    expect(actual.linkedAccounts[1].name, '');
    expect(actual.linkedAccounts[1].url, 'not a uri');
    expect(actual.linkedAccounts.first.name, '  ');
    expect(actual.linkedAccounts.first.url, '');

    secondOjAccount['ojId'] = 'mutated';
    firstOjAccount['handle'] = 'mutated';
    ojAccounts.clear();
    icpcAccount['name'] = 'mutated';
    discordAccount['url'] = 'mutated';
    linkedAccounts.clear();
    expect(actual.ojAccounts.map((account) => account.ojId), [
      'other',
      '',
      'other',
    ]);
    expect(actual.ojAccounts[1].handle, ' raw handle ');
    expect(actual.linkedAccounts.first.name, '  ');
    expect(actual.linkedAccounts[1].url, 'not a uri');
    expect(() => actual.ojAccounts.removeAt(0), throwsUnsupportedError);
    expect(() => actual.linkedAccounts.removeAt(0), throwsUnsupportedError);
  });

  test('requires the exact public profile affiliation shape', () {
    final endpoint = contract.userProfile('index');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/user_profile.json')) as Map,
        );
    Map<String, Object?> affiliation() => <String, Object?>{
          'id': 1,
          'affiliationId': 2,
          'name': 'Example University',
          'type': 'university',
          'logoThumbnailUrl': null,
          'color': null,
        };

    expect(
      () => endpoint.decode(source()..remove('affiliations')),
      throwsFormatException,
      reason: 'affiliations missing',
    );
    for (final invalid in <Object?>[
      null,
      0,
      false,
      'affiliations',
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(source()..['affiliations'] = invalid),
        throwsFormatException,
        reason: 'affiliations = $invalid',
      );
    }
    expect(
      () => endpoint.decode(source()..['affiliations'] = <Object?>[0]),
      throwsFormatException,
      reason: 'affiliations item must be an object',
    );
    expect(
      endpoint.decode(source()..['affiliations'] = <Object?>[]).affiliations,
      isEmpty,
    );

    final invalidValues = <String, List<Object?>>{
      'id': [
        null,
        '1',
        false,
        const <Object?>[],
        const <String, Object?>{},
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ],
      'affiliationId': [
        null,
        '2',
        false,
        const <Object?>[],
        const <String, Object?>{},
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ],
      'name': [null, 0, false, const <Object?>[], const <String, Object?>{}],
      'type': [
        null,
        0,
        false,
        const <Object?>[],
        const <String, Object?>{},
        '',
        'University',
        'university ',
        'unknown',
      ],
      'logoThumbnailUrl': [
        0,
        false,
        const <Object?>[],
        const <String, Object?>{},
      ],
      'color': [0, false, const <Object?>[], const <String, Object?>{}],
    };
    for (final entry in invalidValues.entries) {
      expect(
        () => endpoint.decode(
          source()
            ..['affiliations'] = <Object?>[
              affiliation()..remove(entry.key),
            ],
        ),
        throwsFormatException,
        reason: 'missing affiliations[].${entry.key}',
      );
      for (final invalid in entry.value) {
        expect(
          () => endpoint.decode(
            source()
              ..['affiliations'] = <Object?>[
                affiliation()..[entry.key] = invalid,
              ],
          ),
          throwsFormatException,
          reason: 'affiliations[].${entry.key} = $invalid',
        );
      }
    }
  });

  test('preserves raw immutable public profile affiliations', () {
    final endpoint = contract.userProfile('index');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/user_profile.json')) as Map,
        );
    Map<String, Object?> affiliation({
      required num id,
      required num affiliationId,
      required String name,
      required String type,
      required String? logoThumbnailUrl,
      required String? color,
    }) =>
        <String, Object?>{
          'id': id,
          'affiliationId': affiliationId,
          'name': name,
          'type': type,
          'logoThumbnailUrl': logoThumbnailUrl,
          'color': color,
        };
    final wireTypes = [
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
      wireTypes,
    );
    for (final wireType in wireTypes) {
      final actual = endpoint.decode(
        source()
          ..['affiliations'] = <Object?>[
            affiliation(
              id: 1,
              affiliationId: 2,
              name: 'name',
              type: wireType,
              logoThumbnailUrl: null,
              color: null,
            ),
          ],
      );
      expect(actual.affiliations.single.type.value, wireType);
    }

    final first = affiliation(
      id: -2.5,
      affiliationId: 0,
      name: '  ',
      type: 'undefined',
      logoThumbnailUrl: 'not a uri',
      color: '',
    )..['futureAffiliationField'] = 'allowed';
    final second = affiliation(
      id: 42,
      affiliationId: 42.5,
      name: '',
      type: 'community',
      logoThumbnailUrl: null,
      color: 'not a color',
    );
    final affiliations = <Object?>[second, first, second];
    final actual = endpoint.decode(
      source()
        ..['affiliations'] = affiliations
        ..['futureProfileField'] = 'allowed',
    );

    expect(actual.affiliations.map((value) => value.id), [42, -2.5, 42]);
    expect(actual.affiliations[1].id.runtimeType, double);
    expect(actual.affiliations[1].affiliationId, 0);
    expect(actual.affiliations[1].affiliationId.runtimeType, int);
    expect(actual.affiliations[1].name, '  ');
    expect(actual.affiliations[1].logoThumbnailUrl, 'not a uri');
    expect(actual.affiliations[1].color, '');
    expect(actual.affiliations.first.affiliationId, 42.5);
    expect(actual.affiliations.first.affiliationId.runtimeType, double);
    expect(actual.affiliations.first.name, '');
    expect(actual.affiliations.first.logoThumbnailUrl, isNull);
    expect(actual.affiliations.first.color, 'not a color');

    first['name'] = 'mutated';
    second['affiliationId'] = 99;
    affiliations.clear();
    expect(actual.affiliations.map((value) => value.id), [42, -2.5, 42]);
    expect(actual.affiliations[1].name, '  ');
    expect(actual.affiliations.first.affiliationId, 42.5);
    expect(() => actual.affiliations.removeAt(0), throwsUnsupportedError);
  });

  test('requires the exact public profile ban shape', () {
    final endpoint = contract.userProfile('index');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/user_profile.json')) as Map,
        );
    Map<String, Object?> ban() => <String, Object?>{
          'banType': 'rating',
          'banReason': 'rating_copied_code',
          'reason': 'Copied code',
          'until': '2027-01-01',
        };

    expect(
      () => endpoint.decode(source()..remove('bans')),
      throwsFormatException,
      reason: 'bans missing',
    );
    for (final invalid in <Object?>[
      null,
      0,
      false,
      'bans',
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(source()..['bans'] = invalid),
        throwsFormatException,
        reason: 'bans = $invalid',
      );
    }
    expect(
      () => endpoint.decode(source()..['bans'] = <Object?>[0]),
      throwsFormatException,
      reason: 'bans item must be an object',
    );
    expect(
      endpoint.decode(source()..['bans'] = <Object?>[]).bans,
      isEmpty,
    );

    final invalidValues = <String, List<Object?>>{
      'banType': [
        null,
        0,
        false,
        const <Object?>[],
        const <String, Object?>{},
        '',
        'Rating',
        'rating ',
        'unknown',
      ],
      'banReason': [
        0,
        false,
        const <Object?>[],
        const <String, Object?>{},
        '',
        'Other',
        'other ',
        'unknown',
      ],
      'reason': [null, 0, false, const <Object?>[], const <String, Object?>{}],
      'until': [null, 0, false, const <Object?>[], const <String, Object?>{}],
    };
    for (final entry in invalidValues.entries) {
      expect(
        () => endpoint.decode(
          source()
            ..['bans'] = <Object?>[
              ban()..remove(entry.key),
            ],
        ),
        throwsFormatException,
        reason: 'missing bans[].${entry.key}',
      );
      for (final invalid in entry.value) {
        expect(
          () => endpoint.decode(
            source()
              ..['bans'] = <Object?>[
                ban()..[entry.key] = invalid,
              ],
          ),
          throwsFormatException,
          reason: 'bans[].${entry.key} = $invalid',
        );
      }
    }

    final nullable = endpoint.decode(
      source()
        ..['bans'] = <Object?>[
          ban()..['banReason'] = null,
        ],
    );
    expect(nullable.bans.single.banReason, isNull);
  });

  test('preserves raw immutable public profile bans without inference', () {
    final endpoint = contract.userProfile('index');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/user_profile.json')) as Map,
        );
    Map<String, Object?> ban({
      required String banType,
      required Object? banReason,
      required String reason,
      required String until,
    }) =>
        <String, Object?>{
          'banType': banType,
          'banReason': banReason,
          'reason': reason,
          'until': until,
        };
    final wireReasons = [
      'vote_troll_level',
      'vote_hate_speech',
      'vote_disparagement',
      'vote_profanity',
      'vote_multi_account',
      'vote_repeat_offence',
      'rating_copied_code',
      'other',
      'rating_auto_pace',
      'vote_automated',
      'vote_comment_strikes',
      'vote_mark_abuse',
    ];

    expect(
      OfficialUserProfileBanType.values.map((type) => type.value),
      ['rating', 'vote'],
    );
    expect(
      OfficialUserProfileBanReason.values.map((reason) => reason.value),
      wireReasons,
    );
    for (final wireReason in wireReasons) {
      final actual = endpoint.decode(
        source()
          ..['bans'] = <Object?>[
            ban(
              banType: 'rating',
              banReason: wireReason,
              reason: 'reason',
              until: 'until',
            ),
          ],
      );
      expect(actual.bans.single.banReason?.value, wireReason);
    }

    final ratingBan = ban(
      banType: 'rating',
      banReason: 'vote_troll_level',
      reason: '  ',
      until: 'not a date',
    )..['futureBanField'] = 'allowed';
    final voteBan = ban(
      banType: 'vote',
      banReason: 'rating_copied_code',
      reason: '',
      until: '',
    );
    final bans = <Object?>[voteBan, ratingBan, voteBan];
    final actual = endpoint.decode(
      source()
        ..['bans'] = bans
        ..['futureProfileField'] = 'allowed',
    );

    expect(
      actual.bans.map((value) => value.banType),
      [
        OfficialUserProfileBanType.vote,
        OfficialUserProfileBanType.rating,
        OfficialUserProfileBanType.vote,
      ],
    );
    expect(
      actual.bans.first.banReason,
      OfficialUserProfileBanReason.ratingCopiedCode,
    );
    expect(actual.bans.first.reason, '');
    expect(actual.bans.first.until, '');
    expect(
      actual.bans[1].banReason,
      OfficialUserProfileBanReason.voteTrollLevel,
    );
    expect(actual.bans[1].reason, '  ');
    expect(actual.bans[1].until, 'not a date');

    ratingBan['reason'] = 'mutated';
    voteBan['until'] = 'mutated';
    bans.clear();
    expect(actual.bans[1].reason, '  ');
    expect(actual.bans.first.until, '');
    expect(() => actual.bans.removeAt(0), throwsUnsupportedError);
  });

  test('requires the exact public profile metadata shape', () {
    final endpoint = contract.userProfile('index');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/user_profile.json')) as Map,
        );
    Map<String, Object?> metadata() => <String, Object?>{
          'countryCode': 'KR',
          'pronouns': 'they/them',
          'name': 'Index',
          'nameNative': '인덱스',
          'birthday': <String, Object?>{
            'year': 1999,
            'month': 12,
            'day': 31,
          },
        };

    expect(
      () => endpoint.decode(source()..remove('metadata')),
      throwsFormatException,
      reason: 'metadata missing',
    );
    for (final invalid in <Object?>[
      null,
      0,
      false,
      'metadata',
      const <Object?>[],
    ]) {
      expect(
        () => endpoint.decode(source()..['metadata'] = invalid),
        throwsFormatException,
        reason: 'metadata = $invalid',
      );
    }

    final invalidStringValues = <Object?>[
      0,
      false,
      const <Object?>[],
      const <String, Object?>{},
    ];
    for (final field in ['countryCode', 'pronouns', 'name', 'nameNative']) {
      expect(
        () => endpoint.decode(
          source()..['metadata'] = (metadata()..remove(field)),
        ),
        throwsFormatException,
        reason: 'missing metadata.$field',
      );
      for (final invalid in invalidStringValues) {
        expect(
          () => endpoint.decode(
            source()..['metadata'] = (metadata()..[field] = invalid),
          ),
          throwsFormatException,
          reason: 'metadata.$field = $invalid',
        );
      }
    }

    expect(
      () => endpoint.decode(
        source()..['metadata'] = (metadata()..remove('birthday')),
      ),
      throwsFormatException,
      reason: 'metadata.birthday missing',
    );
    for (final invalid in <Object>[
      0,
      false,
      'birthday',
      const <Object>[],
    ]) {
      expect(
        () => endpoint.decode(
          source()..['metadata'] = (metadata()..['birthday'] = invalid),
        ),
        throwsFormatException,
        reason: 'metadata.birthday = $invalid',
      );
    }

    Map<String, Object?> birthday() => <String, Object?>{
          'year': 1999,
          'month': 12,
          'day': 31,
        };
    for (final field in ['year', 'month', 'day']) {
      expect(
        () => endpoint.decode(
          source()
            ..['metadata'] =
                (metadata()..['birthday'] = (birthday()..remove(field))),
        ),
        throwsFormatException,
        reason: 'missing metadata.birthday.$field',
      );
      for (final invalid in <Object>[
        1.0,
        '1',
        false,
        const <Object>[],
        const <String, Object?>{},
      ]) {
        expect(
          () => endpoint.decode(
            source()
              ..['metadata'] =
                  (metadata()..['birthday'] = (birthday()..[field] = invalid)),
          ),
          throwsFormatException,
          reason: 'metadata.birthday.$field = $invalid',
        );
      }

      final nullableField = endpoint.decode(
        source()
          ..['metadata'] =
              (metadata()..['birthday'] = (birthday()..[field] = null)),
      );
      expect(
        <String, int?>{
          'year': nullableField.metadata.birthday?.year,
          'month': nullableField.metadata.birthday?.month,
          'day': nullableField.metadata.birthday?.day,
        }[field],
        isNull,
        reason: 'metadata.birthday.$field accepts explicit null',
      );
    }

    final nullable = endpoint.decode(
      source()
        ..['metadata'] = <String, Object?>{
          'countryCode': null,
          'pronouns': null,
          'name': null,
          'nameNative': null,
          'birthday': null,
        },
    );
    expect(nullable.metadata.countryCode, isNull);
    expect(nullable.metadata.pronouns, isNull);
    expect(nullable.metadata.name, isNull);
    expect(nullable.metadata.nameNative, isNull);
    expect(nullable.metadata.birthday, isNull);
  });

  test('preserves raw public profile metadata without inference', () {
    final endpoint = contract.userProfile('index');
    final birthday = <String, Object?>{
      'year': -1,
      'month': 13,
      'day': 0,
      'futureBirthdayField': 'allowed',
    };
    final metadata = <String, Object?>{
      'countryCode': 'not-iso',
      'pronouns': '  ',
      'name': '',
      'nameNative': ' 이름 ',
      'birthday': birthday,
      'futureMetadataField': 'allowed',
    };
    final source = Map<String, dynamic>.from(
      jsonDecode(fixture('v4/user_profile.json')) as Map,
    )
      ..['metadata'] = metadata
      ..['futureProfileField'] = 'allowed';

    final actual = endpoint.decode(source);

    expect(actual.metadata.countryCode, 'not-iso');
    expect(actual.metadata.pronouns, '  ');
    expect(actual.metadata.name, '');
    expect(actual.metadata.nameNative, ' 이름 ');
    expect(actual.metadata.birthday?.year, -1);
    expect(actual.metadata.birthday?.month, 13);
    expect(actual.metadata.birthday?.day, 0);

    birthday['year'] = 2000;
    metadata['countryCode'] = 'KR';
    metadata['birthday'] = null;
    expect(actual.metadata.countryCode, 'not-iso');
    expect(actual.metadata.birthday?.year, -1);

    final incomplete = endpoint.decode(
      Map<String, dynamic>.from(
        jsonDecode(fixture('v4/user_profile.json')) as Map,
      )..['metadata'] = <String, Object?>{
          'countryCode': null,
          'pronouns': '',
          'name': null,
          'nameNative': '  ',
          'birthday': <String, Object?>{
            'year': null,
            'month': 99,
            'day': null,
          },
        },
    );
    expect(incomplete.metadata.countryCode, isNull);
    expect(incomplete.metadata.pronouns, '');
    expect(incomplete.metadata.name, isNull);
    expect(incomplete.metadata.nameNative, '  ');
    expect(incomplete.metadata.birthday?.year, isNull);
    expect(incomplete.metadata.birthday?.month, 99);
    expect(incomplete.metadata.birthday?.day, isNull);
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

  test('requires nullable embedded profile asset keys and exact shapes', () {
    final endpoint = contract.userProfile('index');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/user_profile.json')) as Map,
        );

    for (final field in ['background', 'badge']) {
      expect(
        () => endpoint.decode(source()..remove(field)),
        throwsFormatException,
        reason: '$field missing',
      );
      for (final invalid in <Object>[
        0,
        false,
        'asset',
        const <Object>[],
      ]) {
        expect(
          () => endpoint.decode(source()..[field] = invalid),
          throwsFormatException,
          reason: '$field = $invalid',
        );
      }
    }

    final actual = endpoint.decode(
      source()
        ..['background'] = null
        ..['badge'] = null,
    );
    expect(actual.background, isNull);
    expect(actual.backgroundId, isNull);
    expect(actual.badge, isNull);
    expect(actual.badgeId, isNull);
  });

  test('strictly preserves the complete embedded profile background', () {
    final endpoint = contract.userProfile('index');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/user_profile.json')) as Map,
        );
    Map<String, dynamic> background() => Map<String, dynamic>.from(
          source()['background'] as Map,
        );
    final invalidValues = <String, List<Object?>>{
      'key': [null, 0, false, const <Object>[], const <String, Object?>{}],
      'backgroundImageUrl': [
        null,
        0,
        false,
        const <Object>[],
        const <String, Object?>{},
      ],
      'fallbackBackgroundImageUrl': [
        0,
        false,
        const <Object>[],
        const <String, Object?>{},
      ],
      'backgroundVideoUrl': [
        0,
        false,
        const <Object>[],
        const <String, Object?>{},
      ],
      'thumbnailPlaceholder': [
        0,
        false,
        const <Object>[],
        const <String, Object?>{},
      ],
      'isIllust': [
        null,
        0,
        'true',
        const <Object>[],
        const <String, Object?>{},
      ],
      'displayName': [
        0,
        false,
        const <Object>[],
        const <String, Object?>{},
      ],
      'authors': [null, 0, false, 'authors', const <String, Object?>{}],
    };

    for (final entry in invalidValues.entries) {
      final missing = background()..remove(entry.key);
      expect(
        () => endpoint.decode(source()..['background'] = missing),
        throwsFormatException,
        reason: 'missing background.${entry.key}',
      );
      for (final invalid in entry.value) {
        final malformed = background()..[entry.key] = invalid;
        expect(
          () => endpoint.decode(source()..['background'] = malformed),
          throwsFormatException,
          reason: 'background.${entry.key} = $invalid',
        );
      }
    }

    final rawBackground = background()
      ..['key'] = ' raw-key '
      ..['backgroundImageUrl'] = ''
      ..['fallbackBackgroundImageUrl'] = 'not a uri'
      ..['backgroundVideoUrl'] = '../relative-video'
      ..['thumbnailPlaceholder'] = '  '
      ..['isIllust'] = false
      ..['displayName'] = ''
      ..['authors'] = <Object>[]
      ..['futureBackgroundField'] = 'allowed';
    final actual = endpoint.decode(source()..['background'] = rawBackground);
    expect(actual.backgroundId, ' raw-key ');
    expect(actual.background?.key, ' raw-key ');
    expect(actual.background?.imageUrl, '');
    expect(actual.background?.fallbackImageUrl, 'not a uri');
    expect(actual.background?.backgroundVideoUrl, '../relative-video');
    expect(actual.background?.thumbnailPlaceholder, '  ');
    expect(actual.background?.isIllust, isFalse);
    expect(actual.background?.displayName, '');
    expect(actual.background?.authors, isEmpty);

    final nullableBackground = background()
      ..['fallbackBackgroundImageUrl'] = null
      ..['backgroundVideoUrl'] = null
      ..['thumbnailPlaceholder'] = null
      ..['displayName'] = null;
    final nullable = endpoint.decode(
      source()..['background'] = nullableBackground,
    );
    expect(nullable.background?.fallbackImageUrl, isNull);
    expect(nullable.background?.backgroundVideoUrl, isNull);
    expect(nullable.background?.thumbnailPlaceholder, isNull);
    expect(nullable.background?.displayName, isNull);
  });

  test('preserves immutable embedded background authors in wire order', () {
    final endpoint = contract.userProfile('index');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/user_profile.json')) as Map,
        );
    Map<String, dynamic> author() => <String, dynamic>{
          'key': 'author-key',
          'displayName': null,
          'role': 'illustrator',
          'authorUrl': null,
          'handle': null,
          'twitter': null,
          'instagram': null,
        };

    for (final malformed in <Object?>[
      null,
      0,
      false,
      'author',
      const <Object>[],
    ]) {
      final profile = source();
      final embedded = Map<String, dynamic>.from(profile['background'] as Map)
        ..['authors'] = <Object?>[malformed];
      expect(
        () => endpoint.decode(profile..['background'] = embedded),
        throwsFormatException,
        reason: 'background.authors[] = $malformed',
      );
    }

    for (final field in [
      'key',
      'displayName',
      'role',
      'authorUrl',
      'handle',
      'twitter',
      'instagram',
    ]) {
      final missing = author()..remove(field);
      final profile = source();
      final embedded = Map<String, dynamic>.from(profile['background'] as Map)
        ..['authors'] = <Object>[missing];
      expect(
        () => endpoint.decode(profile..['background'] = embedded),
        throwsFormatException,
        reason: 'missing background.authors[].$field',
      );
    }

    for (final field in ['key', 'role']) {
      for (final invalid in <Object?>[
        null,
        0,
        false,
        const <Object>[],
        const <String, Object?>{},
      ]) {
        final malformed = author()..[field] = invalid;
        final profile = source();
        final embedded = Map<String, dynamic>.from(profile['background'] as Map)
          ..['authors'] = <Object>[malformed];
        expect(
          () => endpoint.decode(profile..['background'] = embedded),
          throwsFormatException,
          reason: 'background.authors[].$field = $invalid',
        );
      }
    }
    for (final field in [
      'displayName',
      'authorUrl',
      'handle',
      'twitter',
      'instagram',
    ]) {
      for (final invalid in <Object>[
        0,
        false,
        const <Object>[],
        const <String, Object?>{},
      ]) {
        final malformed = author()..[field] = invalid;
        final profile = source();
        final embedded = Map<String, dynamic>.from(profile['background'] as Map)
          ..['authors'] = <Object>[malformed];
        expect(
          () => endpoint.decode(profile..['background'] = embedded),
          throwsFormatException,
          reason: 'background.authors[].$field = $invalid',
        );
      }
    }

    final first = author()
      ..['displayName'] = ''
      ..['authorUrl'] = 'not a uri'
      ..['futureAuthorField'] = 'allowed';
    final second = author()
      ..['displayName'] = '  '
      ..['handle'] = ''
      ..['twitter'] = ' twitter '
      ..['instagram'] = '';
    final sourceAuthors = <Object>[
      first,
      second,
      Map<String, dynamic>.from(first)
    ];
    final profile = source();
    final embedded = Map<String, dynamic>.from(profile['background'] as Map)
      ..['authors'] = sourceAuthors;
    final actual = endpoint.decode(profile..['background'] = embedded);

    first['key'] = 'mutated';
    (sourceAuthors[1] as Map<String, dynamic>)['displayName'] = 'mutated';
    sourceAuthors.clear();
    embedded['authors'] = <Object>[];

    expect(actual.background?.authors, hasLength(3));
    expect(
      actual.background?.authors.map((value) => value.key),
      ['author-key', 'author-key', 'author-key'],
    );
    expect(
      actual.background?.authors.map((value) => value.displayName),
      ['', '  ', ''],
    );
    expect(actual.background?.authors.first.authorUrl, 'not a uri');
    expect(actual.background?.authors[1].handle, '');
    expect(actual.background?.authors[1].twitter, ' twitter ');
    expect(actual.background?.authors[1].instagram, '');
    expect(
      () => actual.background!.authors.add(actual.background!.authors.first),
      throwsUnsupportedError,
    );
    expect(
      () => actual.background!.authors[0] =
          const OfficialUserProfileBackgroundAuthor(
        key: 'replacement',
        displayName: null,
        role: 'replacement',
        authorUrl: null,
        handle: null,
        twitter: null,
        instagram: null,
      ),
      throwsUnsupportedError,
    );
  });

  test('strictly preserves the embedded profile badge', () {
    final endpoint = contract.userProfile('index');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/user_profile.json')) as Map,
        );
    Map<String, dynamic> badge() => Map<String, dynamic>.from(
          source()['badge'] as Map,
        );

    for (final field in ['key', 'name', 'imageUrl']) {
      final missing = badge()..remove(field);
      expect(
        () => endpoint.decode(source()..['badge'] = missing),
        throwsFormatException,
        reason: 'missing badge.$field',
      );
      for (final invalid in <Object?>[
        null,
        0,
        false,
        const <Object>[],
        const <String, Object?>{},
      ]) {
        final malformed = badge()..[field] = invalid;
        expect(
          () => endpoint.decode(source()..['badge'] = malformed),
          throwsFormatException,
          reason: 'badge.$field = $invalid',
        );
      }
    }

    final rawBadge = badge()
      ..['key'] = ''
      ..['name'] = '  '
      ..['imageUrl'] = 'not a uri'
      ..['futureBadgeField'] = 'allowed';
    final actual = endpoint.decode(source()..['badge'] = rawBadge);
    expect(actual.badgeId, '');
    expect(actual.badge?.key, '');
    expect(actual.badge?.name, '  ');
    expect(actual.badge?.imageUrl, 'not a uri');
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

  test('enforces the official public profile class bounds without inference',
      () {
    final endpoint = contract.userProfile('index');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/user_profile.json')) as Map,
        );

    expect(
      () => endpoint.decode(source()..remove('class')),
      throwsFormatException,
    );
    for (final invalid in <Object?>[
      null,
      6.0,
      '6',
      false,
      const <Object?>[],
      const <String, Object?>{},
      -1,
      11,
    ]) {
      expect(
        () => endpoint.decode(source()..['class'] = invalid),
        throwsFormatException,
        reason: 'class = $invalid',
      );
    }

    final lower = endpoint.decode(
      source()
        ..['class'] = 0
        ..['classPlus'] = true,
    );
    expect(lower.userClass, 0);
    expect(lower.classPlus, isTrue);

    final middle = endpoint.decode(source()..['class'] = 6);
    expect(middle.userClass, 6);

    final upper = endpoint.decode(
      source()
        ..['class'] = 10
        ..['classPlus'] = false,
    );
    expect(upper.userClass, 10);
    expect(upper.classPlus, isFalse);
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

  test('encodes the complete four-digit activity query year range', () {
    final endpoint = contract.userActivity(
      'index',
      from: DateTime.utc(0, 1, 2, 23, 59),
      to: DateTime.utc(9999, 12, 31, 1),
    );

    expect(endpoint.direct.queryParameters, {
      'from': '0000-01-02',
      'to': '9999-12-31',
    });
    expect(endpoint.proxy.queryParameters, endpoint.direct.queryParameters);
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

  test('rejects activity query years outside the official pattern', () {
    final invalidCases = <({String name, DateTime value})>[
      (name: 'from', value: DateTime.utc(-1, 1, 1)),
      (name: 'from', value: DateTime.utc(10000, 1, 1)),
      (name: 'to', value: DateTime.utc(-1, 1, 1)),
      (name: 'to', value: DateTime.utc(10000, 1, 1)),
    ];

    for (final invalid in invalidCases) {
      final from =
          invalid.name == 'from' ? invalid.value : DateTime.utc(2026, 11, 1);
      final to =
          invalid.name == 'to' ? invalid.value : DateTime.utc(2026, 11, 17);
      expect(
        () => contract.userActivity('index', from: from, to: to),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', invalid.name)
              .having(
                (error) => error.invalidValue,
                'invalidValue',
                same(invalid.value),
              ),
        ),
        reason: '${invalid.name} = ${invalid.value.year}',
      );
    }
  });

  test('normalizes the complete official reputation result', () {
    final endpoint = contract.userReputation(
      'index',
      range: SolvedApiV4ReputationRange.year,
    );
    final ProfileReputationResult actual = endpoint.decode(
      jsonDecode(fixture('v4/user_reputation.json')),
    );

    expect(endpoint.direct.path, 'users/index/reputation');
    expect(endpoint.direct.queryParameters, {'range': '1y'});
    expect(actual.reputation, 314);
    expect(actual.scoringCount, 37);
    expect(actual.helpfulCount, 19);
    expect(actual.vouchedCount, 11);
    expect(actual.history, hasLength(1));
    expect(actual.history.single.day, '2026-11-17');
    expect(actual.history.single.value, 314);
    expect(actual.today.contributions.count, 2);
    expect(actual.today.contributions.max, 10);
    expect(actual.today.helpful.earned, 1);
    expect(actual.today.helpful.cap, 5);
    final ProfileContributionStats summary = actual;
    expect(summary, same(actual));
  });

  test('encodes every optional reputation range and its omission', () {
    expect(
      SolvedApiV4ReputationRange.values.map((range) => range.value),
      ['90d', '1y', 'all'],
    );
    for (final range in SolvedApiV4ReputationRange.values) {
      final endpoint = contract.userReputation('index', range: range);
      expect(endpoint.direct.queryParameters, {'range': range.value});
      expect(endpoint.proxy.queryParameters, {'range': range.value});
    }

    final omitted = contract.userReputation('index');
    expect(omitted.direct.queryParameters, isEmpty);
    expect(omitted.proxy.queryParameters, isEmpty);
  });

  test('requires the exact complete reputation response shape', () {
    final endpoint = contract.userReputation('index');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/user_reputation.json')) as Map,
        );
    Map<String, Object?> historyEntry() => <String, Object?>{
          'day': '2026-11-17',
          'value': 314,
        };
    Map<String, Object?> today() => <String, Object?>{
          'contributions': <String, Object?>{'count': 2, 'max': 10},
          'helpful': <String, Object?>{'earned': 1, 'cap': 5},
        };

    for (final field in [
      'reputation',
      'scoringCount',
      'helpfulCount',
      'vouchedCount',
      'history',
      'today',
    ]) {
      expect(
        () => endpoint.decode(source()..remove(field)),
        throwsFormatException,
        reason: '$field missing',
      );
    }
    for (final field in [
      'reputation',
      'scoringCount',
      'helpfulCount',
      'vouchedCount',
    ]) {
      for (final invalid in <Object?>[
        null,
        1.0,
        '1',
        false,
        const <Object?>[],
        const <String, Object?>{},
      ]) {
        expect(
          () => endpoint.decode(source()..[field] = invalid),
          throwsFormatException,
          reason: '$field = $invalid',
        );
      }
    }

    for (final invalid in <Object?>[
      null,
      0,
      false,
      'history',
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(source()..['history'] = invalid),
        throwsFormatException,
        reason: 'history = $invalid',
      );
    }
    expect(
      () => endpoint.decode(source()..['history'] = <Object?>[0]),
      throwsFormatException,
      reason: 'history[] must be an object',
    );
    for (final field in ['day', 'value']) {
      expect(
        () => endpoint.decode(
          source()
            ..['history'] = <Object?>[
              historyEntry()..remove(field),
            ],
        ),
        throwsFormatException,
        reason: 'history[].$field missing',
      );
    }
    for (final invalid in <Object?>[
      null,
      0,
      false,
      const <Object?>[],
      const <String, Object?>{},
      '',
      '2026-1-01',
      '2026-01-1',
      ' 2026-01-01',
      '2026-01-01 ',
    ]) {
      expect(
        () => endpoint.decode(
          source()
            ..['history'] = <Object?>[
              historyEntry()..['day'] = invalid,
            ],
        ),
        throwsFormatException,
        reason: 'history[].day = $invalid',
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
          source()
            ..['history'] = <Object?>[
              historyEntry()..['value'] = invalid,
            ],
        ),
        throwsFormatException,
        reason: 'history[].value = $invalid',
      );
    }

    for (final invalid in <Object?>[
      null,
      0,
      false,
      'today',
      const <Object?>[],
    ]) {
      expect(
        () => endpoint.decode(source()..['today'] = invalid),
        throwsFormatException,
        reason: 'today = $invalid',
      );
    }
    for (final section in ['contributions', 'helpful']) {
      expect(
        () => endpoint.decode(source()..['today'] = (today()..remove(section))),
        throwsFormatException,
        reason: 'today.$section missing',
      );
      for (final invalid in <Object?>[
        null,
        0,
        false,
        'section',
        const <Object?>[],
      ]) {
        expect(
          () => endpoint.decode(
            source()..['today'] = (today()..[section] = invalid),
          ),
          throwsFormatException,
          reason: 'today.$section = $invalid',
        );
      }
    }

    final nestedFields = <String, List<String>>{
      'contributions': ['count', 'max'],
      'helpful': ['earned', 'cap'],
    };
    for (final section in nestedFields.entries) {
      for (final field in section.value) {
        Map<String, Object?> nested() => Map<String, Object?>.from(
              today()[section.key] as Map,
            );
        expect(
          () => endpoint.decode(
            source()
              ..['today'] =
                  (today()..[section.key] = (nested()..remove(field))),
          ),
          throwsFormatException,
          reason: 'today.${section.key}.$field missing',
        );
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
              source()
                ..['today'] =
                    (today()..[section.key] = (nested()..[field] = invalid)),
            ),
            throwsFormatException,
            reason: 'today.${section.key}.$field = $invalid',
          );
        }
      }
    }
  });

  test('preserves raw immutable reputation details without inference', () {
    final endpoint = contract.userReputation('index');
    final first = <String, Object?>{
      'day': '0000-00-00',
      'value': -7,
      'futureHistoryField': 'allowed',
    };
    final second = <String, Object?>{
      'day': '9999-99-99',
      'value': 0,
    };
    final history = <Object?>[second, first, second];
    final contributions = <String, Object?>{
      'count': 10,
      'max': -1,
      'futureContributionsField': 'allowed',
    };
    final helpful = <String, Object?>{
      'earned': 8,
      'cap': -2,
      'futureHelpfulField': 'allowed',
    };
    final today = <String, Object?>{
      'contributions': contributions,
      'helpful': helpful,
      'futureTodayField': 'allowed',
    };
    final source = <String, Object?>{
      'reputation': -1,
      'scoringCount': -2,
      'helpfulCount': -3,
      'vouchedCount': -4,
      'history': history,
      'today': today,
      'futureReputationField': 'allowed',
    };

    final actual = endpoint.decode(source);
    expect(actual.reputation, -1);
    expect(actual.scoringCount, -2);
    expect(actual.helpfulCount, -3);
    expect(actual.vouchedCount, -4);
    expect(actual.history.map((entry) => entry.day), [
      '9999-99-99',
      '0000-00-00',
      '9999-99-99',
    ]);
    expect(actual.history.map((entry) => entry.value), [0, -7, 0]);
    expect(actual.today.contributions.count, 10);
    expect(actual.today.contributions.max, -1);
    expect(actual.today.helpful.earned, 8);
    expect(actual.today.helpful.cap, -2);

    second['day'] = '2026-01-01';
    first['value'] = 99;
    history.clear();
    contributions['count'] = 0;
    helpful['cap'] = 0;
    today.clear();
    source.clear();
    expect(actual.history.map((entry) => entry.day), [
      '9999-99-99',
      '0000-00-00',
      '9999-99-99',
    ]);
    expect(actual.history[1].value, -7);
    expect(actual.today.contributions.count, 10);
    expect(actual.today.helpful.cap, -2);
    expect(() => actual.history.removeAt(0), throwsUnsupportedError);
    expect(
      () => actual.history[0] = const ProfileReputationHistoryEntry(
        day: '2026-01-01',
        value: 0,
      ),
      throwsUnsupportedError,
    );

    final empty = endpoint.decode({
      'reputation': 0,
      'scoringCount': 0,
      'helpfulCount': 0,
      'vouchedCount': 0,
      'history': <Object?>[],
      'today': <String, Object?>{
        'contributions': <String, Object?>{'count': 0, 'max': 0},
        'helpful': <String, Object?>{'earned': 0, 'cap': 0},
      },
    });
    expect(empty.history, isEmpty);
  });

  test('normalizes the official rating history result', () {
    final endpoint = contract.userRatingHistory(
      'index',
      range: SolvedApiV4RatingHistoryRange.year,
    );
    final ProfileRatingHistoryResult actual = endpoint.decode(
      jsonDecode(fixture('v4/user_rating_history.json')),
    );

    expect(endpoint.direct.path, 'users/index/rating/history');
    expect(endpoint.direct.queryParameters, {'range': '1y'});
    expect(endpoint.proxy.path, endpoint.direct.path);
    expect(endpoint.proxy.queryParameters, endpoint.direct.queryParameters);
    expect(actual.history.map((entry) => entry.day), [
      '2026-11-01',
      '2026-11-17',
    ]);
    expect(actual.history.map((entry) => entry.value), [2400, 2417]);
  });

  test('encodes every optional rating history range and its omission', () {
    expect(
      SolvedApiV4RatingHistoryRange.values.map((range) => range.value),
      ['90d', '1y', 'all'],
    );
    for (final range in SolvedApiV4RatingHistoryRange.values) {
      final endpoint = contract.userRatingHistory('index', range: range);
      expect(endpoint.direct.queryParameters, {'range': range.value});
      expect(endpoint.proxy.queryParameters, {'range': range.value});
    }

    final omitted = contract.userRatingHistory('index');
    expect(omitted.direct.queryParameters, isEmpty);
    expect(omitted.proxy.queryParameters, isEmpty);
  });

  test('requires the exact rating history response shape', () {
    final endpoint = contract.userRatingHistory('index');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/user_rating_history.json')) as Map,
        );
    Map<String, Object?> historyEntry() => <String, Object?>{
          'day': '2026-11-17',
          'value': 2417,
        };

    for (final invalid in <Object?>[
      null,
      0,
      false,
      const <Object?>[],
    ]) {
      expect(
        () => endpoint.decode(invalid),
        throwsFormatException,
        reason: 'response = $invalid',
      );
    }
    expect(
      () => endpoint.decode(source()..remove('history')),
      throwsFormatException,
      reason: 'history missing',
    );
    for (final invalid in <Object?>[
      null,
      0,
      false,
      'history',
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(source()..['history'] = invalid),
        throwsFormatException,
        reason: 'history = $invalid',
      );
    }
    expect(
      () => endpoint.decode(source()..['history'] = <Object?>[0]),
      throwsFormatException,
      reason: 'history[] must be an object',
    );
    for (final field in ['day', 'value']) {
      expect(
        () => endpoint.decode(
          source()
            ..['history'] = <Object?>[
              historyEntry()..remove(field),
            ],
        ),
        throwsFormatException,
        reason: 'history[].$field missing',
      );
    }
    for (final invalid in <Object?>[
      null,
      0,
      false,
      const <Object?>[],
      const <String, Object?>{},
      '',
      '2026-1-01',
      '2026-01-1',
      ' 2026-01-01',
      '2026-01-01 ',
    ]) {
      expect(
        () => endpoint.decode(
          source()
            ..['history'] = <Object?>[
              historyEntry()..['day'] = invalid,
            ],
        ),
        throwsFormatException,
        reason: 'history[].day = $invalid',
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
          source()
            ..['history'] = <Object?>[
              historyEntry()..['value'] = invalid,
            ],
        ),
        throwsFormatException,
        reason: 'history[].value = $invalid',
      );
    }
  });

  test('preserves raw immutable rating history without sorting', () {
    final endpoint = contract.userRatingHistory('index');
    final first = <String, Object?>{
      'day': '0000-00-00',
      'value': -7,
      'futureHistoryField': 'allowed',
    };
    final second = <String, Object?>{
      'day': '9999-99-99',
      'value': 0,
    };
    final history = <Object?>[second, first, second];
    final source = <String, Object?>{
      'history': history,
      'futureRatingHistoryField': 'allowed',
    };

    final actual = endpoint.decode(source);
    expect(actual.history.map((entry) => entry.day), [
      '9999-99-99',
      '0000-00-00',
      '9999-99-99',
    ]);
    expect(actual.history.map((entry) => entry.value), [0, -7, 0]);

    second['day'] = '2026-01-01';
    first['value'] = 99;
    history.clear();
    source.clear();
    expect(actual.history.map((entry) => entry.day), [
      '9999-99-99',
      '0000-00-00',
      '9999-99-99',
    ]);
    expect(actual.history[1].value, -7);
    expect(() => actual.history.removeAt(0), throwsUnsupportedError);
    expect(
      () => actual.history[0] = const ProfileRatingHistoryEntry(
        day: '2026-01-01',
        value: 0,
      ),
      throwsUnsupportedError,
    );

    expect(endpoint.decode({'history': <Object?>[]}).history, isEmpty);
  });

  test('normalizes the official achievement summary result', () {
    final endpoint = contract.userAchievementSummary('index');
    final ProfileAchievementSummaryResult actual = endpoint.decode(
      jsonDecode(fixture('v4/user_achievement_summary.json')),
    );

    expect(endpoint.direct.path, 'users/index/achievements/summary');
    expect(endpoint.direct.queryParameters, {'lang': 'ko'});
    expect(endpoint.proxy.path, endpoint.direct.path);
    expect(endpoint.proxy.queryParameters, endpoint.direct.queryParameters);
    expect(actual.earned, 12);
    expect(actual.total, 34);
    expect(actual.past, 2);
    expect(actual.badges, 7);
    expect(actual.backgrounds, 5);
    expect(actual.recent, hasLength(2));
    expect(actual.recent.first.kind, OfficialAchievementItemKind.badge);
    expect(actual.recent.first.id, 101);
    expect(actual.recent.first.key, 'boardgame');
    expect(actual.recent.first.name, 'Board Game');
    expect(actual.recent.first.imageUrl, 'https://example.com/badge.png');
    expect(actual.recent.first.category, 'event');
    expect(actual.recent.first.addedAt, '2020-01-01T00:00:00Z');
    expect(actual.recent.first.acquiredAt, '2026-11-24T00:00:00Z');
    expect(actual.recent.last.kind, OfficialAchievementItemKind.background);
    expect(actual.recent.last.id, 202);
    expect(actual.recent.last.key, 'anniversary_1st');
    expect(actual.recent.last.name, 'First Anniversary');
    expect(
      actual.recent.last.imageUrl,
      'https://example.com/background-thumbnail.png',
    );
    expect(actual.recent.last.category, 'event');
    expect(actual.recent.last.addedAt, '2021-01-01T00:00:00Z');
    expect(actual.recent.last.acquiredAt, '2026-11-25T00:00:00Z');
  });

  test('requires the exact achievement summary response shape', () {
    final endpoint = contract.userAchievementSummary('index');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/user_achievement_summary.json')) as Map,
        );
    Map<String, Object?> recentItem() => <String, Object?>{
          'kind': 'badge',
          'id': 1,
          'key': 'key',
          'name': 'name',
          'imageUrl': 'image',
          'category': 'category',
          'addedAt': 'added',
          'acquiredAt': 'acquired',
        };

    for (final invalid in <Object?>[
      null,
      0,
      false,
      const <Object?>[],
    ]) {
      expect(
        () => endpoint.decode(invalid),
        throwsFormatException,
        reason: 'response = $invalid',
      );
    }
    for (final field in [
      'earned',
      'total',
      'past',
      'badges',
      'backgrounds',
      'recent',
    ]) {
      expect(
        () => endpoint.decode(source()..remove(field)),
        throwsFormatException,
        reason: '$field missing',
      );
    }
    for (final field in [
      'earned',
      'total',
      'past',
      'badges',
      'backgrounds',
    ]) {
      for (final invalid in <Object?>[
        null,
        1.0,
        '1',
        false,
        const <Object?>[],
        const <String, Object?>{},
      ]) {
        expect(
          () => endpoint.decode(source()..[field] = invalid),
          throwsFormatException,
          reason: '$field = $invalid',
        );
      }
    }
    for (final invalid in <Object?>[
      null,
      0,
      false,
      'recent',
      const <String, Object?>{},
    ]) {
      expect(
        () => endpoint.decode(source()..['recent'] = invalid),
        throwsFormatException,
        reason: 'recent = $invalid',
      );
    }
    expect(
      () => endpoint.decode(source()..['recent'] = <Object?>[0]),
      throwsFormatException,
      reason: 'recent[] must be an object',
    );
    expect(
      () => endpoint.decode(
        source()
          ..['recent'] = <Object?>[
            recentItem(),
            recentItem()..remove('acquiredAt'),
          ],
      ),
      throwsFormatException,
      reason: 'every recent item must be decoded eagerly',
    );
    for (final field in [
      'kind',
      'id',
      'key',
      'name',
      'imageUrl',
      'category',
      'addedAt',
      'acquiredAt',
    ]) {
      expect(
        () => endpoint.decode(
          source()
            ..['recent'] = <Object?>[
              recentItem()..remove(field),
            ],
        ),
        throwsFormatException,
        reason: 'recent[].$field missing',
      );
    }
    for (final invalid in <Object?>[
      null,
      0,
      false,
      const <Object?>[],
      const <String, Object?>{},
      'Badge',
      ' badge',
      'badge ',
      'achievement',
    ]) {
      expect(
        () => endpoint.decode(
          source()
            ..['recent'] = <Object?>[
              recentItem()..['kind'] = invalid,
            ],
        ),
        throwsFormatException,
        reason: 'recent[].kind = $invalid',
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
          source()
            ..['recent'] = <Object?>[
              recentItem()..['id'] = invalid,
            ],
        ),
        throwsFormatException,
        reason: 'recent[].id = $invalid',
      );
    }
    for (final field in [
      'key',
      'name',
      'imageUrl',
      'category',
      'addedAt',
      'acquiredAt',
    ]) {
      for (final invalid in <Object?>[
        null,
        0,
        false,
        const <Object?>[],
        const <String, Object?>{},
      ]) {
        expect(
          () => endpoint.decode(
            source()
              ..['recent'] = <Object?>[
                recentItem()..[field] = invalid,
              ],
          ),
          throwsFormatException,
          reason: 'recent[].$field = $invalid',
        );
      }
    }
  });

  test('preserves raw immutable achievement summary without inference', () {
    final endpoint = contract.userAchievementSummary('index');
    final first = <String, Object?>{
      'kind': 'badge',
      'id': -5,
      'key': '',
      'name': ' ',
      'imageUrl': 'not a uri',
      'category': '',
      'addedAt': 'not a date',
      'acquiredAt': 'still not a date',
      'futureRecentField': 'allowed',
    };
    final second = <String, Object?>{
      'kind': 'background',
      'id': 0,
      'key': 'background',
      'name': 'Background',
      'imageUrl': 'image',
      'category': 'category',
      'addedAt': 'added',
      'acquiredAt': 'acquired',
    };
    final recent = <Object?>[second, first, second];
    final source = <String, Object?>{
      'earned': -1,
      'total': -2,
      'past': -3,
      'badges': 99,
      'backgrounds': -4,
      'recent': recent,
      'futureSummaryField': 'allowed',
    };

    final actual = endpoint.decode(source);
    expect(actual.earned, -1);
    expect(actual.total, -2);
    expect(actual.past, -3);
    expect(actual.badges, 99);
    expect(actual.backgrounds, -4);
    expect(actual.recent.map((item) => item.kind), [
      OfficialAchievementItemKind.background,
      OfficialAchievementItemKind.badge,
      OfficialAchievementItemKind.background,
    ]);
    expect(actual.recent.map((item) => item.id), [0, -5, 0]);
    expect(actual.recent[1].key, '');
    expect(actual.recent[1].name, ' ');
    expect(actual.recent[1].imageUrl, 'not a uri');
    expect(actual.recent[1].addedAt, 'not a date');
    expect(actual.recent[1].acquiredAt, 'still not a date');

    second['kind'] = 'badge';
    first['id'] = 9;
    recent.clear();
    source.clear();
    expect(actual.earned, -1);
    expect(actual.recent.map((item) => item.kind), [
      OfficialAchievementItemKind.background,
      OfficialAchievementItemKind.badge,
      OfficialAchievementItemKind.background,
    ]);
    expect(actual.recent[1].id, -5);
    expect(() => actual.recent.removeAt(0), throwsUnsupportedError);
    expect(
      () => actual.recent[0] = const ProfileAchievementSummaryRecentItem(
        kind: OfficialAchievementItemKind.badge,
        id: 1,
        key: 'key',
        name: 'name',
        imageUrl: 'image',
        category: 'category',
        addedAt: 'added',
        acquiredAt: 'acquired',
      ),
      throwsUnsupportedError,
    );

    expect(
      endpoint.decode({
        'earned': 0,
        'total': 0,
        'past': 0,
        'badges': 0,
        'backgrounds': 0,
        'recent': <Object?>[],
      }).recent,
      isEmpty,
    );
  });

  test('normalizes standalone v4 background and badge items', () {
    final OfficialAchievementItem item = contract
        .achievementItem(
          OfficialAchievementItemKind.background,
          'anniversary_1st',
        )
        .decode(jsonDecode(fixture('v4/background_item.json')));
    final emptyItem = contract
        .achievementItem(OfficialAchievementItemKind.badge, 'boardgame')
        .decode(jsonDecode(fixture('v4/badge_item.json')));
    final background = contract.backgroundShow('anniversary_1st').decode(
          jsonDecode(fixture('v4/background_item.json')),
        );
    final badge = contract.badgeShow('boardgame').decode(
          jsonDecode(fixture('v4/badge_item.json')),
        );

    expect(item.kind, OfficialAchievementItemKind.background);
    expect(item.id, 101);
    expect(item.key, 'anniversary_1st');
    expect(item.name, 'First Anniversary');
    expect(item.imageUrl, 'https://example.com/background-thumbnail.png');
    expect(item.category, 'event');
    expect(item.addedAt, '2020-01-01T00:00:00Z');
    expect(item.unlockedByDefault, isFalse);
    expect(item.owned, isNull);
    expect(item.equipped, isNull);
    expect(item.userCount, 1);
    expect(item.background?.key, 'anniversary_1st');
    expect(item.background?.backgroundVideoUrl, isNull);
    expect(item.background?.authors.single.key, 'illustrator');
    expect(item.credits.single.key, 'designer');
    expect(item.achievements.single.key, 'first_solve');
    expect(item.achievements.single.condition, isNull);
    expect(item.achievements.single.historic, isFalse);
    expect(item.achievements.single.hidden, isFalse);
    expect(item.achievements.single.holderCount, 1);
    expect(
      item.achievements.single.earnedAt,
      '2026-11-25T00:00:00Z',
    );
    final problem = item.achievements.single.problems.single;
    expect(problem.problemId, 1000);
    expect(problem.level, 1);
    expect(problem.effectiveVoteCount, 3);
    expect(problem.givesNoRating, isFalse);
    expect(problem.isStandard, isTrue);
    expect(problem.userStatus, ProblemUserStatus.solved);
    expect(problem.titles.single.language, 'ko');
    expect(problem.titles.single.title, 'A+B');
    expect(problem.titles.single.isOriginal, isTrue);
    expect(problem.titles.single.latex, isFalse);
    expect(problem.titles.single.html, isFalse);
    expect(emptyItem.kind, OfficialAchievementItemKind.badge);
    expect(emptyItem.background, isNull);
    expect(emptyItem.achievements, isEmpty);
    expect(background?.key, 'anniversary_1st');
    expect(background?.imageUrl, 'https://example.com/background.png');
    expect(
      background?.fallbackImageUrl,
      'https://example.com/background-fallback.png',
    );
    expect(background, isNot(isA<OfficialUserProfileBackground>()));
    expect(badge.key, 'boardgame');
    expect(badge.name, 'Board Game');
    expect(badge.imageUrl, 'https://example.com/badge.png');
    expect(badge, isNot(isA<OfficialUserProfileBadge>()));
  });

  test('does not reinterpret one item kind as the other', () {
    expect(
      () => contract
          .achievementItem(
            OfficialAchievementItemKind.background,
            'boardgame',
          )
          .decode(jsonDecode(fixture('v4/badge_item.json'))),
      throwsFormatException,
    );
    expect(
      () => contract
          .achievementItem(
            OfficialAchievementItemKind.badge,
            'anniversary_1st',
          )
          .decode(jsonDecode(fixture('v4/background_item.json'))),
      throwsFormatException,
    );
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

  test('requires the complete standalone achievement item envelope', () {
    final endpoint = contract.badgeShow('boardgame');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/badge_item.json')) as Map,
        );
    const fields = [
      'kind',
      'id',
      'key',
      'name',
      'imageUrl',
      'category',
      'addedAt',
      'unlockedByDefault',
      'owned',
      'equipped',
      'background',
      'credits',
      'userCount',
      'achievements',
    ];

    for (final field in fields) {
      expect(
        () => endpoint.decode(source()..remove(field)),
        throwsFormatException,
        reason: '$field missing',
      );
    }

    final invalidValues = <String, List<Object?>>{
      'kind': [
        null,
        0,
        false,
        const <Object?>[],
        const <String, Object?>{},
        '',
        'Badge',
        'badge ',
        'unknown',
      ],
      'id': [
        null,
        1.0,
        '1',
        false,
        const <Object?>[],
        const <String, Object?>{},
      ],
      for (final field in ['key', 'name', 'imageUrl', 'category', 'addedAt'])
        field: [
          null,
          0,
          false,
          const <Object?>[],
          const <String, Object?>{},
        ],
      'unlockedByDefault': [
        null,
        0,
        'false',
        const <Object?>[],
        const <String, Object?>{},
      ],
      for (final field in ['owned', 'equipped'])
        field: [
          0,
          'false',
          const <Object?>[],
          const <String, Object?>{},
        ],
      'background': [
        0,
        false,
        'background',
        const <Object?>[],
      ],
      'credits': [
        null,
        0,
        false,
        'credits',
        const <String, Object?>{},
      ],
      'userCount': [
        null,
        1.0,
        '1',
        false,
        const <Object?>[],
        const <String, Object?>{},
        -1,
      ],
      'achievements': [
        null,
        0,
        false,
        'achievements',
        const <String, Object?>{},
      ],
    };
    for (final entry in invalidValues.entries) {
      for (final invalid in entry.value) {
        expect(
          () => endpoint.decode(source()..[entry.key] = invalid),
          throwsFormatException,
          reason: '${entry.key} = $invalid',
        );
      }
    }

    final raw = endpoint.decode(
      source()
        ..['id'] = -7
        ..['key'] = ''
        ..['name'] = '  '
        ..['imageUrl'] = 'not a uri'
        ..['category'] = ''
        ..['addedAt'] = 'not a date'
        ..['unlockedByDefault'] = true
        ..['owned'] = true
        ..['equipped'] = false
        ..['userCount'] = 0
        ..['futureItemField'] = 'allowed',
    );
    expect(raw.key, '');
    expect(raw.name, '  ');
    expect(raw.imageUrl, 'not a uri');
  });

  test('requires every nested standalone achievement field', () {
    final endpoint = contract.achievementItem(
      OfficialAchievementItemKind.background,
      'anniversary_1st',
    );
    Map<String, dynamic> source() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/background_item.json')) as Map,
        );
    Map<String, Object?> title() => <String, Object?>{
          'language': 'ko',
          'title': 'A+B',
          'isOriginal': true,
          'latex': false,
          'html': false,
        };
    Map<String, Object?> problem() => <String, Object?>{
          'problemId': 1000,
          'level': 1,
          'effectiveVoteCount': 3,
          'givesNoRating': false,
          'isStandard': true,
          'titles': <Object?>[title()],
          'userStatus': 'solved',
        };
    Map<String, Object?> achievement() => <String, Object?>{
          'key': 'first_solve',
          'name': 'First Solve',
          'condition': null,
          'historic': false,
          'hidden': false,
          'holderCount': 1,
          'earnedAt': null,
          'problems': <Object?>[problem()],
        };

    expect(
      () => endpoint.decode(source()..['achievements'] = <Object?>[0]),
      throwsFormatException,
    );
    final invalidAchievementValues = <String, List<Object?>>{
      'key': [null, 0, false, const <Object?>[], const <String, Object?>{}],
      'name': [null, 0, false, const <Object?>[], const <String, Object?>{}],
      'condition': [0, false, const <Object?>[], const <String, Object?>{}],
      'historic': [
        null,
        0,
        'false',
        const <Object?>[],
        const <String, Object?>{},
      ],
      'hidden': [
        null,
        0,
        'false',
        const <Object?>[],
        const <String, Object?>{},
      ],
      'holderCount': [
        null,
        1.0,
        '1',
        false,
        const <Object?>[],
        const <String, Object?>{},
      ],
      'earnedAt': [0, false, const <Object?>[], const <String, Object?>{}],
      'problems': [
        null,
        0,
        false,
        'problems',
        const <String, Object?>{},
      ],
    };
    for (final entry in invalidAchievementValues.entries) {
      expect(
        () => endpoint.decode(
          source()
            ..['achievements'] = <Object?>[
              achievement()..remove(entry.key),
            ],
        ),
        throwsFormatException,
        reason: 'achievements[].${entry.key} missing',
      );
      for (final invalid in entry.value) {
        expect(
          () => endpoint.decode(
            source()
              ..['achievements'] = <Object?>[
                achievement()..[entry.key] = invalid,
              ],
          ),
          throwsFormatException,
          reason: 'achievements[].${entry.key} = $invalid',
        );
      }
    }

    expect(
      () => endpoint.decode(
        source()
          ..['achievements'] = <Object?>[
            achievement()..['problems'] = <Object?>[0],
          ],
      ),
      throwsFormatException,
    );
    final invalidProblemValues = <String, List<Object?>>{
      for (final field in ['problemId', 'level', 'effectiveVoteCount'])
        field: [
          null,
          '1',
          false,
          const <Object?>[],
          const <String, Object?>{},
          double.nan,
          double.infinity,
          double.negativeInfinity,
        ],
      'givesNoRating': [
        null,
        0,
        'false',
        const <Object?>[],
        const <String, Object?>{},
      ],
      'isStandard': [
        null,
        0,
        'true',
        const <Object?>[],
        const <String, Object?>{},
      ],
      'titles': [
        null,
        0,
        false,
        'titles',
        const <String, Object?>{},
      ],
      'userStatus': [
        0,
        false,
        const <Object?>[],
        const <String, Object?>{},
        '',
        'Solved',
        'solved ',
        'unknown',
      ],
    };
    for (final entry in invalidProblemValues.entries) {
      expect(
        () => endpoint.decode(
          source()
            ..['achievements'] = <Object?>[
              achievement()
                ..['problems'] = <Object?>[
                  problem()..remove(entry.key),
                ],
            ],
        ),
        throwsFormatException,
        reason: 'achievements[].problems[].${entry.key} missing',
      );
      for (final invalid in entry.value) {
        expect(
          () => endpoint.decode(
            source()
              ..['achievements'] = <Object?>[
                achievement()
                  ..['problems'] = <Object?>[
                    problem()..[entry.key] = invalid,
                  ],
              ],
          ),
          throwsFormatException,
          reason: 'achievements[].problems[].${entry.key} = $invalid',
        );
      }
    }

    expect(
      () => endpoint.decode(
        source()
          ..['achievements'] = <Object?>[
            achievement()
              ..['problems'] = <Object?>[
                problem()..['titles'] = <Object?>[0],
              ],
          ],
      ),
      throwsFormatException,
    );
    final invalidTitleValues = <String, List<Object?>>{
      'language': [
        null,
        0,
        false,
        const <Object?>[],
        const <String, Object?>{},
      ],
      'title': [null, 0, false, const <Object?>[], const <String, Object?>{}],
      for (final field in ['isOriginal', 'latex', 'html'])
        field: [
          null,
          0,
          'false',
          const <Object?>[],
          const <String, Object?>{},
        ],
    };
    for (final entry in invalidTitleValues.entries) {
      expect(
        () => endpoint.decode(
          source()
            ..['achievements'] = <Object?>[
              achievement()
                ..['problems'] = <Object?>[
                  problem()
                    ..['titles'] = <Object?>[
                      title()..remove(entry.key),
                    ],
                ],
            ],
        ),
        throwsFormatException,
        reason: 'achievements[].problems[].titles[].${entry.key} missing',
      );
      for (final invalid in entry.value) {
        expect(
          () => endpoint.decode(
            source()
              ..['achievements'] = <Object?>[
                achievement()
                  ..['problems'] = <Object?>[
                    problem()
                      ..['titles'] = <Object?>[
                        title()..[entry.key] = invalid,
                      ],
                  ],
              ],
          ),
          throwsFormatException,
          reason: 'achievements[].problems[].titles[].${entry.key} = $invalid',
        );
      }
    }

    expect(
      () => endpoint.decode(
        source()
          ..['achievements'] = <Object?>[
            achievement(),
            achievement()..remove('earnedAt'),
          ],
      ),
      throwsFormatException,
      reason: 'a malformed trailing achievement must not be ignored',
    );
    expect(
      () => endpoint.decode(
        source()
          ..['achievements'] = <Object?>[
            achievement()
              ..['problems'] = <Object?>[
                problem(),
                problem()..remove('userStatus'),
              ],
          ],
      ),
      throwsFormatException,
      reason: 'a malformed trailing problem must not be ignored',
    );
    expect(
      () => endpoint.decode(
        source()
          ..['achievements'] = <Object?>[
            achievement()
              ..['problems'] = <Object?>[
                problem()
                  ..['titles'] = <Object?>[
                    title(),
                    title()..remove('html'),
                  ],
              ],
          ],
      ),
      throwsFormatException,
      reason: 'a malformed trailing title must not be ignored',
    );

    final nullable = endpoint.decode(
      source()
        ..['achievements'] = <Object?>[
          achievement()
            ..['condition'] = null
            ..['earnedAt'] = null
            ..['problems'] = <Object?>[
              problem()..['userStatus'] = null,
            ],
        ],
    );
    expect(nullable.achievements.single.condition, isNull);
    expect(nullable.achievements.single.earnedAt, isNull);
    expect(nullable.achievements.single.problems.single.userStatus, isNull);
  });

  test('preserves immutable nested achievement values without inference', () {
    final endpoint = contract.achievementItem(
      OfficialAchievementItemKind.background,
      'anniversary_1st',
    );
    Map<String, dynamic> fixtureSource() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/background_item.json')) as Map,
        );
    Map<String, Object?> title({
      required String language,
      required String value,
      required bool isOriginal,
    }) =>
        <String, Object?>{
          'language': language,
          'title': value,
          'isOriginal': isOriginal,
          'latex': true,
          'html': true,
        };
    Map<String, Object?> problem({
      required Object? userStatus,
      required List<Object?> titles,
    }) =>
        <String, Object?>{
          'problemId': -2.5,
          'level': 0,
          'effectiveVoteCount': 42.0,
          'givesNoRating': true,
          'isStandard': false,
          'titles': titles,
          'userStatus': userStatus,
        };
    Map<String, Object?> achievement({
      required String key,
      required Object? condition,
      required Object? earnedAt,
      required List<Object?> problems,
    }) =>
        <String, Object?>{
          'key': key,
          'name': '  ',
          'condition': condition,
          'historic': true,
          'hidden': true,
          'holderCount': -7,
          'earnedAt': earnedAt,
          'problems': problems,
        };

    expect(
      ProblemUserStatus.values.map((status) => status.value),
      ['solved', 'partial', 'tried'],
    );
    final emptySource = fixtureSource();
    final emptyBackground = Map<String, dynamic>.from(
      emptySource['background'] as Map,
    )..['authors'] = <Object?>[];
    emptySource
      ..['background'] = emptyBackground
      ..['credits'] = <Object?>[];
    final empty = endpoint.decode(emptySource);
    expect(empty.credits, isEmpty);
    expect(empty.background?.authors, isEmpty);

    for (final status in ProblemUserStatus.values) {
      final source = fixtureSource()
        ..['achievements'] = <Object?>[
          achievement(
            key: status.value,
            condition: null,
            earnedAt: null,
            problems: <Object?>[
              problem(
                userStatus: status.value,
                titles: <Object?>[
                  title(language: 'ko', value: 'title', isOriginal: true),
                ],
              ),
            ],
          ),
        ];
      expect(
        endpoint.decode(source).achievements.single.problems.single.userStatus,
        status,
      );
    }

    final firstTitle = title(
      language: '',
      value: ' raw title ',
      isOriginal: false,
    )..['futureTitleField'] = 'allowed';
    final secondTitle = title(
      language: 'ko',
      value: '',
      isOriginal: true,
    );
    final titles = <Object?>[secondTitle, firstTitle, secondTitle];
    final firstProblem = problem(userStatus: null, titles: titles)
      ..['futureProblemField'] = 'allowed';
    final secondProblem = problem(
      userStatus: 'partial',
      titles: <Object?>[],
    );
    final problems = <Object?>[secondProblem, firstProblem, secondProblem];
    final firstAchievement = achievement(
      key: '',
      condition: '',
      earnedAt: 'not a date',
      problems: problems,
    )..['futureAchievementField'] = 'allowed';
    final secondAchievement = achievement(
      key: 'second',
      condition: null,
      earnedAt: null,
      problems: <Object?>[],
    );
    final achievements = <Object?>[
      secondAchievement,
      firstAchievement,
      secondAchievement,
    ];

    final source = fixtureSource();
    final background = Map<String, dynamic>.from(source['background'] as Map);
    final author = Map<String, dynamic>.from(
      (background['authors'] as List).first as Map,
    )..['futureAuthorField'] = 'allowed';
    final authors = <Object?>[author, author];
    background['authors'] = authors;
    final credit = Map<String, dynamic>.from(
      (source['credits'] as List).first as Map,
    )..['futureCreditField'] = 'allowed';
    final credits = <Object?>[credit, credit];
    source
      ..['background'] = background
      ..['credits'] = credits
      ..['achievements'] = achievements
      ..['futureItemField'] = 'allowed';

    final actual = endpoint.decode(source);
    expect(actual.credits.map((value) => value.key), ['designer', 'designer']);
    expect(actual.background?.authors.map((value) => value.key), [
      'illustrator',
      'illustrator',
    ]);
    expect(actual.achievements.map((value) => value.key), [
      'second',
      '',
      'second',
    ]);
    final decodedAchievement = actual.achievements[1];
    expect(decodedAchievement.name, '  ');
    expect(decodedAchievement.condition, '');
    expect(decodedAchievement.historic, isTrue);
    expect(decodedAchievement.hidden, isTrue);
    expect(decodedAchievement.holderCount, -7);
    expect(decodedAchievement.earnedAt, 'not a date');
    expect(decodedAchievement.problems.map((value) => value.userStatus), [
      ProblemUserStatus.partial,
      null,
      ProblemUserStatus.partial,
    ]);
    final decodedProblem = decodedAchievement.problems[1];
    expect(decodedProblem.problemId, -2.5);
    expect(decodedProblem.problemId.runtimeType, double);
    expect(decodedProblem.level, 0);
    expect(decodedProblem.level.runtimeType, int);
    expect(decodedProblem.effectiveVoteCount, 42.0);
    expect(decodedProblem.effectiveVoteCount.runtimeType, double);
    expect(decodedProblem.givesNoRating, isTrue);
    expect(decodedProblem.isStandard, isFalse);
    expect(
      decodedProblem.titles.map((value) => value.language),
      ['ko', '', 'ko'],
    );
    expect(decodedProblem.titles[1].title, ' raw title ');
    expect(decodedProblem.titles[1].isOriginal, isFalse);
    expect(decodedProblem.titles[1].latex, isTrue);
    expect(decodedProblem.titles[1].html, isTrue);

    author['key'] = 'mutated';
    authors.clear();
    credit['key'] = 'mutated';
    credits.clear();
    firstTitle['title'] = 'mutated';
    titles.clear();
    firstProblem['problemId'] = 99;
    problems.clear();
    firstAchievement['key'] = 'mutated';
    achievements.clear();
    source.clear();
    expect(actual.credits.first.key, 'designer');
    expect(actual.background?.authors.first.key, 'illustrator');
    expect(actual.achievements[1].key, '');
    expect(actual.achievements[1].problems[1].problemId, -2.5);
    expect(actual.achievements[1].problems[1].titles[1].title, ' raw title ');
    expect(
      () => actual.credits[0] = actual.credits[0],
      throwsUnsupportedError,
    );
    expect(
      () => actual.background!.authors[0] = actual.background!.authors[0],
      throwsUnsupportedError,
    );
    expect(
      () => actual.achievements[0] = actual.achievements[0],
      throwsUnsupportedError,
    );
    expect(
      () => decodedAchievement.problems[0] = decodedAchievement.problems[0],
      throwsUnsupportedError,
    );
    expect(
      () => decodedProblem.titles[0] = decodedProblem.titles[0],
      throwsUnsupportedError,
    );
  });

  test('strictly validates standalone background and author shapes', () {
    final endpoint = contract.backgroundShow('anniversary_1st');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/background_item.json')) as Map,
        );
    Map<String, dynamic> background() => Map<String, dynamic>.from(
          source()['background'] as Map,
        );
    Map<String, Object?> author() => <String, Object?>{
          'key': 'author',
          'displayName': null,
          'role': 'Illustration',
          'authorUrl': null,
          'handle': null,
          'twitter': null,
          'instagram': null,
        };
    const fields = [
      'key',
      'backgroundImageUrl',
      'fallbackBackgroundImageUrl',
      'backgroundVideoUrl',
      'thumbnailPlaceholder',
      'isIllust',
      'displayName',
      'authors',
    ];
    for (final field in fields) {
      expect(
        () => endpoint.decode(
          source()..['background'] = (background()..remove(field)),
        ),
        throwsFormatException,
        reason: 'background.$field missing',
      );
    }

    final invalidValues = <String, List<Object?>>{
      'key': [null, 0, false, const <Object?>[], const <String, Object?>{}],
      'backgroundImageUrl': [
        null,
        0,
        false,
        const <Object?>[],
        const <String, Object?>{},
      ],
      for (final field in [
        'fallbackBackgroundImageUrl',
        'backgroundVideoUrl',
        'thumbnailPlaceholder',
        'displayName',
      ])
        field: [
          0,
          false,
          const <Object?>[],
          const <String, Object?>{},
        ],
      'isIllust': [
        null,
        0,
        'true',
        const <Object?>[],
        const <String, Object?>{},
      ],
      'authors': [
        null,
        0,
        false,
        'authors',
        const <String, Object?>{},
      ],
    };
    for (final entry in invalidValues.entries) {
      for (final invalid in entry.value) {
        expect(
          () => endpoint.decode(
            source()..['background'] = (background()..[entry.key] = invalid),
          ),
          throwsFormatException,
          reason: 'background.${entry.key} = $invalid',
        );
      }
    }
    expect(
      () => endpoint.decode(
        source()..['background'] = (background()..['authors'] = <Object?>[0]),
      ),
      throwsFormatException,
    );

    final authorInvalidValues = <String, List<Object?>>{
      'key': [null, 0, false, const <Object?>[], const <String, Object?>{}],
      'displayName': [
        0,
        false,
        const <Object?>[],
        const <String, Object?>{},
      ],
      'role': [null, 0, false, const <Object?>[], const <String, Object?>{}],
      for (final field in ['authorUrl', 'handle', 'twitter', 'instagram'])
        field: [
          0,
          false,
          const <Object?>[],
          const <String, Object?>{},
        ],
    };
    for (final entry in authorInvalidValues.entries) {
      expect(
        () => endpoint.decode(
          source()
            ..['background'] = (background()
              ..['authors'] = <Object?>[author()..remove(entry.key)]),
        ),
        throwsFormatException,
        reason: 'background.authors[].${entry.key} missing',
      );
      for (final invalid in entry.value) {
        expect(
          () => endpoint.decode(
            source()
              ..['background'] = (background()
                ..['authors'] = <Object?>[
                  author()..[entry.key] = invalid,
                ]),
          ),
          throwsFormatException,
          reason: 'background.authors[].${entry.key} = $invalid',
        );
      }
    }

    expect(
      () => endpoint.decode(
        source()
          ..['background'] = (background()
            ..['authors'] = <Object?>[
              author(),
              author()..remove('instagram'),
            ]),
      ),
      throwsFormatException,
      reason: 'a malformed trailing author must not be ignored',
    );
  });

  test('strictly validates every standalone item credit', () {
    final endpoint = contract.badgeShow('boardgame');
    Map<String, dynamic> source() => Map<String, dynamic>.from(
          jsonDecode(fixture('v4/badge_item.json')) as Map,
        );
    Map<String, Object?> credit() => <String, Object?>{
          'key': 'credit',
          'displayName': null,
          'role': 'Design',
          'authorUrl': null,
          'handle': null,
          'twitter': null,
          'instagram': null,
        };
    expect(
      () => endpoint.decode(source()..['credits'] = <Object?>[0]),
      throwsFormatException,
    );

    final invalidValues = <String, List<Object?>>{
      'key': [null, 0, false, const <Object?>[], const <String, Object?>{}],
      'displayName': [
        0,
        false,
        const <Object?>[],
        const <String, Object?>{},
      ],
      'role': [null, 0, false, const <Object?>[], const <String, Object?>{}],
      for (final field in ['authorUrl', 'handle', 'twitter', 'instagram'])
        field: [
          0,
          false,
          const <Object?>[],
          const <String, Object?>{},
        ],
    };
    for (final entry in invalidValues.entries) {
      expect(
        () => endpoint.decode(
          source()..['credits'] = <Object?>[credit()..remove(entry.key)],
        ),
        throwsFormatException,
        reason: 'credits[].${entry.key} missing',
      );
      for (final invalid in entry.value) {
        expect(
          () => endpoint.decode(
            source()
              ..['credits'] = <Object?>[
                credit()..[entry.key] = invalid,
              ],
          ),
          throwsFormatException,
          reason: 'credits[].${entry.key} = $invalid',
        );
      }
    }

    expect(
      () => endpoint.decode(
        source()
          ..['credits'] = <Object?>[
            credit(),
            credit()..remove('instagram'),
          ],
      ),
      throwsFormatException,
      reason: 'a malformed trailing credit must not be ignored',
    );
  });

  test('preserves standalone item projections without relationship inference',
      () {
    final backgroundSource = Map<String, dynamic>.from(
      jsonDecode(fixture('v4/background_item.json')) as Map,
    );
    final background = Map<String, dynamic>.from(
      backgroundSource['background'] as Map,
    )
      ..['key'] = 'nested-key'
      ..['backgroundImageUrl'] = 'not a uri'
      ..['fallbackBackgroundImageUrl'] = ''
      ..['backgroundVideoUrl'] = 'also not a uri'
      ..['thumbnailPlaceholder'] = ' raw placeholder '
      ..['displayName'] = ''
      ..['futureBackgroundField'] = 'allowed';
    final author = Map<String, dynamic>.from(
      (background['authors'] as List).first as Map,
    )
      ..['key'] = ''
      ..['displayName'] = '  '
      ..['role'] = ''
      ..['authorUrl'] = 'not a uri'
      ..['futureAuthorField'] = 'allowed';
    background['authors'] = <Object?>[author, author];
    final credit = Map<String, dynamic>.from(
      (backgroundSource['credits'] as List).first as Map,
    )
      ..['key'] = ''
      ..['displayName'] = '  '
      ..['role'] = ''
      ..['authorUrl'] = 'not a uri'
      ..['futureCreditField'] = 'allowed';
    backgroundSource
      ..['id'] = -1
      ..['key'] = 'outer-key'
      ..['owned'] = true
      ..['equipped'] = false
      ..['background'] = background
      ..['credits'] = <Object?>[credit, credit]
      ..['futureItemField'] = 'allowed';

    final actual = contract.backgroundShow('outer-key').decode(
          backgroundSource,
        );
    expect(actual?.key, 'outer-key');
    expect(actual?.imageUrl, 'not a uri');
    expect(actual?.fallbackImageUrl, '');

    final badgeSource = Map<String, dynamic>.from(
      jsonDecode(fixture('v4/badge_item.json')) as Map,
    )
      ..['id'] = -2
      ..['key'] = ' badge key '
      ..['name'] = ''
      ..['imageUrl'] = 'not a uri'
      ..['background'] = background
      ..['userCount'] = 0
      ..['futureItemField'] = 'allowed';
    final badge = contract.badgeShow('boardgame').decode(badgeSource);
    expect(badge.key, ' badge key ');
    expect(badge.name, '');
    expect(badge.imageUrl, 'not a uri');

    background['backgroundImageUrl'] = 'mutated';
    author['key'] = 'mutated';
    credit['role'] = 'mutated';
    backgroundSource['key'] = 'mutated';
    badgeSource['name'] = 'mutated';
    expect(actual?.key, 'outer-key');
    expect(actual?.imageUrl, 'not a uri');
    expect(badge.name, '');
  });

  test('preserves an unavailable standalone background', () {
    final source = Map<String, dynamic>.from(
      jsonDecode(fixture('v4/background_item.json')) as Map,
    )..['background'] = null;
    final actual = contract.backgroundShow('future-background').decode(source);

    expect(actual, isNull);
  });
}

Map<String, dynamic> _activitySource() =>
    jsonDecode(fixture('v4/user_activity_days.json')) as Map<String, dynamic>;

Map<String, dynamic> _activityDaySource() => Map<String, dynamic>.from(
      (_activitySource()['days'] as List<dynamic>).first as Map,
    );
