import 'problem_no_rating_warning.dart';

/// One page of an official v4 problem's reports.
final class ProblemReportsResult {
  const ProblemReportsResult({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  /// Reports in wire order, including duplicates. No ordering is enforced.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable.
  final List<ProblemReport> items;

  /// Raw finite numbers. No bounds or relation to [items] are implied, and
  /// the response page need not equal the requested page.
  final num total;
  final num page;
  final num pageSize;
}

/// Review status of an official v4 problem report.
enum ProblemReportStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected'),
  resolved('resolved');

  const ProblemReportStatus(this.value);

  final String value;
}

/// One official v4 problem report.
final class ProblemReport {
  const ProblemReport({
    required this.id,
    required this.user,
    required this.reason,
    required this.sameProblems,
    required this.comment,
    required this.status,
    required this.statusChange,
    required this.createdAt,
  });

  /// Raw finite response number. Integer semantics and bounds are not implied.
  final num id;

  /// Required nullable reporter.
  final ProblemReportUser? user;

  final ProblemReportReason reason;

  /// Problems in wire order, including duplicates. No relation to [reason]
  /// is implied.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable.
  final List<ProblemReportSameProblem> sameProblems;

  final String comment;
  final ProblemReportStatus status;

  /// Required nullable staff decision. No relation to [status] is implied.
  final ProblemReportStatusChange? statusChange;

  /// Raw string. It is not parsed or ordered.
  final String createdAt;
}

/// The reason of an official v4 problem report, discriminated by wire `type`.
sealed class ProblemReportReason {
  const ProblemReportReason();
}

/// Wire `type: same-problem`.
final class ProblemReportSameProblemReason extends ProblemReportReason {
  const ProblemReportSameProblemReason({required this.problemIds});

  /// Positive integers in wire order, 1 through 20 entries, duplicates kept.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable.
  final List<int> problemIds;
}

/// Wire `type: issue`.
final class ProblemReportIssueReason extends ProblemReportReason {
  const ProblemReportIssueReason({required this.url});

  /// Raw string of at most 512 code points. URI validity is not implied.
  final String url;
}

/// Wire `type: issue-resolved`.
final class ProblemReportIssueResolvedReason extends ProblemReportReason {
  const ProblemReportIssueResolvedReason({required this.problemReportId});

  /// Positive integer. No relation to other report IDs is implied.
  final int problemReportId;
}

/// A problem summary attached to an official v4 problem report.
final class ProblemReportSameProblem {
  const ProblemReportSameProblem({
    required this.problemId,
    required this.subId,
    required this.level,
    required this.effectiveVoteCount,
    required this.givesNoRating,
    required this.isStandard,
    required this.userStatus,
  });

  /// Raw finite numbers. The schema declares no integer constraint or bounds.
  final num problemId;
  final String subId;
  final num level;
  final num effectiveVoteCount;

  final bool givesNoRating;
  final bool isStandard;

  /// Required nullable viewer status.
  final ProblemUserStatus? userStatus;
}

/// The staff decision on an official v4 problem report.
final class ProblemReportStatusChange {
  const ProblemReportStatusChange({
    required this.by,
    required this.at,
    required this.comment,
  });

  /// Required nullable staff user.
  final ProblemReportUser? by;

  /// Raw string. It is not parsed.
  final String at;

  /// Raw required nullable comment.
  final String? comment;
}

/// A user summary in an official v4 problem report.
final class ProblemReportUser {
  const ProblemReportUser({
    required this.id,
    required this.handle,
    required this.tier,
    required this.profileImageUrl,
  });

  /// Raw finite response number. Integer semantics and bounds are not implied.
  final num id;

  final String handle;

  /// Required nullable official tier. Non-null values are in the range 0..31.
  final int? tier;

  /// Raw required nullable response value. URI validity is not implied.
  final String? profileImageUrl;
}
