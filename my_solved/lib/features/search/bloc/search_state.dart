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
  final SearchObject? problems;
  final List<UserSuggestion>? users;
  final SearchObject? tags;

  const SearchState({
    this.status = SearchStatus.initial,
    this.text = "",
    this.currentIndex = 0,
    this.problems,
    this.users,
    this.tags,
  });

  SearchState copyWith({
    SearchStatus? status,
    String? text,
    int? currentIndex,
    SearchObject? problems,
    List<UserSuggestion>? users,
    SearchObject? tags,
  }) {
    return SearchState(
      status: status ?? this.status,
      text: text ?? this.text,
      currentIndex: currentIndex ?? this.currentIndex,
      problems: problems ?? this.problems,
      users: users ?? this.users,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props => [
        status,
        text,
        currentIndex,
        problems,
        users,
        tags,
      ];
}
