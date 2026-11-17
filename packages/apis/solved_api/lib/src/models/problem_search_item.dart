class ProblemSearchItem {
  const ProblemSearchItem({
    required this.problemId,
    required this.title,
    required this.level,
    required this.tagNames,
  });

  final int problemId;
  final String title;
  final int level;
  final List<String> tagNames;
}
