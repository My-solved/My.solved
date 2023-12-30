import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:solved_api/solved_api.dart';
import 'package:test/test.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockResponse extends Mock implements http.Response {}

class FakeUri extends Fake implements Uri {}

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
            Uri.https(
              'solved.ac',
              '/api/v3/user/show',
              {'handle': handle},
            ),
          ),
        ).called(1);
      });

      test('returns User on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn(
          '''
{
  "handle": "w8385",
  "bio": "https://github.com/w8385",
  "badgeId": "boardgame",
  "backgroundId": "boardgame_5",
  "profileImageUrl": "https://static.solved.ac/uploads/profile/w8385-picture-1661145114047.png",
  "solvedCount": 2766,
  "voteCount": 1442,
  "class": 6,
  "classDecoration": "none",
  "rivalCount": 64,
  "reverseRivalCount": 44,
  "tier": 20,
  "rating": 2126,
  "ratingByProblemsSum": 1716,
  "ratingByClass": 210,
  "ratingBySolvedCount": 175,
  "ratingByVoteCount": 25,
  "arenaTier": 6,
  "arenaRating": 1545,
  "arenaMaxTier": 6,
  "arenaMaxRating": 1545,
  "arenaCompetedRoundCount": 5,
  "maxStreak": 477,
  "coins": 12,
  "stardusts": 10499,
  "joinedAt": "2022-03-20T14:55:40.000Z",
  "bannedUntil": "1970-01-01T00:00:00.000Z",
  "proUntil": "2025-08-29T22:20:53.000Z",
  "rank": 1232,
  "isRival": false,
  "isReverseRival": false,
  "blocked": false,
  "reverseBlocked": false
}''',
        );
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        final actual = await apiClient.userShow(handle);
        expect(
          actual,
          isA<User>().having((l) => l.handle, 'handle', 'w8385'),
        );
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
            Uri.https(
              'solved.ac',
              '/api/v3/user/organizations',
              {'handle': handle},
            ),
          ),
        ).called(1);
      });

      test('returns Organizations on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('''
            [
  {
    "organizationId": 323,
    "name": "숭실대학교",
    "type": "university",
    "rating": 3132,
    "userCount": 816,
    "voteCount": 15899,
    "solvedCount": 14493,
    "color": "#000000"
  },
  {
    "organizationId": 1609,
    "name": "SW마에스트로",
    "type": "community",
    "rating": 2904,
    "userCount": 185,
    "voteCount": 13428,
    "solvedCount": 10730,
    "color": "#000000"
  },
  {
    "organizationId": 1932,
    "name": "Best of the Best",
    "type": "community",
    "rating": 2243,
    "userCount": 2,
    "voteCount": 1590,
    "solvedCount": 3354,
    "color": "#000000"
  }
]
''');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        final actual = await apiClient.userOrganizations(handle);
        expect(
          actual,
          isA<Organizations>().having(
            (l) => l.organizations,
            'organizations',
            isA<List<Organization>>(),
          ),
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
            Uri.https(
              'solved.ac',
              '/api/v3/user/available_badges',
              {'handle': handle},
            ),
          ),
        ).called(1);
      });

      test('returns Badges on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('''
        {
  "count": 3,
  "items": [
    {
      "badgeId": "grass_01",
      "badgeImageUrl": "https://static.solved.ac/profile_badge/grass_01.png",
      "unlockedUserCount": 93103,
      "displayName": "Level 1 Sprout",
      "displayDescription": "Solved problems for 2 days in a row",
      "badgeTier": "bronze",
      "badgeCategory": "achievement",
      "solvedCompanyRights": true,
      "createdAt": "2021-09-14T06:18:34.000Z"
    },
    {
      "badgeId": "grass_02",
      "badgeImageUrl": "https://static.solved.ac/profile_badge/grass_02.png",
      "unlockedUserCount": 57957,
      "displayName": "Level 2 Sprout",
      "displayDescription": "Solved problems for 4 days in a row",
      "badgeTier": "bronze",
      "badgeCategory": "achievement",
      "solvedCompanyRights": true,
      "createdAt": "2021-09-14T06:18:47.000Z"
    },
    {
      "badgeId": "grass_03",
      "badgeImageUrl": "https://static.solved.ac/profile_badge/grass_03.png",
      "unlockedUserCount": 26105,
      "displayName": "Level 3 Sprout",
      "displayDescription": "Solved problems for 8 days in a row",
      "badgeTier": "bronze",
      "badgeCategory": "achievement",
      "solvedCompanyRights": true,
      "createdAt": "2021-09-14T06:18:57.000Z"
    }
  ]
}
''');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        final actual = await apiClient.userAvailableBadges(handle);
        expect(
          actual,
          isA<Badges>().having(
            (l) => l.items,
            'items',
            isA<List<Badge>>(),
          ),
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
            Uri.https(
              'solved.ac',
              '/api/v3/user/grass',
              {'handle': handle, 'topic': topic},
            ),
          ),
        ).called(1);
      });

      test('returns Grass on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('''
{
  "grass": [
    {
      "date": "2023-11-25",
      "value": "frozen"
    },
    {
      "date": "2023-10-06",
      "value": "frozen"
    },
    {
      "date": "2023-09-11",
      "value": "frozen"
    },
    {
      "date": "2023-09-07",
      "value": "frozen"
    },
    {
      "date": "2023-08-18",
      "value": "frozen"
    },
    {
      "date": "2023-08-15",
      "value": "frozen"
    },
    {
      "date": "2023-08-12",
      "value": 8
    },
    {
      "date": "2023-07-30",
      "value": "frozen"
    },
    {
      "date": "2023-01-26",
      "value": 13
    },
    {
      "date": "2022-11-03",
      "value": "frozen"
    },
    {
      "date": "2022-09-16",
      "value": 16
    },
    {
      "date": "2022-09-15",
      "value": 10
    },
    {
      "date": "2022-09-14",
      "value": 11
    },
    {
      "date": "2023-12-30",
      "value": 20
    },
    {
      "date": "2023-12-29",
      "value": 16
    },
    {
      "date": "2023-12-28",
      "value": 16
    },
    {
      "date": "2023-12-27",
      "value": 18
    },
    {
      "date": "2023-12-26",
      "value": 17
    },
    {
      "date": "2023-12-25",
      "value": 17
    },
    {
      "date": "2023-12-24",
      "value": 16
    },
    {
      "date": "2023-12-23",
      "value": 17
    },
    {
      "date": "2023-12-22",
      "value": 17
    },
    {
      "date": "2023-12-21",
      "value": 18
    },
    {
      "date": "2023-12-20",
      "value": 20
    },
    {
      "date": "2023-12-19",
      "value": 17
    },
    {
      "date": "2023-12-18",
      "value": 19
    },
    {
      "date": "2023-12-17",
      "value": 18
    },
    {
      "date": "2023-12-16",
      "value": 17
    },
    {
      "date": "2023-12-15",
      "value": 18
    },
    {
      "date": "2023-12-14",
      "value": 16
    },
    {
      "date": "2023-12-13",
      "value": 19
    },
    {
      "date": "2023-12-12",
      "value": 19
    },
    {
      "date": "2023-12-11",
      "value": 17
    },
    {
      "date": "2023-12-10",
      "value": 21
    },
    {
      "date": "2023-12-09",
      "value": 18
    },
    {
      "date": "2023-12-08",
      "value": 19
    },
    {
      "date": "2023-12-07",
      "value": 18
    },
    {
      "date": "2023-12-06",
      "value": 17
    },
    {
      "date": "2023-12-05",
      "value": 17
    },
    {
      "date": "2023-12-04",
      "value": 18
    },
    {
      "date": "2023-12-03",
      "value": 16
    },
    {
      "date": "2023-12-02",
      "value": 17
    },
    {
      "date": "2023-12-01",
      "value": 16
    },
    {
      "date": "2023-11-30",
      "value": 18
    },
    {
      "date": "2023-11-29",
      "value": 17
    },
    {
      "date": "2023-11-28",
      "value": 16
    },
    {
      "date": "2023-11-27",
      "value": 16
    },
    {
      "date": "2023-11-26",
      "value": 16
    },
    {
      "date": "2023-11-24",
      "value": 18
    },
    {
      "date": "2023-11-23",
      "value": 18
    },
    {
      "date": "2023-11-22",
      "value": 17
    },
    {
      "date": "2023-11-21",
      "value": 17
    },
    {
      "date": "2023-11-20",
      "value": 18
    },
    {
      "date": "2023-11-19",
      "value": 10
    },
    {
      "date": "2023-11-18",
      "value": 11
    },
    {
      "date": "2023-11-17",
      "value": 12
    },
    {
      "date": "2023-11-16",
      "value": 3
    },
    {
      "date": "2023-11-15",
      "value": 3
    },
    {
      "date": "2023-11-14",
      "value": 10
    },
    {
      "date": "2023-11-13",
      "value": 3
    },
    {
      "date": "2023-11-12",
      "value": 11
    },
    {
      "date": "2023-11-11",
      "value": 16
    },
    {
      "date": "2023-11-10",
      "value": 1
    },
    {
      "date": "2023-11-09",
      "value": 2
    },
    {
      "date": "2023-11-08",
      "value": 6
    },
    {
      "date": "2023-11-07",
      "value": 2
    },
    {
      "date": "2023-11-06",
      "value": 15
    },
    {
      "date": "2023-11-05",
      "value": 13
    },
    {
      "date": "2023-11-04",
      "value": 16
    },
    {
      "date": "2023-11-03",
      "value": 4
    },
    {
      "date": "2023-11-02",
      "value": 12
    },
    {
      "date": "2023-11-01",
      "value": 11
    },
    {
      "date": "2023-10-31",
      "value": 19
    },
    {
      "date": "2023-10-30",
      "value": 4
    },
    {
      "date": "2023-10-29",
      "value": 8
    },
    {
      "date": "2023-10-28",
      "value": 19
    },
    {
      "date": "2023-10-27",
      "value": 5
    },
    {
      "date": "2023-10-26",
      "value": 4
    },
    {
      "date": "2023-10-25",
      "value": 5
    },
    {
      "date": "2023-10-24",
      "value": 4
    },
    {
      "date": "2023-10-23",
      "value": 4
    },
    {
      "date": "2023-10-22",
      "value": 3
    },
    {
      "date": "2023-10-21",
      "value": 3
    },
    {
      "date": "2023-10-20",
      "value": 2
    },
    {
      "date": "2023-10-19",
      "value": 3
    },
    {
      "date": "2023-10-18",
      "value": 2
    },
    {
      "date": "2023-10-17",
      "value": 3
    },
    {
      "date": "2023-10-16",
      "value": 11
    },
    {
      "date": "2023-10-15",
      "value": 2
    },
    {
      "date": "2023-10-14",
      "value": 3
    },
    {
      "date": "2023-10-13",
      "value": 3
    },
    {
      "date": "2023-10-12",
      "value": 3
    },
    {
      "date": "2023-10-11",
      "value": 3
    },
    {
      "date": "2023-10-10",
      "value": 2
    },
    {
      "date": "2023-10-09",
      "value": 1
    },
    {
      "date": "2023-10-08",
      "value": 3
    },
    {
      "date": "2023-10-07",
      "value": 4
    },
    {
      "date": "2023-10-05",
      "value": 2
    },
    {
      "date": "2023-10-04",
      "value": 2
    },
    {
      "date": "2023-10-03",
      "value": 2
    },
    {
      "date": "2023-10-02",
      "value": 2
    },
    {
      "date": "2023-10-01",
      "value": 2
    },
    {
      "date": "2023-09-30",
      "value": 9
    },
    {
      "date": "2023-09-29",
      "value": 1
    },
    {
      "date": "2023-09-28",
      "value": 1
    },
    {
      "date": "2023-09-27",
      "value": 8
    },
    {
      "date": "2023-09-26",
      "value": 4
    },
    {
      "date": "2023-09-25",
      "value": 1
    },
    {
      "date": "2023-09-24",
      "value": 13
    },
    {
      "date": "2023-09-23",
      "value": 1
    },
    {
      "date": "2023-09-22",
      "value": 2
    },
    {
      "date": "2023-09-21",
      "value": 3
    },
    {
      "date": "2023-09-20",
      "value": 2
    },
    {
      "date": "2023-09-19",
      "value": 1
    },
    {
      "date": "2023-09-18",
      "value": 3
    },
    {
      "date": "2023-09-17",
      "value": 11
    },
    {
      "date": "2023-09-16",
      "value": 3
    },
    {
      "date": "2023-09-15",
      "value": 2
    },
    {
      "date": "2023-09-14",
      "value": 1
    },
    {
      "date": "2023-09-13",
      "value": 1
    },
    {
      "date": "2023-09-12",
      "value": 3
    },
    {
      "date": "2023-09-10",
      "value": 8
    },
    {
      "date": "2023-09-09",
      "value": 1
    },
    {
      "date": "2023-09-08",
      "value": 6
    },
    {
      "date": "2023-09-06",
      "value": 3
    },
    {
      "date": "2023-09-05",
      "value": 4
    },
    {
      "date": "2023-09-04",
      "value": 4
    },
    {
      "date": "2023-09-03",
      "value": 6
    },
    {
      "date": "2023-09-02",
      "value": 4
    },
    {
      "date": "2023-09-01",
      "value": 4
    },
    {
      "date": "2023-08-31",
      "value": 6
    },
    {
      "date": "2023-08-30",
      "value": 9
    },
    {
      "date": "2023-08-29",
      "value": 3
    },
    {
      "date": "2023-08-28",
      "value": 5
    },
    {
      "date": "2023-08-27",
      "value": 4
    },
    {
      "date": "2023-08-26",
      "value": 11
    },
    {
      "date": "2023-08-25",
      "value": 2
    },
    {
      "date": "2023-08-24",
      "value": 5
    },
    {
      "date": "2023-08-23",
      "value": 6
    },
    {
      "date": "2023-08-22",
      "value": 2
    },
    {
      "date": "2023-08-21",
      "value": 1
    },
    {
      "date": "2023-08-20",
      "value": 1
    },
    {
      "date": "2023-08-19",
      "value": 1
    },
    {
      "date": "2023-08-17",
      "value": 0
    },
    {
      "date": "2023-08-16",
      "value": 1
    },
    {
      "date": "2023-08-14",
      "value": 1
    },
    {
      "date": "2023-08-13",
      "value": 2
    },
    {
      "date": "2023-08-11",
      "value": 2
    },
    {
      "date": "2023-08-10",
      "value": 4
    },
    {
      "date": "2023-08-09",
      "value": 2
    },
    {
      "date": "2023-08-08",
      "value": 4
    },
    {
      "date": "2023-08-07",
      "value": 4
    },
    {
      "date": "2023-08-06",
      "value": 13
    },
    {
      "date": "2023-08-05",
      "value": 8
    },
    {
      "date": "2023-08-04",
      "value": 5
    },
    {
      "date": "2023-08-03",
      "value": 4
    },
    {
      "date": "2023-08-02",
      "value": 4
    },
    {
      "date": "2023-08-01",
      "value": 7
    },
    {
      "date": "2023-07-31",
      "value": 3
    },
    {
      "date": "2023-07-29",
      "value": 6
    },
    {
      "date": "2023-07-28",
      "value": 4
    },
    {
      "date": "2023-07-27",
      "value": 4
    },
    {
      "date": "2023-07-26",
      "value": 4
    },
    {
      "date": "2023-07-25",
      "value": 5
    },
    {
      "date": "2023-07-24",
      "value": 4
    },
    {
      "date": "2023-07-23",
      "value": 3
    },
    {
      "date": "2023-07-22",
      "value": 4
    },
    {
      "date": "2023-07-21",
      "value": 3
    },
    {
      "date": "2023-07-20",
      "value": 3
    },
    {
      "date": "2023-07-19",
      "value": 2
    },
    {
      "date": "2023-07-18",
      "value": 12
    },
    {
      "date": "2023-07-17",
      "value": 2
    },
    {
      "date": "2023-07-16",
      "value": 2
    },
    {
      "date": "2023-07-15",
      "value": 9
    },
    {
      "date": "2023-07-14",
      "value": 6
    },
    {
      "date": "2023-07-13",
      "value": 11
    },
    {
      "date": "2023-07-12",
      "value": 7
    },
    {
      "date": "2023-07-11",
      "value": 6
    },
    {
      "date": "2023-07-10",
      "value": 6
    },
    {
      "date": "2023-07-09",
      "value": 7
    },
    {
      "date": "2023-07-08",
      "value": 4
    },
    {
      "date": "2023-07-07",
      "value": 4
    },
    {
      "date": "2023-07-06",
      "value": 5
    },
    {
      "date": "2023-07-05",
      "value": 7
    },
    {
      "date": "2023-07-04",
      "value": 7
    },
    {
      "date": "2023-07-03",
      "value": 9
    },
    {
      "date": "2023-07-02",
      "value": 6
    },
    {
      "date": "2023-07-01",
      "value": 9
    },
    {
      "date": "2023-06-30",
      "value": 4
    },
    {
      "date": "2023-06-29",
      "value": 10
    },
    {
      "date": "2023-06-28",
      "value": 15
    },
    {
      "date": "2023-06-27",
      "value": 11
    },
    {
      "date": "2023-06-26",
      "value": 11
    },
    {
      "date": "2023-06-25",
      "value": 11
    },
    {
      "date": "2023-06-24",
      "value": 9
    },
    {
      "date": "2023-06-23",
      "value": 9
    },
    {
      "date": "2023-06-22",
      "value": 10
    },
    {
      "date": "2023-06-21",
      "value": 13
    },
    {
      "date": "2023-06-20",
      "value": 6
    },
    {
      "date": "2023-06-19",
      "value": 9
    },
    {
      "date": "2023-06-18",
      "value": 7
    },
    {
      "date": "2023-06-17",
      "value": 11
    },
    {
      "date": "2023-06-16",
      "value": 8
    },
    {
      "date": "2023-06-15",
      "value": 9
    },
    {
      "date": "2023-06-14",
      "value": 8
    },
    {
      "date": "2023-06-13",
      "value": 8
    },
    {
      "date": "2023-06-12",
      "value": 6
    },
    {
      "date": "2023-06-11",
      "value": 6
    },
    {
      "date": "2023-06-10",
      "value": 9
    },
    {
      "date": "2023-06-09",
      "value": 15
    },
    {
      "date": "2023-06-08",
      "value": 17
    },
    {
      "date": "2023-06-07",
      "value": 6
    },
    {
      "date": "2023-06-06",
      "value": 9
    },
    {
      "date": "2023-06-05",
      "value": 10
    },
    {
      "date": "2023-06-04",
      "value": 4
    },
    {
      "date": "2023-06-03",
      "value": 15
    },
    {
      "date": "2023-06-02",
      "value": 16
    },
    {
      "date": "2023-06-01",
      "value": 18
    },
    {
      "date": "2023-05-31",
      "value": 17
    },
    {
      "date": "2023-05-30",
      "value": 16
    },
    {
      "date": "2023-05-29",
      "value": 7
    },
    {
      "date": "2023-05-28",
      "value": 18
    },
    {
      "date": "2023-05-27",
      "value": 15
    },
    {
      "date": "2023-05-26",
      "value": 15
    },
    {
      "date": "2023-05-25",
      "value": 6
    },
    {
      "date": "2023-05-24",
      "value": 5
    },
    {
      "date": "2023-05-23",
      "value": 4
    },
    {
      "date": "2023-05-22",
      "value": 15
    },
    {
      "date": "2023-05-21",
      "value": 12
    },
    {
      "date": "2023-05-20",
      "value": 11
    },
    {
      "date": "2023-05-19",
      "value": 20
    },
    {
      "date": "2023-05-18",
      "value": 9
    },
    {
      "date": "2023-05-17",
      "value": 4
    },
    {
      "date": "2023-05-16",
      "value": 9
    },
    {
      "date": "2023-05-15",
      "value": 4
    },
    {
      "date": "2023-05-14",
      "value": 3
    },
    {
      "date": "2023-05-13",
      "value": 16
    },
    {
      "date": "2023-05-12",
      "value": 3
    },
    {
      "date": "2023-05-11",
      "value": 4
    },
    {
      "date": "2023-05-10",
      "value": 8
    },
    {
      "date": "2023-05-09",
      "value": 5
    },
    {
      "date": "2023-05-08",
      "value": 4
    },
    {
      "date": "2023-05-07",
      "value": 4
    },
    {
      "date": "2023-05-06",
      "value": 6
    },
    {
      "date": "2023-05-05",
      "value": 4
    },
    {
      "date": "2023-05-04",
      "value": 6
    },
    {
      "date": "2023-05-03",
      "value": 5
    },
    {
      "date": "2023-05-02",
      "value": 5
    },
    {
      "date": "2023-05-01",
      "value": 6
    },
    {
      "date": "2023-04-30",
      "value": 6
    },
    {
      "date": "2023-04-29",
      "value": 10
    },
    {
      "date": "2023-04-28",
      "value": 4
    },
    {
      "date": "2023-04-27",
      "value": 5
    },
    {
      "date": "2023-04-26",
      "value": 5
    },
    {
      "date": "2023-04-25",
      "value": 5
    },
    {
      "date": "2023-04-24",
      "value": 5
    },
    {
      "date": "2023-04-23",
      "value": 10
    },
    {
      "date": "2023-04-22",
      "value": 4
    },
    {
      "date": "2023-04-21",
      "value": 3
    },
    {
      "date": "2023-04-20",
      "value": 3
    },
    {
      "date": "2023-04-19",
      "value": 12
    },
    {
      "date": "2023-04-18",
      "value": 11
    },
    {
      "date": "2023-04-17",
      "value": 9
    },
    {
      "date": "2023-04-16",
      "value": 13
    },
    {
      "date": "2023-04-15",
      "value": 8
    },
    {
      "date": "2023-04-14",
      "value": 3
    },
    {
      "date": "2023-04-13",
      "value": 13
    },
    {
      "date": "2023-04-12",
      "value": 3
    },
    {
      "date": "2023-04-11",
      "value": 10
    },
    {
      "date": "2023-04-10",
      "value": 12
    },
    {
      "date": "2023-04-09",
      "value": 14
    },
    {
      "date": "2023-04-08",
      "value": 7
    },
    {
      "date": "2023-04-07",
      "value": 4
    },
    {
      "date": "2023-04-06",
      "value": 3
    },
    {
      "date": "2023-04-05",
      "value": 15
    },
    {
      "date": "2023-04-04",
      "value": 8
    },
    {
      "date": "2023-04-03",
      "value": 3
    },
    {
      "date": "2023-04-02",
      "value": 10
    },
    {
      "date": "2023-04-01",
      "value": 6
    },
    {
      "date": "2023-03-31",
      "value": 3
    },
    {
      "date": "2023-03-30",
      "value": 4
    },
    {
      "date": "2023-03-29",
      "value": 17
    },
    {
      "date": "2023-03-28",
      "value": 5
    },
    {
      "date": "2023-03-27",
      "value": 3
    },
    {
      "date": "2023-03-26",
      "value": 3
    },
    {
      "date": "2023-03-25",
      "value": 3
    },
    {
      "date": "2023-03-24",
      "value": 3
    },
    {
      "date": "2023-03-23",
      "value": 6
    },
    {
      "date": "2023-03-22",
      "value": 6
    },
    {
      "date": "2023-03-21",
      "value": 3
    },
    {
      "date": "2023-03-20",
      "value": 13
    },
    {
      "date": "2023-03-19",
      "value": 3
    },
    {
      "date": "2023-03-18",
      "value": 13
    },
    {
      "date": "2023-03-17",
      "value": 9
    },
    {
      "date": "2023-03-16",
      "value": 3
    },
    {
      "date": "2023-03-15",
      "value": 14
    },
    {
      "date": "2023-03-14",
      "value": 13
    },
    {
      "date": "2023-03-13",
      "value": 4
    },
    {
      "date": "2023-03-12",
      "value": 10
    },
    {
      "date": "2023-03-11",
      "value": 15
    },
    {
      "date": "2023-03-10",
      "value": 10
    },
    {
      "date": "2023-03-09",
      "value": 9
    },
    {
      "date": "2023-03-08",
      "value": 5
    },
    {
      "date": "2023-03-07",
      "value": 9
    },
    {
      "date": "2023-03-06",
      "value": 8
    },
    {
      "date": "2023-03-05",
      "value": 5
    },
    {
      "date": "2023-03-04",
      "value": 5
    },
    {
      "date": "2023-03-03",
      "value": 12
    },
    {
      "date": "2023-03-02",
      "value": 3
    },
    {
      "date": "2023-03-01",
      "value": 3
    },
    {
      "date": "2023-02-28",
      "value": 3
    },
    {
      "date": "2023-02-27",
      "value": 3
    },
    {
      "date": "2023-02-26",
      "value": 14
    },
    {
      "date": "2023-02-25",
      "value": 9
    },
    {
      "date": "2023-02-24",
      "value": 14
    },
    {
      "date": "2023-02-23",
      "value": 14
    },
    {
      "date": "2023-02-22",
      "value": 14
    },
    {
      "date": "2023-02-21",
      "value": 12
    },
    {
      "date": "2023-02-20",
      "value": 9
    },
    {
      "date": "2023-02-19",
      "value": 12
    },
    {
      "date": "2023-02-18",
      "value": 12
    },
    {
      "date": "2023-02-17",
      "value": 3
    },
    {
      "date": "2023-02-16",
      "value": 3
    },
    {
      "date": "2023-02-15",
      "value": 3
    },
    {
      "date": "2023-02-14",
      "value": 9
    },
    {
      "date": "2023-02-13",
      "value": 10
    },
    {
      "date": "2023-02-12",
      "value": 16
    },
    {
      "date": "2023-02-11",
      "value": 7
    },
    {
      "date": "2023-02-10",
      "value": 3
    },
    {
      "date": "2023-02-09",
      "value": 9
    },
    {
      "date": "2023-02-08",
      "value": 14
    },
    {
      "date": "2023-02-07",
      "value": 20
    },
    {
      "date": "2023-02-06",
      "value": 15
    },
    {
      "date": "2023-02-05",
      "value": 5
    },
    {
      "date": "2023-02-04",
      "value": 3
    },
    {
      "date": "2023-02-03",
      "value": 13
    },
    {
      "date": "2023-02-02",
      "value": 12
    },
    {
      "date": "2023-02-01",
      "value": 15
    },
    {
      "date": "2023-01-31",
      "value": 15
    },
    {
      "date": "2023-01-30",
      "value": 10
    },
    {
      "date": "2023-01-29",
      "value": 6
    },
    {
      "date": "2023-01-28",
      "value": 14
    },
    {
      "date": "2023-01-27",
      "value": 12
    },
    {
      "date": "2023-01-25",
      "value": 6
    },
    {
      "date": "2023-01-24",
      "value": 5
    },
    {
      "date": "2023-01-23",
      "value": 6
    },
    {
      "date": "2023-01-22",
      "value": 5
    },
    {
      "date": "2023-01-21",
      "value": 5
    },
    {
      "date": "2023-01-20",
      "value": 5
    },
    {
      "date": "2023-01-19",
      "value": 13
    },
    {
      "date": "2023-01-18",
      "value": 3
    },
    {
      "date": "2023-01-17",
      "value": 6
    },
    {
      "date": "2023-01-16",
      "value": 8
    },
    {
      "date": "2023-01-15",
      "value": 3
    },
    {
      "date": "2023-01-14",
      "value": 10
    },
    {
      "date": "2023-01-13",
      "value": 15
    },
    {
      "date": "2023-01-12",
      "value": 13
    },
    {
      "date": "2023-01-11",
      "value": 16
    },
    {
      "date": "2023-01-10",
      "value": 16
    },
    {
      "date": "2023-01-09",
      "value": 14
    },
    {
      "date": "2023-01-08",
      "value": 15
    },
    {
      "date": "2023-01-07",
      "value": 14
    },
    {
      "date": "2023-01-06",
      "value": 13
    },
    {
      "date": "2023-01-05",
      "value": 2
    },
    {
      "date": "2023-01-04",
      "value": 13
    },
    {
      "date": "2023-01-03",
      "value": 2
    },
    {
      "date": "2023-01-02",
      "value": 11
    },
    {
      "date": "2023-01-01",
      "value": 11
    },
    {
      "date": "2022-12-31",
      "value": 15
    },
    {
      "date": "2022-12-30",
      "value": 8
    },
    {
      "date": "2022-12-29",
      "value": 13
    },
    {
      "date": "2022-12-28",
      "value": 12
    },
    {
      "date": "2022-12-27",
      "value": 2
    },
    {
      "date": "2022-12-26",
      "value": 8
    },
    {
      "date": "2022-12-25",
      "value": 13
    },
    {
      "date": "2022-12-24",
      "value": 11
    },
    {
      "date": "2022-12-23",
      "value": 1
    },
    {
      "date": "2022-12-22",
      "value": 7
    },
    {
      "date": "2022-12-21",
      "value": 12
    },
    {
      "date": "2022-12-20",
      "value": 11
    },
    {
      "date": "2022-12-19",
      "value": 9
    },
    {
      "date": "2022-12-18",
      "value": 9
    },
    {
      "date": "2022-12-17",
      "value": 6
    },
    {
      "date": "2022-12-16",
      "value": 9
    },
    {
      "date": "2022-12-15",
      "value": 7
    },
    {
      "date": "2022-12-14",
      "value": 7
    },
    {
      "date": "2022-12-13",
      "value": 1
    },
    {
      "date": "2022-12-12",
      "value": 13
    },
    {
      "date": "2022-12-11",
      "value": 15
    },
    {
      "date": "2022-12-10",
      "value": 17
    },
    {
      "date": "2022-12-09",
      "value": 20
    },
    {
      "date": "2022-12-08",
      "value": 15
    },
    {
      "date": "2022-12-07",
      "value": 20
    },
    {
      "date": "2022-12-06",
      "value": 12
    },
    {
      "date": "2022-12-05",
      "value": 20
    },
    {
      "date": "2022-12-04",
      "value": 17
    },
    {
      "date": "2022-12-03",
      "value": 11
    },
    {
      "date": "2022-12-02",
      "value": 16
    },
    {
      "date": "2022-12-01",
      "value": 16
    },
    {
      "date": "2022-11-30",
      "value": 12
    },
    {
      "date": "2022-11-29",
      "value": 9
    },
    {
      "date": "2022-11-28",
      "value": 12
    },
    {
      "date": "2022-11-27",
      "value": 9
    },
    {
      "date": "2022-11-26",
      "value": 6
    },
    {
      "date": "2022-11-25",
      "value": 13
    },
    {
      "date": "2022-11-24",
      "value": 15
    },
    {
      "date": "2022-11-23",
      "value": 15
    },
    {
      "date": "2022-11-22",
      "value": 11
    },
    {
      "date": "2022-11-21",
      "value": 15
    },
    {
      "date": "2022-11-20",
      "value": 8
    },
    {
      "date": "2022-11-19",
      "value": 4
    },
    {
      "date": "2022-11-18",
      "value": 4
    },
    {
      "date": "2022-11-17",
      "value": 3
    },
    {
      "date": "2022-11-16",
      "value": 7
    },
    {
      "date": "2022-11-15",
      "value": 1
    },
    {
      "date": "2022-11-14",
      "value": 7
    },
    {
      "date": "2022-11-13",
      "value": 7
    },
    {
      "date": "2022-11-12",
      "value": 14
    },
    {
      "date": "2022-11-11",
      "value": 11
    },
    {
      "date": "2022-11-10",
      "value": 9
    },
    {
      "date": "2022-11-09",
      "value": 11
    },
    {
      "date": "2022-11-08",
      "value": 9
    },
    {
      "date": "2022-11-07",
      "value": 7
    },
    {
      "date": "2022-11-06",
      "value": 7
    },
    {
      "date": "2022-11-05",
      "value": 7
    },
    {
      "date": "2022-11-04",
      "value": 1
    },
    {
      "date": "2022-11-02",
      "value": 6
    },
    {
      "date": "2022-11-01",
      "value": 6
    },
    {
      "date": "2022-10-31",
      "value": 6
    },
    {
      "date": "2022-10-30",
      "value": 16
    },
    {
      "date": "2022-10-29",
      "value": 11
    },
    {
      "date": "2022-10-28",
      "value": 11
    },
    {
      "date": "2022-10-27",
      "value": 2
    },
    {
      "date": "2022-10-26",
      "value": 7
    },
    {
      "date": "2022-10-25",
      "value": 11
    },
    {
      "date": "2022-10-24",
      "value": 9
    },
    {
      "date": "2022-10-23",
      "value": 11
    },
    {
      "date": "2022-10-22",
      "value": 5
    },
    {
      "date": "2022-10-21",
      "value": 3
    },
    {
      "date": "2022-10-20",
      "value": 2
    },
    {
      "date": "2022-10-19",
      "value": 2
    },
    {
      "date": "2022-10-18",
      "value": 9
    },
    {
      "date": "2022-10-17",
      "value": 12
    },
    {
      "date": "2022-10-16",
      "value": 10
    },
    {
      "date": "2022-10-15",
      "value": 9
    },
    {
      "date": "2022-10-14",
      "value": 1
    },
    {
      "date": "2022-10-13",
      "value": 9
    },
    {
      "date": "2022-10-12",
      "value": 9
    },
    {
      "date": "2022-10-11",
      "value": 2
    },
    {
      "date": "2022-10-10",
      "value": 10
    },
    {
      "date": "2022-10-09",
      "value": 10
    },
    {
      "date": "2022-10-08",
      "value": 5
    },
    {
      "date": "2022-10-07",
      "value": 2
    },
    {
      "date": "2022-10-06",
      "value": 2
    },
    {
      "date": "2022-10-05",
      "value": 11
    },
    {
      "date": "2022-10-04",
      "value": 12
    },
    {
      "date": "2022-10-03",
      "value": 11
    },
    {
      "date": "2022-10-02",
      "value": 4
    },
    {
      "date": "2022-10-01",
      "value": 2
    },
    {
      "date": "2022-09-30",
      "value": 11
    },
    {
      "date": "2022-09-29",
      "value": 10
    },
    {
      "date": "2022-09-28",
      "value": 12
    },
    {
      "date": "2022-09-27",
      "value": 2
    },
    {
      "date": "2022-09-26",
      "value": 10
    },
    {
      "date": "2022-09-25",
      "value": 10
    },
    {
      "date": "2022-09-24",
      "value": 13
    },
    {
      "date": "2022-09-23",
      "value": 12
    },
    {
      "date": "2022-09-22",
      "value": 12
    },
    {
      "date": "2022-09-21",
      "value": 13
    },
    {
      "date": "2022-09-20",
      "value": 11
    },
    {
      "date": "2022-09-19",
      "value": 13
    },
    {
      "date": "2022-09-18",
      "value": 12
    },
    {
      "date": "2022-09-17",
      "value": 2
    },
    {
      "date": "2022-09-13",
      "value": 2
    },
    {
      "date": "2022-09-12",
      "value": 9
    },
    {
      "date": "2022-09-11",
      "value": 10
    },
    {
      "date": "2022-09-10",
      "value": 1
    },
    {
      "date": "2022-09-09",
      "value": 1
    },
    {
      "date": "2022-09-08",
      "value": 6
    },
    {
      "date": "2022-09-07",
      "value": 10
    },
    {
      "date": "2022-09-06",
      "value": 11
    },
    {
      "date": "2022-09-05",
      "value": 10
    },
    {
      "date": "2022-09-04",
      "value": 9
    },
    {
      "date": "2022-09-03",
      "value": 9
    },
    {
      "date": "2022-09-02",
      "value": 8
    },
    {
      "date": "2022-09-01",
      "value": 7
    },
    {
      "date": "2022-08-24",
      "value": 6
    },
    {
      "date": "2022-08-23",
      "value": 6
    },
    {
      "date": "2022-08-22",
      "value": 7
    },
    {
      "date": "2022-08-20",
      "value": 6
    },
    {
      "date": "2022-08-14",
      "value": 7
    },
    {
      "date": "2022-08-02",
      "value": 7
    },
    {
      "date": "2022-08-01",
      "value": 7
    },
    {
      "date": "2022-07-30",
      "value": 5
    },
    {
      "date": "2022-07-26",
      "value": 6
    },
    {
      "date": "2022-07-17",
      "value": 6
    }
  ],
  "theme": "special_hanbyeol",
  "currentStreak": 478,
  "longestStreak": 478,
  "topic": "today-solved-max-tier"
}
        ''');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        final actual = await apiClient.userGrass(handle, topic);
        expect(actual, isA<Grass>());
      });
    });

    group('userTop100', () => {});

    group('userTagRatings', () => {});

    group('backgroundShow', () => {});

    group('badgeShow', () => {});

    group('searchSuggestions', () => {});

    group('searchProblems', () => {});

    group('searchTag', () => {});

    group('arenaContests', () => {});

    group('siteStats', () => {});
  });
}
