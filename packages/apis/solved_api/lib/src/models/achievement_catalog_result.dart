import 'official_achievement_item.dart';

/// One reward attached to an official v4 achievement.
final class AchievementReward {
  const AchievementReward({
    required this.kind,
    required this.id,
    required this.key,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.addedAt,
  });

  final OfficialAchievementItemKind kind;

  /// Raw integer identifier. The schema declares no bounds.
  final int id;
  final String key;
  final String name;
  final String imageUrl;
  final String category;

  /// Raw response value. The schema declares no date format or pattern.
  final String addedAt;
}

/// The viewer's progress toward one achievement.
final class AchievementProgress {
  const AchievementProgress({required this.current, required this.target});

  /// Raw integer progress value. The schema declares no bounds.
  final int current;

  /// Raw integer target value. The schema declares no bounds.
  final int target;
}

/// One entry in the official public achievement catalog.
final class AchievementCatalogItem {
  const AchievementCatalogItem({
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
}

/// The official public achievement catalog and reported user total.
final class AchievementCatalogResult {
  const AchievementCatalogResult({
    required this.items,
    required this.userCount,
  });

  /// Catalog entries in wire order, including duplicates.
  ///
  /// Decoder-produced lists are source-isolated and unmodifiable.
  final List<AchievementCatalogItem> items;

  /// Reported user total. The schema requires a non-negative integer.
  final int userCount;
}
