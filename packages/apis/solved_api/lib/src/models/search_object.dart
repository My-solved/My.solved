class SearchObject {
  final int count;
  final List<dynamic> items;

  const SearchObject({
    required this.count,
    required this.items,
  });

  factory SearchObject.fromJson(Map<String, dynamic> json) {
    return SearchObject(
      count: json['count'],
      items: json['items'],
    );
  }
}
