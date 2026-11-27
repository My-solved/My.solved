/// One official v4 help article.
final class HelpArticleResult {
  const HelpArticleResult({
    required this.slug,
    required this.language,
    required this.title,
    required this.content,
    required this.updatedAt,
  });

  /// Raw response slug. It need not equal the requested slug.
  final String slug;

  /// Raw served language. It need not equal the requested language.
  final String language;

  final String title;

  /// The raw document object, recursively source-isolated and unmodifiable.
  ///
  /// The schema only requires `type: "doc"` and, when present, an array
  /// `content`. Every other key and node is kept as opaque JSON.
  final Map<String, Object?> content;

  /// Raw string. It is not parsed.
  final String updatedAt;
}
