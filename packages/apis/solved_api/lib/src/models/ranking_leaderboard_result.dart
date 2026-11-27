/// One page from the official v4 user leaderboard response shared by ranking
/// scopes.
final class RankingLeaderboardResult {
  const RankingLeaderboardResult({
    required this.me,
    required this.mePage,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.items,
  });

  /// The required nullable current-user entry.
  ///
  /// Its presence does not imply authentication or a relationship to [items].
  final RankingLeaderboardUser? me;

  /// Raw required nullable page for [me].
  ///
  /// The schema declares no bounds or relationship to [page].
  final int? mePage;

  /// Raw reported total. The schema declares no bounds.
  final int total;

  /// Raw response page. It need not equal the requested page.
  final int page;

  /// Raw response page size. No relationship to [items] is implied.
  final int pageSize;

  /// Ranking entries in wire order, including duplicates.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable.
  final List<RankingLeaderboardUser> items;
}

/// One user in the official v4 leaderboard response shared by ranking scopes.
final class RankingLeaderboardUser {
  const RankingLeaderboardUser({
    required this.id,
    required this.handle,
    required this.tier,
    required this.profileImageUrl,
    required this.rank,
    required this.rating,
    required this.solvedCount,
    required this.voteCount,
    required this.reputation,
    required this.userClass,
    required this.classPlus,
    required this.tagRating,
    required this.globalRank,
  });

  /// Raw finite response number. Integer semantics and bounds are not implied.
  final num id;

  final String handle;

  /// Required nullable official tier. Non-null values are in the range 0..31.
  final int? tier;

  /// Raw required nullable response value. URI validity is not implied.
  final String? profileImageUrl;

  /// Raw integer fields. The schema declares no bounds or relationships.
  final int rank;
  final int rating;
  final int solvedCount;
  final int voteCount;
  final int reputation;

  /// Raw wire `class` integer. The schema declares no bounds.
  final int userClass;

  final bool classPlus;

  /// Raw required nullable tag rating. No sort-specific meaning is inferred.
  final int? tagRating;

  /// Raw required nullable global rank. No relation to [rank] is implied.
  final int? globalRank;
}
