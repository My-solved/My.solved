import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences_repository/shared_preferences_repository.dart';

part 'app_state.dart';
part 'app_event.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  final SharedPreferencesRepository sharedPreferencesRepository;

  AppBloc({required this.sharedPreferencesRepository}) : super(AppInitial()) {
    on<AppInit>(_initApp);
    on<Login>(_login);
    on<Logout>(_logout);
  }

  Future<void> _initApp(
    AppInit event,
    Emitter<AppState> emit,
  ) async {
    final handle = await sharedPreferencesRepository.requestHandle();

    if (handle == null) {
      emit(AppLoggedOut());
    } else {
      emit(AppLoggedIn(handle: handle));
    }
  }

  Future<void> _login(
    Login event,
    Emitter<AppState> emit,
  ) async {
    await sharedPreferencesRepository.login(handle: event.handle);
    emit(AppLoggedIn(handle: event.handle));
  }

  Future<void> _logout(
    Logout event,
    Emitter<AppState> emit,
  ) async {
    await sharedPreferencesRepository.logout();
    emit(AppLoggedOut());
  }
}
