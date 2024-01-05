import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginInitial(handle: "")) {
    on<LoginHandleFieldOnChanged>(_onChangeHandleTextField);
    on<LoginHandleFieldOnSummited>(_onSummitHandleTextField);
  }

  Future<void> _onChangeHandleTextField(
    LoginHandleFieldOnChanged event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginInitial(handle: event.handle));
  }

  Future<void> _onSummitHandleTextField(
    LoginHandleFieldOnSummited event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginInitial(handle: event.handle));
  }
}
