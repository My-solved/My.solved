part of 'search_bloc.dart';

@immutable
abstract class SearchState extends Equatable {
  final String text;

  const SearchState({required this.text});
}

class SearchInitial extends SearchState {
  const SearchInitial({required super.text});

  @override
  List<Object?> get props => [super.text];
}

class SearchLoading extends SearchState {
  const SearchLoading({required super.text});

  @override
  List<Object?> get props => [super.text];
}

class SearchSuccess extends SearchState {
  const SearchSuccess({required super.text});

  @override
  List<Object?> get props => [super.text];
}

class SearchFailure extends SearchState {
  final String errorMessage;

  const SearchFailure({required super.text, required this.errorMessage});

  @override
  List<Object?> get props => [super.text, errorMessage];
}
