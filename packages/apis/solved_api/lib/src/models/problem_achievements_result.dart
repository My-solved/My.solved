import 'achievement_catalog_result.dart';

/// How one achievement relates to the requested problem.
enum ProblemAchievementRelation {
  unlocks('unlocks'),
  counts('counts');

  const ProblemAchievementRelation(this.value);

  final String value;
}

/// One official achievement related to a problem.
final class ProblemAchievementItem {
  const ProblemAchievementItem({
    required this.key,
    required this.name,
    required this.condition,
    required this.rewards,
    required this.holderCount,
    required this.earnedAt,
    required this.relation,
    required this.byLevel,
  });

  final String key;
  final String name;
  final String? condition;

  /// Rewards in wire order, including duplicates.
  ///
  /// Decoder-produced lists are source-isolated and unmodifiable.
  final List<AchievementReward> rewards;

  /// Raw integer holder count. The schema declares no bounds.
  final int holderCount;

  /// Raw required nullable response value. Calendar validity is not implied.
  final String? earnedAt;

  final ProblemAchievementRelation relation;
  final bool byLevel;
}

/// Official achievements related to one problem.
final class ProblemAchievementsResult {
  const ProblemAchievementsResult({required this.items});

  /// Related achievements in wire order, including duplicates.
  ///
  /// Decoder-produced lists are source-isolated and unmodifiable.
  final List<ProblemAchievementItem> items;
}
