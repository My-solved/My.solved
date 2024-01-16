import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:solved_api/solved_api.dart';
import 'package:user_repository/user_repository.dart';

part "home_event.dart";
part "home_state.dart";

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final UserRepository userRepository;

  HomeBloc({
    required this.userRepository,
    required String handle,
  }) : super(HomeState(
          handle: handle,
          isShowIllustBackground: true,
        )) {
    on<InitHome>((event, emit) async {
      state.copyWith(status: HomeStatus.loading);

      try {
        final user = await userRepository.getUser(handle);
        emit(state.copyWith(status: HomeStatus.success, user: user));
      } catch (e) {
        emit(state.copyWith(status: HomeStatus.failure));
      }
    });
    on<SettingIsShowIllustBackground>(
      (event, emit) {
        emit(state.copyWith(isShowIllustBackground: event.isOn));
      },
    );
  }
}
