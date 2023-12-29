import 'package:solved_api/src/models/badge.dart';

class Badges {
  final int count;
  final List<dynamic> items;

  const Badges({
    required this.count,
    required this.items,
  });

  factory Badges.fromJson(Map<String, dynamic> json) {
    return Badges(
      count: json['count'],
      items: json['items'].map((i) => Badge.fromJson(i)).toList().cast<Badge>(),
    );
  }
}
