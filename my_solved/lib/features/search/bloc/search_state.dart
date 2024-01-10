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

  const SearchState({
    this.status = SearchStatus.initial,
    this.text = "",
    this.currentIndex = 0,
  });

  SearchState copyWith({
    SearchStatus? status,
    String? text,
    int? currentIndex,
  }) {
    return SearchState(
      status: status ?? this.status,
      text: text ?? this.text,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  @override
  List<Object?> get props => [status, text, currentIndex];
}
