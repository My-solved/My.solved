/// The official v4 level histogram for one user and one tag.
final class ProfileTagLevelHistogramResult {
  const ProfileTagLevelHistogramResult({
    required this.key,
    required this.histogram,
  });

  /// The raw tag key reported by the response.
  final String key;

  /// Buckets in wire order, including negative values and duplicates.
  ///
  /// Decoder-produced lists are unmodifiable. An empty list is authoritative.
  final List<int> histogram;
}
