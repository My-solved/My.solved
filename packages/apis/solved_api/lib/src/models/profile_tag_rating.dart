/// Version-neutral tag rating consumed by profile charts.
class ProfileTagRating {
  const ProfileTagRating({
    this.key,
    required this.rating,
    this.solvedCount,
    this.ratingByProblemsSum,
    this.ratingByClass,
    this.ratingBySolvedCount,
    this.ratingProblemsCutoff,
  });

  final String? key;
  final int rating;
  final int? solvedCount;
  final int? ratingByProblemsSum;
  final int? ratingByClass;
  final int? ratingBySolvedCount;
  final int? ratingProblemsCutoff;
}
