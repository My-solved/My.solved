class Badge {
  final String badgeId;
  final String badgeImageUrl;
  final int unlockedUserCount;
  final String displayName;
  final String displayDescription;

  const Badge({
    required this.badgeId,
    required this.badgeImageUrl,
    required this.unlockedUserCount,
    required this.displayName,
    required this.displayDescription,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      badgeId: json['badgeId'],
      badgeImageUrl: json['badgeImageUrl'],
      unlockedUserCount: json['unlockedUserCount'],
      displayName: json['displayName'],
      displayDescription: json['displayDescription'],
    );
  }
}
