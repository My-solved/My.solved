class Problem {
  final int problemId;
  final String titleKo;
  final bool isSolvable;
  final bool isPartial;
  final int acceptedUserCount;
  final int level;
  final int votedUserCount;
  final bool isLevelLocked;
  final num averageTries;
  final List<dynamic> tags;

  const Problem({
    required this.problemId,
    required this.titleKo,
    required this.isSolvable,
    required this.isPartial,
    required this.acceptedUserCount,
    required this.level,
    required this.votedUserCount,
    required this.isLevelLocked,
    required this.averageTries,
    required this.tags,
  });

  factory Problem.fromJson(Map<String, dynamic> json) {
    return Problem(
      problemId: json['problemId'],
      titleKo: json['titleKo'],
      isSolvable: json['isSolvable'],
      isPartial: json['isPartial'],
      acceptedUserCount: json['acceptedUserCount'],
      level: json['level'],
      votedUserCount: json['votedUserCount'],
      isLevelLocked: json['isLevelLocked'],
      averageTries: json['averageTries'],
      tags: json['tags'],
    );
  }
}
