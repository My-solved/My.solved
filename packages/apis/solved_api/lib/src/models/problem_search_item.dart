import 'problem_no_rating_warning.dart';

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
    this.votedUserCount,
    this.solvedUserCount,
    this.givesNoRating,
    this.noRatingReasons,
    this.noRatingWarnings,
  });

  final int problemId;
  final String? title;
  final int level;

  /// The raw voted-user count reported by the active contract.
  /// `null` means the contract did not provide it.
  final num? votedUserCount;

  /// The raw solved-user count reported by the active contract.
  /// `null` means the contract did not provide it.
  final num? solvedUserCount;

  /// Whether the active contract explicitly marks the problem as not
  /// contributing to rating. `null` means the contract did not provide it.
  final bool? givesNoRating;

  /// Reasons explicitly reported by the active contract.
  ///
  /// `null` means the contract did not provide this field, while an empty list
  /// means it explicitly reported no reasons.
  final List<ProblemNoRatingReason>? noRatingReasons;

  /// Warnings explicitly reported by the active contract.
  ///
  /// `null` means the contract did not provide this field, while an empty list
  /// means it explicitly reported no warnings.
  final List<ProblemNoRatingWarning>? noRatingWarnings;

  /// Display labels normalized for the search UI.
  ///
  /// v3 provides localized tag names. The official v4 problem response only
  /// provides tag keys, so those keys are used as the display labels there.
  final List<String> tagNames;
}
