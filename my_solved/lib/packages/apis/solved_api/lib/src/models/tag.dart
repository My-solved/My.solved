class Tag {
  final String key;
  final bool isMeta;
  final int bojTagId;
  final int problemCount;
  final List<dynamic> displayNames;
  final List<dynamic> aliases;

  const Tag({
    required this.key,
    required this.isMeta,
    required this.bojTagId,
    required this.problemCount,
    required this.displayNames,
    required this.aliases,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      key: json['key'],
      isMeta: json['isMeta'],
      bojTagId: json['bojTagId'],
      problemCount: json['problemCount'],
      displayNames: json['displayNames'],
      aliases: json['aliases'],
    );
  }
}

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
