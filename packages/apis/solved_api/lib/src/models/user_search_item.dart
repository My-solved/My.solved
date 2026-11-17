class UserSearchItem {
  const UserSearchItem({
    required this.handle,
    required this.profileImageUrl,
    required this.tier,
    this.id,
    this.rank,
    this.userClass,
    this.classPlus,
    this.rating,
    this.solvedCount,
    this.voteCount,
    this.reputation,
    this.tagRating,
    this.globalRank,
    this.page,
  });

  final String handle;
  final String? profileImageUrl;
  final int? tier;

  /// Raw user identifier returned by the active search contract.
  /// `null` means the contract did not expose it.
  final num? id;

  /// Rank returned by the active search contract. This must not be replaced
  /// with a separate global-rank or page field.
  final int? rank;

  /// CLASS value returned by the active search contract.
  final int? userClass;

  /// Whether the active contract explicitly marks [userClass] as CLASS+.
  /// Legacy decoration fields must not be reinterpreted as this marker.
  final bool? classPlus;

  /// Public rating, or `null` when the active contract did not expose it.
  final int? rating;

  /// Number of solved problems, or `null` when unavailable.
  final int? solvedCount;

  /// Raw vote count returned by the active search contract.
  /// This value is independent from [reputation].
  final int? voteCount;

  /// Official reputation, or `null` when the active contract did not expose
  /// it. Legacy vote counts must not be reinterpreted as reputation.
  final int? reputation;

  /// Tag rating returned by the active search contract, when available.
  final int? tagRating;

  /// Separate global rank returned by the active search contract.
  /// This must not be used as a fallback for [rank].
  final int? globalRank;

  /// Per-result page metadata returned by the active search contract.
  /// This must not be reinterpreted as request pagination.
  final int? page;
}
