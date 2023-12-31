import 'models.dart';

class Streak {
  final List<dynamic> grass;
  final dynamic theme;
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
