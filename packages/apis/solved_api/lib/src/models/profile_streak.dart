/// Version-neutral profile activity streak consumed by profile surfaces.
class ProfileStreak {
  const ProfileStreak({
    required this.days,
    required this.currentStreak,
    this.maxStreak,
    this.theme,
    this.firstActiveDay,
  });

  final List<ProfileSolvedDay> days;
  final int currentStreak;
  final int? maxStreak;
  final String? theme;

  /// The opaque upstream value. The official v4 schema declares only
  /// `string | null` and does not promise a date format.
  final String? firstActiveDay;
}

/// One calendar day in a profile activity streak.
class ProfileSolvedDay {
  const ProfileSolvedDay({
    required this.year,
    required this.month,
    required this.day,
    required this.solvedCount,
    this.maxSolvedLevel,
    this.ratingDelta,
    this.freezeUsed,
    this.streakRepaired,
  });

  final int year;
  final int month;
  final int day;
  final int solvedCount;
  final int? maxSolvedLevel;
  final int? ratingDelta;
  final bool? freezeUsed;
  final bool? streakRepaired;
}
