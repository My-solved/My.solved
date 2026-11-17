part of 'search_filter_bloc.dart';

enum SearchSortMethod {
  id(SolvedApiV4ProblemSort.id, "ID"),
  level(SolvedApiV4ProblemSort.level, "레벨"),
  solved(SolvedApiV4ProblemSort.solved, "푼 사람 수"),
  averageTry(SolvedApiV4ProblemSort.averageTry, "평균 시도"),
  random(SolvedApiV4ProblemSort.random, "랜덤");

  const SearchSortMethod(this.apiValue, this.displayName);

  final SolvedApiV4ProblemSort apiValue;
  final String displayName;

  static List<SearchSortMethod> get allCases => [
    SearchSortMethod.id,
    SearchSortMethod.level,
    SearchSortMethod.solved,
    SearchSortMethod.averageTry,
  ];
}

enum SearchDirection {
  asc(SolvedApiV4SearchDirection.asc, "오름차순"),
  desc(SolvedApiV4SearchDirection.desc, "내림차순");

  const SearchDirection(this.apiValue, this.displayName);

  final SolvedApiV4SearchDirection apiValue;
  final String displayName;

  static List<SearchDirection> get allCases => [
    SearchDirection.asc,
    SearchDirection.desc,
  ];
}

class SearchFilterState extends Equatable {
  final List<SearchSortMethod> sorts = SearchSortMethod.allCases;
  final List<SearchDirection> directions = SearchDirection.allCases;

  @override
  List<Object?> get props => [sorts, directions];
}
