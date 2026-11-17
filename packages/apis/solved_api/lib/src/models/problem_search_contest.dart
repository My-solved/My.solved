/// One contest association from the official v4 problem-search contract.
final class ProblemSearchContest {
  const ProblemSearchContest({
    required this.id,
    required this.displayId,
    required this.name,
    required this.abbreviation,
  });

  final num id;
  final String displayId;
  final String name;
  final String? abbreviation;
}
