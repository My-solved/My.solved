class Top100 {
  final int count;
  final List<dynamic> items;

  const Top100({
    required this.count,
    required this.items,
  });

  factory Top100.fromJson(Map<String, dynamic> json) {
    return Top100(
      count: json['count'],
      items: json['items'],
    );
  }
}
