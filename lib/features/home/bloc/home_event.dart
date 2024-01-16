part of "home_bloc.dart";

@immutable
abstract class HomeEvent extends Equatable {}

class InitHome extends HomeEvent {
  @override
  List<Object?> get props => [];
}

class SettingIsShowIllustBackground extends HomeEvent {
  final bool isOn;

  SettingIsShowIllustBackground({required this.isOn});

  @override
  List<Object?> get props => [isOn];
}
