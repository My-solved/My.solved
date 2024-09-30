class ProblemStats {
  final int level;
  final int total;
  final int solved;
  final int partial;
  final int tried;

  ProblemStats({
    required this.level,
    required this.total,
    required this.solved,
    required this.partial,
    required this.tried,
  });

  factory ProblemStats.fromJson(Map<String, dynamic> json) {
    return ProblemStats(
      level: json['level'],
      total: json['total'],
      solved: json['solved'],
      partial: json['partial'],
      tried: json['tried'],
    );
  }
}
