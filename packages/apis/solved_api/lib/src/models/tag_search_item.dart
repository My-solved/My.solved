class TagSearchItem {
  const TagSearchItem({
    required this.key,
    required this.problemCount,
    this.displayName,
  });

  final String key;

  /// Preferred localized name, when the source provides a usable one.
  ///
  /// [key] remains the stable solved.ac search identifier and must be kept
  /// alongside this human-readable label.
  final String? displayName;

  /// Number of problems carrying this tag, when the source provides it.
  ///
  /// The official v4 `/tags` catalog does not include this value, so v4
  /// search results preserve it as `null` instead of manufacturing zero.
  final int? problemCount;
}
