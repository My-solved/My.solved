import 'profile_contribution_stats.dart';

/// One raw day/value entry from the official v4 reputation history.
final class ProfileReputationHistoryEntry {
  const ProfileReputationHistoryEntry({
    required this.day,
    required this.value,
  });

  /// Raw `YYYY-MM-DD` token. Calendar validity is not implied.
  final String day;
  final int value;
}

/// Today's contribution quota values in the official v4 reputation response.
final class ProfileReputationTodayContributions {
  const ProfileReputationTodayContributions({
    required this.count,
    required this.max,
  });

  final int count;
  final int max;
}

/// Today's helpful-reputation values in the official v4 response.
final class ProfileReputationTodayHelpful {
  const ProfileReputationTodayHelpful({
    required this.earned,
    required this.cap,
  });

  final int earned;
  final int cap;
}

/// Today's nested reputation breakdown in the official v4 response.
final class ProfileReputationToday {
  const ProfileReputationToday({
    required this.contributions,
    required this.helpful,
  });

  final ProfileReputationTodayContributions contributions;
  final ProfileReputationTodayHelpful helpful;
}

/// The complete official v4 reputation result.
final class ProfileReputationResult extends ProfileContributionStats {
  const ProfileReputationResult({
    required super.reputation,
    required super.scoringCount,
    required super.helpfulCount,
    required super.vouchedCount,
    required this.history,
    required this.today,
  });

  /// History in wire order, including duplicates.
  ///
  /// Decoder-produced lists are unmodifiable. An empty list is authoritative.
  final List<ProfileReputationHistoryEntry> history;

  final ProfileReputationToday today;
}
