/// The official v4 top-level source groups.
final class SourceGroupsResult {
  const SourceGroupsResult({required this.groups});

  /// Groups in wire order, including duplicates.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable.
  final List<SourceGroupSummary> groups;
}

/// The official v4 problem order of a source group or contest.
enum SourceProblemOrder {
  ascending('ascending'),
  random('random'),
  mixed('mixed');

  const SourceProblemOrder(this.value);

  final String value;
}

/// One source group summary from the official v4 source schema.
final class SourceGroupSummary {
  const SourceGroupSummary({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.groupCount,
    required this.contestCount,
    required this.problemCount,
    required this.solvedCount,
    required this.level,
    required this.order,
  });

  /// Raw finite response number. Integer semantics and bounds are not implied.
  final num id;

  final String name;

  /// Raw required nullable abbreviation.
  final String? abbreviation;

  /// Raw finite counts. The schema declares no bounds or relationships.
  final num groupCount;
  final num contestCount;

  /// Raw required nullable finite counts. No relationship is implied.
  final num? problemCount;
  final num? solvedCount;

  /// Required nullable level summary.
  final SourceLevelSummary? level;

  /// Required nullable problem order. No relation to [level] is implied.
  final SourceProblemOrder? order;
}

/// Level statistics shared by official v4 source groups and contests.
final class SourceLevelSummary {
  const SourceLevelSummary({
    required this.q25,
    required this.q50,
    required this.q75,
    required this.tierCounts,
    required this.ratedCount,
    required this.order,
    required this.progress,
  });

  /// Raw integer quartiles. The schema declares no bounds or ordering.
  final int q25;
  final int q50;
  final int q75;

  /// Raw integer counts in wire order. No length or index meaning is implied.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable.
  final List<int> tierCounts;

  /// Raw integer count. No relationship to [tierCounts] is implied.
  final int ratedCount;

  /// Required nullable problem order.
  final SourceProblemOrder? order;

  /// Required nullable viewer progress. Its presence does not imply auth.
  final SourceLevelProgress? progress;
}

/// Viewer progress embedded in an official v4 source level summary.
final class SourceLevelProgress {
  const SourceLevelProgress({required this.solved, required this.through});

  /// Raw integer count. The schema declares no bounds.
  final int solved;

  final SourceLevelProgressThrough through;
}

/// Which quartiles the viewer has reached in an official v4 source level.
final class SourceLevelProgressThrough {
  const SourceLevelProgressThrough({
    required this.q25,
    required this.q50,
    required this.q75,
  });

  final bool q25;
  final bool q50;
  final bool q75;
}
