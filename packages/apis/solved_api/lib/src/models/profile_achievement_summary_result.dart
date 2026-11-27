import 'official_achievement_item.dart';

/// One recently acquired item in the official v4 achievement summary.
final class ProfileAchievementSummaryRecentItem {
  const ProfileAchievementSummaryRecentItem({
    required this.kind,
    required this.id,
    required this.key,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.addedAt,
    required this.acquiredAt,
  });

  final OfficialAchievementItemKind kind;
  final int id;
  final String key;
  final String name;
  final String imageUrl;
  final String category;

  /// Raw response value. The schema declares no date format or pattern.
  final String addedAt;

  /// Raw response value. The schema declares no date format or pattern.
  final String acquiredAt;
}

/// The complete official v4 public achievement summary.
final class ProfileAchievementSummaryResult {
  const ProfileAchievementSummaryResult({
    required this.earned,
    required this.total,
    required this.past,
    required this.badges,
    required this.backgrounds,
    required this.recent,
  });

  final int earned;
  final int total;
  final int past;
  final int badges;
  final int backgrounds;

  /// Recent items in wire order, including duplicates.
  ///
  /// Decoder-produced lists are unmodifiable. An empty list is authoritative.
  final List<ProfileAchievementSummaryRecentItem> recent;
}
