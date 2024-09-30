import 'package:mocktail/mocktail.dart';
import 'package:solved_api/solved_api.dart' as solved_api;
import 'package:test/test.dart';
import 'package:user_repository/user_repository.dart';

class MockSolvedApiClient extends Mock implements solved_api.SolvedApiClient {}

class MockUser extends Mock implements solved_api.User {}

class MockOrganization extends Mock implements solved_api.Organization {}

class MockBadge extends Mock implements solved_api.Badge {}

class MockStreak extends Mock implements solved_api.Streak {}

class MockProblem extends Mock implements solved_api.Problem {}

class MockProblemStats extends Mock implements solved_api.ProblemStat {}

class MockTagRating extends Mock implements solved_api.TagRating {}

class MockBackground extends Mock implements solved_api.Background {}

class MockSiteStats extends Mock implements solved_api.SiteStats {}

void main() {
  group('UserRepository', () {
    late solved_api.SolvedApiClient solvedApiClient;
    late UserRepository userRepository;

    setUp(() {
      solvedApiClient = MockSolvedApiClient();
      userRepository = UserRepository(solvedApiClient: solvedApiClient);
    });

    group('getUser', () {
      const handle = 'w8385';

      test('calls userShow with correct handle', () async {
        try {
          await userRepository.getUser(handle);
        } catch (_) {}
        verify(() => solvedApiClient.userShow(handle)).called(1);
      });

      test('returns correct user on success', () async {
        final user = MockUser();
        when(() => solvedApiClient.userShow(handle))
            .thenAnswer((_) async => user);

        expect(await userRepository.getUser(handle), user);
      });
    });

    group('getOrganizations', () {
      const handle = 'w8385';

      test('calls userOrganizations with correct handle', () async {
        try {
          await userRepository.getOrganizations(handle);
        } catch (_) {}
        verify(() => solvedApiClient.userOrganizations(handle)).called(1);
      });

      test('returns correct organizations on success', () async {
        final organizations = [MockOrganization()];
        when(() => solvedApiClient.userOrganizations(handle))
            .thenAnswer((_) async => organizations);

        expect(await userRepository.getOrganizations(handle), organizations);
      });
    });

    group('getBadges', () {
      const handle = 'w8385';

      test('calls userAvailableBadges with correct handle', () async {
        try {
          await userRepository.getBadges(handle);
        } catch (_) {}
        verify(() => solvedApiClient.userAvailableBadges(handle)).called(1);
      });

      test('returns correct badges on success', () async {
        final badges = [MockBadge()];
        when(() => solvedApiClient.userAvailableBadges(handle))
            .thenAnswer((_) async => badges);

        expect(await userRepository.getBadges(handle), badges);
      });
    });

    group('getStreak', () {
      const handle = 'w8385';
      const topic = 'today-solved';

      test('calls userGrass with correct handle and topic', () async {
        try {
          await userRepository.getStreak(handle, topic);
        } catch (_) {}
        verify(() => solvedApiClient.userGrass(handle, topic)).called(1);
      });

      test('returns correct streak on success', () async {
        final streak = MockStreak();
        when(() => solvedApiClient.userGrass(handle, topic))
            .thenAnswer((_) async => streak);

        expect(await userRepository.getStreak(handle, topic), streak);
      });
    });

    group('getProblemStats', () {
      const handle = 'w8385';

      test('calls userProblemStats with correct handle', () async {
        try {
          await userRepository.getProblemStats(handle);
        } catch (_) {}
        verify(() => solvedApiClient.userProblemStats(handle)).called(1);
      });

      test('returns correct problemStats on success', () async {
        final problemStats = [MockProblemStats()];
        when(() => solvedApiClient.userProblemStats(handle))
            .thenAnswer((_) async => problemStats);

        expect(await userRepository.getProblemStats(handle), problemStats);
      });
    });

    group('getTopProblems', () {
      const handle = 'w8385';

      test('calls userTop100 with correct handle', () async {
        final problems = [MockProblem()];
        when(() => solvedApiClient.userTop100(handle))
            .thenAnswer((_) async => problems);

        await userRepository.getTopProblems(handle);

        verify(() => solvedApiClient.userTop100(handle)).called(1);
      });

      test('returns correct problems on success', () async {
        final problems = [MockProblem()];
        when(() => solvedApiClient.userTop100(handle))
            .thenAnswer((_) async => problems);

        expect(await userRepository.getTopProblems(handle), problems);
      });
    });

    group('getTagRatings', () {
      const handle = 'w8385';

      test('calls userTagRatings with correct handle', () async {
        try {
          await userRepository.getTagRatings(handle);
        } catch (_) {}
        verify(() => solvedApiClient.userTagRatings(handle)).called(1);
      });

      test('returns correct tagRatings on success', () async {
        final tagRatings = [MockTagRating()];
        when(() => solvedApiClient.userTagRatings(handle))
            .thenAnswer((_) async => tagRatings);

        expect(await userRepository.getTagRatings(handle), tagRatings);
      });
    });

    group('getBackground', () {
      const backgroundId = 'boardgame_5';

      test('calls backgroundShow with correct backgroundId', () async {
        try {
          await userRepository.getBackground(backgroundId);
        } catch (_) {}
        verify(() => solvedApiClient.backgroundShow(backgroundId)).called(1);
      });

      test('returns correct background on success', () async {
        final background = MockBackground();
        when(() => solvedApiClient.backgroundShow(backgroundId))
            .thenAnswer((_) async => background);

        expect(await userRepository.getBackground(backgroundId), background);
      });
    });

    group('getBadge', () {
      const badgeId = 'boardgame';

      test('calls badgeShow with correct badgeId', () async {
        try {
          await userRepository.getBadge(badgeId);
        } catch (_) {}
        verify(() => solvedApiClient.badgeShow(badgeId)).called(1);
      });

      test('returns correct badge on success', () async {
        final badge = MockBadge();
        when(() => solvedApiClient.badgeShow(badgeId))
            .thenAnswer((_) async => badge);

        expect(await userRepository.getBadge(badgeId), badge);
      });
    });

    group('getSiteStats', () {
      test('calls siteStats', () async {
        try {
          await userRepository.getSiteStats();
        } catch (_) {}
        verify(() => solvedApiClient.siteStats()).called(1);
      });

      test('returns correct siteStats on success', () async {
        final siteStats = MockSiteStats();
        when(() => solvedApiClient.siteStats())
            .thenAnswer((_) async => siteStats);

        expect(await userRepository.getSiteStats(), siteStats);
      });
    });
  });
}
