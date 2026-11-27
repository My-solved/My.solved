import 'problem_search_item.dart';
import 'source_group_detail_result.dart';
import 'source_groups_result.dart';

/// One official v4 source contest with its path and problems.
final class SourceContestDetailResult {
  const SourceContestDetailResult({
    required this.contest,
    required this.path,
    required this.links,
    required this.query,
    required this.problems,
  });

  final SourceContestDetail contest;

  /// Path entries in wire order. No relation to [contest] is implied.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable, as are [links] and [problems].
  final List<SourcePathEntry> path;

  final List<SourceLink> links;

  /// Raw required nullable query string. No search syntax is implied.
  final String? query;

  /// Problems in wire order, including duplicates.
  final List<SourceContestProblem> problems;
}

/// The contest of an official v4 source contest response.
final class SourceContestDetail {
  const SourceContestDetail({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.startsAt,
    required this.problemCount,
    required this.solvedCount,
    required this.level,
    required this.url,
    required this.venue,
  });

  /// Raw finite response number. Integer semantics and bounds are not implied.
  final num id;

  final String name;

  /// Raw required nullable abbreviation.
  final String? abbreviation;

  /// Raw required nullable `date-time` string. It is not parsed.
  final String? startsAt;

  /// Raw finite count. No relation to [SourceContestDetailResult.problems].
  final num problemCount;

  /// Raw required nullable finite count. No relation to [problemCount].
  final num? solvedCount;

  /// Required nullable level summary.
  final SourceLevelSummary? level;

  /// Raw required nullable value. URI validity is not implied.
  final String? url;

  /// Raw required nullable venue.
  final String? venue;
}

/// One problem in an official v4 source contest.
final class SourceContestProblem {
  const SourceContestProblem({
    required this.numberInContest,
    required this.problem,
  });

  /// Raw label within the contest. No ordering or format is implied.
  final String numberInContest;

  /// The problem, in the exact official v4 problem-search item shape.
  final ProblemSearchItem problem;
}
