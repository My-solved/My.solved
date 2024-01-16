import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:user_repository/user_repository.dart';

part "home_event.dart";
part "home_state.dart";

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final UserRepository userRepository;

  HomeBloc({
    required this.userRepository,
    required String handle,
  }) : super(HomeState(handle: handle)) {
    on<InitHome>((event, emit) async {
      state.copyWith(status: HomeStatus.loading);

      try {
        final user = await userRepository.getUser(handle);
        print(user);
        emit(state.copyWith(status: HomeStatus.success));
      } catch (e) {
        emit(state.copyWith(status: HomeStatus.failure));
      }
    });
  }
}
