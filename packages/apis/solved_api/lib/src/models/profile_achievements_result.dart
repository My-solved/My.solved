import 'achievement_catalog_result.dart';

/// The comparison user's acquisition state for one profile achievement.
final class ProfileAchievementVs {
  const ProfileAchievementVs({required this.earnedAt});

  /// Raw required nullable response value. Calendar validity is not implied.
  final String? earnedAt;
}

/// One entry in an official user's achievement catalog.
final class ProfileAchievementItem {
  const ProfileAchievementItem({
    required this.id,
    required this.key,
    required this.series,
    required this.seriesOrder,
    required this.historic,
    required this.hidden,
    required this.name,
    required this.condition,
    required this.searchQuery,
    required this.shopKey,
    required this.rewards,
    required this.holderCount,
    required this.earnedAt,
    required this.progress,
    required this.vs,
  });

  /// Raw integer identifier. The schema declares no bounds.
  final int id;
  final String key;
  final String series;

  /// Raw integer series order. The schema declares no bounds.
  final int seriesOrder;
  final bool historic;
  final bool hidden;
  final String name;
  final String? condition;
  final String? searchQuery;
  final String? shopKey;

  /// Rewards in wire order, including duplicates.
  ///
  /// Decoder-produced lists are source-isolated and unmodifiable.
  final List<AchievementReward> rewards;

  /// Raw integer holder count. The schema declares no bounds.
  final int holderCount;

  /// Raw required nullable response value. Calendar validity is not implied.
  final String? earnedAt;

  final AchievementProgress? progress;

  /// Required nullable comparison state.
  final ProfileAchievementVs? vs;
}

/// One official user's complete achievement catalog.
final class ProfileAchievementsResult {
  const ProfileAchievementsResult({
    required this.handle,
    required this.vsHandle,
    required this.items,
    required this.userCount,
  });

  final String handle;
  final String? vsHandle;

  /// Achievement entries in wire order, including duplicates.
  ///
  /// Decoder-produced lists are source-isolated and unmodifiable.
  final List<ProfileAchievementItem> items;

  /// Reported user total. The schema requires a non-negative integer.
  final int userCount;
}
