class ProblemStat {
  final int level;
  final int total;
  final int solved;
  final int partial;
  final int tried;

  ProblemStat({
    required this.level,
    required this.total,
    required this.solved,
    required this.partial,
    required this.tried,
  });

  factory ProblemStat.fromJson(Map<String, dynamic> json) {
    return ProblemStat(
      level: json['level'],
      total: json['total'],
      solved: json['solved'],
      partial: json['partial'],
      tried: json['tried'],
    );
  }
}
