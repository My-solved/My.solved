part of 'contest_bloc.dart';

@immutable
abstract class ContestEvent {}

class ContestInit extends ContestEvent {}

class ContestSegmentedControlPressed extends ContestEvent {
  final int index;

  ContestSegmentedControlPressed({required this.index});
}

class ContestNotificationButtonPressed extends ContestEvent {
  final int index;

  ContestNotificationButtonPressed({required this.index});
}

class ContestFilterTogglePressed extends ContestEvent {
  final ContestVenue venue;

  ContestFilterTogglePressed({required this.venue});
}
