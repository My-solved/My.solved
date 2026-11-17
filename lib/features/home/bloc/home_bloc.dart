import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences_repository/shared_preferences_repository.dart';
import 'package:solved_api/solved_api.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:user_repository/user_repository.dart';

part "home_event.dart";
part "home_state.dart";

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required UserRepository userRepository,
    required SharedPreferencesRepository sharedPreferencesRepository,
    required String handle,
    DateTime Function()? now,
  })  : _userRepository = userRepository,
        _sharedPreferencesRepository = sharedPreferencesRepository,
        _handle = handle,
        _now = now ?? _currentSolvedDay,
        super(
          HomeState(
            handle: handle,
            isOnIllustBackground: true,
          ),
        ) {
    on<HomeInit>(_onInit);
    on<HomeIsOnIllustBackgroundChanged>(_onIsOnIllustBackgroundChanged);
  }

  final UserRepository _userRepository;
  final SharedPreferencesRepository _sharedPreferencesRepository;
  final String _handle;
  final DateTime Function() _now;

  static const int _maxConcurrentAuxiliaryRequests = 3;
  bool _isInitializing = false;

  static DateTime _currentSolvedDay() =>
      tz.TZDateTime.now(tz.UTC).add(const Duration(hours: 3));

  Future<void> _onInit(HomeInit event, Emitter<HomeState> emit) async {
    if (_isInitializing) return;
    _isInitializing = true;
    try {
      await _loadHome(emit);
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _loadHome(Emitter<HomeState> emit) async {
    emit(state.copyWith(status: HomeStatus.loading));
    final solvedDay = _now();
    final usesV4 = _userRepository.supportsV4;

    late UserProfile user;
    try {
      user = await _userRepository.getUser(_handle);
    } catch (_) {
      emit(state.copyWith(status: HomeStatus.failure));
      return;
    }

    final auxiliary = _HomeAuxiliaryData(
      isOnIllustBackground: state.isOnIllustBackground,
      background: usesV4 ? user.background : null,
      badge: usesV4 ? user.badge : null,
      tagRatings: usesV4 ? user.tagRatings : const [],
    );
    final requests = <Future<void> Function()>[
      if (!usesV4 && user.backgroundId != null)
        () async {
          auxiliary.background = await _optional<ProfileBackgroundAsset?>(
            () => _userRepository.getBackground(user.backgroundId!),
          );
        },
      () async {
        auxiliary.isOnIllustBackground = await _optional(
              _sharedPreferencesRepository.getIsOnIllustBackground,
            ) ??
            auxiliary.isOnIllustBackground;
      },
      if (!usesV4 && user.badgeId != null)
        () async {
          auxiliary.badge = await _optional(
            () => _userRepository.getBadge(user.badgeId!),
          );
        },
      () async {
        auxiliary.streak = await _optional(
          () => _userRepository.getStreak(
            _handle,
            from: solvedDay,
            to: solvedDay,
          ),
        );
      },
      if (!usesV4)
        () async {
          auxiliary.tagRatings =
              await _optional(() => _userRepository.getTagRatings(_handle)) ??
                  const [];
        },
      if (!usesV4)
        () async {
          // Official v4 has no equivalent of the legacy tier distribution.
          auxiliary.problemStats =
              await _optional(() => _userRepository.getProblemStats(_handle)) ??
                  const [];
        },
    ];

    await _runLimited(requests);
    final effectiveStreak = auxiliary.streak ?? state.streak;

    emit(
      HomeState(
        status: HomeStatus.success,
        handle: _handle,
        isOnIllustBackground: auxiliary.isOnIllustBackground,
        user: user,
        profileImageUrl: user.profileImageUrl,
        background: auxiliary.background,
        badge: auxiliary.badge,
        streak: effectiveStreak,
        solvedToday: _hasSolvedToday(effectiveStreak, solvedDay),
        tagRatings: auxiliary.tagRatings,
        problemStats: auxiliary.problemStats,
      ),
    );
  }

  Future<T?> _optional<T>(Future<T> Function() request) async {
    try {
      return await request();
    } catch (_) {
      return null;
    }
  }

  Future<void> _runLimited(List<Future<void> Function()> requests) async {
    for (var offset = 0;
        offset < requests.length;
        offset += _maxConcurrentAuxiliaryRequests) {
      final end = (offset + _maxConcurrentAuxiliaryRequests < requests.length)
          ? offset + _maxConcurrentAuxiliaryRequests
          : requests.length;
      await Future.wait(
        requests.sublist(offset, end).map((request) => request()),
      );
    }
  }

  bool _hasSolvedToday(ProfileStreak? streak, DateTime now) {
    if (streak == null) return false;
    return streak.days.any(
      (entry) =>
          entry.year == now.year &&
          entry.month == now.month &&
          entry.day == now.day &&
          entry.solvedCount > 0,
    );
  }

  void _onIsOnIllustBackgroundChanged(
    HomeIsOnIllustBackgroundChanged event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(isOnIllustBackground: event.isOn));
  }
}

class _HomeAuxiliaryData {
  _HomeAuxiliaryData({
    required this.isOnIllustBackground,
    this.background,
    this.badge,
    this.tagRatings = const [],
  });

  bool isOnIllustBackground;
  ProfileBackgroundAsset? background;
  ProfileBadgeAsset? badge;
  ProfileStreak? streak;
  List<ProfileTagRating> tagRatings;
  List<ProfileTierStat>? problemStats;
}
