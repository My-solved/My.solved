import 'package:flutter_test/flutter_test.dart';
import 'package:my_solved/features/home/bloc/home_bloc.dart';
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
    expect(state.solvedToday, isTrue);
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
    this.failUser = false,
    this.failingAuxiliaryRequests = const {},
    this.userDelay = Duration.zero,
    this.auxiliaryDelay = Duration.zero,
    UserProfile? user,
    ProfileStreak? streak,
  })  : user = user ?? _user,
        streak = streak ?? _streak(currentStreak: 0, days: const []);

  final bool failUser;
  final Set<String> failingAuxiliaryRequests;
  final Duration userDelay;
  final Duration auxiliaryDelay;
  final UserProfile user;
  final ProfileStreak streak;

  int _activeAuxiliaryRequests = 0;
  int maxActiveAuxiliaryRequests = 0;
  int auxiliaryRequestCount = 0;
  int userRequestCount = 0;
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
  Future<List<Organization>> getOrganizations(String handle) =>
      _auxiliary('organizations', const []);

  @override
  Future<ProfileBadgeAsset> getBadge(String badgeId) =>
      _auxiliary('badge', _badge);

  @override
  Future<List<Badge>> getBadges(String handle) =>
      _auxiliary('badges', const []);

  @override
  Future<ProfileStreak> getStreak(String handle, String? topic) =>
      _auxiliary('streak', streak);

  @override
  Future<List<ProfileTagRating>> getTagRatings(String handle) =>
      _auxiliary('tagRatings', const []);

  @override
  Future<List<ProfileTierStat>> getProblemStats(String handle) =>
      _auxiliary('problemStats', const []);

  @override
  Future<List<Problem>> getTopProblems(String handle) =>
      throw UnimplementedError();

  @override
  Future<SiteStats> getSiteStats() => throw UnimplementedError();
}

class _FakeSharedPreferencesRepository extends SharedPreferencesRepository {
  @override
  Future<bool> getIsOnIllustBackground() async => true;
}

ProfileStreak _streak({
  required int currentStreak,
  required List<ProfileSolvedDay> days,
}) {
  return ProfileStreak(
    days: days,
    currentStreak: currentStreak,
  );
}

UserProfile _profile({
  String? backgroundId = 'default',
  String? badgeId,
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
      rating: 1,
    );

final _user = _profile();

final _background = ProfileBackgroundAsset(
  imageUrl: 'https://example.com/background.png',
  fallbackImageUrl: null,
);

final _badge = ProfileBadgeAsset(
  imageUrl: 'https://example.com/badge.png',
);
