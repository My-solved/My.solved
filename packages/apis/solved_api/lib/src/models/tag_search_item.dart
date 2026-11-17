class TagSearchItem {
  const TagSearchItem({required this.key, required this.problemCount});

  final String key;

  /// Number of problems carrying this tag, when the source provides it.
  ///
  /// The official v4 `/tags` catalog does not include this value, so v4
  /// search results preserve it as `null` instead of manufacturing zero.
  final int? problemCount;
}
