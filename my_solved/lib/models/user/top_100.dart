class Top_100 {
  final int count;
  final List<dynamic> items;

  const Top_100({
    required this.count,
    required this.items,
  });

  factory Top_100.fromJson(Map<String, dynamic> json) {
    return Top_100(
      count: json['count'],
      items: json['items'],
    );
  }
}
