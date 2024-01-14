class SiteStats {
  final int problemCount;
  final int problemVotedCount;
  final int userCount;
  final int contributorCount;
  final int contributionCount;

  const SiteStats({
    required this.problemCount,
    required this.problemVotedCount,
    required this.userCount,
    required this.contributorCount,
    required this.contributionCount,
  });

  factory SiteStats.fromJson(Map<String, dynamic> json) {
    return SiteStats(
      problemCount: json['problemCount'],
      problemVotedCount: json['problemVotedCount'],
      userCount: json['userCount'],
      contributorCount: json['contributorCount'],
      contributionCount: json['contributionCount'],
    );
  }
}
