/// The official v4 regions that have a public ranking.
final class RankingRegionsResult {
  const RankingRegionsResult({required this.regions});

  /// Regions in the wire order supplied by solved.ac.
  ///
  /// Decoder-produced lists are source-isolated and unmodifiable.
  final List<RankingRegion> regions;
}

/// One region and its reported user total.
final class RankingRegion {
  const RankingRegion({required this.countryCode, required this.userCount});

  /// Raw country code. The schema declares no format or length constraint.
  final String countryCode;

  /// Raw user count. The schema declares no lower or upper bound.
  final int userCount;
}
