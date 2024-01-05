part of 'login_bloc.dart';

@immutable
abstract class LoginEvent {}

class LoginHandleFieldOnChanged extends LoginEvent {
  final String handle;

  LoginHandleFieldOnChanged({required this.handle});
}

class LoginHandleFieldOnSummited extends LoginEvent {
  final String handle;

  LoginHandleFieldOnSummited({required this.handle});
}
