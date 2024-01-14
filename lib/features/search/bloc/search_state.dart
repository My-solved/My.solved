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
  final SearchSortMethod sort;
  final SearchDirection direction;
  final String text;
  final int currentIndex;
  final SearchObject? problems;
  final SearchObject? users;
  final SearchObject? tags;

  const SearchState({
    this.status = SearchStatus.initial,
    required this.sort,
    required this.direction,
    this.text = "",
    this.currentIndex = 0,
    this.problems,
    this.users,
    this.tags,
  });

  SearchState copyWith({
    SearchStatus? status,
    SearchSortMethod? sort,
    SearchDirection? direction,
    String? text,
    int? currentIndex,
    SearchObject? problems,
    SearchObject? users,
    SearchObject? tags,
  }) {
    return SearchState(
      status: status ?? this.status,
      sort: sort ?? this.sort,
      direction: direction ?? this.direction,
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
        sort,
        direction,
        text,
        currentIndex,
        problems,
        users,
        tags,
      ];
}
