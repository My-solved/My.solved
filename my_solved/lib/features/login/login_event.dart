part of 'login_bloc.dart';

@immutable
abstract class LoginEvent extends Equatable {}

class HandleTextFieldOnChanged extends LoginEvent {
  final String handle;

  HandleTextFieldOnChanged({required this.handle});

  @override
  List<Object?> get props => [handle];
}

class HandleTextFieldOnSummited extends LoginEvent {
  final String handle;

  HandleTextFieldOnSummited({required this.handle});

  @override
  List<Object?> get props => [handle];
}

class LoginButtonTapped extends LoginEvent {
  final BuildContext context;
  final String handle;

  LoginButtonTapped({required this.context, required this.handle});

  @override
  List<Object?> get props => [context];
}
