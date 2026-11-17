/// Codes exposed by the official v4 `noRatingReasons` field.
enum ProblemNoRatingReason {
  unofficial('unofficial'),
  legacy('legacy'),
  staff('staff'),
  unsettled('unsettled');

  const ProblemNoRatingReason(this.value);

  final String value;
}

class ProblemSearchItem {
  const ProblemSearchItem({
    required this.problemId,
    required this.title,
    required this.level,
    required this.tagNames,
    this.givesNoRating,
    this.noRatingReasons,
  });

  final int problemId;
  final String? title;
  final int level;

  /// Whether the active contract explicitly marks the problem as not
  /// contributing to rating. `null` means the contract did not provide it.
  final bool? givesNoRating;

  /// Reasons explicitly reported by the active contract.
  ///
  /// `null` means the contract did not provide this field, while an empty list
  /// means it explicitly reported no reasons.
  final List<ProblemNoRatingReason>? noRatingReasons;

  /// Display labels normalized for the search UI.
  ///
  /// v3 provides localized tag names. The official v4 problem response only
  /// provides tag keys, so those keys are used as the display labels there.
  final List<String> tagNames;
}
