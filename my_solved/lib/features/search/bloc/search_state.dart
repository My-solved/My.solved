part of 'search_bloc.dart';

abstract class SearchState extends Equatable {
  final String text;

  const SearchState({required this.text});
}

class SearchInitial extends SearchState {
  const SearchInitial({required super.text});

  @override
  List<Object?> get props => [super.text];
}
