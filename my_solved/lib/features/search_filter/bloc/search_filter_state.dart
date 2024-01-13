part of 'search_filter_bloc.dart';

enum SearchSortMethod {
  id("id", "ID"),
  level("level", "레벨"),
  title("title", "제목"),
  solved("solved", "푼 사람 수"),
  averageTry("average_try", "평균 시도");

  const SearchSortMethod(this.value, this.displayName);

  final String value;
  final String displayName;

  static List<SearchSortMethod> get allCases => [
        SearchSortMethod.id,
        SearchSortMethod.level,
        SearchSortMethod.title,
        SearchSortMethod.solved,
        SearchSortMethod.averageTry
      ];
}

enum SearchDirection {
  asc("asc", "오름차순"),
  desc("decs", "내림차순");

  const SearchDirection(this.value, this.displayName);

  final String value;
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
  List<Object?> get props => [];
}
