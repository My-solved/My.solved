/// Version-neutral profile activity streak consumed by profile surfaces.
class ProfileStreak {
  const ProfileStreak({
    required this.days,
    required this.currentStreak,
  });

  final List<ProfileSolvedDay> days;
  final int currentStreak;
}

/// One calendar day in a profile activity streak.
class ProfileSolvedDay {
  const ProfileSolvedDay({
    required this.year,
    required this.month,
    required this.day,
    required this.solvedCount,
  });

  final int year;
  final int month;
  final int day;
  final int solvedCount;
}
