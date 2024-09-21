enum ContestType { ongoing, upcoming, ended }

class Contest {
  final String? venue;
  final String name;
  final String? url;
  final DateTime startTime;
  final DateTime endTime;
  final String? badge;
  final String? background;

  const Contest({
    this.venue,
    required this.name,
    this.url,
    required this.startTime,
    required this.endTime,
    this.badge,
    this.background,
  });

  factory Contest.fromJson(Map<String, dynamic> json) {
    return Contest(
        venue: json['venue'],
        name: json['name'],
        url: json['url'],
        startTime: DateTime.parse(json['startTime']),
        endTime: DateTime.parse(json['endTime']),
        badge: json['badge'],
        background: json['background']);
  }
}
