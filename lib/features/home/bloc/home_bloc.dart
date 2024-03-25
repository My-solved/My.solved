import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences_repository/shared_preferences_repository.dart';
import 'package:solved_api/solved_api.dart';
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
      final isOnIllustBackground = await _sharedPreferencesRepository.getIsOnIllustBackground();
      Badge? badge;

      if (user.badgeId != null) {
        badge = await _userRepository.getBadge(user.badgeId!);
      }
      final badges = await _userRepository.getBadges(_handle);

      emit(state.copyWith(
        isOnIllustBackground: isOnIllustBackground,
        status: HomeStatus.success,
        user: user,
        background: background,
        organizations: organizations,
        badge: badge,
        badges: badges,
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
