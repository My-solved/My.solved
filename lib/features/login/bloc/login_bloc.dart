import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:user_repository/user_repository.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required UserRepository userRepository})
      : _userRepository = userRepository,
        super(LoginInitial(handle: "")) {
    on<HandleTextFieldOnChanged>(_onChangeHandleTextField);
    on<HandleTextFieldOnSummited>(_onSummitHandleTextField);
    on<LoginButtonTapped>(_onLoginButtonTapped);
  }

  final UserRepository _userRepository;

  Future<void> _onChangeHandleTextField(
    HandleTextFieldOnChanged event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginInitial(handle: event.handle));
  }

  Future<void> _onSummitHandleTextField(
    HandleTextFieldOnSummited event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginInitial(handle: event.handle));
  }

  Future<void> _onLoginButtonTapped(
    LoginButtonTapped event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading(handle: event.handle));
    try {
      await _userRepository.getUser(event.handle);
      emit(LoginSuccess(handle: event.handle));
    } catch (e) {
      emit(LoginFailure(handle: "", errorMessage: "User not found"));
    }
  }
}
