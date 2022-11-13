class Background {
  final String backgroundId;
  final String backgroundImageUrl;
  final String author;
  final String authorUrl;
  final int unlockedUserCount;
  final String displayName;
  final String displayDescription;
  final String conditions;
  final bool hiddenConditions;
  final bool isIllust;

  Background({
      required this.backgroundId,
      required this.backgroundImageUrl,
      required this.author,
      required this.authorUrl,
      required this.unlockedUserCount,
      required this.displayName,
      required this.displayDescription,
      required this.conditions,
      required this.hiddenConditions,
      required this.isIllust,
  });

  factory Background.fromJson(Map<String, dynamic> json) {
    return Background(
      backgroundId: json['backgroundId'],
      backgroundImageUrl: json['backgroundImageUrl'],
      author: json['author'],
      authorUrl: json['authorUrl'],
      unlockedUserCount: json['unlockedUserCount'],
      displayName: json['displayName'],
      displayDescription: json['displayDescription'],
      conditions: json['conditions'],
      hiddenConditions: json['hiddenConditions'],
      isIllust: json['isIllust'],
    );
  }
}