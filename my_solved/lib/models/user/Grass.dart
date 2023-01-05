class Grass {
  final List<dynamic> grass;
  final String theme;
  final int currentStreak;
  final int longestStreak;

  const Grass({
    required this.grass,
    required this.theme,
    required this.currentStreak,
    required this.longestStreak,
  });

  factory Grass.fromJson(Map<String, dynamic> json) {
    return Grass(
      grass: json['grass'],
      theme: json['theme'],
      currentStreak: json['currentStreak'],
      longestStreak: json['longestStreak'],
    );
  }
}
