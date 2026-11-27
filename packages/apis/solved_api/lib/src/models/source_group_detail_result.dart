import 'source_groups_result.dart';

/// One official v4 source group with its path, child groups, and contests.
final class SourceGroupDetailResult {
  const SourceGroupDetailResult({
    required this.group,
    required this.path,
    required this.links,
    required this.query,
    required this.groups,
    required this.contests,
  });

  final SourceGroupSummary group;

  /// Path entries in wire order. No relation to [group] is implied.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable, as are [links], [groups], and [contests].
  final List<SourcePathEntry> path;

  final List<SourceLink> links;

  /// Raw required nullable query string. No search syntax is implied.
  final String? query;

  /// Child groups in wire order, including duplicates.
  final List<SourceGroupSummary> groups;

  /// Contests in wire order, including duplicates.
  final List<SourceContestSummary> contests;
}

/// One entry in an official v4 source path.
final class SourcePathEntry {
  const SourcePathEntry({required this.id, required this.name});

  /// Raw finite response number. Integer semantics and bounds are not implied.
  final num id;

  final String name;
}

/// One external judge link of an official v4 source.
final class SourceLink {
  const SourceLink({
    required this.ojId,
    required this.ojName,
    required this.url,
  });

  final String ojId;
  final String ojName;

  /// Raw response value. URI validity is not implied.
  final String url;
}

/// One contest summary from an official v4 source group.
final class SourceContestSummary {
  const SourceContestSummary({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.startsAt,
    required this.problemCount,
    required this.solvedCount,
    required this.level,
  });

  /// Raw finite response number. Integer semantics and bounds are not implied.
  final num id;

  final String name;

  /// Raw required nullable abbreviation.
  final String? abbreviation;

  /// Raw required nullable `date-time` string. It is not parsed.
  final String? startsAt;

  /// Raw finite count. The schema declares no bounds.
  final num problemCount;

  /// Raw required nullable finite count. No relation to [problemCount].
  final num? solvedCount;

  /// Required nullable level summary.
  final SourceLevelSummary? level;
}
