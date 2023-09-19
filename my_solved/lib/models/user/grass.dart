class Grass {
  final List<dynamic> grass;
  final dynamic theme;
  final int currentStreak;
  final int longestStreak;
  final String topic;

  const Grass({
    required this.grass,
    required this.theme,
    required this.currentStreak,
    required this.longestStreak,
    required this.topic,
  });

  factory Grass.fromJson(Map<String, dynamic> json) {
    return Grass(
      grass: json['grass'],
      theme: json['theme'],
      currentStreak: json['currentStreak'],
      longestStreak: json['longestStreak'],
      topic: json['topic'],
    );
  }
}
