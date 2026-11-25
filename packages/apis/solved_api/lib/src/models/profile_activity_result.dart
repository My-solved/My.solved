import 'profile_streak.dart';

/// Sources exposed by the official v4 profile-activity vacation field.
enum ProfileActivityVacationSource {
  item('item'),
  launch('launch');

  const ProfileActivityVacationSource(this.value);

  final String value;
}

/// The nullable vacation object in an official v4 activity response.
final class ProfileActivityCurrentVacation {
  const ProfileActivityCurrentVacation({
    required this.fromDay,
    required this.source,
  });

  /// Raw response value. The schema does not declare a date format.
  final String fromDay;
  final ProfileActivityVacationSource source;
}

/// One entry in the official v4 activity vacation list.
final class ProfileActivityVacation {
  const ProfileActivityVacation({
    required this.fromDay,
    required this.untilDay,
  });

  /// Raw response value. The schema does not declare a date format.
  final String fromDay;

  /// Raw response value, or `null` as explicitly returned by the API.
  final String? untilDay;
}

/// The complete official v4 profile-activity response.
final class ProfileActivityResult extends ProfileStreak {
  const ProfileActivityResult({
    required this.from,
    required this.to,
    required super.days,
    required this.maxSolvedCount,
    required super.currentStreak,
    required int maxStreak,
    required super.theme,
    required super.firstActiveDay,
    required this.vacation,
    required this.vacations,
    required this.countedToday,
    required this.frozenYesterday,
  }) : super(maxStreak: maxStreak);

  /// Raw response range values. Their response schemas impose no date format.
  final String from;
  final String to;
  final int maxSolvedCount;

  @override
  int get maxStreak => super.maxStreak!;

  /// The required nullable vacation value from the v4 response.
  final ProfileActivityCurrentVacation? vacation;

  /// Vacation entries in wire order, including duplicates.
  ///
  /// Decoder-produced lists are unmodifiable. An empty list is authoritative.
  final List<ProfileActivityVacation> vacations;

  final bool countedToday;
  final bool frozenYesterday;
}
