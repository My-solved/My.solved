import 'profile_activity_feed_result.dart';

/// What moved a user's reputation, from the official v4 reputation log.
final class ProfileReputationLogResult {
  const ProfileReputationLogResult({
    required this.days,
    required this.firstDay,
  });

  /// Days in wire order, including duplicates. No ordering is enforced.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable.
  final List<ProfileReputationLogDay> days;

  /// Raw required nullable `YYYY-MM-DD` token. Calendar validity and any
  /// relation to [days] are not implied.
  final String? firstDay;
}

/// One day of an official v4 reputation log.
final class ProfileReputationLogDay {
  const ProfileReputationLogDay({
    required this.day,
    required this.change,
    required this.after,
    required this.capped,
    required this.items,
    required this.others,
  });

  /// Raw `YYYY-MM-DD` token. Calendar validity is not implied.
  final String day;

  /// Raw integers. The schema declares no bounds or arithmetic relationship.
  final int change;
  final int after;
  final int capped;

  /// Items in wire order, including duplicates.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable.
  final List<ProfileReputationLogItem> items;

  /// Required nullable remainder. No relation to [items] is implied.
  final ProfileReputationLogOthers? others;
}

/// The official v4 reputation log item kinds.
enum ProfileReputationLogKind {
  contribution('contribution'),
  helpful('helpful'),
  unhelpful('unhelpful'),
  markedUnhelpful('markedUnhelpful'),
  takedown('takedown');

  const ProfileReputationLogKind(this.value);

  final String value;
}

/// One reputation change source within a day.
final class ProfileReputationLogItem {
  const ProfileReputationLogItem({
    required this.kind,
    required this.problem,
    required this.count,
    required this.points,
  });

  final ProfileReputationLogKind kind;

  /// Required nullable problem in the exact activity-feed problem shape.
  final ProfileActivityFeedProblem? problem;

  /// Raw integers. The schema declares no bounds or relationship.
  final int count;
  final int points;
}

/// Reputation changes not itemized within a day.
final class ProfileReputationLogOthers {
  const ProfileReputationLogOthers({required this.count, required this.points});

  /// Raw integers. The schema declares no bounds or relationship.
  final int count;
  final int points;
}
