/// The official v4 tags that have a public ranking.
final class RankingTagsResult {
  const RankingTagsResult({required this.tags});

  /// Tags in the wire order supplied by solved.ac.
  ///
  /// Decoder-produced lists are source-isolated and unmodifiable.
  final List<RankingTag> tags;
}

/// One ranked tag and its localized display name.
final class RankingTag {
  const RankingTag({
    required this.key,
    required this.ratingTagIndex,
    required this.displayName,
  });

  /// Raw tag key. The schema declares no format or length constraint.
  final String key;

  /// Raw rating slot index. The schema declares no lower or upper bound.
  final int ratingTagIndex;

  /// Raw display name for the requested language.
  final String displayName;
}
