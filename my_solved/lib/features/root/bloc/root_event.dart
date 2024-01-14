part of 'root_bloc.dart';

@immutable
abstract class RootEvent extends Equatable {}

class NavigationBarItemTapped extends RootEvent {
  final int tabIndex;

  NavigationBarItemTapped({required this.tabIndex});

  @override
  List<Object?> get props => [tabIndex];
}
