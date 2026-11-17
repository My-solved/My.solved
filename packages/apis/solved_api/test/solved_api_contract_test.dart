import 'dart:convert';

import 'package:solved_api/solved_api.dart';
import 'package:test/test.dart';

import 'helpers/fixture.dart';

void main() {
  group('SolvedApiV3Contract', () {
    test(
      'describes the verified user request for direct and proxy targets',
      () {
        final endpoint = const SolvedApiV3Contract().userShow('index');

        expect(endpoint.direct.baseUri, Uri.parse('https://solved.ac/api/v3/'));
        expect(endpoint.direct.path, 'user/show');
        expect(endpoint.direct.queryParameters, {'handle': 'index'});
        expect(
          endpoint.proxy.baseUri,
          Uri.parse('https://codepoker.w8385.dev/solved/'),
        );
        expect(endpoint.proxy.path, 'user/show');
        expect(endpoint.proxy.queryParameters, {'handle': 'index'});
      },
    );

    test('preserves verified search targets and defaults', () {
      const contract = SolvedApiV3Contract();
      final problem = contract.searchProblem('rsa', null, null, null);
      final user = contract.searchUser('index', null);
      final tag = contract.searchTag('math', null);

      expect(problem.direct.baseUri, Uri.parse('https://solved.ac/api/v3/'));
      expect(problem.direct.path, 'search/problem');
      expect(problem.direct.queryParameters, {
        'query': 'rsa',
        'page': '1',
        'sort': 'solved',
        'direction': 'descending',
      });
      expect(
        problem.proxy.baseUri,
        Uri.parse('https://codepoker.w8385.dev/solved/'),
      );
      expect(problem.proxy.path, 'search/problem');
      expect(problem.proxy.queryParameters, problem.direct.queryParameters);
      expect(user.direct.path, 'search/user');
      expect(user.direct.queryParameters, {'query': 'index', 'page': '1'});
      expect(tag.direct.path, 'search/tag');
      expect(tag.direct.queryParameters, {'query': 'math', 'page': '1'});
    });

    test('normalizes verified v3 search fixtures', () {
      const contract = SolvedApiV3Contract();
      final problems = contract
          .searchProblem('rsa', 1, 'id', 'asc')
          .decode(jsonDecode(fixture('v3/search_problem.json')));
      final users = contract
          .searchUser('fdsa', 1)
          .decode(jsonDecode(fixture('v3/search_user.json')));
      final tags = contract
          .searchTag('number_theory', 1)
          .decode(jsonDecode(fixture('v3/search_tag.json')));

      expect(problems, isA<SearchObject<ProblemSearchItem>>());
      expect(problems.count, 1);
      expect(problems.items.single.problemId, 3734);
      expect(problems.items.single.title, 'RSA 인수 분해');
      expect(problems.items.single.level, 16);
      expect(problems.items.single.isStandard, isNull);
      expect(problems.items.single.votedUserCount, 10);
      expect(problems.items.single.effectiveVoteCount, isNull);
      expect(problems.items.single.solvedUserCount, isNull);
      expect(problems.items.single.givesNoRating, isFalse);
      expect(problems.items.single.noRatingReasons, isNull);
      expect(problems.items.single.noRatingWarnings, isNull);
      expect(problems.items.single.tagNames, [
        '애드 혹',
        '임의 정밀도 / 큰 수 연산',
        '브루트포스 알고리즘',
        '수학',
        '정수론',
      ]);
      expect(users, isA<SearchObject<UserSearchItem>>());
      expect(users.count, 2);
      expect(users.items.first.handle, 'fdsajklt2');
      expect(users.items.first.profileImageUrl, isNull);
      expect(users.items.first.tier, 16);
      expect(users.items.first.rank, 5169);
      expect(users.items.last.rank, 17200);
      expect(users.items.first.userClass, 4);
      expect(users.items.last.userClass, 3);
      expect(users.items.first.classPlus, isNull);
      expect(users.items.first.rating, 1675);
      expect(users.items.first.solvedCount, 489);
      expect(tags, isA<SearchObject<TagSearchItem>>());
      expect(tags.count, 1);
      expect(tags.items.single.key, 'number_theory');
      expect(tags.items.single.displayName, isNull);
      expect(tags.items.single.problemCount, 1314);
    });

    test('preserves an optional legacy no-rating marker as a boolean', () {
      const item = ProblemSearchItem(
        problemId: 1,
        title: 'legacy',
        level: 0,
        tagNames: [],
      );
      final endpoint = const SolvedApiV3Contract().searchProblem(
        'legacy',
        1,
        'id',
        'asc',
      );
      Map<String, dynamic> source({
        Object? givesNoRating,
        bool includeMarker = true,
      }) =>
          {
            'count': 1,
            'items': [
              {
                'problemId': 1,
                'titleKo': 'legacy',
                'level': 0,
                'tags': <Object>[],
                if (includeMarker) 'givesNoRating': givesNoRating,
              },
            ],
          };

      expect(item.givesNoRating, isNull);
      expect(item.isStandard, isNull);
      expect(item.votedUserCount, isNull);
      expect(item.effectiveVoteCount, isNull);
      expect(item.solvedUserCount, isNull);
      expect(item.noRatingReasons, isNull);
      expect(item.noRatingWarnings, isNull);
      expect(
        endpoint
            .decode(source(includeMarker: false))
            .items
            .single
            .givesNoRating,
        isNull,
      );
      final missingMarker = endpoint.decode(source()).items.single;
      expect(missingMarker.givesNoRating, isNull);
      expect(missingMarker.solvedUserCount, isNull);
      expect(missingMarker.noRatingReasons, isNull);
      expect(missingMarker.noRatingWarnings, isNull);
      final unrated = endpoint.decode(source(givesNoRating: true)).items.single;
      expect(unrated.givesNoRating, isTrue);
      expect(unrated.solvedUserCount, isNull);
      expect(unrated.noRatingReasons, isNull);
      expect(unrated.noRatingWarnings, isNull);
      for (final invalid in <Object>[0, 'false', const <Object>[]]) {
        expect(
          () => endpoint.decode(source(givesNoRating: invalid)),
          throwsA(isA<TypeError>()),
          reason: 'givesNoRating = $invalid',
        );
      }
    });

    test('does not infer v4 standard status from legacy flags', () {
      final endpoint = const SolvedApiV3Contract().searchProblem(
        'rsa',
        1,
        'id',
        'asc',
      );
      Map<String, dynamic> source() =>
          jsonDecode(fixture('v3/search_problem.json')) as Map<String, dynamic>;
      Map<String, dynamic> firstProblem(Map<String, dynamic> body) =>
          (body['items'] as List).first as Map<String, dynamic>;

      expect(endpoint.decode(source()).items.single.isStandard, isNull);

      final inverted = source();
      firstProblem(inverted)
        ..['official'] = false
        ..['isSolvable'] = false;
      expect(endpoint.decode(inverted).items.single.isStandard, isNull);
    });

    test('preserves an optional legacy voted-user count as a number', () {
      final endpoint = const SolvedApiV3Contract().searchProblem(
        'rsa',
        1,
        'id',
        'asc',
      );
      Map<String, dynamic> source() =>
          jsonDecode(fixture('v3/search_problem.json')) as Map<String, dynamic>;
      Map<String, dynamic> firstProblem(Map<String, dynamic> body) =>
          (body['items'] as List).first as Map<String, dynamic>;

      final captured = endpoint.decode(source()).items.single;
      expect(captured.votedUserCount, 10);
      expect(captured.effectiveVoteCount, isNull);

      final missing = source();
      firstProblem(missing).remove('votedUserCount');
      expect(endpoint.decode(missing).items.single.votedUserCount, isNull);

      final explicitNull = source();
      firstProblem(explicitNull)['votedUserCount'] = null;
      expect(endpoint.decode(explicitNull).items.single.votedUserCount, isNull);

      for (final invalid in <Object>[
        '10',
        true,
        const <String, Object?>{},
        const <Object>[],
      ]) {
        final malformed = source();
        firstProblem(malformed)['votedUserCount'] = invalid;
        expect(
          () => endpoint.decode(malformed),
          throwsA(isA<TypeError>()),
          reason: 'votedUserCount = $invalid',
        );
      }
    });

    test('keeps legacy and public user-search shapes compatible', () {
      const item = UserSearchItem(
        handle: 'legacy',
        profileImageUrl: null,
        tier: 0,
      );
      final decoded = const SolvedApiV3Contract()
          .searchUser('legacy', 1)
          .decode({
        'count': 1,
        'items': [
          {
            'handle': 'legacy',
            'profileImageUrl': null,
            'tier': 0,
            'voteCount': 999,
          },
        ],
      });

      expect(item.rating, isNull);
      expect(item.rank, isNull);
      expect(item.userClass, isNull);
      expect(item.classPlus, isNull);
      expect(item.solvedCount, isNull);
      expect(item.reputation, isNull);
      expect(decoded.items.single.rating, isNull);
      expect(decoded.items.single.rank, isNull);
      expect(decoded.items.single.userClass, isNull);
      expect(decoded.items.single.classPlus, isNull);
      expect(decoded.items.single.solvedCount, isNull);
      expect(decoded.items.single.reputation, isNull);
    });

    test('rejects a non-integer legacy user rank', () {
      final source = Map<String, dynamic>.from(
        jsonDecode(fixture('v3/search_user.json')) as Map,
      );
      final items = List<dynamic>.from(source['items'] as List);
      items[0] = Map<String, dynamic>.from(items.first as Map)
        ..['rank'] = '5169';
      source['items'] = items;

      expect(
        () =>
            const SolvedApiV3Contract().searchUser('legacy', 1).decode(source),
        throwsA(isA<TypeError>()),
      );
    });

    test('keeps the legacy public tag-item constructor source-compatible', () {
      const item = TagSearchItem(key: 'stable_key', problemCount: null);

      expect(item.key, 'stable_key');
      expect(item.displayName, isNull);
      expect(item.problemCount, isNull);
    });

    test('selects a Korean tag name with safe fallbacks', () {
      final result = const SolvedApiV3Contract()
          .searchProblem('tags', 1, 'id', 'asc')
          .decode({
        'count': 1,
        'items': [
          {
            'problemId': 1,
            'titleKo': '태그 이름',
            'level': 0,
            'tags': [
              {
                'key': 'korean',
                'displayNames': [
                  {'language': 'en', 'name': 'English name'},
                  {'language': 'ko', 'name': '한국어 이름'},
                ],
              },
              {
                'key': 'first',
                'displayNames': [
                  null,
                  {'language': 'en', 'name': 'English fallback'},
                ],
              },
              {
                'key': 'key_only',
                'displayNames': [
                  {'language': 'ko', 'name': ''},
                  42,
                ],
              },
            ],
          },
        ],
      });

      expect(result.items.single.tagNames, [
        '한국어 이름',
        'English fallback',
        'key_only',
      ]);
    });

    test('accepts empty search result lists', () {
      const contract = SolvedApiV3Contract();
      final empty = {'count': 0, 'items': <dynamic>[]};

      expect(
        contract.searchProblem('', null, null, null).decode(empty).items,
        isEmpty,
      );
      expect(contract.searchUser('', null).decode(empty).items, isEmpty);
      expect(contract.searchTag('', null).decode(empty).items, isEmpty);
    });

    test('preserves only the verified v3 profile streak summary', () {
      const contract = SolvedApiV3Contract();
      final actual = contract
          .userShow('w8385')
          .decode(jsonDecode(fixture('v3/user_show.json')));
      final explicitNull = contract.userShow('null-bio').decode(
            Map<String, dynamic>.from(
              jsonDecode(fixture('v3/user_show.json')) as Map,
            )
              ..['handle'] = 'null-bio'
              ..['bio'] = null,
          );
      final minimal = contract.userShow('minimal').decode({
        'handle': 'minimal',
        'badgeId': null,
        'backgroundId': null,
        'profileImageUrl': null,
        'solvedCount': 0,
        'voteCount': 0,
        'class': 0,
        'reverseRivalCount': 0,
        'tier': 0,
        'rating': 0,
      });

      expect(actual.currentStreak, isNull);
      expect(actual.maxStreak, 477);
      expect(actual.bio, 'https://github.com/w8385');
      expect(explicitNull.bio, isNull);
      expect(actual.classPlus, isNull);
      expect(actual.ratingBreakdown, isNull);
      expect(minimal.currentStreak, isNull);
      expect(minimal.maxStreak, isNull);
      expect(minimal.bio, isNull);
      expect(minimal.classPlus, isNull);
      expect(minimal.ratingBreakdown, isNull);
    });

    test('normalizes profile streak days without mutating v3 wire data', () {
      final json = <String, dynamic>{
        'grass': [
          {'date': '2026-11-15', 'value': 4},
          {'date': '2026-11-16', 'value': 'frozen'},
          {'date': '2026-11-17', 'value': 'frozen-repaired'},
        ],
        'theme': 'wire-only-theme',
        'currentStreak': 7,
        'longestStreak': 100,
        'topic': 'default',
      };

      final endpoint = const SolvedApiV3Contract().userGrass('index', null);
      final actual = endpoint.decode(json);

      expect(endpoint.direct.queryParameters, {
        'handle': 'index',
        'topic': 'default',
      });
      expect(actual.currentStreak, 7);
      expect(actual.days, hasLength(3));
      expect(actual.days.map((day) => day.solvedCount), [4, 0, 1]);
      expect(actual.days.last.year, 2026);
      expect(actual.days.last.month, 11);
      expect(actual.days.last.day, 17);
      expect((json['grass'] as List).first, {
        'date': '2026-11-15',
        'value': 4,
      });
      expect(json['theme'], 'wire-only-theme');
    });

    test('normalizes selected problem stat wire fields', () {
      final json = <Map<String, dynamic>>[
        {
          'level': 17,
          'solved': 107,
          'total': 1217,
          'partial': 1,
          'tried': 10,
        },
      ];

      final actual =
          const SolvedApiV3Contract().userProblemStats('index').decode(json);

      expect(actual.single.tier, 17);
      expect(actual.single.solvedCount, 107);
      expect(json.single['total'], 1217);
    });

    test('normalizes selected tag rating wire fields', () {
      final json = <Map<String, dynamic>>[
        {
          'tag': {'key': 'bfs'},
          'solvedCount': 51,
          'rating': 1138,
          'ratingByProblemsSum': 1058,
          'ratingByClass': 0,
          'ratingBySolvedCount': 80,
          'ratingProblemsCutoff': 9,
        },
      ];

      final actual =
          const SolvedApiV3Contract().userTagRatings('index').decode(json);

      expect(actual.single.key, 'bfs');
      expect(actual.single.rating, 1138);
      expect(actual.single.solvedCount, 51);
      expect(actual.single.ratingByProblemsSum, 1058);
      expect(actual.single.ratingByClass, 0);
      expect(actual.single.ratingBySolvedCount, 80);
      expect(actual.single.ratingProblemsCutoff, 9);
      expect((json.single['tag'] as Map)['key'], 'bfs');
    });

    test('normalizes background wire fields without mutating the response', () {
      final json = <String, dynamic>{
        'backgroundId': 'anniversary_1st',
        'backgroundImageUrl': 'https://example.com/background.png',
        'fallbackBackgroundImageUrl': 'https://example.com/fallback.png',
        'wireOnlyField': true,
      };

      final actual =
          const SolvedApiV3Contract().backgroundShow('anniversary_1st').decode(
                json,
              );

      expect(actual.imageUrl, 'https://example.com/background.png');
      expect(actual.key, 'anniversary_1st');
      expect(actual.fallbackImageUrl, 'https://example.com/fallback.png');
      expect(json['wireOnlyField'], isTrue);
    });

    test('normalizes selected badge wire fields', () {
      final actual = const SolvedApiV3Contract().badgeShow('boardgame').decode({
        'badgeId': 'boardgame',
        'badgeImageUrl': 'https://example.com/badge.png',
        'wireOnlyField': true,
      });

      expect(actual.imageUrl, 'https://example.com/badge.png');
      expect(actual.key, 'boardgame');
    });
  });

  group('SolvedApiTarget', () {
    test('normalizes its base and defensively copies query parameters', () {
      final query = {'handle': 'index'};
      final target = SolvedApiTarget(
        baseUri: Uri.parse('https://example.com/api'),
        path: 'user/show',
        queryParameters: query,
      );
      query['handle'] = 'changed';

      expect(target.baseUri, Uri.parse('https://example.com/api/'));
      expect(target.queryParameters, {'handle': 'index'});
      expect(
        () => target.queryParameters['handle'] = 'changed',
        throwsUnsupportedError,
      );
    });

    test('rejects ambiguous bases and non-relative endpoint paths', () {
      expect(
        () =>
            SolvedApiTarget(baseUri: Uri.parse('/api/v3/'), path: 'user/show'),
        throwsArgumentError,
      );
      expect(
        () => SolvedApiTarget(
          baseUri: Uri.parse('https://example.com/api/?token=secret'),
          path: 'user/show',
        ),
        throwsArgumentError,
      );
      for (final path in [
        '/user/show',
        '../user/show',
        '%2e%2e/user/show',
        r'user\show',
        'https://evil.example/user/show',
        'user/show?handle=index',
        'user/show#fragment',
      ]) {
        expect(
          () => SolvedApiTarget(
            baseUri: Uri.parse('https://example.com/api/'),
            path: path,
          ),
          throwsArgumentError,
        );
      }
    });
  });
}
