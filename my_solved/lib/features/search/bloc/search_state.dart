part of 'search_bloc.dart';

enum SearchStatus { initial, loading, success, failure }

extension SearchStatusX on SearchStatus {
  bool get isInitial => this == SearchStatus.initial;
  bool get isLoading => this == SearchStatus.loading;
  bool get isSuccess => this == SearchStatus.success;
  bool get isFailure => this == SearchStatus.failure;
}

class SearchState extends Equatable {
  final SearchStatus status;
  final String text;
  final int currentIndex;
  final SearchSuggestion? result;

  const SearchState({
    this.status = SearchStatus.initial,
    this.text = "",
    this.currentIndex = 0,
    this.result,
  });

  SearchState copyWith({
    SearchStatus? status,
    String? text,
    int? currentIndex,
    SearchSuggestion? result,
  }) {
    return SearchState(
      status: status ?? this.status,
      text: text ?? this.text,
      currentIndex: currentIndex ?? this.currentIndex,
      result: result ?? this.result,
    );
  }

  @override
  List<Object?> get props => [status, text, currentIndex];
}
