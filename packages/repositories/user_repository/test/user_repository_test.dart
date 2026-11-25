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
      when(() => solvedApiClient.supportsV4).thenReturn(false);
      userRepository = UserRepository(solvedApiClient: solvedApiClient);
    });

    test('exposes whether the API client supports v4', () {
      expect(userRepository.supportsV4, isFalse);

      when(() => solvedApiClient.supportsV4).thenReturn(true);

      expect(userRepository.supportsV4, isTrue);
    });

    group('getUser', () {
      const handle = 'w8385';

      test('uses the v3 profile when v4 is unavailable', () async {
        try {
          await userRepository.getUser(handle);
        } catch (_) {}
        verify(() => solvedApiClient.userShow(handle)).called(1);
        verifyNever(() => solvedApiClient.v4UserProfile(any()));
      });

      test('returns correct user on success', () async {
        final user = MockUserProfile();
        when(() => solvedApiClient.userShow(handle))
            .thenAnswer((_) async => user);

        expect(await userRepository.getUser(handle), user);
      });

      test('uses only the v4 profile when configured', () async {
        final profile = _officialProfile();
        when(() => solvedApiClient.supportsV4).thenReturn(true);
        when(
          () => solvedApiClient.v4UserProfile(handle),
        ).thenAnswer((_) async => profile);

        final solved_api.UserProfile actual =
            await userRepository.getUser(handle);
        expect(actual, same(profile));
        verify(() => solvedApiClient.v4UserProfile(handle)).called(1);
        verifyNever(() => solvedApiClient.userShow(any()));
      });
    });

    group('getStreak', () {
      const handle = 'w8385';
      final from = DateTime.utc(2026, 11, 17);
      final to = DateTime.utc(2026, 11, 17);

      test('uses the v3 default grass when v4 is unavailable', () async {
        try {
          await userRepository.getStreak(handle, from: from, to: to);
        } catch (_) {}
        verify(() => solvedApiClient.userGrass(handle, 'default')).called(1);
        verifyNever(
          () => solvedApiClient.v4UserActivity(
            handle,
            from: from,
            to: to,
          ),
        );
      });

      test('returns correct streak on success', () async {
        final streak = MockProfileStreak();
        when(() => solvedApiClient.userGrass(handle, 'default'))
            .thenAnswer((_) async => streak);

        expect(
          await userRepository.getStreak(handle, from: from, to: to),
          streak,
        );
      });

      test('uses the explicit day range only for v4 activity', () async {
        const activity = solved_api.ProfileActivityResult(
          from: '2026-11-17',
          to: '2026-11-17',
          days: <solved_api.ProfileSolvedDay>[],
          maxSolvedCount: 0,
          currentStreak: 0,
          maxStreak: 0,
          theme: null,
          firstActiveDay: null,
          vacation: null,
          vacations: <solved_api.ProfileActivityVacation>[],
          countedToday: false,
          frozenYesterday: false,
        );
        when(() => solvedApiClient.supportsV4).thenReturn(true);
        when(
          () => solvedApiClient.v4UserActivity(
            handle,
            from: from,
            to: to,
          ),
        ).thenAnswer((_) async => activity);

        final solved_api.ProfileStreak actual = await userRepository.getStreak(
          handle,
          from: from,
          to: to,
        );
        expect(actual, same(activity));
        verify(
          () => solvedApiClient.v4UserActivity(
            handle,
            from: from,
            to: to,
          ),
        ).called(1);
        verifyNever(() => solvedApiClient.userGrass(any(), any()));
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

      test('does not leak to v3 when v4 has no equivalent', () async {
        when(() => solvedApiClient.supportsV4).thenReturn(true);

        await expectLater(
          userRepository.getProblemStats(handle),
          throwsA(
            isA<UnsupportedError>().having(
              (error) => error.message,
              'message',
              contains('tier distribution'),
            ),
          ),
        );
        verifyNever(() => solvedApiClient.userProblemStats(any()));
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

      test('uses tag ratings embedded in the v4 profile', () async {
        final tagRatings = [MockProfileTagRating()];
        final profile = _officialProfile(tagRatings: tagRatings);
        when(() => solvedApiClient.supportsV4).thenReturn(true);
        when(
          () => solvedApiClient.v4UserProfile(handle),
        ).thenAnswer((_) async => profile);

        expect(await userRepository.getTagRatings(handle), tagRatings);
        verify(() => solvedApiClient.v4UserProfile(handle)).called(1);
        verifyNever(() => solvedApiClient.userTagRatings(any()));
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

      test(
        'uses only the official v4 background endpoint when configured',
        () async {
          final background = MockProfileBackgroundAsset();
          when(() => solvedApiClient.supportsV4).thenReturn(true);
          when(
            () => solvedApiClient.v4BackgroundShow(backgroundId),
          ).thenAnswer((_) async => background);

          expect(await userRepository.getBackground(backgroundId), background);
          verify(
            () => solvedApiClient.v4BackgroundShow(backgroundId),
          ).called(1);
          verifyNever(() => solvedApiClient.backgroundShow(any()));
        },
      );

      test('preserves an unavailable v4 background as null', () async {
        when(() => solvedApiClient.supportsV4).thenReturn(true);
        when(
          () => solvedApiClient.v4BackgroundShow(backgroundId),
        ).thenAnswer((_) async => null);

        expect(await userRepository.getBackground(backgroundId), isNull);
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

      test(
        'uses only the official v4 badge endpoint when configured',
        () async {
          final badge = MockProfileBadgeAsset();
          when(() => solvedApiClient.supportsV4).thenReturn(true);
          when(
            () => solvedApiClient.v4BadgeShow(badgeId),
          ).thenAnswer((_) async => badge);

          expect(await userRepository.getBadge(badgeId), badge);
          verify(() => solvedApiClient.v4BadgeShow(badgeId)).called(1);
          verifyNever(() => solvedApiClient.badgeShow(any()));
        },
      );
    });
  });
}

solved_api.OfficialUserProfile _officialProfile({
  List<solved_api.ProfileTagRating> tagRatings = const [],
}) =>
    solved_api.OfficialUserProfile(
      id: 1,
      voteCount: 37,
      streakVacation: null,
      streakCountedToday: false,
      streakFrozenYesterday: false,
      streakTheme: null,
      isRival: false,
      isReverseRival: false,
      ojAccounts: const [],
      linkedAccounts: const [],
      affiliations: const [],
      bans: const [],
      handle: 'w8385',
      profileImageUrl: null,
      solvedCount: 2048,
      userClass: 6,
      tier: null,
      rating: 2417,
      background: null,
      badge: null,
      tagRatings: tagRatings,
    );
