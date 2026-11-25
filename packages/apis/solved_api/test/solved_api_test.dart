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
  SolvedApiEndpoint<UserProfile> userShow(String handle) => SolvedApiEndpoint(
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
        decode: (json) => UserProfile(
          handle: Map<String, dynamic>.from(json)['opaque'],
          badgeId: null,
          backgroundId: null,
          profileImageUrl: null,
          solvedCount: 0,
          legacyContributionCount: null,
          userClass: 0,
          reverseRivalCount: null,
          tier: 0,
          rating: 0,
        ),
      );
}

class AlternateSearchContract extends SolvedApiV3Contract {
  const AlternateSearchContract();

  @override
  SolvedApiEndpoint<SearchObject<ProblemSearchItem>> searchProblem(
    String query,
    int? page,
    String? sort,
    String? direction,
  ) =>
      _endpoint(
        path: 'find/problems',
        queryParameters: {'text': query},
        value: const SearchObject(
          count: 1,
          items: [
            ProblemSearchItem(
              problemId: 9000,
              title: 'opaque problem',
              level: 7,
              tagNames: ['opaque'],
            ),
          ],
        ),
      );

  @override
  SolvedApiEndpoint<SearchObject<UserSearchItem>> searchUser(
    String query,
    int? page,
  ) =>
      _endpoint(
        path: 'find/users',
        queryParameters: {'text': query},
        value: const SearchObject(
          count: 1,
          items: [
            UserSearchItem(
                handle: 'opaque-user', profileImageUrl: null, tier: 8),
          ],
        ),
      );

  @override
  SolvedApiEndpoint<SearchObject<TagSearchItem>> searchTag(
    String query,
    int? page,
  ) =>
      _endpoint(
        path: 'find/tags',
        queryParameters: {'text': query},
        value: const SearchObject(
          count: 1,
          items: [TagSearchItem(key: 'opaque-tag', problemCount: 9)],
        ),
      );

  SolvedApiEndpoint<T> _endpoint<T>({
    required String path,
    required Map<String, String> queryParameters,
    required T value,
  }) {
    return SolvedApiEndpoint(
      direct: SolvedApiTarget(
        baseUri: Uri.https('contract.example.com', '/direct/'),
        path: path,
        queryParameters: queryParameters,
      ),
      proxy: SolvedApiTarget(
        baseUri: Uri.https('proxy.example.com', '/gateway/'),
        path: path,
        queryParameters: queryParameters,
      ),
      decode: (_) => value,
    );
  }
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
          (_) async => http.Response('{"opaque":"contract-decoded"}', 200),
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

      test(
        'uses contract-specific search decoders without a v3 shape',
        () async {
          when(() => httpClient.get(any())).thenAnswer(
            (_) async => http.Response('{"opaque":"contract-decoded"}', 200),
          );
          apiClient = SolvedApiClient(
            httpClient: httpClient,
            useProxy: false,
            contract: const AlternateSearchContract(),
          );

          final problems = await apiClient.searchProblem(
            'opaque',
            null,
            null,
            null,
          );
          final users = await apiClient.searchUser('opaque', null);
          final tags = await apiClient.searchTag('opaque', null);

          expect(problems.items.single.title, 'opaque problem');
          expect(users.items.single.handle, 'opaque-user');
          expect(tags.items.single.key, 'opaque-tag');
          verify(
            () => httpClient.get(
              Uri.https('contract.example.com', '/direct/find/problems', {
                'text': 'opaque',
              }),
            ),
          ).called(1);
          verify(
            () => httpClient.get(
              Uri.https('contract.example.com', '/direct/find/users', {
                'text': 'opaque',
              }),
            ),
          ).called(1);
          verify(
            () => httpClient.get(
              Uri.https('contract.example.com', '/direct/find/tags', {
                'text': 'opaque',
              }),
            ),
          ).called(1);
        },
      );

