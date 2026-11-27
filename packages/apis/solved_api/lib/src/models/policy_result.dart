/// Official v4 policy documents.
enum PolicySlug {
  tos('tos'),
  tosRecurring('tos_recurring'),
  privacy('privacy'),
  chromePrivacy('chrome_privacy'),
  guideline('guideline'),
  rules('rules'),
  developerTerms('developer_terms'),
  partnerTerms('partner_terms');

  const PolicySlug(this.value);

  final String value;
}

/// One version of an official v4 policy document.
final class PolicyResult {
  const PolicyResult({
    required this.slug,
    required this.version,
    required this.label,
    required this.announcedAt,
    required this.effectiveAt,
    required this.language,
    required this.title,
    required this.content,
    required this.revisedAt,
    required this.isCurrent,
    required this.currentLabel,
    required this.versions,
  });

  /// Response slug. It need not equal the requested slug.
  final PolicySlug slug;

  /// Raw version and label strings. No format is inferred.
  final String version;
  final String label;

  /// Raw required nullable date string. It is not parsed.
  final String? announcedAt;

  /// Raw date string. It is not parsed or ordered.
  final String effectiveAt;

  /// Raw served language. It need not equal the requested language.
  final String language;

  final String title;
  final PolicyContent content;

  /// Raw required nullable date string. It is not parsed.
  final String? revisedAt;

  final bool isCurrent;

  /// Raw required nullable label. No relation to [label] is implied.
  final String? currentLabel;

  /// Versions in wire order, including duplicates. No ordering is enforced.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable.
  final List<PolicyVersion> versions;
}

/// Policy text, discriminated by wire `format`.
sealed class PolicyContent {
  const PolicyContent();
}

/// Wire `format: markdown`.
final class PolicyMarkdownContent extends PolicyContent {
  const PolicyMarkdownContent({required this.body});

  /// Raw markdown source. It is not rendered or sanitized.
  final String body;
}

/// Wire `format: tiptap`.
final class PolicyTiptapContent extends PolicyContent {
  const PolicyTiptapContent({required this.doc});

  /// The raw document object, recursively source-isolated and unmodifiable.
  ///
  /// The schema only requires `type: "doc"` and, when present, an array
  /// `content`. Every other key and node is kept as opaque JSON.
  final Map<String, Object?> doc;
}

/// One listed version of an official v4 policy document.
final class PolicyVersion {
  const PolicyVersion({
    required this.version,
    required this.label,
    required this.announcedAt,
    required this.effectiveAt,
  });

  final String version;
  final String label;

  /// Raw required nullable date string. It is not parsed.
  final String? announcedAt;

  /// Raw date string. It is not parsed or ordered.
  final String effectiveAt;
}
