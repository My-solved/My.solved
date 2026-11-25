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
    expect(background, isNot(isA<OfficialUserProfileBackground>()));
    expect(badge.key, 'boardgame');
    expect(badge.name, 'Board Game');
    expect(badge.imageUrl, 'https://example.com/badge.png');
    expect(badge, isNot(isA<OfficialUserProfileBadge>()));
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
