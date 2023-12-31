import 'models.dart';

class TagRating {
  final Tag tag;
  final int solvedCount;
  final int rating;
  final int ratingByProblemsSum;
  final int ratingByClass;
  final int ratingBySolvedCount;
  final int ratingProblemsCutoff;

  const TagRating(
      {required this.tag,
      required this.solvedCount,
      required this.rating,
      required this.ratingByProblemsSum,
      required this.ratingByClass,
      required this.ratingBySolvedCount,
      required this.ratingProblemsCutoff});

  factory TagRating.fromJson(Map<String, dynamic> json) {
    return TagRating(
        tag: Tag.fromJson(json['tag']),
        solvedCount: json['solvedCount'],
        rating: json['rating'],
        ratingByProblemsSum: json['ratingByProblemsSum'],
        ratingByClass: json['ratingByClass'],
        ratingBySolvedCount: json['ratingBySolvedCount'],
        ratingProblemsCutoff: json['ratingProblemsCutoff']);
  }
}
