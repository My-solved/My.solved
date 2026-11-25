import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_solved/features/home/bloc/home_bloc.dart';
import 'package:my_solved/features/home/screen/home_screen.dart';
import 'package:shared_preferences_repository/shared_preferences_repository.dart';
import 'package:solved_api/solved_api.dart';
import 'package:user_repository/user_repository.dart';

void main() {
  final today = DateTime(2026, 11, 17, 12);

  test('emits loading then success and limits auxiliary concurrency', () async {
    final repository = _FakeUserRepository(
      streak: _streak(currentStreak: 3, days: const []),
      userDelay: const Duration(milliseconds: 5),
      auxiliaryDelay: const Duration(milliseconds: 5),
    );
    final bloc = _createBloc(repository, today);
    addTearDown(bloc.close);

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<HomeState>().having(
          (state) => state.status,
          'status',
          HomeStatus.loading,
        ),
        isA<HomeState>()
            .having((state) => state.status, 'status', HomeStatus.success)
            .having((state) => state.user, 'user', same(_user)),
      ]),
    );

    bloc.add(HomeInit());
    bloc.add(HomeInit());

    await states;
    await Future<void>.delayed(Duration.zero);
    expect(repository.userRequestCount, 1);
    expect(repository.auxiliaryRequestCount, 4);
    expect(
      repository.requestedAuxiliaryNames,
      isNot(contains('organizations')),
    );
    expect(repository.requestedAuxiliaryNames, isNot(contains('badges')));
    expect(repository.maxActiveAuxiliaryRequests, greaterThan(1));
    expect(repository.maxActiveAuxiliaryRequests, lessThanOrEqualTo(3));
  });

  test('loads the selected badge without loading unused collections',
      () async {
    final repository = _FakeUserRepository(
      user: _profile(badgeId: 'badge'),
    );
    final bloc = _createBloc(repository, today);
    addTearDown(bloc.close);

    final success = bloc.stream.firstWhere((state) => state.status.isSuccess);
    bloc.add(HomeInit());

    final state = await success;
    expect(state.badge, same(_badge));
    expect(state.problemStats, isNotNull);
    expect(state.user?.reputation, isNull);
    expect(repository.requestedStreakFrom, today);
    expect(repository.requestedStreakTo, today);
    expect(
      repository.requestedAuxiliaryNames,
      unorderedEquals([
        'background',
        'badge',
        'streak',
        'tagRatings',
        'problemStats',
      ]),
    );
  });

  test(
    'uses embedded v4 profile data and requests only the solved day',
    () async {
      const tagRatings = [ProfileTagRating(key: 'dp', rating: 1700)];
      final repository = _FakeUserRepository(
        supportsV4: true,
        streak: _streak(
          currentStreak: 0,
          maxStreak: 0,
          days: const [],
        ),
        user: _profile(
          backgroundId: 'must-not-be-requested',
          badgeId: 'must-not-be-requested',
          reputation: 42,
          currentStreak: 12,
          maxStreak: 365,
          background: _background,
          badge: _badge,
          tagRatings: tagRatings,
        ),
      );
      var nowCalls = 0;
      final bloc = HomeBloc(
        userRepository: repository,
        sharedPreferencesRepository: _FakeSharedPreferencesRepository(),
        handle: _user.handle,
        now: () {
          nowCalls++;
          return today;
        },
      );
      addTearDown(bloc.close);

      final success = bloc.stream.firstWhere((state) => state.status.isSuccess);
      bloc.add(HomeInit());

      final state = await success;
      expect(state.background, same(_background));
      expect(state.badge, same(_badge));
      expect(state.tagRatings, same(tagRatings));
      expect(state.problemStats, isNull);
      expect(state.user?.reputation, 42);
      expect(state.currentStreak, 0);
      expect(state.maxStreak, 0);
      expect(state.streak, same(repository.streak));
      expect(repository.requestedAuxiliaryNames, ['streak']);
      expect(repository.requestedStreakFrom, today);
      expect(repository.requestedStreakTo, today);
      expect(nowCalls, 1);
    },
  );

  test(
    'uses the v4 profile summary when activity is unavailable without '
    'inferring solvedToday',
    () async {
      final repository = _FakeUserRepository(
        supportsV4: true,
        user: _officialProfile(
          currentStreak: 12,
          maxStreak: 365,
          streakCountedToday: true,
        ),
        failingAuxiliaryRequests: const {'streak'},
      );
      final bloc = _createBloc(repository, today);
      addTearDown(bloc.close);

      final success = bloc.stream.firstWhere((state) => state.status.isSuccess);
      bloc.add(HomeInit());

      final state = await success;
      expect(state.currentStreak, 12);
      expect(state.maxStreak, 365);
      expect(state.streak, isNull);
      expect(state.solvedToday, isFalse);
      expect(repository.requestedAuxiliaryNames, ['streak']);
    },
  );

  testWidgets('shows the v4 profile streak when activity is unavailable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeUserRepository(
      supportsV4: true,
      user: _profile(
        currentStreak: 12,
        maxStreak: 365,
        tagRatings: const [ProfileTagRating(key: 'dp', rating: 1700)],
      ),
      failingAuxiliaryRequests: const {'streak'},
    );
    final bloc = _createBloc(repository, today);
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<HomeBloc>.value(
          value: bloc,
          child: const HomeView(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final streakCard = find.ancestor(
      of: find.text('스트릭'),
      matching: find.byType(OutlinedButton),
    );
    expect(streakCard, findsOneWidget);
    expect(
      find.descendant(of: streakCard, matching: find.text('12')),
      findsOneWidget,
    );
    expect(repository.requestedAuxiliaryNames, ['streak']);
  });

  testWidgets('shows v4 reputation instead of unavailable difficulty stats', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeUserRepository(
      supportsV4: true,
      user: _profile(
        backgroundId: null,
        reputation: 42,
        classPlus: true,
        tagRatings: const [ProfileTagRating(key: 'dp', rating: 1700)],
      ),
    );
    final bloc = _createBloc(repository, today);
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<HomeBloc>.value(
          value: bloc,
          child: const HomeView(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('평판'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('클래스+'), findsOneWidget);
    expect(find.text('클래스'), findsNothing);
    expect(find.text('난이도 분포'), findsNothing);
  });

  testWidgets('shows the existing v4 rating breakdown without another call', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const breakdown = ProfileRatingBreakdown(
      rating: 2417,
      ratingByProblemsSum: 2010,
      ratingByClass: 0,
      ratingBySolvedCount: -207,
      ratingProblemsCutoff: 100,
      ratingProblemsHistogram: [2, 7, 15],
      noRatingSolvedCount: -4,
    );
    final repository = _FakeUserRepository(
      supportsV4: true,
      user: _profile(
        rating: 2417,
        ratingBreakdown: breakdown,
        tagRatings: const [ProfileTagRating(key: 'dp', rating: 1700)],
      ),
    );
    final bloc = _createBloc(repository, today);
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<HomeBloc>.value(
          value: bloc,
          child: const HomeView(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final userRequests = repository.userRequestCount;
    final auxiliaryRequests = repository.auxiliaryRequestCount;

    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    await tester.tap(find.text('레이팅'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('레이팅 상세'), findsOneWidget);
    expect(find.text('현재 레이팅'), findsOneWidget);
    expect(find.text('2417'), findsOneWidget);
    expect(find.text('문제 레이팅 합'), findsOneWidget);
    expect(find.text('2010'), findsOneWidget);
    expect(find.text('CLASS 레이팅'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );
    expect(find.text('해결 수 레이팅'), findsOneWidget);
    expect(find.text('-207'), findsOneWidget);
    expect(find.text('레이팅 미반영 문제'), findsOneWidget);
    expect(find.text('-4'), findsOneWidget);
    expect(find.textContaining('cutoff'), findsNothing);
    expect(find.textContaining('histogram'), findsNothing);
    expect(find.textContaining('Over'), findsNothing);
    expect(repository.userRequestCount, userRequests);
    expect(repository.auxiliaryRequestCount, auxiliaryRequests);

    await tester.tap(find.text('닫기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('레이팅 상세'), findsNothing);
  });

  testWidgets('keeps the legacy rating card without a fake breakdown', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeUserRepository(
      user: _profile(
        rating: 1234,
        tagRatings: const [ProfileTagRating(key: 'dp', rating: 1700)],
      ),
      problemStats: const [ProfileTierStat(tier: 1, solvedCount: 1)],
    );
    final bloc = _createBloc(repository, today);
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<HomeBloc>.value(
          value: bloc,
          child: const HomeView(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Bronze V 1234'), findsOneWidget);
    expect(find.text('클래스'), findsOneWidget);
    expect(find.text('클래스+'), findsNothing);
    final ratingButton = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('레이팅'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(ratingButton.onPressed, isNull);
    expect(find.byIcon(Icons.info_outline), findsNothing);
    expect(find.text('레이팅 상세'), findsNothing);
  });

  test('emits failure when the core user request fails', () async {
    final repository = _FakeUserRepository(failUser: true);
    final bloc = _createBloc(repository, today);
    addTearDown(bloc.close);

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<HomeState>().having(
          (state) => state.status,
          'status',
          HomeStatus.loading,
        ),
        isA<HomeState>().having(
          (state) => state.status,
          'status',
          HomeStatus.failure,
        ),
      ]),
    );

    bloc.add(HomeInit());

    await states;
    expect(repository.auxiliaryRequestCount, 0);
  });

  test('keeps a success state when auxiliary requests fail', () async {
    final repository = _FakeUserRepository(
      streak: _streak(currentStreak: 10, days: const []),
      failingAuxiliaryRequests: const {'background', 'streak', 'tagRatings'},
    );
    final bloc = _createBloc(repository, today);
    addTearDown(bloc.close);

    final success = bloc.stream.firstWhere((state) => state.status.isSuccess);
    bloc.add(HomeInit());

    final state = await success;
    expect(state.user, same(_user));
    expect(state.background, isNull);
    expect(state.streak, isNull);
    expect(state.tagRatings, isEmpty);
    expect(state.solvedToday, isFalse);
  });

  test('skips the background request when the profile has no background ID',
      () async {
    final repository = _FakeUserRepository(
      user: _profile(backgroundId: null),
    );
    final bloc = _createBloc(repository, today);
    addTearDown(bloc.close);

    final success = bloc.stream.firstWhere((state) => state.status.isSuccess);
    bloc.add(HomeInit());

    final state = await success;
    expect(state.background, isNull);
    expect(repository.requestedAuxiliaryNames, isNot(contains('background')));
  });

  test('keeps cached streak and solvedToday consistent after refresh failure',
      () async {
    final failures = <String>{};
    final cachedStreak = _streak(
      currentStreak: 1,
      maxStreak: 10,
      days: const [
        ProfileSolvedDay(
          day: 17,
          month: 11,
          year: 2026,
          solvedCount: 1,
        ),
      ],
    );
    final repository = _FakeUserRepository(
      streak: cachedStreak,
      failingAuxiliaryRequests: failures,
    );
    final bloc = _createBloc(repository, today);
    addTearDown(bloc.close);

    final firstSuccess = bloc.stream.firstWhere(
      (state) => state.status.isSuccess,
    );
    bloc.add(HomeInit());
    await firstSuccess;
    await Future<void>.delayed(Duration.zero);

    failures.add('streak');
    final refreshed = bloc.stream.firstWhere((state) => state.status.isSuccess);
    bloc.add(HomeInit());

    final state = await refreshed;
    expect(state.streak, same(cachedStreak));
    expect(state.currentStreak, 1);
    expect(state.maxStreak, 10);
    expect(state.solvedToday, isTrue);
  });

  test('prefers a fresh v4 profile summary to cached activity', () async {
    final failures = <String>{};
    final cachedStreak = _streak(
      currentStreak: 9,
      maxStreak: 90,
      days: const [
        ProfileSolvedDay(
          day: 17,
          month: 11,
          year: 2026,
          solvedCount: 1,
        ),
      ],
    );
    final repository = _FakeUserRepository(
      supportsV4: true,
      user: _profile(currentStreak: 8, maxStreak: 80),
      streak: cachedStreak,
      failingAuxiliaryRequests: failures,
    );
    final bloc = _createBloc(repository, today);
    addTearDown(bloc.close);

    final firstSuccess = bloc.stream.firstWhere(
      (state) => state.status.isSuccess,
    );
    bloc.add(HomeInit());
    final initial = await firstSuccess;
    expect(initial.currentStreak, 9);
    expect(initial.maxStreak, 90);
    await Future<void>.delayed(Duration.zero);

    repository.user = _profile(currentStreak: 12, maxStreak: 365);
    failures.add('streak');
    final refreshed = bloc.stream.firstWhere((state) => state.status.isSuccess);
    bloc.add(HomeInit());

    final state = await refreshed;
    expect(state.streak, same(cachedStreak));
    expect(state.currentStreak, 12);
    expect(state.maxStreak, 365);
    expect(state.solvedToday, isTrue);
  });

  test('does not use a legacy profile max streak as an activity fallback',
      () async {
    final repository = _FakeUserRepository(
      user: _profile(maxStreak: 477),
      failingAuxiliaryRequests: const {'streak'},
    );
    final bloc = _createBloc(repository, today);
    addTearDown(bloc.close);

    final success = bloc.stream.firstWhere((state) => state.status.isSuccess);
    bloc.add(HomeInit());

    final state = await success;
    expect(state.currentStreak, isNull);
    expect(state.maxStreak, isNull);
    expect(state.streak, isNull);
    expect(state.solvedToday, isFalse);
  });

  test('keeps streak summaries in copyWith and Equatable comparisons', () {
    const state = HomeState(
      handle: 'w8385',
      isOnIllustBackground: true,
      currentStreak: 12,
      maxStreak: 365,
    );

    expect(state.copyWith(status: HomeStatus.loading).currentStreak, 12);
    expect(state.copyWith(status: HomeStatus.loading).maxStreak, 365);
    expect(
      state,
      isNot(
        const HomeState(
          handle: 'w8385',
          isOnIllustBackground: true,
          currentStreak: 13,
          maxStreak: 365,
        ),
      ),
    );
  });

  test('derives solvedToday from the grass entry for the solved day', () async {
    final repository = _FakeUserRepository(
      streak: _streak(
        currentStreak: 0,
        days: const [
          ProfileSolvedDay(
            day: 17,
            month: 11,
            year: 2026,
            solvedCount: 1,
          ),
        ],
      ),
    );
    final bloc = _createBloc(repository, today);
    addTearDown(bloc.close);

    final success = bloc.stream.firstWhere((state) => state.status.isSuccess);
    bloc.add(HomeInit());

    expect((await success).solvedToday, isTrue);
  });

  test('does not infer solvedToday from a non-zero streak', () async {
    final repository = _FakeUserRepository(
      streak: _streak(
        currentStreak: 100,
        days: const [
          ProfileSolvedDay(
            day: 16,
            month: 11,
            year: 2026,
            solvedCount: 5,
          ),
        ],
      ),
    );
    final bloc = _createBloc(repository, today);
    addTearDown(bloc.close);

    final success = bloc.stream.firstWhere((state) => state.status.isSuccess);
    bloc.add(HomeInit());

    expect((await success).solvedToday, isFalse);
  });
}

HomeBloc _createBloc(_FakeUserRepository repository, DateTime now) {
  return HomeBloc(
    userRepository: repository,
    sharedPreferencesRepository: _FakeSharedPreferencesRepository(),
    handle: _user.handle,
    now: () => now,
  );
}

class _FakeUserRepository implements UserRepository {
  _FakeUserRepository({
    this.supportsV4 = false,
    this.failUser = false,
    this.failingAuxiliaryRequests = const {},
    this.userDelay = Duration.zero,
    this.auxiliaryDelay = Duration.zero,
    this.problemStats = const [],
    UserProfile? user,
    ProfileStreak? streak,
  })  : user = user ?? _user,
        streak = streak ?? _streak(currentStreak: 0, days: const []);

  final bool failUser;
  @override
  final bool supportsV4;
  final Set<String> failingAuxiliaryRequests;
  final Duration userDelay;
  final Duration auxiliaryDelay;
  final List<ProfileTierStat> problemStats;
  UserProfile user;
  final ProfileStreak streak;

  int _activeAuxiliaryRequests = 0;
  int maxActiveAuxiliaryRequests = 0;
  int auxiliaryRequestCount = 0;
  int userRequestCount = 0;
  DateTime? requestedStreakFrom;
  DateTime? requestedStreakTo;
  final List<String> requestedAuxiliaryNames = [];

  Future<T> _auxiliary<T>(String name, T value) async {
    auxiliaryRequestCount++;
    requestedAuxiliaryNames.add(name);
    _activeAuxiliaryRequests++;
    if (_activeAuxiliaryRequests > maxActiveAuxiliaryRequests) {
      maxActiveAuxiliaryRequests = _activeAuxiliaryRequests;
    }
    try {
      if (auxiliaryDelay > Duration.zero) {
        await Future<void>.delayed(auxiliaryDelay);
      }
      if (failingAuxiliaryRequests.contains(name)) {
        throw Exception('$name failed');
      }
      return value;
    } finally {
      _activeAuxiliaryRequests--;
    }
  }

  @override
  Future<UserProfile> getUser(String handle) async {
    userRequestCount++;
    if (userDelay > Duration.zero) {
      await Future<void>.delayed(userDelay);
    }
    if (failUser) throw Exception('user failed');
    return user;
  }

  @override
  Future<ProfileBackgroundAsset> getBackground(String backgroundId) =>
      _auxiliary('background', _background);

  @override
  Future<ProfileBadgeAsset> getBadge(String badgeId) =>
      _auxiliary('badge', _badge);

  @override
  Future<ProfileStreak> getStreak(
    String handle, {
    required DateTime from,
    required DateTime to,
  }) {
    requestedStreakFrom = from;
    requestedStreakTo = to;
    return _auxiliary('streak', streak);
  }

  @override
  Future<List<ProfileTagRating>> getTagRatings(String handle) =>
      _auxiliary('tagRatings', user.tagRatings);

  @override
  Future<List<ProfileTierStat>> getProblemStats(String handle) =>
      _auxiliary('problemStats', problemStats);
}

class _FakeSharedPreferencesRepository extends SharedPreferencesRepository {
  @override
  Future<bool> getIsOnIllustBackground() async => true;
}

ProfileStreak _streak({
  required int currentStreak,
  int? maxStreak,
  required List<ProfileSolvedDay> days,
}) {
  return ProfileStreak(
    days: days,
    currentStreak: currentStreak,
    maxStreak: maxStreak,
  );
}

UserProfile _profile({
  String? backgroundId = 'default',
  String? badgeId,
  int rating = 1,
  int? reputation,
  bool? classPlus,
  int? currentStreak,
  int? maxStreak,
  ProfileRatingBreakdown? ratingBreakdown,
  ProfileBackgroundAsset? background,
  ProfileBadgeAsset? badge,
  List<ProfileTagRating> tagRatings = const [],
}) =>
    UserProfile(
      handle: 'w8385',
      badgeId: badgeId,
      backgroundId: backgroundId,
      profileImageUrl: null,
      solvedCount: 1,
      legacyContributionCount: 0,
      userClass: 1,
      reverseRivalCount: 0,
      tier: 1,
      rating: rating,
      reputation: reputation,
      classPlus: classPlus,
      currentStreak: currentStreak,
      maxStreak: maxStreak,
      ratingBreakdown: ratingBreakdown,
      background: background,
      badge: badge,
      tagRatings: tagRatings,
    );

OfficialUserProfile _officialProfile({
  int? currentStreak,
  int? maxStreak,
  required bool streakCountedToday,
}) => OfficialUserProfile(
  id: 1,
  voteCount: 0,
  streakVacation: null,
  streakCountedToday: streakCountedToday,
  streakFrozenYesterday: false,
  streakTheme: null,
  isRival: false,
  isReverseRival: false,
  handle: 'w8385',
  profileImageUrl: null,
  solvedCount: 1,
  userClass: 1,
  tier: 1,
  rating: 1,
  currentStreak: currentStreak,
  maxStreak: maxStreak,
  background: null,
  badge: null,
);

final _user = _profile();

final _background = ProfileBackgroundAsset(
  imageUrl: 'https://example.com/background.png',
  fallbackImageUrl: null,
);

final _badge = ProfileBadgeAsset(
  imageUrl: 'https://example.com/badge.png',
);