      test(
        'custom base overrides only the selected contract target base',
        () async {
          when(() => httpClient.get(any())).thenAnswer(
            (_) async => http.Response('{"opaque":"contract-decoded"}', 200),
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
        },
      );

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
          'backgroundImageUrl': 'https://example.com/한글-배경.png',
          'fallbackBackgroundImageUrl': null,
        });
        when(() => httpClient.get(any())).thenAnswer(
          (_) async => http.Response.bytes(
            utf8.encode(payload),
            200,
            headers: {'content-type': 'application/json; charset=iso-8859-1'},
          ),
        );

        final background = await apiClient.backgroundShow('test');

        expect(background.imageUrl, 'https://example.com/한글-배경.png');
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
          apiClient.userShow('w8385'),
          throwsA(
            isA<UserRequestFailed>()
                .having(
                  (error) => error.uri,
                  'uri',
                  Uri.https(
                    'solved.ac',
                    '/api/v3/user/show',
                    {'handle': 'w8385'},
                  ),
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
          apiClient.userShow('w8385'),
          throwsA(
            isA<UserRequestFailed>().having(
              (error) => error.retryAfter,
              'retryAfter',
              Duration.zero,
            ),
          ),
        );
      });

      test('keeps 429 retryable and limits server retries to 5xx', () {
        expect(
          const UserRequestFailed(statusCode: 429).isRetryable,
          isTrue,
        );
        expect(
          const UserRequestFailed(statusCode: 599).isRetryable,
          isTrue,
        );
        expect(
          const UserRequestFailed(statusCode: 600).isRetryable,
          isFalse,
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

      test('does not close an externally-owned HTTP client', () {
        apiClient.close();
        apiClient.close();

        verifyNever(() => httpClient.close());
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

    group('v4 capability', () {
      test('is disabled on the legacy constructor', () {
        expect(apiClient.supportsV4, isFalse);
      });

      test('is enabled only through the official v4 factory', () {
        apiClient = SolvedApiClient.officialV4(
          proxyBaseUri: Uri.parse(
            'https://gateway.example/solved/v4/',
          ),
          httpClient: httpClient,
        );

        expect(apiClient.supportsV4, isTrue);
      });

      test('closes every legacy route before transport when v4 is configured',
          () {
        apiClient = SolvedApiClient.officialV4(
          proxyBaseUri: Uri.parse(
            'https://gateway.example/solved/v4/',
          ),
          httpClient: httpClient,
        );
        final legacyCalls = <String, Object? Function()>{
          'userShow': () => apiClient.userShow('index'),
          'userGrass': () => apiClient.userGrass('index', 'default'),
          'userProblemStats': () => apiClient.userProblemStats('index'),
          'userTagRatings': () => apiClient.userTagRatings('index'),
          'backgroundShow': () => apiClient.backgroundShow('background'),
          'badgeShow': () => apiClient.badgeShow('badge'),
          'searchProblem': () => apiClient.searchProblem('dp', 1, 'id', 'asc'),
          'searchUser': () => apiClient.searchUser('index', 1),
          'searchTag': () => apiClient.searchTag('dp', 1),
        };

        for (final entry in legacyCalls.entries) {
          expect(entry.value, throwsStateError, reason: entry.key);
        }
        verifyNever(() => httpClient.get(any()));
      });

      test('rejects v4 methods on the legacy constructor', () {
        expect(
          () => apiClient.v4UserProfile('index'),
          throwsStateError,
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

      test('returns a normalized UserProfile on valid v3 response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn(fixture('v3/user_show.json'));
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.userShow(handle);
        expect(actual, isNot(isA<OfficialUserProfile>()));
        expect(
          actual,
          isA<UserProfile>()
              .having((profile) => profile.handle, 'handle', 'w8385')
              .having((profile) => profile.badgeId, 'badgeId', 'boardgame')
              .having(
                (profile) => profile.backgroundId,
                'backgroundId',
                'boardgame_5',
              )
              .having(
                (profile) => profile.profileImageUrl,
                'profileImageUrl',
                'https://static.solved.ac/uploads/profile/'
                    'w8385-picture-1661145114047.png',
              )
              .having(
                (profile) => profile.solvedCount,
                'solvedCount',
                2766,
              )
              .having(
                (profile) => profile.legacyContributionCount,
                'legacyContributionCount',
                1442,
              )
              .having((profile) => profile.userClass, 'userClass', 6)
              .having(
                (profile) => profile.reverseRivalCount,
                'reverseRivalCount',
                44,
              )
              .having((profile) => profile.tier, 'tier', 20)
              .having((profile) => profile.rating, 'rating', 2126)
              .having(
                (profile) => profile.currentStreak,
                'currentStreak',
                isNull,
              )
              .having((profile) => profile.maxStreak, 'maxStreak', 477),
        );
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

      test('returns normalized profile streak on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn(fixture('v3/user_grass.json'));
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.userGrass(handle, topic);
        expect(actual, isNot(isA<ProfileActivityResult>()));
        expect(
          actual,
          isA<ProfileStreak>()
              .having(
                (streak) => streak.currentStreak,
                'currentStreak',
                478,
              )
              .having((streak) => streak.days, 'days', hasLength(3)),
        );
        expect(actual.days.first.year, 2023);
        expect(actual.days.first.month, 11);
        expect(actual.days.first.day, 25);
        expect(actual.days.first.solvedCount, 0);
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

      test('returns normalized profile tier stats on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(
          () => response.body,
        ).thenReturn(fixture('v3/user_problem_stats.json'));
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.userProblemStats(handle);
        expect(
            actual,
            isA<List<ProfileTierStat>>().having(
              (stats) => stats.length,
              'length',
              31,
            ));
        expect(actual.first.tier, 0);
        expect(actual.first.solvedCount, 15);
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

      test('returns normalized profile tag ratings on valid response',
          () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(
          () => response.body,
        ).thenReturn(fixture('v3/user_tag_ratings.json'));
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.userTagRatings(handle);
        expect(actual, isA<List<ProfileTagRating>>());
        expect(actual.first.rating, 1011);
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

      test('returns normalized background asset on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(
          () => response.body,
        ).thenReturn(fixture('v3/background_show.json'));
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.backgroundShow(backgroundId);
        expect(
          actual,
          isA<ProfileBackgroundAsset>()
              .having(
                (background) => background.imageUrl,
                'imageUrl',
                'https://static.solved.ac/profile_bg/anniversary_1st/anniversary_1st.png',
              )
              .having(
                (background) => background.fallbackImageUrl,
                'fallbackImageUrl',
                isNull,
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

      test('returns normalized badge asset on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn(fixture('v3/badge_show.json'));
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.badgeShow(badgeId);
        expect(
          actual,
          isA<ProfileBadgeAsset>().having(
            (badge) => badge.imageUrl,
            'imageUrl',
            'https://static.solved.ac/profile_badge/boardgame.png',
          ),
        );
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

      test('returns normalized problem results on valid response', () async {
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
        expect(actual, isA<SearchObject<ProblemSearchItem>>());
        expect(actual.count, 1);
        expect(actual.items, hasLength(1));
        expect(actual.items.single.problemId, 3734);
        expect(actual.items.single.title, 'RSA 인수 분해');
        expect(actual.items.single.level, 16);
        expect(actual.items.single.tagNames, [
          '애드 혹',
          '임의 정밀도 / 큰 수 연산',
          '브루트포스 알고리즘',
          '수학',
          '정수론',
        ]);
      });

      test('decodes items without mutating the response JSON', () {
        final json = jsonDecode(fixture('v3/search_problem.json'))
            as Map<String, dynamic>;
        final original = jsonDecode(jsonEncode(json));
        final rawItems = json['items'] as List<dynamic>;
        final rawFirstItem = rawItems.first;
        final rawTags = (rawFirstItem as Map<String, dynamic>)['tags'];

        final actual = const SolvedApiV3Contract()
            .searchProblem(query, page, sort, direction)
            .decode(json);

        expect(actual.items.single, isA<ProblemSearchItem>());
        expect(json, original);
        expect(json['items'], same(rawItems));
        expect(rawItems.first, same(rawFirstItem));
        expect((rawItems.first as Map<String, dynamic>)['tags'], same(rawTags));
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

      test('returns normalized user results on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn(fixture('v3/search_user.json'));
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.searchUser(query, page);
        expect(actual, isA<SearchObject<UserSearchItem>>());
        expect(actual.items, isA<List<UserSearchItem>>());
        expect(actual.items, hasLength(2));
        expect(actual.items.first.handle, 'fdsajklt2');
        expect(actual.items.first.tier, 16);
        expect(actual.items.first.profileImageUrl, isNull);
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

      test('returns normalized tag results on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn(fixture('v3/search_tag.json'));
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.searchTag(query, page);
        expect(actual, isA<SearchObject<TagSearchItem>>());
        expect(actual.count, 1);
        expect(actual.items, hasLength(1));
        expect(actual.items.single.key, 'number_theory');
        expect(actual.items.single.problemCount, 1314);
      });
    });
  });
}
