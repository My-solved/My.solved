part of 'search_bloc.dart';

@immutable
abstract class SearchEvent {}

class SearchInit extends SearchEvent {}

class SearchTextFieldOnChanged extends SearchEvent {
  final String text;

  SearchTextFieldOnChanged({required this.text});
}

class SearchTextFieldOnSummited extends SearchEvent {
  final String text;

  SearchTextFieldOnSummited({required this.text});
}

class SearchSegmentedControlTapped extends SearchEvent {
  final int index;

  SearchSegmentedControlTapped({required this.index});
}

class SearchFilterSortMethodSelected extends SearchEvent {
  final SearchSortMethod sort;

  SearchFilterSortMethodSelected({required this.sort});
}

class SearchFilterDirectionSelected extends SearchEvent {
  final SearchDirection direction;

  SearchFilterDirectionSelected({required this.direction});
}

class SearchFilterShowSolvedProblemChanged extends SearchEvent {
  final bool isOn;

  SearchFilterShowSolvedProblemChanged({required this.isOn});
}

class SearchFilterShowProblemTagChanged extends SearchEvent {
  final bool isOn;

  SearchFilterShowProblemTagChanged({required this.isOn});
}
