part of 'app_bloc.dart';

@immutable
abstract class AppState extends Equatable {}

class AppInitial extends AppState {
  @override
  List<Object?> get props => [];
}

class AppLoggedOut extends AppState {
  @override
  List<Object?> get props => [];
}

class AppLoggedIn extends AppState {
  @override
  List<Object?> get props => [];
}
