/// Version-neutral profile data consumed by the app's profile surfaces.
///
/// Each API contract is responsible for normalizing its own wire response into
/// this model. Search results intentionally continue to use [User].
class UserProfile {
  const UserProfile({
    required this.handle,
    required this.badgeId,
    required this.backgroundId,
    required this.profileImageUrl,
    required this.solvedCount,
    required this.legacyContributionCount,
    required this.userClass,
    required this.reverseRivalCount,
    required this.tier,
    required this.rating,
  });

  final String handle;
  final String? badgeId;
  final String? backgroundId;
  final String? profileImageUrl;
  final int solvedCount;

  /// The legacy contribution count populated from the v3 `voteCount` field.
  ///
  /// This value must not be interpreted as Reputation or any other newer
  /// contribution metric. `null` means that the active contract did not
  /// provide the legacy metric.
  final int? legacyContributionCount;

  final int userClass;
  final int? reverseRivalCount;
  final int tier;
  final int rating;
}
