class Background {
  final String backgroundId;
  final String backgroundImageUrl;
  final String fallbackBackgroundImageUrl;
  final String backgroundVideoUrl;
  final int unlockedUserCount;
  final String displayDescription;
  final String conditions;
  final bool hiddenConditions;
  final bool isIllust;
  final String displayName;

  Background({
    required this.backgroundId,
    required this.backgroundImageUrl,
    required this.fallbackBackgroundImageUrl,
    required this.backgroundVideoUrl,
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
      fallbackBackgroundImageUrl: json['fallbackBackgroundImageUrl'],
      backgroundVideoUrl: json['backgroundVideoUrl'],
      unlockedUserCount: json['unlockedUserCount'],
      displayName: json['displayName'],
      displayDescription: json['displayDescription'],
      conditions: json['conditions'],
      hiddenConditions: json['hiddenConditions'],
      isIllust: json['isIllust'],
    );
  }
}
