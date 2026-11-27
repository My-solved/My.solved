import 'problem_search_tag.dart';

/// Points and aggregate figures for an official v4 problem vote graph.
final class ProblemVoteSummaryResult {
  const ProblemVoteSummaryResult({
    required this.items,
    required this.tagDistribution,
  });

  /// Points in wire order, including duplicates. No ordering is enforced.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable, as is [tagDistribution].
  final List<ProblemVoteSummaryPoint> items;

  /// Tag shares in wire order, including duplicates.
  final List<ProblemVoteTagShare> tagDistribution;
}

/// One point of an official v4 problem vote graph.
final class ProblemVoteSummaryPoint {
  const ProblemVoteSummaryPoint({
    required this.votedAt,
    required this.level,
    required this.weight,
    required this.invalidated,
    required this.notInCalculation,
    required this.banned,
    required this.cutoff,
  });

  /// Raw string. It is not parsed or ordered.
  final String votedAt;

  /// Raw required nullable finite number. No bounds are implied.
  final num? level;

  /// Raw finite number. No bounds are implied.
  final num weight;

  /// Raw flags. No relationship between them is implied.
  final bool invalidated;
  final bool notInCalculation;
  final bool banned;
  final bool cutoff;
}

/// One tag share of an official v4 problem vote summary.
final class ProblemVoteTagShare {
  const ProblemVoteTagShare({
    required this.tag,
    required this.count,
    required this.denominator,
  });

  /// The tag, in the exact problem-search tag shape.
  final ProblemSearchTag tag;

  /// Raw finite numbers. No ratio, bounds, or relationship is implied.
  final num count;
  final num denominator;
}
