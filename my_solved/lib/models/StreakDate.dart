class StreakDate {
  final int day;
  final int month;
  final int year;
  final int weekDay;
  final int solvedCount;
  final bool isFuture;
  final bool isFrozen;
  final bool isRepaired;

  const StreakDate(
      {required this.day,
      required this.month,
      required this.year,
      required this.weekDay,
      required this.solvedCount,
      required this.isFuture,
      required this.isFrozen,
      required this.isRepaired});
}
