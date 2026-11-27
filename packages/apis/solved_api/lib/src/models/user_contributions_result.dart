import 'problem_no_rating_warning.dart';
import 'problem_search_title.dart';
import 'problem_votes_result.dart';

/// Sort orders of a user's official v4 contributions.
enum UserContributionSort {
  recent('recent'),
  helpful('helpful');

  const UserContributionSort(this.value);

  final String value;
}

/// Filters of a user's official v4 contributions.
enum UserContributionFilter {
  scoring('scoring'),
  helpful('helpful'),
  vouched('vouched');

  const UserContributionFilter(this.value);

  final String value;
}

/// One page of a user's contributions, with what each earns.
final class UserContributionsResult {
  const UserContributionsResult({
    required this.items,
    required this.total,
    required this.hiddenCount,
    required this.page,
    required this.pageSize,
    required this.sort,
  });

  /// Contributions in wire order, including duplicates.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable.
  final List<UserContribution> items;

  /// Raw integers. No relation to [items] or the requested page is inferred.
  final int total;
  final int hiddenCount;
  final int page;
  final int pageSize;

  /// The served sort. It need not equal the requested sort.
  final UserContributionSort sort;
}

/// One contribution: a vote and what it earns.
final class UserContribution {
  const UserContribution({
    required this.voteId,
    required this.problem,
    required this.votedAt,
    required this.points,
    required this.place,
    required this.vote,
  });

  /// Raw integer. No relation to [vote] is inferred.
  final int voteId;

  final ContributionProblem problem;

  /// Raw string. It is not parsed.
  final String votedAt;

  /// Raw integer. The schema declares no bounds.
  final int points;

  /// Raw required nullable integer.
  final int? place;

  /// The vote, in the exact problem-vote shape.
  final ProblemVote vote;
}

/// The problem a contribution is about.
final class ContributionProblem {
  const ContributionProblem({
    required this.problemId,
    required this.subId,
    required this.level,
    required this.effectiveVoteCount,
    required this.givesNoRating,
    required this.isStandard,
    required this.titles,
    required this.userStatus,
  });

  final int problemId;
  final String subId;

  /// Integer from 0 through 30.
  final int level;

  /// Non-negative integer.
  final int effectiveVoteCount;

  final bool givesNoRating;
  final bool isStandard;

  /// Titles in wire order, including duplicates.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable.
  final List<ProblemSearchTitle> titles;

  /// Required nullable status of the viewer, when a token is sent.
  final ProblemUserStatus? userStatus;
}
