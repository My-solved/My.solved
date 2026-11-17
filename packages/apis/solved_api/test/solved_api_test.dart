import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:solved_api/solved_api.dart';
import 'package:test/test.dart';

import 'helpers/fixture.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockResponse extends Mock implements http.Response {
  @override
  Uint8List get bodyBytes => Uint8List.fromList(utf8.encode(body));
}

class FakeUri extends Fake implements Uri {}

class AlternateUserContract extends SolvedApiV3Contract {
  const AlternateUserContract();

  @override
  SolvedApiEndpoint<User> userShow(String handle) => SolvedApiEndpoint(
        direct: SolvedApiTarget(
          baseUri: Uri.https('contract.example.com', '/direct/'),
          path: 'profile/show',
          queryParameters: {'user': handle},
        ),
        proxy: SolvedApiTarget(
          baseUri: Uri.https('proxy.example.com', '/gateway/'),
          path: 'profile/lookup',
          queryParameters: {'proxyUser': handle},
        ),
        decode: (json) {
          final decoded = Map<String, dynamic>.from(json);
          decoded['handle'] = 'contract-decoded';
          return User.fromJson(decoded);
        },
      );
}

void main() {
  group('SolvedApiClient', () {
    late http.Client httpClient;
    late SolvedApiClient apiClient;

    setUpAll(() {
      registerFallbackValue(FakeUri());
    });

    setUp(() {
      httpClient = MockHttpClient();
      apiClient = SolvedApiClient(httpClient: httpClient);
    });

    group('transport', () {
      test('uses the direct API URI when proxying is disabled', () async {
        apiClient = SolvedApiClient(httpClient: httpClient, useProxy: false);
        when(
          () => httpClient.get(any()),
        ).thenAnswer((_) async => http.Response('{}', 200));

        await expectLater(
          apiClient.userShow('w8385'),
          throwsA(isA<UserRequestFailed>()),
        );

        verify(
          () => httpClient.get(
            Uri.https('solved.ac', '/api/v3/user/show', {'handle': 'w8385'}),
          ),
        ).called(1);
      });

      test('uses the web proxy URI when proxying is enabled', () async {
        apiClient = SolvedApiClient(httpClient: httpClient, useProxy: true);
        when(
          () => httpClient.get(any()),
        ).thenAnswer((_) async => http.Response('{}', 200));

        await expectLater(
          apiClient.userShow('w8385'),
          throwsA(isA<UserRequestFailed>()),
        );

        verify(
          () => httpClient.get(
            Uri.https('codepoker.w8385.dev', '/solved/user/show', {
              'handle': 'w8385',
            }),
          ),
        ).called(1);
      });

      test('uses contract-specific direct and proxy targets', () async {
        when(() => httpClient.get(any())).thenAnswer(
          (_) async => http.Response(fixture('v3/user_show.json'), 200),
        );

        final directClient = SolvedApiClient(
          httpClient: httpClient,
          useProxy: false,
          contract: const AlternateUserContract(),
        );
        final proxyClient = SolvedApiClient(
          httpClient: httpClient,
          useProxy: true,
          contract: const AlternateUserContract(),
        );

        final directUser = await directClient.userShow('w8385');
        final proxyUser = await proxyClient.userShow('w8385');

        expect(directUser.handle, 'contract-decoded');
        expect(proxyUser.handle, 'contract-decoded');

        verify(
          () => httpClient.get(
            Uri.https('contract.example.com', '/direct/profile/show', {
              'user': 'w8385',
            }),
          ),
        ).called(1);
        verify(
          () => httpClient.get(
            Uri.https('proxy.example.com', '/gateway/profile/lookup', {
              'proxyUser': 'w8385',
            }),
          ),
        ).called(1);
      });

      test('custom base overrides only the selected contract target base',
          () async {
        when(() => httpClient.get(any())).thenAnswer(
          (_) async => http.Response(fixture('v3/user_show.json'), 200),
        );
        apiClient = SolvedApiClient(
          httpClient: httpClient,
          useProxy: false,
          apiBaseUri: Uri.https('staging.example.com', '/api'),
          contract: const AlternateUserContract(),
        );

        final user = await apiClient.userShow('w8385');

        expect(user.handle, 'contract-decoded');
        verify(
          () => httpClient.get(
            Uri.https('staging.example.com', '/api/profile/show', {
              'user': 'w8385',
            }),
          ),
        ).called(1);
      });

      test('normalizes and uses a custom direct API base URI', () async {
        apiClient = SolvedApiClient(
          httpClient: httpClient,
          useProxy: false,
          apiBaseUri: Uri.https('api.example.com', '/custom/api'),
        );
        when(
          () => httpClient.get(any()),
        ).thenAnswer((_) async => http.Response('{}', 200));

        await expectLater(
          apiClient.userShow('w8385'),
          throwsA(isA<UserRequestFailed>()),
        );

        verify(
          () => httpClient.get(
            Uri.https('api.example.com', '/custom/api/user/show', {
              'handle': 'w8385',
            }),
          ),
        ).called(1);
      });

      test('normalizes and uses a custom proxy base URI', () async {
        apiClient = SolvedApiClient(
          httpClient: httpClient,
          useProxy: true,
          proxyBaseUri: Uri.https('proxy.example.com', '/gateway/solved'),
        );
        when(
          () => httpClient.get(any()),
        ).thenAnswer((_) async => http.Response('{}', 200));

        await expectLater(
          apiClient.userShow('w8385'),
          throwsA(isA<UserRequestFailed>()),
        );

        verify(
          () => httpClient.get(
            Uri.https('proxy.example.com', '/gateway/solved/user/show', {
              'handle': 'w8385',
            }),
          ),
        ).called(1);
      });

      test('decodes successful response bodies as UTF-8', () async {
        final payload = jsonEncode({
          'backgroundId': 'test',
          'backgroundImageUrl': 'https://example.com/background.png',
          'fallbackBackgroundImageUrl': null,
          'backgroundVideoUrl': null,
          'unlockedUserCount': 1,
          'displayName': '한글 배경',
          'displayDescription': '설명',
          'conditions': null,
          'hiddenConditions': false,
          'isIllust': false,
        });
        when(() => httpClient.get(any())).thenAnswer(
          (_) async => http.Response.bytes(
            utf8.encode(payload),
            200,
            headers: {'content-type': 'application/json; charset=iso-8859-1'},
          ),
        );

        final background = await apiClient.backgroundShow('test');

        expect(background.displayName, '한글 배경');
        expect(background.displayDescription, '설명');
      });

      test('preserves rate-limit metadata on non-success responses', () async {
        when(() => httpClient.get(any())).thenAnswer(
          (_) async => http.Response(
            '{"message":"rate limited"}',
            429,
            headers: {'retry-after': '12'},
          ),
        );

        await expectLater(
          apiClient.siteStats(),
          throwsA(
            isA<SiteRequestFailed>()
                .having(
                  (error) => error.uri,
                  'uri',
                  Uri.https('solved.ac', '/api/v3/site/stats'),
                )
                .having((error) => error.statusCode, 'statusCode', 429)
                .having(
                  (error) => error.retryAfter,
                  'retryAfter',
                  const Duration(seconds: 12),
                )
                .having((error) => error.isRetryable, 'isRetryable', isTrue)
                .having(
                  (error) => error.responseBody,
                  'responseBody',
                  '{"message":"rate limited"}',
                ),
          ),
        );
      });

      test('parses an HTTP-date Retry-After value', () async {
        when(() => httpClient.get(any())).thenAnswer(
          (_) async => http.Response(
            '{"message":"rate limited"}',
            429,
            headers: {'Retry-After': 'Sun, 06 Nov 1994 08:49:37 GMT'},
          ),
        );

        await expectLater(
          apiClient.siteStats(),
          throwsA(
            isA<SiteRequestFailed>().having(
              (error) => error.retryAfter,
              'retryAfter',
              Duration.zero,
            ),
          ),
        );
      });

      test(
        'maps other non-success responses without marking them retryable',
        () async {
          when(
            () => httpClient.get(any()),
          ).thenAnswer((_) async => http.Response('not found', 404));

          await expectLater(
            apiClient.badgeShow('missing'),
            throwsA(
              isA<BadgeRequestFailed>()
                  .having((error) => error.statusCode, 'statusCode', 404)
                  .having((error) => error.isRetryable, 'isRetryable', isFalse)
                  .having(
                    (error) => error.responseBody,
                    'responseBody',
                    'not found',
                  ),
            ),
          );
        },
      );

      test('maps request timeouts to the endpoint failure type', () async {
        apiClient = SolvedApiClient(
          httpClient: httpClient,
          requestTimeout: const Duration(milliseconds: 1),
        );
        when(
          () => httpClient.get(any()),
        ).thenAnswer((_) => Completer<http.Response>().future);

        await expectLater(
          apiClient.userShow('w8385'),
          throwsA(
            isA<UserRequestFailed>()
                .having((error) => error.isTimeout, 'isTimeout', isTrue)
                .having((error) => error.statusCode, 'statusCode', isNull)
                .having((error) => error.isRetryable, 'isRetryable', isTrue),
          ),
        );
      });

      test('maps client failures to the endpoint failure type', () async {
        final cause = StateError('offline');
        when(() => httpClient.get(any())).thenThrow(cause);

        await expectLater(
          apiClient.userShow('w8385'),
          throwsA(
            isA<UserRequestFailed>()
                .having((error) => error.cause, 'cause', same(cause))
                .having((error) => error.statusCode, 'statusCode', isNull)
                .having((error) => error.isRetryable, 'isRetryable', isFalse),
          ),
        );
      });

      test('marks HTTP client failures as retryable', () async {
        final cause = http.ClientException('offline');
        when(() => httpClient.get(any())).thenThrow(cause);

        await expectLater(
          apiClient.userShow('w8385'),
          throwsA(
            isA<UserRequestFailed>()
                .having((error) => error.cause, 'cause', same(cause))
                .having((error) => error.isRetryable, 'isRetryable', isTrue),
          ),
        );
      });

      test('maps invalid JSON to the endpoint failure type', () async {
        when(
          () => httpClient.get(any()),
        ).thenAnswer((_) async => http.Response('not json', 200));

        await expectLater(
          apiClient.badgeShow('test'),
          throwsA(
            isA<BadgeRequestFailed>()
                .having((error) => error.statusCode, 'statusCode', 200)
                .having((error) => error.cause, 'cause', isA<FormatException>())
                .having((error) => error.isRetryable, 'isRetryable', isFalse),
          ),
        );
      });

      test('maps invalid UTF-8 to the endpoint failure type', () async {
        when(
          () => httpClient.get(any()),
        ).thenAnswer((_) async => http.Response.bytes([0xff], 200));

        await expectLater(
          apiClient.badgeShow('test'),
          throwsA(
            isA<BadgeRequestFailed>()
                .having((error) => error.statusCode, 'statusCode', 200)
                .having(
                  (error) => error.cause,
                  'cause',
                  isA<FormatException>(),
                ),
          ),
        );
      });
    });

    group('userShow', () {
      const handle = 'w8385';
      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.userShow(handle);
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https('solved.ac', '/api/v3/user/show', {'handle': handle}),
          ),
        ).called(1);
      });

      test('returns User on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn(fixture('v3/user_show.json'));
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.userShow(handle);
        expect(actual, isA<User>().having((l) => l.handle, 'handle', 'w8385'));
      });
    });

    group('userOrganizations', () {
      const handle = 'w8385';
      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.userOrganizations(handle);
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https('solved.ac', '/api/v3/user/organizations', {
              'handle': handle,
            }),
          ),
        ).called(1);
      });

      test('returns List<Organization> on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(
          () => response.body,
        ).thenReturn(fixture('v3/user_organizations.json'));
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.userOrganizations(handle);
        expect(
          actual,
          isA<List<Organization>>().having((l) => l.length, 'length', 3),
        );
      });
    });

    group('userAvailableBadges', () {
      const handle = 'w8385';
      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.userAvailableBadges(handle);
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https('solved.ac', '/api/v3/user/available_badges', {
              'handle': handle,
            }),
          ),
        ).called(1);
      });

      test('returns List<Badge> on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(
          () => response.body,
        ).thenReturn(fixture('v3/user_available_badges.json'));
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.userAvailableBadges(handle);
        expect(actual, isA<List<Badge>>().having((l) => l.length, 'length', 3));
      });
    });

    group('userGrass', () {
      const handle = 'w8385';
      const topic = 'default';
      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.userGrass(handle, null);
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https('solved.ac', '/api/v3/user/grass', {
              'handle': handle,
              'topic': topic,
            }),
          ),
        ).called(1);
      });

      test('returns Streak on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn(fixture('v3/user_grass.json'));
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.userGrass(handle, topic);
        expect(
          actual,
          isA<Streak>().having(
            (streak) => streak.grass,
            'grass',
            isA<List<Grass>>(),
          ),
        );
      });
    });

    group('userTop100', () {
      const handle = 'w8385';
      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.userTop100(handle);
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https('solved.ac', '/api/v3/user/top_100', {'handle': handle}),
          ),
        ).called(1);
      });

      test('returns List<Problem> on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn(fixture('v3/user_top_100.json'));
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.userTop100(handle);
        expect(actual, isA<List<Problem>>());
        for (final problem in actual) {
          expect(problem, isA<Problem>());
          expect(problem.tags, isA<List<Tag>>());
        }
      });
    });

    group('userProblemStats', () {
      const handle = 'w8385';
      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.userProblemStats(handle);
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https('solved.ac', '/api/v3/user/problem_stats', {
              'handle': handle,
            }),
          ),
        ).called(1);
      });

      test('returns List<ProblemStat> on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(
          () => response.body,
        ).thenReturn(fixture('v3/user_problem_stats.json'));
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.userProblemStats(handle);
        expect(actual, isA<List<ProblemStat>>());
        for (final stat in actual) {
          expect(stat, isA<ProblemStat>());
        }
      });
    });

    group('userTagRatings', () {
      const handle = 'w8385';
      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.userTagRatings(handle);
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https('solved.ac', '/api/v3/user/tag_ratings', {
              'handle': handle,
            }),
          ),
        ).called(1);
      });

      test('returns List<TagRating> on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(
          () => response.body,
        ).thenReturn(fixture('v3/user_tag_ratings.json'));
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.userTagRatings(handle);
        expect(actual, isA<List<TagRating>>());
        for (final tagRating in actual) {
          expect(tagRating.tag, isA<Tag>());
        }
      });
    });

    group('backgroundShow', () {
      const backgroundId = 'anniversary_1st';
      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.backgroundShow(backgroundId);
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https('solved.ac', '/api/v3/background/show', {
              'backgroundId': backgroundId,
            }),
          ),
        ).called(1);
      });

      test('returns Background on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(
          () => response.body,
        ).thenReturn(fixture('v3/background_show.json'));
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.backgroundShow(backgroundId);
        expect(
          actual,
          isA<Background>().having(
            (b) => b.backgroundId,
            'backgroundId',
            backgroundId,
          ),
        );
      });
    });

    group('badgeShow', () {
      const badgeId = 'boardgame';
      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.badgeShow(badgeId);
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https('solved.ac', '/api/v3/badge/show', {'badgeId': badgeId}),
          ),
        ).called(1);
      });

      test('returns Badge on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn(fixture('v3/badge_show.json'));
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.badgeShow(badgeId);
        expect(
          actual,
          isA<Badge>().having((b) => b.badgeId, 'badgeId', badgeId),
        );
      });
    });

    group('searchSuggestions', () {
      const query = 'rsa';
      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.searchSuggestion(query);
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https('solved.ac', '/api/v3/search/suggestion', {
              'query': query,
            }),
          ),
        ).called(1);
      });

      test('returns SearchSuggestion on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(
          () => response.body,
        ).thenReturn(fixture('v3/search_suggestion.json'));
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.searchSuggestion(query);
        expect(actual, isA<SearchSuggestion>());
        expect(actual.problems, isA<List<ProblemSuggestion>>());
        expect(actual.tags, isA<List<TagSuggestion>>());
        expect(actual.users, isA<List<UserSuggestion>>());
      });
    });

    group('searchProblems', () {
      const query = 'rsa';
      const page = 1;
      const sort = 'id';
      const direction = 'asc';

      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.searchProblem(query, page, sort, direction);
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https('solved.ac', '/api/v3/search/problem', {
              'query': query,
              'page': '$page',
              'sort': sort,
              'direction': direction,
            }),
          ),
        ).called(1);
      });

      test('returns SearchObject on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn(fixture('v3/search_problem.json'));
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.searchProblem(
          query,
          page,
          sort,
          direction,
        );
        expect(actual, isA<SearchObject>());
        expect(actual.items, isA<List<Problem>>());
      });
    });

    group('searchUsers', () {
      const query = 'fdsa';
      const page = 1;

      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.searchUser(query, page);
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https('solved.ac', '/api/v3/search/user', {
              'query': query,
              'page': page.toString(),
            }),
          ),
        ).called(1);
      });

      test('returns SearchObject on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn(fixture('v3/search_user.json'));
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.searchUser(query, page);
        expect(actual, isA<SearchObject>());
        expect(actual.items, isA<List<User>>());
      });
    });

    group('searchTag', () {
      const query = 'number_theory';
      const page = 1;

      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.searchTag(query, page);
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https('solved.ac', '/api/v3/search/tag', {
              'query': query,
              'page': page.toString(),
            }),
          ),
        ).called(1);
      });

      test('returns SearchObject on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn(fixture('v3/search_tag.json'));
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.searchTag(query, page);
        expect(actual, isA<SearchObject>());
        expect(actual.items, isA<List<Tag>>());
      });
    });

    group('arenaContests', () {
      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.arenaContests();
        } catch (_) {}
        verify(
          () =>
              httpClient.get(Uri.https('solved.ac', '/api/v3/arena/contests')),
        ).called(1);
      });

      test('returns List<ArenaContest> on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn(fixture('v3/arena_contests.json'));
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.arenaContests();
        expect(actual, isA<List<ArenaContest>>());
      });
    });

    group('siteStats', () {
      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.siteStats();
        } catch (_) {}
        verify(
          () => httpClient.get(Uri.https('solved.ac', '/api/v3/site/stats')),
        ).called(1);
      });

      test('returns SiteStats on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn(fixture('v3/site_stats.json'));
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.siteStats();
        expect(actual, isA<SiteStats>());
      });
    });
  });
}
