part of "home_bloc.dart";

@immutable
abstract class HomeEvent {}

class HomeInit extends HomeEvent {}

class HomeIsOnIllustBackgroundChanged extends HomeEvent {
  final bool isOn;

  HomeIsOnIllustBackgroundChanged({required this.isOn});
}