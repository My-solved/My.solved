/// Codes exposed by the official v4 `noRatingWarnings[].type` field.
enum ProblemNoRatingWarningType {
  same('same'),
  searchable('searchable'),
  wrongInputs('wrong-inputs'),
  insufficientConditions('insufficient-conditions'),
  noSpecialJudge('no-special-judge'),
  wrongConditions('wrong-conditions'),
  wrongStatement('wrong-statement');

  const ProblemNoRatingWarningType(this.value);

  final String value;
}

/// Codes exposed by official v4 problem `userStatus` fields.
enum ProblemUserStatus {
  solved('solved'),
  partial('partial'),
  tried('tried');

  const ProblemUserStatus(this.value);

  final String value;
}

/// A warning reported by the official v4 `noRatingWarnings` field.
final class ProblemNoRatingWarning {
  const ProblemNoRatingWarning({required this.type, required this.problem});

  final ProblemNoRatingWarningType type;
  final ProblemNoRatingWarningProblem? problem;
}

/// The exact related-problem shape nested inside a no-rating warning.
final class ProblemNoRatingWarningProblem {
  const ProblemNoRatingWarningProblem({
    required this.problemId,
    required this.subId,
    required this.level,
    required this.effectiveVoteCount,
    required this.givesNoRating,
    required this.isStandard,
    required this.userStatus,
  });

  final num problemId;
  final String subId;
  final num level;
  final num effectiveVoteCount;
  final bool givesNoRating;
  final bool isStandard;
  final ProblemUserStatus? userStatus;
}
