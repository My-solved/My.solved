part of 'login_bloc.dart';

@immutable
abstract class LoginState extends Equatable {
  final String handle;

  const LoginState({required this.handle});
}

class LoginInitial extends LoginState {
  const LoginInitial({required super.handle});

  @override
  List<Object?> get props => [super.handle];
}

class LoginLoading extends LoginState {
  const LoginLoading({required super.handle});

  @override
  List<Object?> get props => [super.handle];
}

class LoginSuccess extends LoginState {
  const LoginSuccess({required super.handle});

  @override
  List<Object?> get props => [super.handle];
}

class LoginFailure extends LoginState {
  final String errorMessage;

  const LoginFailure({required super.handle, required this.errorMessage});

  @override
  List<Object?> get props => [super.handle, errorMessage];
}
