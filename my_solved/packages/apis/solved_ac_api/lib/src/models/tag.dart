// TODO
class ProblemTag {
  final String key;
  final bool isMeta;
  final int bojTagId;
  final int problemCount;

  const ProblemTag({
    required this.key,
    required this.isMeta,
    required this.bojTagId,
    required this.problemCount,
  });

  factory ProblemTag.fromJson(Map<String, dynamic> json) {
    return ProblemTag(
      key: json['key'],
      isMeta: json['isMeta'],
      bojTagId: json['bojTagId'],
      problemCount: json['problemCount'],
    );
  }
}
