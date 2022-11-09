class SearchProblem {
  final int count;
  final List<dynamic> items;

  const SearchProblem({
    required this.count,
    required this.items,
  });

  factory SearchProblem.fromJson(Map<String, dynamic> json) {
    return SearchProblem(
        count: json['count'],
        items: json['items'],
    );
  }
}
