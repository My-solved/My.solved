import 'profile_background_asset.dart';
import 'profile_badge_asset.dart';
import 'profile_rating_breakdown.dart';
import 'profile_tag_rating.dart';

/// Version-neutral profile data consumed by the app's profile surfaces.
///
/// Each API contract is responsible for normalizing its own wire response into
/// this model. Search results use their own version-neutral item models.
class UserProfile {
  const UserProfile({
    required this.handle,
    required this.badgeId,
    required this.backgroundId,
    required this.profileImageUrl,
    this.bio,
    required this.solvedCount,
    required this.legacyContributionCount,
    required this.userClass,
    required this.reverseRivalCount,
    required this.tier,
    required this.rating,
    this.classPlus,
    this.currentStreak,
    this.maxStreak,
    this.reputation,
    this.ratingBreakdown,
    this.background,
    this.badge,
    this.tagRatings = const [],
  });

  final String handle;
  final String? badgeId;
  final String? backgroundId;
  final String? profileImageUrl;

  /// Public profile biography from the active contract, including explicit
  /// empty or whitespace-only values. `null` means absent or explicitly null.
  final String? bio;
  final int solvedCount;

  /// The legacy contribution count populated from the v3 `voteCount` field.
  ///
  /// This value must not be interpreted as Reputation or any other newer
  /// contribution metric. `null` means that the active contract did not
  /// provide the legacy metric.
  final int? legacyContributionCount;

  final int userClass;

  /// Whether the active contract marks the displayed CLASS as CLASS+.
  final bool? classPlus;

  /// Legacy v3 reverse-rival count, unrelated to v4 rivalry booleans.
  final int? reverseRivalCount;

  /// The public tier, or `null` when the active contract explicitly withholds
  /// or does not assign one. Callers must choose their own display fallback.
  final int? tier;
  final int rating;

  /// Current and longest streak summaries exposed by the active profile
  /// contract. Daily activity remains a separate response.
  final int? currentStreak;
  final int? maxStreak;

  /// Reputation from the v4 public profile, distinct from v3 `voteCount`.
  final int? reputation;

  /// Official v4 wire components. `null` for contracts that do not expose
  /// this breakdown.
  final ProfileRatingBreakdown? ratingBreakdown;

  /// Assets embedded by the v4 profile response.
  final ProfileBackgroundAsset? background;
  final ProfileBadgeAsset? badge;

  /// Tag ratings embedded by the v4 profile response.
  final List<ProfileTagRating> tagRatings;
}
