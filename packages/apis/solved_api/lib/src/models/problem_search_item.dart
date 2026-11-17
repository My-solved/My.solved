class ProblemSearchItem {
  const ProblemSearchItem({
    required this.problemId,
    required this.title,
    required this.level,
    required this.tagNames,
    this.givesNoRating,
  });

  final int problemId;
  final String? title;
  final int level;

  /// Whether the active contract explicitly marks the problem as not
  /// contributing to rating. `null` means the contract did not provide it.
  final bool? givesNoRating;

  /// Display labels normalized for the search UI.
  ///
  /// v3 provides localized tag names. The official v4 problem response only
  /// provides tag keys, so those keys are used as the display labels there.
  final List<String> tagNames;
}
