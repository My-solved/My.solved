class UserSearchItem {
  const UserSearchItem({
    required this.handle,
    required this.profileImageUrl,
    required this.tier,
    this.rating,
    this.solvedCount,
    this.reputation,
  });

  final String handle;
  final String? profileImageUrl;
  final int? tier;

  /// Public rating, or `null` when the active contract did not expose it.
  final int? rating;

  /// Number of solved problems, or `null` when unavailable.
  final int? solvedCount;

  /// Official reputation, or `null` when the active contract did not expose
  /// it. Legacy vote counts must not be reinterpreted as reputation.
  final int? reputation;
}
