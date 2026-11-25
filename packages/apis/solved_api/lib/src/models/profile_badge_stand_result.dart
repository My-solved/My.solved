import 'official_achievement_item.dart';

/// One item displayed on the official v4 profile badge stand.
final class ProfileBadgeStandItem {
  const ProfileBadgeStandItem({
    required this.kind,
    required this.id,
    required this.key,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.addedAt,
    required this.holderCount,
  });

  final OfficialAchievementItemKind kind;
  final int id;
  final String key;
  final String name;
  final String imageUrl;
  final String category;

  /// Raw response value. The schema declares no date format or pattern.
  final String addedAt;

  final int holderCount;
}

/// The complete official v4 public profile badge stand.
final class ProfileBadgeStandResult {
  const ProfileBadgeStandResult({
    required this.chosen,
    required this.badges,
  });

  final bool chosen;

  /// Stand items in wire order, including duplicates and background items.
  ///
  /// Decoder-produced lists are unmodifiable. An empty list is authoritative.
  final List<ProfileBadgeStandItem> badges;
}
