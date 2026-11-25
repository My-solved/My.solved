import 'problem_no_rating_warning.dart';
import 'problem_search_title.dart';

/// Event kinds exposed by the official v4 profile activity feed.
enum ProfileActivityFeedEventType {
  solved('solved'),
  unsolved('unsolved'),
  vote('vote'),
  rating('rating'),
  tier('tier'),
  solvedMilestone('solvedMilestone'),
  voteMilestone('voteMilestone');

  const ProfileActivityFeedEventType(this.value);

  final String value;
}

/// One page of the official v4 reverse-chronological activity feed.
final class ProfileActivityFeedResult {
  const ProfileActivityFeedResult({
    required this.events,
    required this.nextCursor,
  });

  /// Events in wire order, including duplicates.
  ///
  /// Decoder-produced lists are source-isolated and unmodifiable.
  final List<ProfileActivityFeedEvent> events;

  /// The required nullable cursor returned by the API.
  final String? nextCursor;
}

/// One event from the official v4 profile activity feed.
final class ProfileActivityFeedEvent {
  const ProfileActivityFeedEvent({
    required this.id,
    required this.type,
    required this.occurredAt,
    required this.problem,
    required this.reason,
    required this.milestone,
    required this.hasPayload,
    required this.payload,
  });

  final int id;
  final ProfileActivityFeedEventType type;

  /// Raw response value. The schema does not declare a date-time format.
  final String occurredAt;

  final ProfileActivityFeedProblem? problem;
  final String? reason;
  final int? milestone;

  /// Whether the optional `payload` key was present in the wire object.
  final bool hasPayload;

  /// The arbitrary JSON value returned in `payload` when [hasPayload] is true.
  ///
  /// `null` can mean either an explicitly null payload or an absent payload;
  /// consult [hasPayload] to distinguish them. Decoder-produced nested lists
  /// and maps are recursively source-isolated and unmodifiable.
  final Object? payload;
}

/// The exact problem summary nested in an activity-feed event.
final class ProfileActivityFeedProblem {
  const ProfileActivityFeedProblem({
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
  final int level;
  final int effectiveVoteCount;
  final bool givesNoRating;
  final bool isStandard;

  /// Localized titles in wire order, including duplicates.
  ///
  /// Decoder-produced lists are source-isolated and unmodifiable.
  final List<ProblemSearchTitle> titles;

  final ProblemUserStatus? userStatus;
}
