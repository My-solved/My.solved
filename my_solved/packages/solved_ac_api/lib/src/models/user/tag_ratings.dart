class TagRatings {
  final dynamic tag;
  final dynamic aliases;
  final int solvedCount;
  final int rating;
  final int ratingByProblemsSum;
  final int ratingByClass;
  final int ratingBySolvedCount;
  final int ratingProblemsCutoff;

  const TagRatings(
      {required this.tag,
      required this.aliases,
      required this.solvedCount,
      required this.rating,
      required this.ratingByProblemsSum,
      required this.ratingByClass,
      required this.ratingBySolvedCount,
      required this.ratingProblemsCutoff});

  factory TagRatings.fromJson(Map<String, dynamic> json) {
    return TagRatings(
        tag: json['tag'],
        aliases: json['aliases'],
        solvedCount: json['solvedCount'],
        rating: json['rating'],
        ratingByProblemsSum: json['ratingByProblemsSum'],
        ratingByClass: json['ratingByClass'],
        ratingBySolvedCount: json['ratingBySolvedCount'],
        ratingProblemsCutoff: json['ratingProblemsCutoff']);
  }
}
