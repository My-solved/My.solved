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
  });
}
