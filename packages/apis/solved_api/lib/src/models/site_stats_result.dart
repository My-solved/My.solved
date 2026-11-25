/// The official v4 site-wide totals, as reported by `/site/stats`.
final class SiteStatsResult {
  const SiteStatsResult({
    required this.problemsWithLevel,
    required this.users,
    required this.contributors,
    required this.contributions,
    required this.usersByTier,
  });

  final int problemsWithLevel;
  final int users;
  final int contributors;
  final int contributions;

  /// User totals in the wire order supplied by solved.ac.
  ///
  /// Decoder-produced lists are unmodifiable. The schema does not assign
  /// tier indices or a fixed length to this array.
  final List<int> usersByTier;
}
