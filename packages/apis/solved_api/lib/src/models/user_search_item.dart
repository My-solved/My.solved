class UserSearchItem {
  const UserSearchItem({
    required this.handle,
    required this.profileImageUrl,
    required this.tier,
    this.rating,
    this.solvedCount,
  });

  final String handle;
  final String? profileImageUrl;
  final int? tier;

  /// Public rating, or `null` when the active contract did not expose it.
  final int? rating;

  /// Number of solved problems, or `null` when unavailable.
  final int? solvedCount;
}
