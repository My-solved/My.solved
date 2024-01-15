part of 'contest_bloc.dart';

@immutable
abstract class ContestEvent extends Equatable {}

class InitContest extends ContestEvent {
  @override
  List<Object?> get props => [];
}

class SegmentedControlTapped extends ContestEvent {
  final int index;

  SegmentedControlTapped({required this.index});

  @override
  List<Object?> get props => [index];
}

class ContestFilterToggleTapped extends ContestEvent {
  final ContestVenue venue;

  ContestFilterToggleTapped({required this.venue});

  @override
  List<Object?> get props => [venue];
}
