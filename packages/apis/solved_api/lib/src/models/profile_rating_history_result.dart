/// One raw day/value entry from the official v4 rating history.
final class ProfileRatingHistoryEntry {
  const ProfileRatingHistoryEntry({
    required this.day,
    required this.value,
  });

  /// Raw `YYYY-MM-DD` token. Calendar validity is not implied.
  final String day;
  final int value;
}

/// The complete official v4 rating-history result.
final class ProfileRatingHistoryResult {
  const ProfileRatingHistoryResult({required this.history});

  /// History in wire order, including duplicates.
  ///
  /// Decoder-produced lists are unmodifiable. An empty list is authoritative.
  final List<ProfileRatingHistoryEntry> history;
}
