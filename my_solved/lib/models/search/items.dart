class Items {
  final int problemId;
  final String titleKo;
  final List<dynamic> titles;
  final bool isSolvable;
  final bool isPartial;
  final int acceptedUserCount;
  final int level;
  final int votedUserCount;
  final bool sprout;
  final bool isLevelLocked;
  final num averageTries;
  final bool official;
  final List<dynamic> tags;

  const Items({
    required this.problemId,
    required this.titleKo,
    required this.titles,
    required this.isSolvable,
    required this.isPartial,
    required this.acceptedUserCount,
    required this.level,
    required this.votedUserCount,
    required this.sprout,
    required this.isLevelLocked,
    required this.averageTries,
    required this.official,
    required this.tags,
  });

  factory Items.fromJson(Map<String, dynamic> json) {
    return Items(
      problemId: json['problemId'],
      titleKo: json['titleKo'],
      titles: json['titles'],
      isSolvable: json['isSolvable'],
      isPartial: json['isPartial'],
      acceptedUserCount: json['acceptedUserCount'],
      level: json['level'],
      votedUserCount: json['votedUserCount'],
      sprout: json['sprout'],
      isLevelLocked: json['isLevelLocked'],
      averageTries: json['averageTries'],
      official: json['official'],
      tags: json['tags'],
    );
  }
}
