class Grass {
  final int day;
  final int month;
  final int year;
  final int solvedCount;
  final bool isSolved;
  final bool isFrozen;
  final bool isRepaired;

  const Grass(
      {required this.day,
      required this.month,
      required this.year,
      required this.solvedCount,
      required this.isSolved,
      required this.isFrozen,
      required this.isRepaired});

  factory Grass.fromJson(Map<String, dynamic> json) {
    final int year = int.parse(json['date'].split('-')[0]);
    final int month = int.parse(json['date'].split('-')[1]);
    final int day = int.parse(json['date'].split('-')[2]);

    int solvedCount;
    bool isSolved;
    final bool isFrozen = json['value'] == 'frozen';
    final bool isRepaired = json['value'].toString().contains('repaired');

    if (json['value'].runtimeType == int) {
      solvedCount = json['value'];
      isSolved = true;
    } else if (isRepaired) {
      solvedCount = 1;
      isSolved = true;
    } else {
      solvedCount = 0;
      isSolved = false;
    }

    return Grass(
      year: year,
      month: month,
      day: day,
      solvedCount: solvedCount,
      isSolved: isSolved,
      isFrozen: isFrozen,
      isRepaired: isRepaired,
    );
  }
}

class Streak {
  final List<Grass> grass;
  final String? theme;
  final int currentStreak;
  final int longestStreak;
  final String topic;

  const Streak({
    required this.grass,
    required this.theme,
    required this.currentStreak,
    required this.longestStreak,
    required this.topic,
  });

  factory Streak.fromJson(Map<String, dynamic> json) {
    return Streak(
      grass: json['grass']
          .map((grass) => Grass.fromJson(grass))
          .cast<Grass>()
          .toList(),
      theme: json['theme'],
      currentStreak: json['currentStreak'],
      longestStreak: json['longestStreak'],
      topic: json['topic'],
    );
  }
}
