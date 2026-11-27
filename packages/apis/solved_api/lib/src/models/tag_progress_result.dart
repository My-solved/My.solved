/// The viewer's per-tag progress from the official v4 API.
final class TagProgressResult {
  const TagProgressResult({
    required this.counts,
    required this.items,
    required this.ratings,
  });

  /// Lists in wire order, including duplicates. No join between the lists by
  /// `key`, completeness, or ordering is implied.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable.
  final List<TagProblemCount> counts;
  final List<TagProgressItem> items;
  final List<TagRating> ratings;
}

/// The number of problems under one tag.
final class TagProblemCount {
  const TagProblemCount({required this.key, required this.problemCount});

  final String key;

  /// Raw integer. The schema declares no bounds.
  final int problemCount;
}

/// The viewer's solved and tried counts under one tag.
final class TagProgressItem {
  const TagProgressItem({
    required this.key,
    required this.solved,
    required this.tried,
  });

  final String key;

  /// Raw integers. No bounds or relationship are implied.
  final int solved;
  final int tried;
}

/// The viewer's rating under one tag.
final class TagRating {
  const TagRating({required this.key, required this.rating});

  final String key;

  /// Raw integer. The schema declares no bounds.
  final int rating;
}
