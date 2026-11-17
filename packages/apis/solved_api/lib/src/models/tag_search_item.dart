class TagSearchItem {
  const TagSearchItem({
    required this.key,
    required this.problemCount,
    this.displayName,
    this.id,
    this.isMeta,
    this.parents,
    this.names,
    this.aliases,
    this.rated,
  });

  final String key;

  /// The official v4 catalog identifier, when provided by the source.
  ///
  /// The v3 tag identifier is not assumed to share this namespace.
  final num? id;

  /// Whether this is a meta tag in the official v4 catalog.
  final bool? isMeta;

  /// Immediate parent keys from the official v4 catalog.
  ///
  /// Decoder-produced lists are unmodifiable. A `null` value means the source
  /// did not provide the v4 catalog field, while an empty list is authoritative.
  final List<String>? parents;

  /// Raw locale-to-name entries from the official v4 catalog.
  ///
  /// Decoder-produced maps are unmodifiable. [displayName] remains the
  /// presentation-oriented projection used by existing callers.
  final Map<String, String>? names;

  /// Raw search aliases from the official v4 catalog.
  ///
  /// Decoder-produced lists are unmodifiable.
  final List<String>? aliases;

  /// Whether the official v4 catalog marks this tag as rated.
  final bool? rated;

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
