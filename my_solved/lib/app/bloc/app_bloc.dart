import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:my_solved/packages/user_repository/lib/user_repository.dart';

part 'app_state.dart';
part 'app_event.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  final UserRepository userRepository;

  AppBloc({required this.userRepository}) : super(AppInitial()) {
    on<AppInit>(_initApp);
    on<Login>(_login);
    on<Logout>(_logout);
  }

  Future<void> _initApp(
    AppInit event,
    Emitter<AppState> emit,
  ) async {
    final handle = await userRepository.requestHandle();

    if (handle == null) {
      emit(AppLoggedOut());
    } else {
      emit(AppLoggedIn());
    }
  }

  Future<void> _login(
    Login event,
    Emitter<AppState> emit,
  ) async {
    // await userRepository.login(handle: event.handle);
    emit(AppLoggedIn());
  }

  Future<void> _logout(
    Logout event,
    Emitter<AppState> emit,
  ) async {
    await userRepository.logout();
    emit(AppLoggedOut());
  }
}
