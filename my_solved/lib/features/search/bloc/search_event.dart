part of 'search_bloc.dart';

@immutable
abstract class SearchEvent extends Equatable {}

class SearchTextFieldOnChanged extends SearchEvent {
  final String text;

  SearchTextFieldOnChanged({required this.text});

  @override
  List<Object?> get props => [text];
}

class SearchTextFieldOnSummited extends SearchEvent {
  final String text;

  SearchTextFieldOnSummited({required this.text});

  @override
  List<Object?> get props => [text];
}

class SearchSegmentedControlTapped extends SearchEvent {
  final int index;

  SearchSegmentedControlTapped({required this.index});

  @override
  List<Object?> get props => [index];
}
