// TODO
class Badge {
  final String badgeId;
  final String badgeImageUrl;
  final int unlockedUserCount;
  final String displayName;
  final String displayDescription;
  final String badgeTier;
  final String badgeCategory;

  const Badge({
    required this.badgeId,
    required this.badgeImageUrl,
    required this.unlockedUserCount,
    required this.displayName,
    required this.displayDescription,
    required this.badgeTier,
    required this.badgeCategory,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      badgeId: json['badgeId'],
      badgeImageUrl: json['badgeImageUrl'],
      unlockedUserCount: json['unlockedUserCount'],
      displayName: json['displayName'],
      displayDescription: json['displayDescription'],
      badgeTier: json['badgeTier'],
      badgeCategory: json['badgeCategory'],
    );
  }
}
