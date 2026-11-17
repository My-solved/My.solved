class ProblemSearchItem {
  const ProblemSearchItem({
    required this.problemId,
    required this.title,
    required this.level,
    required this.tagNames,
  });

  final int problemId;
  final String? title;
  final int level;

  /// Display labels normalized for the search UI.
  ///
  /// v3 provides localized tag names. The official v4 problem response only
  /// provides tag keys, so those keys are used as the display labels there.
  final List<String> tagNames;
}
