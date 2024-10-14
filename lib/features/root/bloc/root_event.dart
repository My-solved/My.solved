part of 'root_bloc.dart';

@immutable
abstract class RootEvent {}

class VersionInfoInit extends RootEvent {}

class NavigationBarItemTapped extends RootEvent {
  final int tabIndex;

  NavigationBarItemTapped({required this.tabIndex});
}
