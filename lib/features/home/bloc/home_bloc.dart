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
  })  : _userRepository = userRepository,
        _sharedPreferencesRepository = sharedPreferencesRepository,
        _handle = handle,
        super(HomeState(
          handle: handle,
          isOnIllustBackground: true,
          organizations: [],
          badges: [],
        )) {
    on<HomeInit>(_onInit);
    on<HomeIsOnIllustBackgroundChanged>(_onIsOnIllustBackgroundChanged);
  }

  final UserRepository _userRepository;
  final SharedPreferencesRepository _sharedPreferencesRepository;
  final String _handle;

  Future<void> _onInit(
    HomeInit event,
    Emitter<HomeState> emit,
  ) async {
    state.copyWith(status: HomeStatus.loading);

    try {
      final user = await _userRepository.getUser(_handle);
      final background = await _userRepository.getBackground(user.backgroundId);
      final organizations = await _userRepository.getOrganizations(_handle);
      final isOnIllustBackground =
          await _sharedPreferencesRepository.getIsOnIllustBackground();
      Badge? badge;

      if (user.badgeId != null) {
        badge = await _userRepository.getBadge(user.badgeId!);
      }
      final badges = await _userRepository.getBadges(_handle);
      final streak = await _userRepository.getStreak(_handle, "default");
      streak.grass.sort((a, b) {
        if (a.year != b.year) {
          return a.year.compareTo(b.year);
        } else if (a.month != b.month) {
          return a.month.compareTo(b.month);
        } else {
          return a.day.compareTo(b.day);
        }
      });

      tz.TZDateTime? today =
          tz.TZDateTime.now(tz.UTC).add(const Duration(hours: 3));

      late bool solvedToday = today.year == streak.grass.last.year &&
          today.month == streak.grass.last.month &&
          today.day == streak.grass.last.day;

      final tagRatings = await _userRepository.getTagRatings(_handle);
      final problemStats = await _userRepository.getProblemStats(_handle);

      emit(state.copyWith(
        isOnIllustBackground: isOnIllustBackground,
        status: HomeStatus.success,
        user: user,
        background: background,
        organizations: organizations,
        badge: badge,
        badges: badges,
        solvedToday: solvedToday,
        tagRatings: tagRatings,
        problemStats: problemStats,
      ));
    } catch (e) {
      emit(state.copyWith(status: HomeStatus.failure));
    }
  }

  void _onIsOnIllustBackgroundChanged(
    HomeIsOnIllustBackgroundChanged event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(isOnIllustBackground: event.isOn));
  }
}
