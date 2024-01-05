import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_solved/app/bloc/app_bloc.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginInitial(handle: "")) {
    on<HandleTextFieldOnChanged>(_onChangeHandleTextField);
    on<HandleTextFieldOnSummited>(_onSummitHandleTextField);
    on<LoginButtonTapped>(_onLoginButtonTapped);
  }

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
    event.context.read<AppBloc>().add(Login(handle: event.handle));
  }
}
