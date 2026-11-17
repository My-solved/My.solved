/// Version-neutral rating fields exposed by the v4 public profile.
///
/// The names intentionally follow the official wire contract. The official
/// OpenAPI document does not expose an Over Rating field, so [overRating]
/// remains nullable until a separate official contract establishes it.
class ProfileRatingBreakdown {
  const ProfileRatingBreakdown({
    required this.rating,
    required this.ratingByProblemsSum,
    required this.ratingByClass,
    required this.ratingBySolvedCount,
    required this.ratingProblemsCutoff,
    required this.ratingProblemsHistogram,
    this.noRatingSolvedCount,
    this.overRating,
  });

  final int rating;
  final int ratingByProblemsSum;
  final int ratingByClass;
  final int ratingBySolvedCount;
  final int ratingProblemsCutoff;
  final List<int> ratingProblemsHistogram;

  /// Problems that the active contract reports outside rating calculation.
  /// No non-negative bound is implied by the official v4 schema.
  final int? noRatingSolvedCount;
  final int? overRating;
}
