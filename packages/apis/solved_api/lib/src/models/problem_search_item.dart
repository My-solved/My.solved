import 'problem_no_rating_warning.dart';
import 'problem_search_contest.dart';
import 'problem_search_tag.dart';
import 'problem_search_title.dart';

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
    this.id,
    this.subId,
    this.titles,
    this.contests,
    this.tags,
    this.levelAverage,
    this.levelStdev,
    this.isStandard,
    this.userStatus,
    this.votedUserCount,
    this.effectiveVoteCount,
    this.solvedUserCount,
    this.givesNoRating,
    this.noRatingReasons,
    this.noRatingWarnings,
  });

  final int problemId;

  /// The raw v4 problem identifier reported by the active contract.
  /// `null` means the contract did not provide it.
  final num? id;

  /// The raw v4 sub-identifier reported by the active contract.
  /// `null` means the contract did not provide it.
  final String? subId;

  final String? title;

  /// Full official-v4 title entries reported by the active contract.
  ///
  /// `null` means this complete representation is unavailable, including on
  /// the legacy v3 contract. An empty list means v4 explicitly reported no
  /// titles.
  final List<ProblemSearchTitle>? titles;

  /// Contest associations reported by the official v4 contract.
  ///
  /// `null` means this complete representation is unavailable, including on
  /// the legacy v3 contract. An empty list means v4 explicitly reported no
  /// associated contests.
  final List<ProblemSearchContest>? contests;

  /// Full official-v4 tag entries reported by the active contract.
  ///
  /// `null` means this complete representation is unavailable, including on
  /// the legacy v3 contract. An empty list means v4 explicitly reported no
  /// tags.
  final List<ProblemSearchTag>? tags;

  final int level;

  /// The raw level average reported by the active contract.
  /// `null` means the contract did not provide it.
  final num? levelAverage;

  /// The raw level standard deviation reported by the active contract.
  /// `null` means the contract did not provide it.
  final num? levelStdev;

  /// The raw standard-problem marker reported by the active contract.
  /// `null` means the contract did not provide it.
  final bool? isStandard;

  /// The user-specific problem status reported by the active contract.
  /// `null` means no status was reported or the contract did not provide it.
  final ProblemUserStatus? userStatus;

  /// The raw voted-user count reported by the active contract.
  /// `null` means the contract did not provide it.
  final num? votedUserCount;

  /// The raw effective-vote count reported by the active contract.
  /// `null` means the contract did not provide it.
  final num? effectiveVoteCount;

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
