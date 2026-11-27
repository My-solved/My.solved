/// One localized title entry from the official v4 problem contract.
final class ProblemSearchTitle {
  const ProblemSearchTitle({
    required this.language,
    required this.title,
    required this.isOriginal,
    required this.latex,
    required this.html,
  });

  final String language;
  final String title;
  final bool isOriginal;
  final bool latex;
  final bool html;
}
