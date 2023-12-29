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

    group('userGrass', () {});

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
