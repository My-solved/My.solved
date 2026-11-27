import 'ranking_leaderboard_result.dart';

/// One page of the viewer's official v4 rival or reverse-rival board.
final class RivalLeaderboardResult {
  const RivalLeaderboardResult({
    required this.me,
    required this.mePage,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.items,
    required this.rivalCount,
    required this.reverseRivalCount,
  });

  /// Required nullable viewer entry, in the exact leaderboard user shape.
  final RankingLeaderboardUser? me;

  /// Raw required nullable page for [me]. No relation to [page] is implied.
  final int? mePage;

  /// Raw integers. No bounds or relation to [items] are implied, and the
  /// response page need not equal the requested page.
  final int total;
  final int page;
  final int pageSize;

  /// Entries in wire order, including duplicates.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable.
  final List<RivalLeaderboardUser> items;

  /// Raw integers. No relation to [items] or [total] is implied.
  final int rivalCount;
  final int reverseRivalCount;
}

/// One entry of an official v4 rival board.
final class RivalLeaderboardUser {
  const RivalLeaderboardUser({
    required this.user,
    required this.isRival,
    required this.isReverseRival,
  });

  /// The 13 fields shared exactly with the public leaderboard user.
  final RankingLeaderboardUser user;

  /// Raw viewer relationship flags. No relation between them is implied.
  final bool isRival;
  final bool isReverseRival;
}
