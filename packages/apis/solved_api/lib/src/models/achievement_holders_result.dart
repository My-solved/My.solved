/// The user attached to one official achievement-holder entry.
final class AchievementHolderUser {
  const AchievementHolderUser({
    required this.id,
    required this.handle,
    required this.tier,
    required this.profileImageUrl,
  });

  /// Raw finite response number. The schema declares no integer constraint.
  final num id;
  final String handle;

  /// Required nullable official tier from 0 through 31.
  final int? tier;

  /// Raw required nullable response value.
  final String? profileImageUrl;
}

/// One acquisition in an official achievement-holder page.
final class AchievementHolderItem {
  const AchievementHolderItem({
    required this.user,
    required this.acquiredAt,
  });

  final AchievementHolderUser user;

  /// Raw response value. The schema declares no date format or pattern.
  final String acquiredAt;
}

/// One official page of users holding an achievement item.
final class AchievementHoldersResult {
  const AchievementHoldersResult({
    required this.unlockedByDefault,
    required this.total,
    required this.items,
  });

  final bool unlockedByDefault;

  /// Raw integer total. The schema declares no bounds.
  final int total;

  /// Holder entries in wire order, including duplicates.
  ///
  /// Decoder-produced lists are source-isolated and unmodifiable.
  final List<AchievementHolderItem> items;
}
