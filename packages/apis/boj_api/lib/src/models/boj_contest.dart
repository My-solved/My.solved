enum ContestType { ongoing, upcoming, ended }

class Contest {
  final String? venue;
  final String name;
  final String? url;
  final DateTime startTime;
  final DateTime endTime;

  const Contest({
    required this.venue,
    required this.name,
    required this.url,
    required this.startTime,
    required this.endTime,
  });

  factory Contest.fromJson(Map<String, dynamic> json) {
    return Contest(
        venue: json['venue'],
        name: json['name'],
        url: json['url'],
        startTime: DateTime.parse(json['startDate']),
        endTime: DateTime.parse(json['endDate']));
  }
}
