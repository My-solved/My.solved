import 'package:mocktail/mocktail.dart';
import 'package:solved_api/solved_api.dart' as solved_api;
import 'package:test/test.dart';
import 'package:user_repository/user_repository.dart';

class MockSolvedApiClient extends Mock implements solved_api.SolvedApiClient {}

class MockUserProfile extends Mock implements solved_api.UserProfile {}

class MockProfileStreak extends Mock implements solved_api.ProfileStreak {}

class MockProfileTierStat extends Mock implements solved_api.ProfileTierStat {}

class MockProfileTagRating extends Mock implements solved_api.ProfileTagRating {}

class MockProfileBackgroundAsset extends Mock
    implements solved_api.ProfileBackgroundAsset {}

class MockProfileBadgeAsset extends Mock
    implements solved_api.ProfileBadgeAsset {}

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
        final user = MockUserProfile();
        when(() => solvedApiClient.userShow(handle))
            .thenAnswer((_) async => user);

        expect(await userRepository.getUser(handle), user);
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
        final streak = MockProfileStreak();
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
        final problemStats = [MockProfileTierStat()];
        when(() => solvedApiClient.userProblemStats(handle))
            .thenAnswer((_) async => problemStats);

        expect(await userRepository.getProblemStats(handle), problemStats);
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
        final tagRatings = [MockProfileTagRating()];
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
        final background = MockProfileBackgroundAsset();
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
        final badge = MockProfileBadgeAsset();
        when(() => solvedApiClient.badgeShow(badgeId))
            .thenAnswer((_) async => badge);

        expect(await userRepository.getBadge(badgeId), badge);
      });
    });
  });
}
