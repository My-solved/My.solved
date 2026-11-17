class UserSearchItem {
  const UserSearchItem({
    required this.handle,
    required this.profileImageUrl,
    required this.tier,
    this.rank,
    this.userClass,
    this.classPlus,
    this.rating,
    this.solvedCount,
    this.reputation,
  });

  final String handle;
  final String? profileImageUrl;
  final int? tier;

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

  /// Official reputation, or `null` when the active contract did not expose
  /// it. Legacy vote counts must not be reinterpreted as reputation.
  final int? reputation;
}
