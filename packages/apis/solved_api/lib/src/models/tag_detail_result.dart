/// The official detail response for one solved.ac tag.
final class TagDetailResult {
  const TagDetailResult({
    required this.id,
    required this.key,
    required this.names,
    required this.aliases,
    required this.parents,
    required this.children,
    required this.rated,
    required this.problemCount,
    required this.solvedCount,
    required this.levels,
  });

  final num id;
  final String key;

  /// Raw locale-to-name entries in wire order.
  ///
  /// Decoder-produced maps are source-isolated and unmodifiable.
  final Map<String, String> names;

  /// Raw aliases in wire order, including duplicates.
  ///
  /// Decoder-produced lists are source-isolated and unmodifiable.
  final List<String> aliases;

  /// Raw parent-tag relationships in wire order, including duplicates.
  ///
  /// Decoder-produced lists are source-isolated and unmodifiable.
  final List<TagDetailRelatedTag> parents;

  /// Raw child-tag relationships in wire order, including duplicates.
  ///
  /// Decoder-produced lists are source-isolated and unmodifiable.
  final List<TagDetailRelatedTag> children;

  final bool rated;
  final int problemCount;

  /// The authenticated viewer's solved count, when the server supplies one.
  ///
  /// This key is required by the wire contract even when its value is `null`.
  final int? solvedCount;

  /// Per-level statistics in wire order, including duplicates.
  ///
  /// Decoder-produced lists are source-isolated and unmodifiable.
  final List<TagDetailLevel> levels;
}

/// A parent or child relation embedded in a tag detail response.
final class TagDetailRelatedTag {
  const TagDetailRelatedTag({required this.key, required this.names});

  final String key;

  /// Raw locale-to-name entries in wire order.
  ///
  /// Decoder-produced maps are source-isolated and unmodifiable.
  final Map<String, String> names;
}

/// A per-level statistic embedded in a tag detail response.
final class TagDetailLevel {
  const TagDetailLevel({
    required this.level,
    required this.count,
    required this.solved,
  });

  final int level;
  final int count;

  /// The authenticated viewer's solved count at this level, when supplied.
  ///
  /// This key is required by the wire contract even when its value is `null`.
  final int? solved;
}
