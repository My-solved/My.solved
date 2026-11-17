class SearchObject<T> {
  final int count;
  final List<T> items;

  const SearchObject({required this.count, required this.items});

  factory SearchObject.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) decodeItem,
  ) {
    return SearchObject<T>(
      count: json['count'] as int,
      items: (json['items'] as List<dynamic>)
          .map<T>((item) => decodeItem(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
