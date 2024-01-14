part of 'app_bloc.dart';

@immutable
abstract class AppEvent extends Equatable {}

class AppInit extends AppEvent {
  @override
  List<Object?> get props => [];
}

class Login extends AppEvent {
  final String handle;

  Login({required this.handle});

  @override
  List<Object?> get props => [handle];
}

class Logout extends AppEvent {
  @override
  List<Object?> get props => [];
}
