import 'user_profile.dart';

/// The official v4 public profile with its wire identity metadata preserved.
final class OfficialUserProfile extends UserProfile {
  const OfficialUserProfile({
    required this.id,
    required this.voteCount,
    required super.handle,
    required super.badgeId,
    required super.backgroundId,
    required super.profileImageUrl,
    super.bio,
    required super.solvedCount,
    required super.legacyContributionCount,
    required super.userClass,
    required super.reverseRivalCount,
    required super.tier,
    required super.rating,
    super.classPlus,
    super.currentStreak,
    super.maxStreak,
    super.reputation,
    super.ratingBreakdown,
    super.background,
    super.badge,
    super.tagRatings,
  });

  /// Raw finite response number. The public-profile schema declares no bounds
  /// or stability relationship with other identity endpoints.
  final num id;

  /// Official v4 vote count, distinct from Reputation and the v3 legacy field.
  final int voteCount;
}
