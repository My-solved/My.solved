import 'user_profile.dart';

/// Sources exposed by the official v4 public-profile streak vacation field.
enum OfficialUserProfileStreakVacationSource {
  item('item'),
  launch('launch');

  const OfficialUserProfileStreakVacationSource(this.value);

  final String value;
}

/// The nullable current streak vacation in an official v4 public profile.
final class OfficialUserProfileStreakVacation {
  const OfficialUserProfileStreakVacation({
    required this.fromDay,
    required this.source,
  });

  /// Raw response value. The schema does not declare a date format.
  final String fromDay;
  final OfficialUserProfileStreakVacationSource source;
}

/// The official v4 public profile with its wire metadata preserved.
final class OfficialUserProfile extends UserProfile {
  const OfficialUserProfile({
    required this.id,
    required this.voteCount,
    required this.streakVacation,
    required this.streakCountedToday,
    required this.streakFrozenYesterday,
    required this.streakTheme,
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

  /// Required nullable current streak vacation from the profile response.
  final OfficialUserProfileStreakVacation? streakVacation;

  final bool streakCountedToday;
  final bool streakFrozenYesterday;

  /// Raw required nullable theme value from the profile response.
  final String? streakTheme;
}
