import 'official_user_profile.dart';

/// One page of the official affiliation rating board.
final class RankingAffiliationBoardResult {
  const RankingAffiliationBoardResult({
    required this.mine,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.items,
  });

  /// Entries from the required `mine` array in wire order, including duplicates.
  ///
  /// Decoder-produced lists are source-isolated and unmodifiable.
  final List<RankingAffiliationBoardMineItem> mine;

  /// Raw reported total. The schema declares no bounds.
  final int total;

  /// Raw response page. The schema declares no bounds.
  final int page;

  /// Raw response page size. The schema declares no bounds.
  final int pageSize;

  /// Board entries in wire order, including duplicates.
  ///
  /// Decoder-produced lists are source-isolated and unmodifiable.
  final List<RankingAffiliationBoardItem> items;
}

/// One affiliation on the official rating board.
final class RankingAffiliationBoardItem {
  const RankingAffiliationBoardItem({
    required this.id,
    required this.affiliationId,
    required this.name,
    required this.type,
    required this.userCount,
    required this.logoThumbnailUrl,
    required this.color,
    required this.rank,
    required this.globalRank,
    required this.rating,
    required this.solvedCount,
  });

  /// Raw integer identifier. The schema declares no bounds.
  final int id;

  /// Raw integer affiliation identifier, independent from [id].
  final int affiliationId;

  final String name;

  /// The exact shared official affiliation type vocabulary.
  final OfficialUserProfileAffiliationType type;

  /// Raw user count. The schema declares no lower or upper bound.
  final int userCount;

  /// Raw required nullable response value. URI validity is not implied.
  final String? logoThumbnailUrl;

  /// Raw required nullable response value. Color syntax is not implied.
  final String? color;

  /// Raw board rank. The schema declares no bounds.
  final int rank;

  /// Raw required nullable global rank. No relation to [rank] is implied.
  final int? globalRank;

  /// Raw board rating. The schema declares no bounds.
  final int rating;

  /// Raw solved count. The schema declares no bounds.
  final int solvedCount;
}

/// One affiliation entry from the required `mine` array.
final class RankingAffiliationBoardMineItem {
  const RankingAffiliationBoardMineItem({
    required this.id,
    required this.affiliationId,
    required this.name,
    required this.type,
    required this.userCount,
    required this.logoThumbnailUrl,
    required this.color,
    required this.rank,
    required this.globalRank,
    required this.rating,
    required this.solvedCount,
    required this.page,
  });

  /// Raw integer identifier. The schema declares no bounds.
  final int id;

  /// Raw integer affiliation identifier, independent from [id].
  final int affiliationId;

  final String name;

  /// The exact shared official affiliation type vocabulary.
  final OfficialUserProfileAffiliationType type;

  /// Raw user count. The schema declares no lower or upper bound.
  final int userCount;

  /// Raw required nullable response value. URI validity is not implied.
  final String? logoThumbnailUrl;

  /// Raw required nullable response value. Color syntax is not implied.
  final String? color;

  /// Raw board rank. The schema declares no bounds.
  final int rank;

  /// Raw required nullable global rank. No relation to [rank] is implied.
  final int? globalRank;

  /// Raw board rating. The schema declares no bounds.
  final int rating;

  /// Raw solved count. The schema declares no bounds.
  final int solvedCount;

  /// Raw entry page. No relation to the outer page is implied.
  final int page;
}
