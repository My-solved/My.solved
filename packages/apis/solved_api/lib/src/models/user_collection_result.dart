import 'official_achievement_item.dart';

/// A page of badges or backgrounds a user owns, from the official v4 API.
final class UserCollectionResult {
  const UserCollectionResult({
    required this.items,
    required this.total,
    required this.nextOffset,
    required this.counts,
    required this.categories,
    required this.equipped,
    required this.equippedBadge,
    required this.equippedBackground,
  });

  /// Items in wire order, including duplicates.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable, as is [categories].
  final List<UserCollectionItem> items;

  /// Raw integer. No bounds or relation to [items] or [counts] are implied.
  final int total;

  /// Raw required nullable integer. No pagination arithmetic is implied.
  final int? nextOffset;

  final UserCollectionCounts counts;

  /// Raw category names in wire order, including duplicates.
  final List<String> categories;

  /// Required nullable equipped item. No relation to [items] is implied.
  final UserCollectionItem? equipped;

  /// Required nullable wire `equippedByKind.badge`.
  final UserCollectionItem? equippedBadge;

  /// Required nullable wire `equippedByKind.background`.
  final UserCollectionItem? equippedBackground;
}

/// Owned item counts by kind.
final class UserCollectionCounts {
  const UserCollectionCounts({required this.badge, required this.background});

  /// Raw integers. The schema declares no bounds.
  final int badge;
  final int background;
}

/// One owned badge or background in an official v4 collection.
final class UserCollectionItem {
  const UserCollectionItem({
    required this.kind,
    required this.id,
    required this.key,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.addedAt,
    required this.equipped,
    required this.acquiredAt,
    required this.holderCount,
  });

  final OfficialAchievementItemKind kind;

  /// Raw integer. The schema declares no bounds.
  final int id;

  final String key;
  final String name;

  /// Raw response value. URI validity is not implied.
  final String imageUrl;

  final String category;

  /// Raw strings. They are not parsed or ordered.
  final String addedAt;

  final bool equipped;

  /// Raw required nullable string. It is not parsed.
  final String? acquiredAt;

  /// Raw required nullable integer. The schema declares no bounds.
  final int? holderCount;
}
